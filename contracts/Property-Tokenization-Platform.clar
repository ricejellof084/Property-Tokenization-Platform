(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_INSUFFICIENT_BALANCE (err u103))
(define-constant ERR_PROPERTY_EXISTS (err u104))
(define-constant ERR_PROPERTY_NOT_ACTIVE (err u105))
(define-constant ERR_INVALID_PRICE (err u106))
(define-constant ERR_CANNOT_TRANSFER_TO_SELF (err u107))
(define-constant ERR_NO_RENT_AVAILABLE (err u108))
(define-constant ERR_ALREADY_CLAIMED (err u109))

(define-data-var next-property-id uint u1)
(define-data-var platform-fee uint u250)

(define-map properties
    uint
    {
        owner: principal,
        address: (string-ascii 100),
        total-tokens: uint,
        available-tokens: uint,
        price-per-token: uint,
        active: bool,
        created-at: uint,
    }
)

(define-map property-tokens
    {
        property-id: uint,
        holder: principal,
    }
    { amount: uint }
)

(define-map user-properties
    principal
    { property-count: uint }
)

(define-map property-metadata
    uint
    {
        description: (string-ascii 500),
        property-type: (string-ascii 50),
        square-feet: uint,
        year-built: uint,
    }
)

(define-map total-supply
    uint
    uint
)

(define-map property-rent-pools
    uint
    {
        total-deposited: uint,
        total-claimed: uint,
        last-distribution: uint,
    }
)

(define-map rent-claims
    {
        property-id: uint,
        claimant: principal,
        distribution-period: uint,
    }
    { claimed: bool }
)

(define-read-only (get-property (property-id uint))
    (map-get? properties property-id)
)

(define-read-only (get-property-metadata (property-id uint))
    (map-get? property-metadata property-id)
)

(define-read-only (get-token-balance
        (property-id uint)
        (holder principal)
    )
    (default-to u0
        (get amount
            (map-get? property-tokens {
                property-id: property-id,
                holder: holder,
            })
        ))
)

(define-read-only (get-total-supply (property-id uint))
    (map-get? total-supply property-id)
)

(define-read-only (get-user-property-count (user principal))
    (default-to u0 (get property-count (map-get? user-properties user)))
)

(define-read-only (get-platform-fee)
    (var-get platform-fee)
)

(define-read-only (get-next-property-id)
    (var-get next-property-id)
)

(define-read-only (get-rent-pool (property-id uint))
    (map-get? property-rent-pools property-id)
)

(define-read-only (get-claimable-rent
        (property-id uint)
        (claimant principal)
    )
    (match (map-get? property-rent-pools property-id)
        rent-pool (let (
                (user-tokens (get-token-balance property-id claimant))
                (total-tokens (default-to u0 (get-total-supply property-id)))
                (current-period (get last-distribution rent-pool))
                (already-claimed (is-some (map-get? rent-claims {
                    property-id: property-id,
                    claimant: claimant,
                    distribution-period: current-period,
                })))
                (available-rent (- (get total-deposited rent-pool) (get total-claimed rent-pool)))
            )
            (if (and
                    (> user-tokens u0)
                    (> total-tokens u0)
                    (not already-claimed)
                    (> available-rent u0)
                )
                (ok (/ (* user-tokens available-rent) total-tokens))
                (ok u0)
            )
        )
        (ok u0)
    )
)

(define-public (create-property
        (address (string-ascii 100))
        (total-tokens uint)
        (price-per-token uint)
        (description (string-ascii 500))
        (property-type (string-ascii 50))
        (square-feet uint)
        (year-built uint)
    )
    (let (
            (property-id (var-get next-property-id))
            (current-count (get-user-property-count tx-sender))
        )
        (asserts! (> total-tokens u0) ERR_INVALID_AMOUNT)
        (asserts! (> price-per-token u0) ERR_INVALID_PRICE)

        (map-set properties property-id {
            owner: tx-sender,
            address: address,
            total-tokens: total-tokens,
            available-tokens: total-tokens,
            price-per-token: price-per-token,
            active: true,
            created-at: stacks-block-height,
        })

        (map-set property-metadata property-id {
            description: description,
            property-type: property-type,
            square-feet: square-feet,
            year-built: year-built,
        })

        (map-set total-supply property-id total-tokens)

        (map-set user-properties tx-sender { property-count: (+ current-count u1) })

        (var-set next-property-id (+ property-id u1))
        (ok property-id)
    )
)

(define-public (purchase-tokens
        (property-id uint)
        (token-amount uint)
    )
    (let (
            (property (unwrap! (get-property property-id) ERR_NOT_FOUND))
            (total-cost (* token-amount (get price-per-token property)))
            (fee-amount (/ (* total-cost (var-get platform-fee)) u10000))
            (owner-amount (- total-cost fee-amount))
            (current-balance (get-token-balance property-id tx-sender))
        )
        (asserts! (get active property) ERR_PROPERTY_NOT_ACTIVE)
        (asserts! (> token-amount u0) ERR_INVALID_AMOUNT)
        (asserts! (>= (get available-tokens property) token-amount)
            ERR_INSUFFICIENT_BALANCE
        )

        (try! (stx-transfer? total-cost tx-sender (as-contract tx-sender)))
        (try! (as-contract (stx-transfer? owner-amount tx-sender (get owner property))))

        (map-set properties property-id
            (merge property { available-tokens: (- (get available-tokens property) token-amount) })
        )

        (map-set property-tokens {
            property-id: property-id,
            holder: tx-sender,
        } { amount: (+ current-balance token-amount) }
        )

        (ok token-amount)
    )
)

