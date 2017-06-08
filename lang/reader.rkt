#lang racket/base

(provide
  (rename-out
   [mf-apply-read read]
   [mf-apply-read-syntax read-syntax]
   [mf-apply-get-info get-info]))

(require
  syntax/readerr
  (only-in syntax/module-reader
    make-meta-reader))

;; =============================================================================

(define-values (mf-apply-read mf-apply-read-syntax mf-apply-get-info)
  (make-meta-reader
    'mf-apply
    "mf-apply"
    (λ (bstr)
      (let* ([str (bytes->string/latin-1 bstr)]
             [sym (string->symbol str)])
        (and (module-path? sym)
             (vector
              ;; try submod first:
              `(submod ,sym reader)
              ;; fall back to /lang/reader:
              (string->symbol (string-append str "/lang/reader"))))))
    (λ (r)
      (define (new-read [in (current-input-port)])
        (parameterize ([current-readtable (update-readtable (current-readtable))])
          (r in)))
      new-read)
    (λ (old-read-syntax)
      (define (new-read-syntax . arg*)
        (parameterize ([current-readtable (update-readtable (current-readtable))])
          (apply old-read-syntax arg*)))
      new-read-syntax)
    values))

(define (update-readtable old-rt)
  (define-values (c reader-proc dispatch-proc)
    (if old-rt
      (readtable-mapping old-rt #\{)
      (values #f #f #f)))
  (if dispatch-proc
    old-rt
    (make-readtable old-rt #\{ 'dispatch-macro parse-brace)))

(define parse-brace
  (case-lambda
    [(ch port src line col pos)
     ;; `read-syntax' mode
     (datum->syntax
      #f
      (make-mf-apply port (lambda () (read-syntax src port)) src)
      (let-values ([(l c p) (port-next-location port)])
        (list src line col pos (and pos (- p pos)))))]))

(define (skip-whitespace port)
  (define rt (current-readtable))
  (let loop ()
    (let ([ch (peek-char port)])
      (unless (eof-object? ch)
        ;; Consult current readtable:
        (let-values ([(like-ch/sym proc dispatch-proc) (readtable-mapping rt ch)])
          ;; If like-ch/sym is whitespace, then ch is whitespace
          (when (and (char? like-ch/sym)
                     (char-whitespace? like-ch/sym))
            (read-char port)
            (loop)))))))

(define (make-mf-apply port read-one src)
  (skip-whitespace port)
  (let ([first-elem (read-one)])
    (begin0
      (let ([rest-elems
             (let loop ([es '()])
               (skip-whitespace port)
               (if (equal? #\} (peek-char port))
                   (reverse es)
                   (loop (cons (read-one) es))))])
        (datum->syntax first-elem `(mf-apply ,first-elem ,@rest-elems)))
      (skip-whitespace port)
      (let ([c (read-char port)])
        (unless (equal? #\} c)
          (let-values ([(l c p) (port-next-location port)])
            (raise-read-error (format "metafunction application ~a not properly terminated" (syntax->datum first-elem)) src l c p 1)))))))
