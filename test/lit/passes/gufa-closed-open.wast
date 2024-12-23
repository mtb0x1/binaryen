;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.
;; RUN: foreach %s %t wasm-opt -all --gufa                -S -o - | filecheck %s --check-prefix OPEND
;; RUN: foreach %s %t wasm-opt -all --gufa --closed-world -S -o - | filecheck %s --check-prefix CLOSE

;; Compare behavior on closed and open world. In open world we must assume that
;; funcrefs, for example, can be called from outside.

(module
 ;; OPEND:      (type $0 (func (param funcref)))

 ;; OPEND:      (type $1 (func))

 ;; OPEND:      (type $2 (func (param i32)))

 ;; OPEND:      (import "fuzzing-support" "call-ref-catch" (func $external-caller (type $0) (param funcref)))
 ;; CLOSE:      (type $0 (func (param funcref)))

 ;; CLOSE:      (type $1 (func))

 ;; CLOSE:      (type $2 (func (param i32)))

 ;; CLOSE:      (import "fuzzing-support" "call-ref-catch" (func $external-caller (type $0) (param funcref)))
 (import "fuzzing-support" "call-ref-catch" (func $external-caller (param funcref)))

 ;; OPEND:      (elem declare func $func)

 ;; OPEND:      (export "call-import" (func $call-import))

 ;; OPEND:      (func $call-import (type $1)
 ;; OPEND-NEXT:  (call $external-caller
 ;; OPEND-NEXT:   (ref.func $func)
 ;; OPEND-NEXT:  )
 ;; OPEND-NEXT: )
 ;; CLOSE:      (elem declare func $func)

 ;; CLOSE:      (export "call-import" (func $call-import))

 ;; CLOSE:      (func $call-import (type $1)
 ;; CLOSE-NEXT:  (call $external-caller
 ;; CLOSE-NEXT:   (ref.func $func)
 ;; CLOSE-NEXT:  )
 ;; CLOSE-NEXT: )
 (func $call-import (export "call-import")
  ;; Send a reference to $func to the outside, which may call it.
  (call $external-caller
   (ref.func $func)
  )
 )

 ;; OPEND:      (func $func (type $2) (param $0 i32)
 ;; OPEND-NEXT:  (drop
 ;; OPEND-NEXT:   (local.get $0)
 ;; OPEND-NEXT:  )
 ;; OPEND-NEXT: )
 ;; CLOSE:      (func $func (type $2) (param $0 i32)
 ;; CLOSE-NEXT:  (drop
 ;; CLOSE-NEXT:   (unreachable)
 ;; CLOSE-NEXT:  )
 ;; CLOSE-NEXT: )
 (func $func (param $0 i32)
  ;; This is called from the outside, so this is not dead code, and nothing
  ;; should change here in open world. In closed world, this can become an
  ;; unreachable, since nothing can call it.
  (drop
   (local.get $0)
  )
 )
)
