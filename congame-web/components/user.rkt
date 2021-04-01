#lang racket/base

(require component
         db
         deta
         file/sha1
         gregor
         koyo/database
         koyo/profiler
         koyo/random
         racket/contract
         racket/random
         racket/string
         threading
         "hash.rkt")

;; user ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide
 (schema-out user)
 set-user-password
 user-admin?
 generate-api-key)

(define-schema user
  ([id id/f #:primary-key #:auto-increment]
   [username string/f #:contract non-empty-string? #:wrapper string-downcase]
   [(password-hash "") string/f]
   [api-key string/f #:nullable]
   [(role 'user) symbol/f #:contract (or/c 'user 'bot 'api 'admin)]
   [(verified? #f) boolean/f]
   [(verification-code (generate-random-string)) string/f #:contract non-empty-string?]
   [bot-set-id integer/f #:nullable]
   [(created-at (now/moment)) datetime-tz/f]
   [(updated-at (now/moment)) datetime-tz/f])

  #:pre-persist-hook
  (lambda (u)
    (define user-with-key
      (cond
        [(and (user-api-key u)
              (not (sql-null? (user-api-key u))))
         (displayln "Have an api-key") (flush-output) u]
        [else (set-user-api-key u (generate-api-key u))]))
    (displayln (format "Api-key: ~a" (user-api-key user-with-key)))
    (flush-output)
    (set-user-updated-at user-with-key (now/moment))))

(define/contract (user-admin? u)
  (-> user? boolean?)
  (eq? (user-role u) 'admin))

(define/contract (generate-api-key u)
  (-> user? string?)
  (bytes->hex-string
   (sha224-bytes
    (bytes-append (string->bytes/utf-8 (user-username u))
                  (crypto-random-bytes 32)))))

(define/contract (set-user-password u p)
  (-> user? string? user?)
  (set-user-password-hash u (make-password-hash p)))

(define/contract (user-password-valid? u p)
  (-> user? string? boolean?)
  (hash-matches? (user-password-hash u) p))


;; password reset ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-schema password-reset
  #:table "password_reset_requests"
  ([user-id id/f #:unique]
   [ip-address string/f #:contract non-empty-string?]
   [user-agent string/f #:contract non-empty-string?]
   [(token (generate-random-string)) string/f #:contract non-empty-string?]
   [(expires-at (+days (now/moment) 1)) datetime-tz/f]))


;; user-manager ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide
 exn:fail:user-manager?
 exn:fail:user-manager:username-taken?

 make-user-manager
 user-manager?
 user-manager-lookup/id
 user-manager-lookup/api-key
 user-manager-lookup/username
 user-manager-create!
 user-manager-create-reset-token!
 user-manager-login
 user-manager-verify!
 user-manager-reset-password!)

(struct exn:fail:user-manager exn:fail ())
(struct exn:fail:user-manager:username-taken exn:fail:user-manager ())

(struct user-manager (db)
  #:transparent
  #:methods gen:component [])

(define/contract (make-user-manager db)
  (-> database? user-manager?)
  (user-manager db))

(define/contract (user-manager-create! um username password [role 'user])
  (->* (user-manager? string? string?) ((or/c 'admin 'user 'bot)) user?)

  (define user
    (~> (make-user #:username username
                   #:role role)
        (set-user-password password)))

  (with-handlers ([exn:fail:sql:constraint-violation?
                   (lambda _
                     (raise (exn:fail:user-manager:username-taken
                             (format "username '~a' is taken" username)
                             (current-continuation-marks))))])
    (with-database-transaction [conn (user-manager-db um)]
      (insert-one! conn user))))

(define/contract (user-manager-create-reset-token! um
                                                   #:username username
                                                   #:ip-address ip-address
                                                   #:user-agent user-agent)
  (-> user-manager?
      #:username non-empty-string?
      #:ip-address non-empty-string?
      #:user-agent non-empty-string?
      (values (or/c false/c user?)
              (or/c false/c string?)))
  (with-timing 'user-manager "user-manager-create-reset-token!"
    (with-database-transaction [conn (user-manager-db um)]
      (cond
        [(user-manager-lookup/username um username)
         => (lambda (user)
              (query-exec conn (delete (~> (from password-reset #:as pr)
                                           (where (= pr.user-id ,(user-id user))))))

              (values user
                      (~> (make-password-reset #:user-id (user-id user)
                                               #:ip-address ip-address
                                               #:user-agent user-agent)
                          (insert-one! conn _)
                          (password-reset-token))))]

        [else
         (values #f #f)]))))

(define/contract (user-manager-lookup/id um id)
  (-> user-manager? exact-positive-integer? (or/c false/c user?))
  (with-timing 'user-manager (format "(user-manager-lookup/id ~v)" id)
    (with-database-connection [conn (user-manager-db um)]
      (lookup conn (~> (from user #:as u)
                       (where (= u.id ,id)))))))

(define/contract (user-manager-lookup/api-key um key)
  (-> user-manager? string? (or/c false/c user?))
  (with-timing 'user-manager (format "(user-manager/lookup/api-key ~v)" key)
    (with-database-connection [conn (user-manager-db um)]
      (lookup conn (~> (from user #:as u)
                       (where (and (= u.role "api")
                                   (= u.api-key ,key))))))))

(define/contract (user-manager-lookup/username um username)
  (-> user-manager? string? (or/c false/c user?))
  (with-timing 'user-manager (format "(user-manager-lookup/username ~v)" username)
    (with-database-connection [conn (user-manager-db um)]
      (lookup conn (~> (from user #:as u)
                       (where (= u.username ,(string-downcase username))))))))

(define/contract (user-manager-login um username password)
  (-> user-manager? string? string? (or/c false/c user?))
  (with-timing 'user-manager "user-manager-login"
    (define user (user-manager-lookup/username um username))
    (and user (user-password-valid? user password) user)))

(define/contract (user-manager-verify! um id verification-code)
  (-> user-manager? exact-positive-integer? string? void?)
  (with-timing 'user-manager "user-manager-verify!"
    (void
     (with-database-transaction [conn (user-manager-db um)]
       (query-exec conn (~> (from user #:as u)
                            (update [verified? #t])
                            (where (and (= u.id ,id)
                                        (= u.verification-code ,verification-code)))))))))

(define/contract (user-manager-reset-password! um
                                               #:user-id user-id
                                               #:token token
                                               #:password password)
  (-> user-manager?
      #:user-id id/c
      #:token non-empty-string?
      #:password non-empty-string?
      boolean?)
  (with-timing 'user-manager "user-manager-reset-password!"
    (with-database-transaction [conn (user-manager-db um)]
      (cond
        [(lookup-password-reset conn user-id token)
         => (lambda (_pr)
              (begin0 #t
                (clear-password-reset! conn user-id)
                (and~> (lookup conn
                               (~> (from user #:as u)
                                   (where (= u.id ,user-id))))
                       (set-user-password password)
                       (update! conn _))))]


        [else #f]))))

(define (lookup-password-reset conn user-id token)
  (lookup conn (~> (from password-reset #:as pr)
                   (where (and (= pr.user-id ,user-id)
                               (= pr.token ,token)
                               (> pr.expires-at (now)))))))

(define (clear-password-reset! conn user-id)
  (query-exec conn (~> (from password-reset #:as pr)
                       (where (= pr.user-id ,user-id))
                       (delete))))