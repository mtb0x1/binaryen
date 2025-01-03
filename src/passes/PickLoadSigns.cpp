/*
 * Copyright 2017 WebAssembly Community Group participants
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <ir/properties.h>
#include <pass.h>
#include <wasm.h>

namespace wasm {

//
// Adjust load signedness based on usage. If a load only has uses that sign or
// unsign it anyhow, then it could be either, and picking the popular one can
// help remove the most sign/unsign operations.
//

struct PickLoadSigns : public WalkerPass<ExpressionStackWalker<PickLoadSigns>> {
  bool isFunctionParallel() override { return true; }

  std::unique_ptr<Pass> create() override {
    return std::make_unique<PickLoadSigns>();
  }

  struct Usage {
    Index signedUsages = 0;
    Index signedBits;
    Index unsignedUsages = 0;
    Index unsignedBits;
    Index totalUsages = 0;
  };
  std::vector<Usage> usages; // local index => usage

  // loads that write to a local => the local
  std::unordered_map<Load*, Index> loads;

  void doWalkFunction(Function* func) {
    if (getModule()->memories.empty()) {
      // There can be no loads without a memory.
      return;
    }

    // prepare
    usages.resize(func->getNumLocals());
    // walk
    ExpressionStackWalker<PickLoadSigns>::doWalkFunction(func);
    // optimize
    optimize();
  }

  void visitLocalGet(LocalGet* curr) {
    // This is a use. check from the context what it is, signed or unsigned,
    // etc. Sign- and zero-extends may have two levels of nesting (x << K >> K)
    // or one (x & K), so check both.
    auto& usage = usages[curr->index];
    usage.totalUsages++;
    for (Index i = 2; i <= 3; i++) {
      if (expressionStack.size() < i) {
        // We do not have that many expressions above us. (And if we don't have
        // 2 then we definitely don't have 3.)
        break;
      }

      auto* parent = expressionStack[expressionStack.size() - i];
      if (Properties::getZeroExtValue(parent) == curr) {
        auto bits = Properties::getZeroExtBits(parent);
        if (usage.unsignedUsages == 0) {
          usage.unsignedBits = bits;
        } else if (usage.unsignedBits != bits) {
          usage.unsignedBits = 0;
        }
        usage.unsignedUsages++;
      } else if (Properties::getSignExtValue(parent) == curr) {
        auto bits = Properties::getSignExtBits(parent);
        if (usage.signedUsages == 0) {
          usage.signedBits = bits;
        } else if (usage.signedBits != bits) {
          usage.signedBits = 0;
        }
        usage.signedUsages++;
      }
    }
  }

  void visitLocalSet(LocalSet* curr) {
    if (curr->isTee()) {
      // we can't modify a tee, the value is used elsewhere
      return;
    }
    if (auto* load = curr->value->dynCast<Load>()) {
      loads[load] = curr->index;
    }
  }

  void optimize() {
    // optimize based on the info we saw
    for (auto& [load, index] : loads) {
      auto& usage = usages[index];
      // if we can't optimize, give up
      if (usage.totalUsages == 0 || // no usages, so no idea
          usage.signedUsages + usage.unsignedUsages !=
            usage.totalUsages || // non-sign/unsigned usages, so cannot change
          (usage.signedUsages != 0 &&
           usage.signedBits !=
             load->bytes * 8) || // sign usages exist but the wrong size
          (usage.unsignedUsages != 0 &&
           usage.unsignedBits !=
             load->bytes * 8)) { // unsigned usages exist but the wrong size
        continue;
      }
      // Atomic operations are always unsigned, never signed.
      if (load->isAtomic) {
        continue;
      }
      // we can pick the optimal one. our hope is to remove 2 items per
      // signed use (two shifts), so we factor that in
      load->signed_ = usage.signedUsages * 2 >= usage.unsignedUsages;
    }
  }
};

Pass* createPickLoadSignsPass() { return new PickLoadSigns(); }

} // namespace wasm