(define-public (transfer-tokens
        (property-id uint)
        (recipient principal)
        (token-amount uint)
    )
    (let (
            (sender-balance (get-token-balance property-id tx-sender))
            (recipient-balance (get-token-balance property-id recipient))
        )
        (asserts! (not (is-eq tx-sender recipient)) ERR_CANNOT_TRANSFER_TO_SELF)
        (asserts! (> token-amount u0) ERR_INVALID_AMOUNT)
        (asserts! (>= sender-balance token-amount) ERR_INSUFFICIENT_BALANCE)

        (map-set property-tokens {
            property-id: property-id,
            holder: tx-sender,
        } { amount: (- sender-balance token-amount) }
        )

        (map-set property-tokens {
            property-id: property-id,
            holder: recipient,
        } { amount: (+ recipient-balance token-amount) }
        )

        (ok token-amount)
    )
)

(define-public (update-property-price
        (property-id uint)
        (new-price uint)
    )
    (let ((property (unwrap! (get-property property-id) ERR_NOT_FOUND)))
        (asserts! (is-eq tx-sender (get owner property)) ERR_UNAUTHORIZED)
        (asserts! (> new-price u0) ERR_INVALID_PRICE)

        (map-set properties property-id
            (merge property { price-per-token: new-price })
        )

        (ok new-price)
    )
)

(define-public (toggle-property-status (property-id uint))
    (let ((property (unwrap! (get-property property-id) ERR_NOT_FOUND)))
        (asserts! (is-eq tx-sender (get owner property)) ERR_UNAUTHORIZED)

        (map-set properties property-id
            (merge property { active: (not (get active property)) })
        )

        (ok (not (get active property)))
    )
)

(define-public (list-tokens-for-sale
        (property-id uint)
        (token-amount uint)
        (sale-price uint)
    )
    (let ((seller-balance (get-token-balance property-id tx-sender)))
        (asserts! (> token-amount u0) ERR_INVALID_AMOUNT)
        (asserts! (> sale-price u0) ERR_INVALID_PRICE)
        (asserts! (>= seller-balance token-amount) ERR_INSUFFICIENT_BALANCE)

        (ok {
            seller: tx-sender,
            amount: token-amount,
            price: sale-price,
        })
    )
)

(define-public (set-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (<= new-fee u1000) ERR_INVALID_AMOUNT)
        (var-set platform-fee new-fee)
        (ok new-fee)
    )
)

(define-read-only (calculate-ownership-percentage
        (property-id uint)
        (holder principal)
    )
    (let (
            (user-tokens (get-token-balance property-id holder))
            (total-tokens (unwrap! (get-total-supply property-id) u0))
        )
        (if (> total-tokens u0)
            (/ (* user-tokens u10000) total-tokens)
            u0
        )
    )
)

(define-read-only (get-property-value (property-id uint))
    (match (get-property property-id)
        property (* (get total-tokens property) (get price-per-token property))
        u0
    )
)

(define-read-only (get-user-portfolio-value (user principal))
    (fold calculate-user-value (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) {
        user: user,
        total-value: u0,
    })
)

(define-private (calculate-user-value
        (property-id uint)
        (data {
            user: principal,
            total-value: uint,
        })
    )
    (let (
            (user-tokens (get-token-balance property-id (get user data)))
            (property (get-property property-id))
        )
        (match property
            prop (merge data { total-value: (+ (get total-value data) (* user-tokens (get price-per-token prop))) })
            data
        )
    )
)

(define-public (deposit-rent
        (property-id uint)
        (amount uint)
    )
    (let ((property (unwrap! (get-property property-id) ERR_NOT_FOUND)))
        (asserts! (is-eq tx-sender (get owner property)) ERR_UNAUTHORIZED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)

        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

        (let ((current-pool (default-to {
                total-deposited: u0,
                total-claimed: u0,
                last-distribution: stacks-block-height,
            }
                (map-get? property-rent-pools property-id)
            )))
            (map-set property-rent-pools property-id {
                total-deposited: (+ (get total-deposited current-pool) amount),
                total-claimed: (get total-claimed current-pool),
                last-distribution: stacks-block-height,
            })
        )

        (ok amount)
    )
)

(define-public (claim-rent (property-id uint))
    (let (
            (claimable-amount (unwrap! (get-claimable-rent property-id tx-sender)
                ERR_NO_RENT_AVAILABLE
            ))
            (current-pool (unwrap! (map-get? property-rent-pools property-id) ERR_NOT_FOUND))
            (current-period (get last-distribution current-pool))
        )
        (asserts! (> claimable-amount u0) ERR_NO_RENT_AVAILABLE)
        (asserts!
            (is-none (map-get? rent-claims {
                property-id: property-id,
                claimant: tx-sender,
                distribution-period: current-period,
            }))
            ERR_ALREADY_CLAIMED
        )

        (try! (as-contract (stx-transfer? claimable-amount tx-sender tx-sender)))

        (map-set property-rent-pools property-id
            (merge current-pool { total-claimed: (+ (get total-claimed current-pool) claimable-amount) })
        )

        (map-set rent-claims {
            property-id: property-id,
            claimant: tx-sender,
            distribution-period: current-period,
        } { claimed: true }
        )

        (ok claimable-amount)
    )
)

(define-public (withdraw-contract-balance)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (try! (as-contract (stx-transfer? (stx-get-balance tx-sender) tx-sender CONTRACT_OWNER)))
        (ok true)
    )
)
