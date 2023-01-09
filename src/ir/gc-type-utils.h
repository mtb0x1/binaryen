/*
 * Copyright 2021 WebAssembly Community Group participants
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

#ifndef wasm_ir_gc_type_utils_h
#define wasm_ir_gc_type_utils_h

#include "wasm.h"

namespace wasm::GCTypeUtils {

// Helper code to evaluate a reference at compile time and check if it is of a
// certain kind. Various wasm instructions check if something is a function or
// data etc., and that code is shared here.

enum Kind { Func, Data, I31, Other };

enum EvaluationResult {
  // The result is not known at compile time.
  Unknown,
  // The evaluation is known to succeed (i.e., we find what we are looking
  // for), or fail, at compile time.
  Success,
  Failure
};

// Given an instruction that checks if the child reference is of a certain kind
// (like br_on_func checks if it is a function), see if type info lets us
// determine that at compile time.
// This ignores nullability - it just checks the kind.
inline EvaluationResult evaluateKindCheck(Expression* curr) {
  Kind expected;
  Expression* child;

  // Some operations flip the condition.
  bool flip = false;

  if (auto* br = curr->dynCast<BrOn>()) {
    switch (br->op) {
      // We don't check nullability here.
      case BrOnNull:
      case BrOnNonNull:
        return Unknown;
      case BrOnCastFail:
        flip = true;
        [[fallthrough]];
      case BrOnCast:
        // If we already have a subtype of the cast type, the cast will succeed.
        if (Type::isSubType(br->ref->type, br->castType)) {
          return flip ? Failure : Success;
        }
        // If the cast type is unrelated to the type we have and it's not
        // possible for the cast to succeed anyway because the value is null,
        // then the cast will certainly fail. TODO: This is essentially the same
        // as `canBeCastTo` in OptimizeInstructions. Find a way to deduplicate
        // this logic.
        if (!Type::isSubType(br->castType, br->ref->type) &&
            (br->castType.isNonNullable() || br->ref->type.isNonNullable())) {
          return flip ? Success : Failure;
        }
        return Unknown;
      default:
        WASM_UNREACHABLE("unhandled BrOn");
    }
    child = br->ref;
  } else if (auto* as = curr->dynCast<RefAs>()) {
    switch (as->op) {
      // We don't check nullability here.
      case RefAsNonNull:
        return Unknown;
      case RefAsFunc:
        expected = Func;
        break;
      case RefAsData:
        expected = Data;
        break;
      case RefAsI31:
        expected = I31;
        break;
      case ExternInternalize:
      case ExternExternalize:
        // These instructions can never be removed.
        return Unknown;
      default:
        WASM_UNREACHABLE("unhandled RefAs");
    }
    child = as->value;
  } else {
    WASM_UNREACHABLE("invalid input to evaluateKindCheck");
  }

  auto childType = child->type;

  Kind actual;

  if (childType == Type::unreachable) {
    return Unknown;
  } else if (childType.isFunction()) {
    actual = Func;
  } else if (childType.isData()) {
    actual = Data;
  } else if (childType.getHeapType() == HeapType::i31) {
    actual = I31;
  } else {
    return Unknown;
  }

  auto success = actual == expected;
  if (flip) {
    success = !success;
  }
  return success ? Success : Failure;
}

} // namespace wasm::GCTypeUtils

#endif // wasm_ir_gc_type_utils_h
