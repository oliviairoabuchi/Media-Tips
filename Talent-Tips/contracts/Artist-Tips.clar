;; TipStream: Decentralized Creator Monetization Platform Smart Contract
;;
;; A comprehensive blockchain-based ecosystem that enables direct financial support
;; between content consumers and digital creators through secure, transparent tipping.
;; Features real-time earnings tracking, automated fee distribution, content management,
;; and creator analytics without traditional intermediaries. Built for artists, writers,
;; streamers, educators, and all digital content creators seeking decentralized revenue.

;; ERROR CONSTANTS

(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INVALID-TIP-AMOUNT (err u101))
(define-constant ERR-CONTENT-NOT-FOUND (err u102))
(define-constant ERR-CONTENT-ALREADY-EXISTS (err u103))
(define-constant ERR-PAYMENT-TRANSFER-FAILED (err u104))
(define-constant ERR-INSUFFICIENT-FUNDS (err u105))
(define-constant ERR-INVALID-PARAMETER-VALUE (err u106))
(define-constant ERR-SYSTEM-UNDER-MAINTENANCE (err u107))
(define-constant ERR-ZERO-AMOUNT-NOT-ALLOWED (err u108))
(define-constant ERR-CONTENT-IS-DISABLED (err u109))
(define-constant ERR-INVALID-CONTENT-IDENTIFIER (err u110))
(define-constant ERR-INVALID-TITLE-LENGTH (err u111))
(define-constant ERR-INVALID-DESCRIPTION-LENGTH (err u112))
(define-constant ERR-INVALID-MESSAGE-LENGTH (err u113))
(define-constant ERR-INVALID-WALLET-ADDRESS (err u114))

;; SYSTEM CONFIGURATION

(define-data-var platform-administrator principal tx-sender)
(define-data-var commission-fee-percentage uint u250) ;; 2.5% in basis points
(define-data-var maintenance-mode-active bool false)
(define-data-var accumulated-platform-fees uint u0)

;; CONTENT & CREATOR DATA MODELS

;; Comprehensive content registry with creator metadata
(define-map published-content-registry
  { content-identifier: (string-ascii 64) }
  {
    content-creator-wallet: principal,
    content-title: (string-ascii 256),
    content-description: (string-utf8 1024),
    publication-block-height: uint,
    cumulative-tip-earnings: uint,
    total-tip-transactions: uint,
    content-status-active: bool
  }
)

;; Individual tip transaction history
(define-map tip-transaction-history
  { content-identifier: (string-ascii 64), supporter-wallet: principal }
  {
    tip-amount-sent: uint,
    transaction-block-height: uint,
    supporter-message: (optional (string-utf8 280))
  }
)

;; Creator earnings wallet management
(define-map creator-earnings-balances
  { creator-wallet-address: principal }
  { withdrawable-balance: uint }
)

;; VALIDATION & UTILITY FUNCTIONS

(define-private (verify-platform-admin-access)
  (is-eq tx-sender (var-get platform-administrator))
)

(define-private (check-system-operational-status)
  (not (var-get maintenance-mode-active))
)

(define-private (validate-admin-and-system-status)
  (begin
    (asserts! (verify-platform-admin-access) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (check-system-operational-status) ERR-SYSTEM-UNDER-MAINTENANCE)
    (ok true)
  )
)

(define-private (compute-platform-commission (tip-amount uint))
  (/ (* tip-amount (var-get commission-fee-percentage)) u10000)
)

(define-private (compute-creator-net-earnings (tip-amount uint))
  (- tip-amount (compute-platform-commission tip-amount))
)

(define-private (credit-creator-earnings-account (creator-wallet principal) (earnings-amount uint))
  (let (
    (existing-balance (default-to { withdrawable-balance: u0 } 
                      (map-get? creator-earnings-balances { creator-wallet-address: creator-wallet })))
  )
    (map-set creator-earnings-balances
      { creator-wallet-address: creator-wallet }
      { withdrawable-balance: (+ (get withdrawable-balance existing-balance) earnings-amount) }
    )
  )
)

(define-private (update-content-engagement-metrics 
  (content-identifier (string-ascii 64)) 
  (tip-amount uint)
)
  (let (
    (content-record (unwrap! (map-get? published-content-registry { content-identifier: content-identifier }) 
                             ERR-CONTENT-NOT-FOUND))
  )
    (map-set published-content-registry
      { content-identifier: content-identifier }
      (merge content-record {
        cumulative-tip-earnings: (+ (get cumulative-tip-earnings content-record) tip-amount),
        total-tip-transactions: (+ (get total-tip-transactions content-record) u1)
      })
    )
    (ok true)
  )
)

;; INPUT VALIDATION HELPERS

(define-private (validate-content-identifier-format (content-identifier (string-ascii 64)))
  (and 
    (>= (len content-identifier) u1)
    (<= (len content-identifier) u64)
  )
)

