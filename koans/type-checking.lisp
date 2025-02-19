;;; Copyright 2013 Google Inc.
;;;
;;; Licensed under the Apache License, Version 2.0 (the "License");
;;; you may not use this file except in compliance with the License.
;;; You may obtain a copy of the License at
;;;
;;;     http://www.apache.org/licenses/LICENSE-2.0
;;;
;;; Unless required by applicable law or agreed to in writing, software
;;; distributed under the License is distributed on an "AS IS" BASIS,
;;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;; See the License for the specific language governing permissions and
;;; limitations under the License.

;;; There is a type hierarchy in Lisp, based on the set theory.
;;; An object may belong to multiple types at the same time.
;;; Every object is of type T. No object is of type NIL.

(define-test typep
  ;; TYPEP returns true if the provided object is of the provided type.
  (true-or-false? t (typep "hello" 'string))
  (true-or-false? t (typep "hello" 'array))
  (true-or-false? nil (typep "hello" 'list))
  (true-or-false? t (typep "hello" '(simple-array character (5))))
  (true-or-false? t (typep '(1 2 3) 'list))
  (true-or-false? t (typep 99 'integer))
  (true-or-false? t (typep nil 'NULL))
  (true-or-false? t (typep 22/7 'ratio))
  (true-or-false? t (typep 4.0 'float))
  (true-or-false? t (typep #\a 'character))
  (true-or-false? t (typep #'length 'function)))

(define-test type-of
  ;; TYPE-OF returns a type specifier for the object.
  (assert-equal 'NULL (type-of '()))
  (assert-equal 'ratio (type-of 4/6)))

(define-test overlapping-types
  ;; Because Lisp types are mathematical sets, they are allowed to overlap.
  (let ((thing '()))
    (true-or-false? t (typep thing 'list))
    (true-or-false? t (typep thing 'atom))
    (true-or-false? t (typep thing 'null))
    (true-or-false? t (typep thing 't))))

(define-test fixnum-versus-bignum
  ;; In Lisp, integers are either fixnums or bignums. Fixnums are handled more
  ;; efficiently by the implementation, but some large integers can only be
  ;; represented as bignums.
  ;; Lisp converts between these two types on the fly. The constants
  ;; MOST-NEGATIVE-FIXNUM and MOST-POSITIVE-FIXNUM describe the limits for
  ;; fixnums.
  (let ((integer-1 0)
        (integer-2 most-positive-fixnum)
        (integer-3 (1+ most-positive-fixnum))
        (integer-4 (1- most-negative-fixnum)))
    (true-or-false? t (typep integer-1 'fixnum))
    (true-or-false? nil (typep integer-1 'bignum))
    (true-or-false? t (typep integer-2 'fixnum))
    (true-or-false? nil (typep integer-2 'bignum))
    (true-or-false? nil (typep integer-3 'fixnum))
    (true-or-false? t (typep integer-3 'bignum))
    (true-or-false? nil (typep integer-4 'fixnum))
    (true-or-false? t (typep integer-4 'bignum))
    ;; Regardless of whether an integer is a fixnum or a bignum, it is still
    ;; an integer.
    (true-or-false? t (typep integer-1 'integer))
    (true-or-false? t (typep integer-2 'integer))
    (true-or-false? t (typep integer-3 'integer))
    (true-or-false? t (typep integer-4 'integer))))

(define-test subtypep
  (assert-true (typep 1 'bit))
  (assert-true (typep 1 'fixnum))
  (assert-true (typep 1 'integer))
  (assert-true (typep 2 'integer))
  ;; The function SUBTYPEP attempts to answer whether one type specifier
  ;; represents a subtype of the other type specifier.
  (true-or-false? t (subtypep 'bit 'integer))
  (true-or-false? t (subtypep 'vector 'array))
  (true-or-false? t (subtypep 'string 'vector))
  (true-or-false? t (subtypep 'null 'list)))

(define-test list-type-specifiers
  ;; Some type specifiers are lists; this way, they carry more information than
  ;; type specifiers which are symbols.
  (assert-true (typep (make-array 0) '(vector * 0)))
  (assert-true (typep (make-array 42) '(vector * 42)))
  (assert-true (typep (make-array 42 :element-type 'bit) '(vector bit 42)))
  (assert-true (typep (make-array '(4 2)) '(array * (4 2))))
  (true-or-false? t (typep (make-array '(3 3)) '(simple-array t (3 3))))
  (true-or-false? nil (typep (make-array '(3 2 1)) '(simple-array t (1 2 3)))))

(define-test list-type-specifiers-hierarchy
  ;; Type specifiers that are lists also follow hierarchy.
  (true-or-false? t (subtypep '(simple-array t (3 3)) '(simple-array t *)))
  (true-or-false? t (subtypep '(vector double-float 100) '(vector * 100)))
  (true-or-false? t (subtypep '(vector double-float 100) '(vector double-float *)))
  (true-or-false? t (subtypep '(vector double-float 100) '(vector * *)))
  (true-or-false? t (subtypep '(vector double-float 100) '(array * *)))
  (true-or-false? t (subtypep '(vector double-float 100) t)))

(define-test type-coercion
  (assert-true (typep 0 'integer))
  (true-or-false? nil (typep 0 'short-float))
  (true-or-false? nil (subtypep 'integer 'short-float))
  (true-or-false? nil (subtypep 'short-float 'integer))
  ;; The function COERCE makes it possible to convert values between some
  ;; standard types.
  (true-or-false? t (typep (coerce 0 'short-float) 'short-float)))

(define-test atoms-are-anything-thats-not-a-cons
  ;; In Lisp, an atom is anything that is not a cons cell. The function ATOM
  ;; returns true if its object is an atom.
  (true-or-false? t (atom 4))
  (true-or-false? nil (atom '(1 2 3 4)))
  (true-or-false? nil (atom '(:foo . :bar)))
  (true-or-false? t (atom 'symbol))
  (true-or-false? t (atom :keyword))
  (true-or-false? t (atom #(1 2 3 4 5)))
  (true-or-false? t (atom #\A))
  (true-or-false? t (atom "string"))
  (true-or-false? t (atom (make-array '(4 4)))))

(define-test functionp
  ;; The function FUNCTIONP returns true if its arguments is a function.
  (assert-true (functionp (lambda (a b c) (+ a b c))))
  (true-or-false? t (functionp #'make-array))
  (true-or-false? nil (functionp 'make-array))
  (true-or-false? t (functionp (lambda (x) (* x x))))
  (true-or-false? nil (functionp '(lambda (x) (* x x))))
  (true-or-false? nil (functionp '(1 2 3)))
  (true-or-false? nil (functionp t)))

(define-test other-type-predicates
  ;; Lisp defines multiple type predicates for standard types..
  (true-or-false? t (numberp 999))
  (true-or-false? t (listp '(9 9 9)))
  (true-or-false? t (integerp 999))
  (true-or-false? t (rationalp 9/99))
  (true-or-false? t (floatp 9.99))
  (true-or-false? t (stringp "nine nine nine"))
  (true-or-false? t (characterp #\9))
  (true-or-false? t (bit-vector-p #*01001)))

(define-test guess-that-type
  ;; Fill in the blank with a type specifier that satisfies the following tests.
    (let ((type '(simple-array string (5 3 *))))
    (assert-true (subtypep type '(simple-array * (* 3 *))))
    (assert-true (subtypep type '(simple-array * (5 * *))))
    (assert-true (subtypep type '(simple-array array *)))
    (assert-true (typep (make-array '(5 3 9) :element-type 'string) type))
    (assert-true (typep (make-array '(5 3 33) :element-type 'vector) type))))
