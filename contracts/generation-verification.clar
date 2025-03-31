;; Generation Verification Contract
;; Validates clean energy production

(define-data-var admin principal tx-sender)

;; Data structure for energy generation records
(define-map generation-records
  { generator-id: (string-ascii 64), timestamp: uint }
  {
    energy-amount: uint,
    source-type: (string-ascii 32),
    location: (string-ascii 64),
    verified: bool
  }
)

;; List of authorized verifiers
(define-map authorized-verifiers principal bool)

;; Add a verifier
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok (map-set authorized-verifiers verifier true))
  )
)

;; Remove a verifier
(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok (map-set authorized-verifiers verifier false))
  )
)

;; Register energy generation
(define-public (register-generation
    (generator-id (string-ascii 64))
    (timestamp uint)
    (energy-amount uint)
    (source-type (string-ascii 32))
    (location (string-ascii 64)))
  (begin
    (ok (map-set generation-records
      { generator-id: generator-id, timestamp: timestamp }
      {
        energy-amount: energy-amount,
        source-type: source-type,
        location: location,
        verified: false
      }
    ))
  )
)

;; Verify energy generation
(define-public (verify-generation
    (generator-id (string-ascii 64))
    (timestamp uint))
  (let ((record (unwrap! (map-get? generation-records { generator-id: generator-id, timestamp: timestamp }) (err u101))))
    (begin
      (asserts! (default-to false (map-get? authorized-verifiers tx-sender)) (err u102))
      (ok (map-set generation-records
        { generator-id: generator-id, timestamp: timestamp }
        (merge record { verified: true })
      ))
    )
  )
)

;; Get generation record
(define-read-only (get-generation-record (generator-id (string-ascii 64)) (timestamp uint))
  (map-get? generation-records { generator-id: generator-id, timestamp: timestamp })
)

;; Check if generation is verified
(define-read-only (is-generation-verified (generator-id (string-ascii 64)) (timestamp uint))
  (default-to false (get verified (map-get? generation-records { generator-id: generator-id, timestamp: timestamp })))
)
