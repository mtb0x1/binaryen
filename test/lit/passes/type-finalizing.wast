;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.
;; RUN: foreach %s %t wasm-opt -all --type-unfinalizing -S -o - | filecheck %s --check-prefix UNFINAL
;; RUN: foreach %s %t wasm-opt -all --type-finalizing   -S -o - | filecheck %s --check-prefix DOFINAL

;; The public types should never be modified. The private ones should become
;; final or not depending on what we do.
(module
  ;; Types.

  ;; UNFINAL:      (type $open-public (sub (struct (field i32))))
  ;; DOFINAL:      (type $open-public (sub (struct (field i32))))
  (type $open-public (sub (struct (field i32))))

  ;; UNFINAL:      (type $final-public (struct (field i64)))
  ;; DOFINAL:      (type $final-public (struct (field i64)))
  (type $final-public (sub final (struct (field i64))))

  ;; UNFINAL:      (rec
  ;; UNFINAL-NEXT:  (type $final-private (sub (struct (field f64))))
  ;; DOFINAL:      (rec
  ;; DOFINAL-NEXT:  (type $final-private (struct (field f64)))
  (type $final-private (sub final (struct (field f64))))

  ;; UNFINAL:       (type $open-private (sub (struct (field f32))))
  ;; DOFINAL:       (type $open-private (struct (field f32)))
  (type $open-private (sub (struct (field f32))))

  ;; Globals.

  ;; UNFINAL:      (global $open-public (ref null $open-public) (ref.null none))
  ;; DOFINAL:      (global $open-public (ref null $open-public) (ref.null none))
  (global $open-public (ref null $open-public) (ref.null $open-public))

  ;; UNFINAL:      (global $final-public (ref null $final-public) (ref.null none))
  ;; DOFINAL:      (global $final-public (ref null $final-public) (ref.null none))
  (global $final-public (ref null $final-public) (ref.null $final-public))

  ;; UNFINAL:      (global $open-private (ref null $open-private) (ref.null none))
  ;; DOFINAL:      (global $open-private (ref null $open-private) (ref.null none))
  (global $open-private (ref null $open-private) (ref.null $open-private))

  ;; UNFINAL:      (global $final-private (ref null $final-private) (ref.null none))
  ;; DOFINAL:      (global $final-private (ref null $final-private) (ref.null none))
  (global $final-private (ref null $final-private) (ref.null $final-private))

  ;; Exports.

  ;; UNFINAL:      (export "a" (global $open-public))
  ;; DOFINAL:      (export "a" (global $open-public))
  (export "a" (global $open-public))
  ;; UNFINAL:      (export "b" (global $final-public))
  ;; DOFINAL:      (export "b" (global $final-public))
  (export "b" (global $final-public))
)

;; Test we do not make a type with a subtype final. $parent should always
;; remain open, while the children can be modified.
(module
  (rec
    ;; UNFINAL:      (rec
    ;; UNFINAL-NEXT:  (type $parent (sub (struct)))
    ;; DOFINAL:      (rec
    ;; DOFINAL-NEXT:  (type $parent (sub (struct)))
    (type $parent (sub (struct)))

    ;; UNFINAL:       (type $child-open (sub $parent (struct)))
    ;; DOFINAL:       (type $child-open (sub final $parent (struct)))
    (type $child-open (sub $parent (struct)))

    ;; UNFINAL:       (type $child-final (sub $parent (struct)))
    ;; DOFINAL:       (type $child-final (sub final $parent (struct)))
    (type $child-final (sub final $parent (struct)))
  )

  ;; UNFINAL:       (type $3 (sub (func)))

  ;; UNFINAL:      (func $keepalive (type $3)
  ;; UNFINAL-NEXT:  (local $parent (ref $parent))
  ;; UNFINAL-NEXT:  (local $child-final (ref $child-final))
  ;; UNFINAL-NEXT:  (local $child-open (ref $child-open))
  ;; UNFINAL-NEXT: )
  ;; DOFINAL:       (type $3 (func))

  ;; DOFINAL:      (func $keepalive (type $3)
  ;; DOFINAL-NEXT:  (local $parent (ref $parent))
  ;; DOFINAL-NEXT:  (local $child-final (ref $child-final))
  ;; DOFINAL-NEXT:  (local $child-open (ref $child-open))
  ;; DOFINAL-NEXT: )
  (func $keepalive
    (local $parent (ref $parent))
    (local $child-final (ref $child-final))
    (local $child-open (ref $child-open))
  )
)
