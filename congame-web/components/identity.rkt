#lang racket/base

(require congame/components/export
         (only-in congame/components/study
                  current-study-instance-id
                  current-study-stack)
         (prefix-in http: net/http-easy)
         racket/contract
         racket/format
         "auth.rkt"
         "user.rkt")

(provide
 put/identity)

(define-logger identity)

(define/contract (put/identity key value)
  (-> symbol? any/c void?)
  (define u (current-user))
  (cond
    [(and (user-identity-service-url u)
          (user-identity-service-key u))
     (define url
       (~a (user-identity-service-url u)
           (format "/api/v1/study-instances/~a/data?key=~a"
                   (current-study-instance-id)
                   (user-identity-service-key u))))
     (define data
       (hasheq
        'key (->jsexpr key)
        'stack (->jsexpr (current-study-stack))
        'value (->jsexpr value)))
     (define res
       (http:put url #:json data))
     (log-identity-debug "put/identity~n  url: ~a~n  data: ~e" url data)
     (unless (= (http:response-status-code res) 201)
       (error 'put/identity "request failed~n  response: ~a" (http:response-body res)))]

    [else
     (log-identity-warning 'put/identity "current user is not an identity user~n  username: ~a" (user-username u))]))