(define-private (validate-content-title-format (content-title (string-ascii 256)))
  (and 
    (>= (len content-title) u1)
    (<= (len content-title) u256)
  )
)

(define-private (validate-content-description-format (content-description (string-utf8 1024)))
  (and 
    (>= (len content-description) u1)
    (<= (len content-description) u1024)
  )
)

(define-private (validate-supporter-message-format (supporter-message (optional (string-utf8 280))))
  (match supporter-message
    message-text (and (>= (len message-text) u0) (<= (len message-text) u280))
    true
  )
)

(define-private (validate-wallet-address-format (wallet-address principal))
  (not (is-eq wallet-address 'SP000000000000000000002Q6VF78))
)

;; PLATFORM ADMINISTRATION

(define-public (transfer-platform-ownership (new-administrator principal))
  (begin
    (asserts! (verify-platform-admin-access) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-wallet-address-format new-administrator) ERR-INVALID-WALLET-ADDRESS)
    
    (var-set platform-administrator new-administrator)
    (ok true)
  )
)

(define-public (adjust-commission-fee-rate (new-commission-rate uint))
  (begin
    (asserts! (verify-platform-admin-access) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (<= new-commission-rate u1000) ERR-INVALID-PARAMETER-VALUE) ;; Maximum 10%
    
    (var-set commission-fee-percentage new-commission-rate)
    (ok true)
  )
)

(define-public (toggle-maintenance-mode (enable-maintenance bool))
  (begin
    (asserts! (verify-platform-admin-access) ERR-UNAUTHORIZED-ACCESS)
    
    (var-set maintenance-mode-active enable-maintenance)
    (ok true)
  )
)

(define-public (withdraw-accumulated-platform-fees (destination-wallet principal))
  (let (
    (total-fees-available (var-get accumulated-platform-fees))
  )
    (begin
      (asserts! (verify-platform-admin-access) ERR-UNAUTHORIZED-ACCESS)
      (asserts! (validate-wallet-address-format destination-wallet) ERR-INVALID-WALLET-ADDRESS)
      (asserts! (> total-fees-available u0) ERR-INSUFFICIENT-FUNDS)
      
      (asserts! (is-ok (as-contract (stx-transfer? total-fees-available tx-sender destination-wallet))) 
                ERR-PAYMENT-TRANSFER-FAILED)
      
      (var-set accumulated-platform-fees u0)
      (ok total-fees-available)
    )
  )
)

;; CONTENT LIFECYCLE MANAGEMENT

(define-public (publish-new-content 
  (content-identifier (string-ascii 64))
  (content-title (string-ascii 256))
  (content-description (string-utf8 1024))
)
  (begin
    (asserts! (check-system-operational-status) ERR-SYSTEM-UNDER-MAINTENANCE)
    (asserts! (validate-content-identifier-format content-identifier) ERR-INVALID-CONTENT-IDENTIFIER)
    (asserts! (validate-content-title-format content-title) ERR-INVALID-TITLE-LENGTH)
    (asserts! (validate-content-description-format content-description) ERR-INVALID-DESCRIPTION-LENGTH)
    (asserts! (is-none (map-get? published-content-registry { content-identifier: content-identifier })) 
              ERR-CONTENT-ALREADY-EXISTS)
    
    (map-set published-content-registry
      { content-identifier: content-identifier }
      {
        content-creator-wallet: tx-sender,
        content-title: content-title,
        content-description: content-description,
        publication-block-height: block-height,
        cumulative-tip-earnings: u0,
        total-tip-transactions: u0,
        content-status-active: true
      }
    )
    (ok true)
  )
)

(define-public (update-existing-content
  (content-identifier (string-ascii 64))
  (updated-title (string-ascii 256))
  (updated-description (string-utf8 1024))
  (new-status bool)
)
  (let (
    (existing-content (unwrap! (map-get? published-content-registry { content-identifier: content-identifier }) 
                               ERR-CONTENT-NOT-FOUND))
  )
    (begin
      (asserts! (check-system-operational-status) ERR-SYSTEM-UNDER-MAINTENANCE)
      (asserts! (validate-content-identifier-format content-identifier) ERR-INVALID-CONTENT-IDENTIFIER)
      (asserts! (validate-content-title-format updated-title) ERR-INVALID-TITLE-LENGTH)
      (asserts! (validate-content-description-format updated-description) ERR-INVALID-DESCRIPTION-LENGTH)
      (asserts! (is-eq tx-sender (get content-creator-wallet existing-content)) ERR-UNAUTHORIZED-ACCESS)
      
      (map-set published-content-registry
        { content-identifier: content-identifier }
        (merge existing-content {
          content-title: updated-title,
          content-description: updated-description,
          content-status-active: new-status
        })
      )
      (ok true)
    )
  )
)

;; TIPPING TRANSACTION SYSTEM

(define-public (send-creator-tip
  (content-identifier (string-ascii 64))
  (tip-amount uint)
  (supporter-message (optional (string-utf8 280)))
)
  (let (
    (content-record (unwrap! (map-get? published-content-registry { content-identifier: content-identifier }) 
                             ERR-CONTENT-NOT-FOUND))
    (creator-wallet (get content-creator-wallet content-record))
    (platform-commission (compute-platform-commission tip-amount))
    (creator-net-earnings (compute-creator-net-earnings tip-amount))
  )
    (begin
      (asserts! (check-system-operational-status) ERR-SYSTEM-UNDER-MAINTENANCE)
      (asserts! (validate-content-identifier-format content-identifier) ERR-INVALID-CONTENT-IDENTIFIER)
      (asserts! (validate-supporter-message-format supporter-message) ERR-INVALID-MESSAGE-LENGTH)
      (asserts! (get content-status-active content-record) ERR-CONTENT-IS-DISABLED)
      (asserts! (> tip-amount u0) ERR-ZERO-AMOUNT-NOT-ALLOWED)
      (asserts! (> creator-net-earnings u0) ERR-INVALID-TIP-AMOUNT)
      
      ;; Transfer tip amount to contract escrow
      (asserts! (is-ok (stx-transfer? tip-amount tx-sender (as-contract tx-sender))) 
                ERR-PAYMENT-TRANSFER-FAILED)
      
      ;; Accumulate platform commission
      (var-set accumulated-platform-fees (+ (var-get accumulated-platform-fees) platform-commission))
      
      ;; Credit creator with net earnings
      (credit-creator-earnings-account creator-wallet creator-net-earnings)
      
      ;; Record tip transaction details
      (map-set tip-transaction-history
        { content-identifier: content-identifier, supporter-wallet: tx-sender }
        {
          tip-amount-sent: tip-amount,
          transaction-block-height: block-height,
          supporter-message: supporter-message
        }
      )
      
      ;; Update content engagement statistics
      (unwrap! (update-content-engagement-metrics content-identifier tip-amount) ERR-CONTENT-NOT-FOUND)
      
      (ok true)
    )
  )
)

;; CREATOR EARNINGS WITHDRAWAL

(define-public (withdraw-creator-earnings)
  (let (
    (earnings-record (default-to { withdrawable-balance: u0 } 
                      (map-get? creator-earnings-balances { creator-wallet-address: tx-sender })))
    (available-balance (get withdrawable-balance earnings-record))
  )
    (begin
      (asserts! (check-system-operational-status) ERR-SYSTEM-UNDER-MAINTENANCE)
      (asserts! (> available-balance u0) ERR-INSUFFICIENT-FUNDS)
      
      ;; Transfer available earnings to creator
      (asserts! (is-ok (as-contract (stx-transfer? available-balance tx-sender tx-sender))) 
                ERR-PAYMENT-TRANSFER-FAILED)
      
      ;; Clear creator balance after successful withdrawal
      (map-set creator-earnings-balances
        { creator-wallet-address: tx-sender }
        { withdrawable-balance: u0 }
      )
      
      (ok available-balance)
    )
  )
)

;; PUBLIC READ-ONLY QUERY FUNCTIONS

(define-read-only (get-content-details (content-identifier (string-ascii 64)))
  (map-get? published-content-registry { content-identifier: content-identifier })
)

(define-read-only (get-tip-transaction-record 
  (content-identifier (string-ascii 64)) 
  (supporter-wallet principal)
)
  (map-get? tip-transaction-history { content-identifier: content-identifier, supporter-wallet: supporter-wallet })
)

(define-read-only (get-creator-earnings-info (creator-wallet principal))
  (default-to { withdrawable-balance: u0 } 
              (map-get? creator-earnings-balances { creator-wallet-address: creator-wallet }))
)

(define-read-only (get-current-commission-rate)
  (var-get commission-fee-percentage)
)

(define-read-only (get-total-platform-fees-collected)
  (var-get accumulated-platform-fees)
)

(define-read-only (check-maintenance-status)
  (var-get maintenance-mode-active)
)

(define-read-only (get-platform-administrator)
  (var-get platform-administrator)
)

(define-read-only (calculate-tip-fee-breakdown (tip-amount uint))
  (let (
    (commission-fee (compute-platform-commission tip-amount))
    (creator-portion (compute-creator-net-earnings tip-amount))
  )
    {
      total-tip-amount: tip-amount,
      platform-commission: commission-fee,
      creator-net-earnings: creator-portion,
      commission-rate-basis-points: (var-get commission-fee-percentage)
    }
  )
)

;; CONTRACT INITIALIZATION

(begin
  (var-set platform-administrator tx-sender)
  (var-set commission-fee-percentage u250)
  (var-set maintenance-mode-active false)
)