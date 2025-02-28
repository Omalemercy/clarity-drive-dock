;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-already-booked (err u102))
(define-constant err-invalid-rating (err u103))

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
  { user: principal }
  {
    total-ratings: uint,
    rating-sum: uint,
    reviews: (list 10 (string-ascii 100))
  }
)

;; Public functions
(define-public (create-ride (seats uint) (destination (string-ascii 50)) (price uint) (driver principal))
  (let ((ride-id (var-get next-ride-id)))
    (map-set rides
      { ride-id: ride-id }
      {
        driver: driver,
        destination: destination,
        seats: seats,
        price: price,
        status: "available",
        passenger: none
      }
    )
    (var-set next-ride-id (+ ride-id u1))
    (ok ride-id)
  )
)

(define-public (book-ride (ride-id uint) (passenger principal))
  (let ((ride (unwrap! (map-get? rides { ride-id: ride-id }) err-not-found)))
    (asserts! (is-eq (get status ride) "available") err-already-booked)
    (map-set rides
      { ride-id: ride-id }
      (merge ride { 
        status: "booked",
        passenger: (some passenger)
      })
    )
    (ok true)
  )
)

(define-public (rate-ride (ride-id uint) (rating uint) (review (string-ascii 100)))
  (let (
    (ride (unwrap! (map-get? rides { ride-id: ride-id }) err-not-found))
    (user-to-rate (get driver ride))
  )
    (asserts! (<= rating u5) err-invalid-rating)
    (let ((current-ratings (default-to
      { total-ratings: u0, rating-sum: u0, reviews: (list) }
      (map-get? user-ratings { user: user-to-rate }))))
      (map-set user-ratings
        { user: user-to-rate }
        {
          total-ratings: (+ (get total-ratings current-ratings) u1),
          rating-sum: (+ (get rating-sum current-ratings) rating),
          reviews: (unwrap-panic (as-max-len? (append (get reviews current-ratings) review) u10))
        }
      )
      (ok true)
    )
  )
)

;; Read only functions
(define-read-only (get-ride (ride-id uint))
  (ok (map-get? rides { ride-id: ride-id }))
)

(define-read-only (get-user-rating (user principal))
  (let ((ratings (map-get? user-ratings { user: user })))
    (if (is-some ratings)
      (ok (/ (get rating-sum (unwrap-panic ratings)) (get total-ratings (unwrap-panic ratings))))
      (ok u0)
    )
  )
)
