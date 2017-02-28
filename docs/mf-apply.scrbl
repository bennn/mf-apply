#lang scribble/manual
@require[(for-label racket/base redex/reduction-semantics)]

@title{mf-apply}
@defmodulelang[mf-apply]

A lang-extension that converts:

  @tt{#{f x ...}}

to

  @tt{(mf-apply f x ...)}

This is especially useful in @racket[where] clauses, here's a contrived example:

@codeblock{
  #lang mf-apply racket/base
  (require redex/reduction-semantics)

  (define-language nats
    [nat ::= Z (S nat)])

  (define-judgment-form nats
    #:mode (less-than? I I)
    #:contract (less-than? nat nat)
    [
     --- LT-Zero
     (less-than? Z nat_1)]
    [
     (where nat_2 #{pred nat_0})
     (where (S nat_3) nat_1)
     (less-than? nat_2 nat_3)
     --- LT-Succ
     (less-than? nat_0 nat_1)])

  (define-metafunction nats
    pred : nat -> nat
    [(pred (S nat))
     nat])
}
