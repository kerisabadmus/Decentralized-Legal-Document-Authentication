;; Signature Verification Contract
;; Validates authenticated approvals

;; Data map to store document signatures
(define-map document-signatures
  { document-hash: (buff 32), signer: principal }
  {
    signature-hash: (buff 32),
    timestamp: uint,
    valid: bool
  }
)

;; List to track all signers for a document
(define-map document-signers
  { document-hash: (buff 32) }
  { signers: (list 50 principal) }
)

;; Add a signature to a document
(define-public (sign-document (document-hash (buff 32)) (signature-hash (buff 32)))
  (let
    ((caller tx-sender))

    ;; Add signature
    (if (map-insert document-signatures
          { document-hash: document-hash, signer: caller }
          { signature-hash: signature-hash, timestamp: block-height, valid: true })
        (begin
          ;; Add signer to the list of signers
          (match (map-get? document-signers { document-hash: document-hash })
            existing-signers (map-set document-signers
                               { document-hash: document-hash }
                               { signers: (unwrap! (as-max-len? (append (get signers existing-signers) caller) u50) (err u4)) })
            ;; If no signers yet, create new list
            (map-insert document-signers
              { document-hash: document-hash }
              { signers: (list caller) })
          )
          (ok true)
        )
        (err u2) ;; Signature already exists
    )
  )
)

;; Revoke a signature
(define-public (revoke-signature (document-hash (buff 32)))
  (let
    ((caller tx-sender))
    (match (map-get? document-signatures { document-hash: document-hash, signer: caller })
      signature-data (begin
        (map-set document-signatures
          { document-hash: document-hash, signer: caller }
          (merge signature-data { valid: false })
        )
        (ok true)
      )
      (err u3) ;; Signature not found
    )
  )
)

;; Check if a signature is valid
(define-read-only (is-signature-valid (document-hash (buff 32)) (signer principal))
  (match (map-get? document-signatures { document-hash: document-hash, signer: signer })
    signature-data (get valid signature-data)
    false
  )
)

;; Get all signers for a document
(define-read-only (get-document-signers (document-hash (buff 32)))
  (match (map-get? document-signers { document-hash: document-hash })
    signers-data (get signers signers-data)
    (list)
  )
)

;; Get signature information
(define-read-only (get-signature-info (document-hash (buff 32)) (signer principal))
  (map-get? document-signatures { document-hash: document-hash, signer: signer })
)
