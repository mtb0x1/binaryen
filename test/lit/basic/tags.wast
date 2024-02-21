;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.

;; RUN: wasm-opt %s -all -o %t.text.wast -g -S
;; RUN: wasm-as %s -all -g -o %t.wasm
;; RUN: wasm-dis %t.wasm -all -o %t.bin.wast
;; RUN: wasm-as %s -all -o %t.nodebug.wasm
;; RUN: wasm-dis %t.nodebug.wasm -all -o %t.bin.nodebug.wast
;; RUN: cat %t.text.wast | filecheck %s --check-prefix=CHECK-TEXT
;; RUN: cat %t.bin.wast | filecheck %s --check-prefix=CHECK-BIN
;; RUN: cat %t.bin.nodebug.wast | filecheck %s --check-prefix=CHECK-BIN-NODEBUG

;; Test tags

(module
  (tag $e-import (import "env" "im0") (param i32))
  (import "env" "im1" (tag (param i32 f32)))

  (tag (param i32))

  ;; CHECK-TEXT:      (type $0 (func (param i32 f32)))

  ;; CHECK-TEXT:      (type $1 (func (param i32)))

  ;; CHECK-TEXT:      (type $2 (func))

  ;; CHECK-TEXT:      (import "env" "im0" (tag $e-import (param i32)))

  ;; CHECK-TEXT:      (import "env" "im1" (tag $eimport$1 (param i32 f32)))

  ;; CHECK-TEXT:      (tag $2 (param i32))

  ;; CHECK-TEXT:      (tag $e (param i32 f32))
  ;; CHECK-BIN:      (type $0 (func (param i32 f32)))

  ;; CHECK-BIN:      (type $1 (func (param i32)))

  ;; CHECK-BIN:      (type $2 (func))

  ;; CHECK-BIN:      (import "env" "im0" (tag $e-import (param i32)))

  ;; CHECK-BIN:      (import "env" "im1" (tag $eimport$1 (param i32 f32)))

  ;; CHECK-BIN:      (tag $tag$0 (param i32))

  ;; CHECK-BIN:      (tag $e (param i32 f32))
  (tag $e (param i32 f32))
  ;; CHECK-TEXT:      (tag $empty)
  ;; CHECK-BIN:      (tag $empty)
  (tag $empty)

  ;; CHECK-TEXT:      (tag $e-params0 (param i32 f32))
  ;; CHECK-BIN:      (tag $e-params0 (param i32 f32))
  (tag $e-params0 (param i32 f32))
  ;; CHECK-TEXT:      (tag $e-params1 (param i32 f32))
  ;; CHECK-BIN:      (tag $e-params1 (param i32 f32))
  (tag $e-params1 (param i32) (param f32))

  ;; CHECK-TEXT:      (tag $e-export (param i32))
  ;; CHECK-BIN:      (tag $e-export (param i32))
  (tag $e-export (export "ex0") (param i32))

  ;; CHECK-TEXT:      (export "ex0" (tag $e-export))

  ;; CHECK-TEXT:      (export "ex1" (tag $e))
  ;; CHECK-BIN:      (export "ex0" (tag $e-export))

  ;; CHECK-BIN:      (export "ex1" (tag $e))
  (export "ex1" (tag $e))
)
;; CHECK-BIN-NODEBUG:      (type $0 (func (param i32 f32)))

;; CHECK-BIN-NODEBUG:      (type $1 (func (param i32)))

;; CHECK-BIN-NODEBUG:      (type $2 (func))

;; CHECK-BIN-NODEBUG:      (import "env" "im0" (tag $eimport$0 (param i32)))

;; CHECK-BIN-NODEBUG:      (import "env" "im1" (tag $eimport$1 (param i32 f32)))

;; CHECK-BIN-NODEBUG:      (tag $tag$0 (param i32))

;; CHECK-BIN-NODEBUG:      (tag $tag$1 (param i32 f32))

;; CHECK-BIN-NODEBUG:      (tag $tag$2)

;; CHECK-BIN-NODEBUG:      (tag $tag$3 (param i32 f32))

;; CHECK-BIN-NODEBUG:      (tag $tag$4 (param i32 f32))

;; CHECK-BIN-NODEBUG:      (tag $tag$5 (param i32))

;; CHECK-BIN-NODEBUG:      (export "ex0" (tag $tag$5))

;; CHECK-BIN-NODEBUG:      (export "ex1" (tag $tag$1))