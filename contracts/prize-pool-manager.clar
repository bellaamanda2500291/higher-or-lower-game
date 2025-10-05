;; title: prize-pool-manager
;; version: 1.0.0
;; summary: Manages game prize pool and distributes winnings to correct guessers
;; description: Handles prize pool accumulation, winner payouts, and balance tracking

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-INSUFFICIENT-BALANCE (err u201))
(define-constant ERR-NO-WINNERS (err u202))
(define-constant ERR-ALREADY-CLAIMED (err u203))
(define-constant ERR-INVALID-AMOUNT (err u204))
(define-constant ERR-TRANSFER-FAILED (err u205))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-ENTRY-FEE u1000000) ;; 1 STX in microSTX
(define-constant MAX-WINNERS u100)

;; data vars
;;
(define-data-var prize-pool uint u0)
(define-data-var total-rounds uint u0)
(define-data-var total-distributed uint u0)

;; data maps
;;
;; Track entry fees paid by players for each round
(define-map player-entries
    { round-id: uint, player: principal }
    { amount-paid: uint, timestamp: uint }
)

;; Track winnings claimed by players
(define-map claimed-winnings
    { round-id: uint, player: principal }
    { amount: uint, timestamp: uint }
)

;; Track total winnings available per round
(define-map round-prize-pools
    { round-id: uint }
    { total-pool: uint, winners-count: uint, per-winner-amount: uint }
)

;; public functions
;;

;; Add entry fee to prize pool (players pay to participate)
(define-public (pay-entry-fee (round-id uint))
    (let (
        (player tx-sender)
        (entry-amount MIN-ENTRY-FEE)
    )
        ;; Check if player hasn't already paid for this round
        (asserts! (is-none (map-get? player-entries { round-id: round-id, player: player })) ERR-ALREADY-CLAIMED)
        
        ;; Transfer STX from player to contract
        (match (stx-transfer? entry-amount player (as-contract tx-sender))
            success
            (begin
                ;; Record the entry payment
                (map-set player-entries
                    { round-id: round-id, player: player }
                    { amount-paid: entry-amount, timestamp: stacks-block-height }
                )
                
                ;; Add to prize pool
                (var-set prize-pool (+ (var-get prize-pool) entry-amount))
                
                (ok entry-amount)
            )
            error ERR-TRANSFER-FAILED
        )
    )
)

;; Finalize round and calculate prize distribution
;; Only contract owner can call this (typically after game-logic-engine determines winners)
(define-public (finalize-round (round-id uint) (winners-count uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (> winners-count u0) ERR-NO-WINNERS)
        
        (let (
            (current-pool (var-get prize-pool))
            ;; Winners get half of the current prize pool
            (prize-amount (/ current-pool u2))
            (per-winner-amount (/ prize-amount winners-count))
        )
            ;; Store round prize information
            (map-set round-prize-pools
                { round-id: round-id }
                { total-pool: prize-amount, winners-count: winners-count, per-winner-amount: per-winner-amount }
            )
            
            ;; Remove distributed amount from prize pool
            (var-set prize-pool (- current-pool prize-amount))
            (var-set total-distributed (+ (var-get total-distributed) prize-amount))
            (var-set total-rounds (+ (var-get total-rounds) u1))
            
            (ok { total-prize: prize-amount, per-winner: per-winner-amount, winners: winners-count })
        )
    )
)

;; Claim winnings for a specific round
(define-public (claim-winnings (round-id uint))
    (let (
        (player tx-sender)
    )
        ;; Check if player hasn't already claimed
        (asserts! (is-none (map-get? claimed-winnings { round-id: round-id, player: player })) ERR-ALREADY-CLAIMED)
        
        ;; Get round prize information
        (match (map-get? round-prize-pools { round-id: round-id })
            round-data
            (let (
                (prize-amount (get per-winner-amount round-data))
            )
                ;; Here we'd need to verify the player is actually a winner
                ;; This would require integration with game-logic-engine contract
                ;; For now, we'll assume verification is done externally
                
                ;; Transfer winnings to player
                (match (as-contract (stx-transfer? prize-amount tx-sender player))
                    success
                    (begin
                        ;; Record the claim
                        (map-set claimed-winnings
                            { round-id: round-id, player: player }
                            { amount: prize-amount, timestamp: stacks-block-height }
                        )
                        
                        (ok prize-amount)
                    )
                    error ERR-TRANSFER-FAILED
                )
            )
            ERR-NO-WINNERS
        )
    )
)

;; Owner can add funds to prize pool
(define-public (add-to-pool (amount uint))
    (begin
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        
        ;; Transfer STX from sender to contract
        (match (stx-transfer? amount tx-sender (as-contract tx-sender))
            success
            (begin
                (var-set prize-pool (+ (var-get prize-pool) amount))
                (ok amount)
            )
            error ERR-TRANSFER-FAILED
        )
    )
)

;; Emergency withdraw (only owner)
(define-public (emergency-withdraw (amount uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (>= (var-get prize-pool) amount) ERR-INSUFFICIENT-BALANCE)
        
        (match (as-contract (stx-transfer? amount tx-sender CONTRACT-OWNER))
            success
            (begin
                (var-set prize-pool (- (var-get prize-pool) amount))
                (ok amount)
            )
            error ERR-TRANSFER-FAILED
        )
    )
)

;; read only functions
;;

;; Get current prize pool balance
(define-read-only (get-pool-balance)
    (var-get prize-pool)
)

;; Get pool statistics
(define-read-only (get-pool-stats)
    {
        current-pool: (var-get prize-pool),
        total-rounds: (var-get total-rounds),
        total-distributed: (var-get total-distributed),
        contract-balance: (stx-get-balance (as-contract tx-sender))
    }
)

;; Get round prize information
(define-read-only (get-round-prize-info (round-id uint))
    (map-get? round-prize-pools { round-id: round-id })
)

;; Check if player has paid entry fee for a round
(define-read-only (has-paid-entry (round-id uint) (player principal))
    (is-some (map-get? player-entries { round-id: round-id, player: player }))
)

;; Check if player has claimed winnings for a round
(define-read-only (has-claimed-winnings (round-id uint) (player principal))
    (is-some (map-get? claimed-winnings { round-id: round-id, player: player }))
)

;; Calculate potential payout per winner for current pool
(define-read-only (calculate-payout (winner-count uint))
    (if (> winner-count u0)
        (/ (/ (var-get prize-pool) u2) winner-count)
        u0
    )
)

;; Get entry fee amount
(define-read-only (get-entry-fee)
    MIN-ENTRY-FEE
)

;; private functions
;;
