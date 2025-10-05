;; title: game-logic-engine
;; version: 1.0.0
;; summary: Core game logic for higher/lower prediction game
;; description: Implements higher/lower comparison logic and winner determination

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-GAME-NOT-ACTIVE (err u101))
(define-constant ERR-INVALID-PREDICTION (err u102))
(define-constant ERR-ALREADY-PREDICTED (err u103))
(define-constant ERR-NO-ACTIVE-ROUND (err u104))

;; Game constants
(define-constant MIN-NUMBER u1)
(define-constant MAX-NUMBER u100)
(define-constant CONTRACT-OWNER tx-sender)

;; data vars
;;
(define-data-var game-active bool true)
(define-data-var current-number uint u50) ;; Start with middle value
(define-data-var round-id uint u0)
(define-data-var total-predictions uint u0)

;; data maps
;;
;; Store predictions for each round
(define-map predictions 
    { round-id: uint, player: principal } 
    { prediction: bool, timestamp: uint }
)

;; Store round results
(define-map round-results 
    { round-id: uint } 
    { previous-number: uint, new-number: uint, winners-count: uint, timestamp: uint }
)

;; Track players who have predicted in current round
(define-map round-participants
    { round-id: uint }
    { players: (list 200 principal), count: uint }
)

;; public functions
;;

;; Make a prediction for the current round
;; @param prediction: true for higher, false for lower
(define-public (make-prediction (prediction bool))
    (let (
        (current-round (var-get round-id))
        (player tx-sender)
    )
        ;; Check if game is active
        (asserts! (var-get game-active) ERR-GAME-NOT-ACTIVE)
        
        ;; Check if player hasn't already predicted this round
        (asserts! (is-none (map-get? predictions { round-id: current-round, player: player })) ERR-ALREADY-PREDICTED)
        
        ;; Store the prediction
        (map-set predictions 
            { round-id: current-round, player: player }
            { prediction: prediction, timestamp: stacks-block-height }
        )
        
        ;; Update total predictions count
        (var-set total-predictions (+ (var-get total-predictions) u1))
        
        (ok true)
    )
)

;; Generate next number and determine winners
;; Only contract owner can trigger this
(define-public (generate-next-number (random-seed uint))
    (begin
        ;; Only contract owner can generate next number
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        
        (let (
            (current-round (var-get round-id))
            (previous-number (var-get current-number))
            ;; Generate pseudo-random number based on seed and block info
            (new-number (+ u1 (mod (+ random-seed stacks-block-height (stx-get-balance tx-sender)) (- MAX-NUMBER MIN-NUMBER))))
            (is-higher (> new-number previous-number))
        )
            ;; Update current number
            (var-set current-number new-number)
            
            ;; Count winners and store round results
            (let ((winners-count (count-winners current-round is-higher)))
                (map-set round-results
                    { round-id: current-round }
                    { previous-number: previous-number, new-number: new-number, winners-count: winners-count, timestamp: stacks-block-height }
                )
                
                ;; Move to next round
                (var-set round-id (+ current-round u1))
                (var-set total-predictions u0)
                
                (ok { previous-number: previous-number, new-number: new-number, winners-count: winners-count })
            )
        )
    )
)

;; Pause or resume the game
(define-public (set-game-active (active bool))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (var-set game-active active)
        (ok active)
    )
)

;; read only functions
;;

;; Get current game state
(define-read-only (get-game-state)
    {
        current-number: (var-get current-number),
        round-id: (var-get round-id),
        game-active: (var-get game-active),
        total-predictions: (var-get total-predictions)
    }
)

;; Get player's prediction for a specific round
(define-read-only (get-player-prediction (round-number uint) (player principal))
    (map-get? predictions { round-id: round-number, player: player })
)

;; Get round results
(define-read-only (get-round-results (round-number uint))
    (map-get? round-results { round-id: round-number })
)

;; Check if a player was a winner in a specific round
(define-read-only (is-winner (round-number uint) (player principal))
    (match (map-get? predictions { round-id: round-number, player: player })
        prediction-data
        (match (map-get? round-results { round-id: round-number })
            round-data
            (let (
                (predicted-higher (get prediction prediction-data))
                (actual-higher (> (get new-number round-data) (get previous-number round-data)))
            )
                (is-eq predicted-higher actual-higher)
            )
            false
        )
        false
    )
)

;; Get current number (for display purposes)
(define-read-only (get-current-number)
    (var-get current-number)
)

;; private functions
;;

;; Count winners for a specific round
(define-private (count-winners (round-number uint) (actual-higher bool))
    ;; This is a simplified implementation - in practice you'd iterate through all predictions
    ;; For now, we'll return a placeholder that would be calculated by iterating through predictions
    u0  ;; This would need to be implemented with a fold function over all predictions
)
