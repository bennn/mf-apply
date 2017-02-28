mf-apply
===
[![Scribble](https://img.shields.io/badge/Docs-Scribble-blue.svg)](http://docs.racket-lang.org/mf-apply/index.html)

A lang extension that converts

```racket
  #{f x ...}
```

to

```racket
  (mf-apply f x ...)
```


Example
---

```racket
#lang mf-apply racket/base
(require redex)

(define-syntax (f stx)
  #'42)

(term #{f 0})
;; term: expected a previously defined metafunction
;;   at: f
;;   in: (mf-apply f 0)
```


Install
---

```
  $ raco pkg install mf-apply
```
