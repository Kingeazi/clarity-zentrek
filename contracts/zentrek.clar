;; ZenTrek Mindfulness Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-session (err u101))
(define-constant err-session-exists (err u102))
(define-constant err-session-expired (err u103))
(define-constant err-invalid-duration (err u104))
(define-constant max-session-duration u7200) ;; 2 hours in seconds
(define-constant session-timeout-blocks u144) ;; ~24 hours in blocks

;; Data Variables
(define-data-var reward-rate uint u10)
(define-data-var admin-address principal contract-owner)

;; Data Maps
(define-map sessions 
  { session-id: (string-ascii 32) }
  {
    exercise-type: (string-ascii 32),
    sound-type: (string-ascii 32),
    duration: uint,
    completed: bool,
    start-block: uint
  }
)

(define-map user-stats
  { user: principal }
  {
    total-sessions: uint,
    total-minutes: uint,
    rewards-earned: uint,
    achievements: (list 10 (string-ascii 32))
  }
)

;; Define the mindfulness token
(define-fungible-token mindfulness-token)

;; Admin Functions
(define-public (set-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin-address)) err-owner-only)
    (ok (var-set reward-rate new-rate))
  )
)

;; Public Functions
(define-public (start-session (exercise-type (string-ascii 32)) (sound-type (string-ascii 32)) (duration uint))
  (begin
    (asserts! (<= duration max-session-duration) err-invalid-duration)
    (let ((session-id (generate-session-id tx-sender)))
      (match (map-insert sessions
        { session-id: session-id }
        {
          exercise-type: exercise-type,
          sound-type: sound-type,
          duration: duration,
          completed: false,
          start-block: block-height
        })
        true (ok session-id)
        false err-session-exists
      )
    )
  )
)

(define-public (complete-session (session-id (string-ascii 32)))
  (let (
    (session (unwrap! (map-get? sessions {session-id: session-id}) err-invalid-session))
    (session-age (- block-height (get start-block session)))
  )
    (asserts! (< session-age session-timeout-blocks) err-session-expired)
    (if (get completed session)
      err-invalid-session
      (begin
        (try! (update-user-stats tx-sender (get duration session)))
        (try! (ft-mint? mindfulness-token (calculate-rewards (get duration session)) tx-sender))
        (map-set sessions 
          {session-id: session-id}
          (merge session {completed: true})
        )
        (ok (calculate-rewards (get duration session)))
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
      rewards-earned: u0,
      achievements: (list)
    }
    (map-get? user-stats {user: user})
  )
)

(define-read-only (get-session (session-id (string-ascii 32)))
  (map-get? sessions {session-id: session-id})
)

(define-read-only (get-current-reward-rate)
  (var-get reward-rate)
)

;; Private Functions
(define-private (generate-session-id (user principal))
  (concat (to-ascii user) (to-ascii block-height))
)

(define-private (calculate-rewards (duration uint))
  (* duration (var-get reward-rate))
)

(define-private (update-user-stats (user principal) (duration uint))
  (let (
    (current-stats (get-user-stats user))
    (rewards (calculate-rewards duration))
  )
    (map-set user-stats
      {user: user}
      {
        total-sessions: (+ (get total-sessions current-stats) u1),
        total-minutes: (+ (get total-minutes current-stats) duration),
        rewards-earned: (+ (get rewards-earned current-stats) rewards),
        achievements: (check-and-award-achievements current-stats)
      }
    )
    (ok true)
  )
)

(define-private (check-and-award-achievements (stats {total-sessions: uint, total-minutes: uint, rewards-earned: uint, achievements: (list 10 (string-ascii 32))}))
  (let ((current-achievements (get achievements stats)))
    (if (and (>= (get total-sessions stats) u10) (is-none (index-of current-achievements "DEDICATED_USER")))
      (unwrap-panic (as-max-len? (append current-achievements "DEDICATED_USER") u10))
      current-achievements
    )
  )
)
