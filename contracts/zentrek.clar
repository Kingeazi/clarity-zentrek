;; ZenTrek Mindfulness Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-session (err u101))
(define-constant err-session-exists (err u102))

;; Data Variables
(define-data-var reward-rate uint u10)
(define-map sessions 
  { session-id: (string-ascii 32) }
  {
    exercise-type: (string-ascii 32),
    sound-type: (string-ascii 32),
    duration: uint,
    completed: bool
  }
)

(define-map user-stats
  { user: principal }
  {
    total-sessions: uint,
    total-minutes: uint,
    rewards-earned: uint
  }
)

;; Define the mindfulness token
(define-fungible-token mindfulness-token)

;; Public Functions
(define-public (start-session (exercise-type (string-ascii 32)) (sound-type (string-ascii 32)) (duration uint))
  (let ((session-id (generate-session-id tx-sender)))
    (match (map-insert sessions
      { session-id: session-id }
      {
        exercise-type: exercise-type,
        sound-type: sound-type,
        duration: duration,
        completed: false
      })
      true (ok session-id)
      false err-session-exists
    )
  )
)

(define-public (complete-session (session-id (string-ascii 32)))
  (let (
    (session (unwrap! (map-get? sessions {session-id: session-id}) err-invalid-session))
    (rewards (calculate-rewards (get duration session)))
  )
    (if (get completed session)
      err-invalid-session
      (begin
        (try! (update-user-stats tx-sender (get duration session) rewards))
        (try! (ft-mint? mindfulness-token rewards tx-sender))
        (map-set sessions 
          {session-id: session-id}
          (merge session {completed: true})
        )
        (ok rewards)
      )
    )
  )
)

;; Read Only Functions
(define-read-only (get-user-stats (user principal))
  (default-to
    {
      total-sessions: u0,
      total-minutes: u0,
      rewards-earned: u0
    }
    (map-get? user-stats {user: user})
  )
)

;; Private Functions
(define-private (generate-session-id (user principal))
  (concat (to-ascii user) (to-ascii block-height))
)

(define-private (calculate-rewards (duration uint))
  (* duration (var-get reward-rate))
)

(define-private (update-user-stats (user principal) (duration uint) (rewards uint))
  (let ((current-stats (get-user-stats user)))
    (map-set user-stats
      {user: user}
      {
        total-sessions: (+ (get total-sessions current-stats) u1),
        total-minutes: (+ (get total-minutes current-stats) duration),
        rewards-earned: (+ (get rewards-earned current-stats) rewards)
      }
    )
    (ok true)
  )
)
