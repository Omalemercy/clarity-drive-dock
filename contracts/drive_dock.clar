;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-already-booked (err u102))
(define-constant err-invalid-rating (err u103))
(define-constant err-invalid-seats (err u104))
(define-constant err-invalid-price (err u105))
(define-constant err-self-booking (err u106))

;; Data variables
(define-data-var next-ride-id uint u1)

;; Data maps
(define-map rides
  { ride-id: uint }
  {
    driver: principal,
    destination: (string-ascii 50),
    seats: uint,
    price: uint,
    status: (string-ascii 10),
    passenger: (optional principal)
  }
)

(define-map user-ratings
  { user: principal, ride-id: uint }
  {
    rating: uint,
    review: (string-ascii 100)
  }
)

(define-map user-stats
  { user: principal }
  {
    total-ratings: uint,
    rating-sum: uint,
    reviews: (list 10 (string-ascii 100))
  }
)

;; Public functions
(define-public (create-ride (seats uint) (destination (string-ascii 50)) (price uint))
  (begin
    (asserts! (> seats u0) err-invalid-seats)
    (asserts! (> price u0) err-invalid-price)
    
    (let ((ride-id (var-get next-ride-id)))
      (map-set rides
        { ride-id: ride-id }
        {
          driver: tx-sender,
          destination: destination,
          seats: seats,
          price: price,
          status: "available",
          passenger: none
        }
      )
      (var-set next-ride-id (+ ride-id u1))
      (print { type: "ride-created", ride-id: ride-id })
      (ok ride-id)
    )
  )
)

(define-public (book-ride (ride-id uint) (passenger principal))
  (let ((ride (unwrap! (map-get? rides { ride-id: ride-id }) err-not-found)))
    (asserts! (not (is-eq (get driver ride) passenger)) err-self-booking)
    (asserts! (is-eq (get status ride) "available") err-already-booked)
    
    (map-set rides
      { ride-id: ride-id }
      (merge ride { 
        status: "booked",
        passenger: (some passenger)
      })
    )
    (print { type: "ride-booked", ride-id: ride-id, passenger: passenger })
    (ok true)
  )
)

(define-public (complete-ride (ride-id uint))
  (let ((ride (unwrap! (map-get? rides { ride-id: ride-id }) err-not-found)))
    (asserts! (is-eq (get driver ride) tx-sender) err-unauthorized)
    (asserts! (is-eq (get status ride) "booked") err-unauthorized)
    
    (map-set rides
      { ride-id: ride-id }
      (merge ride { status: "completed" })
    )
    (print { type: "ride-completed", ride-id: ride-id })
    (ok true)
  )
)

(define-public (rate-ride (ride-id uint) (rating uint) (review (string-ascii 100)))
  (let (
    (ride (unwrap! (map-get? rides { ride-id: ride-id }) err-not-found))
    (user-to-rate (get driver ride))
  )
    (asserts! (<= rating u5) err-invalid-rating)
    (asserts! (is-eq (get status ride) "completed") err-unauthorized)
    (asserts! (is-none (map-get? user-ratings { user: user-to-rate, ride-id: ride-id })) err-unauthorized)
    
    (map-set user-ratings
      { user: user-to-rate, ride-id: ride-id }
      { rating: rating, review: review }
    )
    
    (let ((current-stats (default-to
      { total-ratings: u0, rating-sum: u0, reviews: (list) }
      (map-get? user-stats { user: user-to-rate }))))
      (map-set user-stats
        { user: user-to-rate }
        {
          total-ratings: (+ (get total-ratings current-stats) u1),
          rating-sum: (+ (get rating-sum current-stats) rating),
          reviews: (unwrap-panic (as-max-len? (append (get reviews current-stats) review) u10))
        }
      )
      (print { type: "ride-rated", ride-id: ride-id, rating: rating })
      (ok true)
    )
  )
)

;; Read only functions
(define-read-only (get-ride (ride-id uint))
  (ok (map-get? rides { ride-id: ride-id }))
)

(define-read-only (get-user-rating (user principal))
  (let ((stats (map-get? user-stats { user: user })))
    (if (is-some stats)
      (ok (/ (get rating-sum (unwrap-panic stats)) (get total-ratings (unwrap-panic stats))))
      (ok u0)
    )
  )
)
