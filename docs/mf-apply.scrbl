#lang scribble/manual
@require[(for-label racket/base redex/reduction-semantics)]

@title{mf-apply}
@defmodulelang[mf-apply]

A lang-extension that converts:

  @tt{#{f x ...}}

to

  @tt{(mf-apply f x ...)}

Example:

@codeblock{
  #lang mf-apply racket/base
  (require redex/reduction-semantics)

  (define-language nats
    [nat ::= Z (S nat)])

  (define-judgment-form nats
    #:mode (<=? I I)
    #:contract (<=? nat nat)
    [
     --- LT-Zero
     (<=? Z nat_1)]
    [
     (where nat_2 #{pred (S nat_0)})
     (where (S nat_3) nat_1)
     (<=? nat_2 nat_3)
     --- LT-Succ
     (<=? (S nat_0) nat_1)])

  (define-metafunction nats
    pred : nat -> nat
    [(pred (S nat))
     nat])

  (module+ test
    (test-equal (term Z) (term #{pred (S Z)}))
    (test-judgment-holds (<=? Z #{pred (S Z)}))
    (test-results))
}
