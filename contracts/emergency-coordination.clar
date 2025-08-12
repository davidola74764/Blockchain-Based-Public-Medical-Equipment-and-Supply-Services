;; Emergency Supply Coordination Contract
;; Manages rapid deployment of medical equipment during health emergencies

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-INVALID-INPUT (err u501))
(define-constant ERR-EMERGENCY-NOT-FOUND (err u502))
(define-constant ERR-INSUFFICIENT-INVENTORY (err u503))
(define-constant ERR-DEPLOYMENT-NOT-FOUND (err u504))
(define-constant ERR-EMERGENCY-NOT-ACTIVE (err u505))

;; Data Variables
(define-data-var next-emergency-id uint u1)
(define-data-var next-deployment-id uint u1)
(define-data-var emergency-coordinator principal tx-sender)

;; Data Maps
(define-map emergency-declarations
  { emergency-id: uint }
  {
    declaration-date: uint,
    emergency-type: (string-ascii 50),
    affected-area: (string-ascii 100),
    severity-level: uint,
    coordinator: principal,
    status: (string-ascii 20),
    resolution-date: uint,
    resources-needed: (list 20 (string-ascii 50))
  }
)

(define-map emergency-inventory
  { equipment-type: (string-ascii 50) }
  {
    total-available: uint,
    reserved-emergency: uint,
    deployed-count: uint,
    minimum-threshold: uint,
    priority-level: uint,
    last-restocked: uint
  }
)

(define-map equipment-deployments
  { deployment-id: uint }
  {
    emergency-id: uint,
    equipment-type: (string-ascii 50),
    quantity: uint,
    destination: (string-ascii 100),
    deployment-date: uint,
    deployed-by: principal,
    status: (string-ascii 20),
    return-date: uint
  }
)

(define-map authorized-coordinators
  { coordinator: principal }
  {
    authorization-level: uint,
    authorized-areas: (list 10 (string-ascii 100)),
    authorization-date: uint,
    expiration-date: uint,
    emergency-types: (list 10 (string-ascii 50))
  }
)

(define-map priority-facilities
  { facility-id: (string-ascii 100) }
  {
    name: (string-ascii 100),
    location: (string-ascii 200),
    facility-type: (string-ascii 50),
    priority-level: uint,
    capacity: uint,
    contact-info: (string-ascii 200)
  }
)

;; Initialize emergency inventory
(map-set emergency-inventory
  { equipment-type: "wheelchair" }
  {
    total-available: u100,
    reserved-emergency: u20,
    deployed-count: u0,
    minimum-threshold: u10,
    priority-level: u2,
    last-restocked: u0
  }
)

(map-set emergency-inventory
  { equipment-type: "hospital-bed" }
  {
    total-available: u50,
    reserved-emergency: u15,
    deployed-count: u0,
    minimum-threshold: u5,
    priority-level: u1,
    last-restocked: u0
  }
)

(map-set emergency-inventory
  { equipment-type: "medical-device" }
  {
    total-available: u30,
    reserved-emergency: u10,
    deployed-count: u0,
    minimum-threshold: u3,
    priority-level: u1,
    last-restocked: u0
  }
)

;; Initialize priority facilities
(map-set priority-facilities
  { facility-id: "hospital-001" }
  {
    name: "Central Emergency Hospital",
    location: "Downtown Medical District",
    facility-type: "hospital",
    priority-level: u1,
    capacity: u500,
    contact-info: "emergency@centralhospital.org"
  }
)

;; Public Functions

;; Declare emergency
(define-public (declare-emergency (emergency-type (string-ascii 50)) (affected-area (string-ascii 100)) (severity-level uint) (resources-needed (list 20 (string-ascii 50))))
  (let (
    (emergency-id (var-get next-emergency-id))
    (current-time (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-INPUT))
    (coordinator-auth (map-get? authorized-coordinators { coordinator: tx-sender }))
  )
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-some coordinator-auth)) ERR-NOT-AUTHORIZED)
    (asserts! (> (len emergency-type) u0) ERR-INVALID-INPUT)
    (asserts! (> (len affected-area) u0) ERR-INVALID-INPUT)
    (asserts! (and (> severity-level u0) (< severity-level u6)) ERR-INVALID-INPUT)

    ;; Create emergency declaration
    (map-set emergency-declarations
      { emergency-id: emergency-id }
      {
        declaration-date: current-time,
        emergency-type: emergency-type,
        affected-area: affected-area,
        severity-level: severity-level,
        coordinator: tx-sender,
        status: "active",
        resolution-date: u0,
        resources-needed: resources-needed
      }
    )

    ;; Increment emergency ID counter
    (var-set next-emergency-id (+ emergency-id u1))

    (ok emergency-id)
  )
)

;; Deploy emergency equipment
(define-public (deploy-equipment (emergency-id uint) (equipment-type (string-ascii 50)) (quantity uint) (destination (string-ascii 100)))
  (let (
    (deployment-id (var-get next-deployment-id))
    (current-time (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-INPUT))
    (emergency-info (unwrap! (map-get? emergency-declarations { emergency-id: emergency-id }) ERR-EMERGENCY-NOT-FOUND))
    (inventory-info (unwrap! (map-get? emergency-inventory { equipment-type: equipment-type }) ERR-INVALID-INPUT))
    (available-quantity (- (get reserved-emergency inventory-info) (get deployed-count inventory-info)))
  )
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get coordinator emergency-info))) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status emergency-info) "active") ERR-EMERGENCY-NOT-ACTIVE)
    (asserts! (> quantity u0) ERR-INVALID-INPUT)
    (asserts! (>= available-quantity quantity) ERR-INSUFFICIENT-INVENTORY)
    (asserts! (> (len destination) u0) ERR-INVALID-INPUT)

    ;; Create deployment record
    (map-set equipment-deployments
      { deployment-id: deployment-id }
      {
        emergency-id: emergency-id,
        equipment-type: equipment-type,
        quantity: quantity,
        destination: destination,
        deployment-date: current-time,
        deployed-by: tx-sender,
        status: "deployed",
        return-date: u0
      }
    )

    ;; Update inventory
    (map-set emergency-inventory
      { equipment-type: equipment-type }
      (merge inventory-info {
        deployed-count: (+ (get deployed-count inventory-info) quantity)
      })
    )

    ;; Increment deployment ID counter
    (var-set next-deployment-id (+ deployment-id u1))

    (ok deployment-id)
  )
)

;; Return deployed equipment
(define-public (return-equipment (deployment-id uint))
  (let (
    (deployment-info (unwrap! (map-get? equipment-deployments { deployment-id: deployment-id }) ERR-DEPLOYMENT-NOT-FOUND))
    (current-time (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-INPUT))
    (inventory-info (unwrap! (map-get? emergency-inventory { equipment-type: (get equipment-type deployment-info) }) ERR-INVALID-INPUT))
  )
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get deployed-by deployment-info))) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status deployment-info) "deployed") ERR-INVALID-INPUT)

    ;; Update deployment record
    (map-set equipment-deployments
      { deployment-id: deployment-id }
      (merge deployment-info {
        status: "returned",
        return-date: current-time
      })
    )

    ;; Update inventory
    (map-set emergency-inventory
      { equipment-type: (get equipment-type deployment-info) }
      (merge inventory-info {
        deployed-count: (- (get deployed-count inventory-info) (get quantity deployment-info))
      })
    )

    (ok true)
  )
)

;; Resolve emergency
(define-public (resolve-emergency (emergency-id uint))
  (let (
    (emergency-info (unwrap! (map-get? emergency-declarations { emergency-id: emergency-id }) ERR-EMERGENCY-NOT-FOUND))
    (current-time (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-INPUT))
  )
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get coordinator emergency-info))) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status emergency-info) "active") ERR-EMERGENCY-NOT-ACTIVE)

    ;; Update emergency status
    (map-set emergency-declarations
      { emergency-id: emergency-id }
      (merge emergency-info {
        status: "resolved",
        resolution-date: current-time
      })
    )

    (ok true)
  )
)

;; Authorize emergency coordinator
(define-public (authorize-coordinator (coordinator principal) (authorization-level uint) (authorized-areas (list 10 (string-ascii 100))) (validity-days uint))
  (let (
    (current-time (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-INPUT))
    (expiration-time (+ current-time (* validity-days u86400)))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (and (> authorization-level u0) (< authorization-level u6)) ERR-INVALID-INPUT)
    (asserts! (> validity-days u0) ERR-INVALID-INPUT)
    (asserts! (< validity-days u1095) ERR-INVALID-INPUT)

    ;; Create coordinator authorization
    (map-set authorized-coordinators
      { coordinator: coordinator }
      {
        authorization-level: authorization-level,
        authorized-areas: authorized-areas,
        authorization-date: current-time,
        expiration-date: expiration-time,
        emergency-types: (list "natural-disaster" "pandemic" "infrastructure-failure" "mass-casualty")
      }
    )

    (ok true)
  )
)

;; Restock emergency inventory
(define-public (restock-inventory (equipment-type (string-ascii 50)) (additional-quantity uint) (emergency-reserve uint))
  (let (
    (current-time (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-INPUT))
    (inventory-info (unwrap! (map-get? emergency-inventory { equipment-type: equipment-type }) ERR-INVALID-INPUT))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> additional-quantity u0) ERR-INVALID-INPUT)
    (asserts! (>= emergency-reserve u0) ERR-INVALID-INPUT)

    ;; Update inventory with additional stock
    (map-set emergency-inventory
      { equipment-type: equipment-type }
      (merge inventory-info {
        total-available: (+ (get total-available inventory-info) additional-quantity),
        reserved-emergency: (+ (get reserved-emergency inventory-info) emergency-reserve),
        last-restocked: current-time
      })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get emergency declaration
(define-read-only (get-emergency-declaration (emergency-id uint))
  (map-get? emergency-declarations { emergency-id: emergency-id })
)

;; Get emergency inventory
(define-read-only (get-emergency-inventory (equipment-type (string-ascii 50)))
  (map-get? emergency-inventory { equipment-type: equipment-type })
)

;; Get equipment deployment
(define-read-only (get-equipment-deployment (deployment-id uint))
  (map-get? equipment-deployments { deployment-id: deployment-id })
)

;; Get coordinator authorization
(define-read-only (get-coordinator-authorization (coordinator principal))
  (map-get? authorized-coordinators { coordinator: coordinator })
)

;; Get priority facility
(define-read-only (get-priority-facility (facility-id (string-ascii 100)))
  (map-get? priority-facilities { facility-id: facility-id })
)

;; Check equipment availability
(define-read-only (check-equipment-availability (equipment-type (string-ascii 50)) (requested-quantity uint))
  (match (map-get? emergency-inventory { equipment-type: equipment-type })
    inventory-info
      (let (
        (available-quantity (- (get reserved-emergency inventory-info) (get deployed-count inventory-info)))
      )
        (>= available-quantity requested-quantity)
      )
    false
  )
)

;; Check if emergency is active
(define-read-only (is-emergency-active (emergency-id uint))
  (match (map-get? emergency-declarations { emergency-id: emergency-id })
    emergency-info (is-eq (get status emergency-info) "active")
    false
  )
)

;; Get available emergency stock
(define-read-only (get-available-emergency-stock (equipment-type (string-ascii 50)))
  (match (map-get? emergency-inventory { equipment-type: equipment-type })
    inventory-info
      (- (get reserved-emergency inventory-info) (get deployed-count inventory-info))
    u0
  )
)

;; Check if inventory is below threshold
(define-read-only (is-below-threshold (equipment-type (string-ascii 50)))
  (match (map-get? emergency-inventory { equipment-type: equipment-type })
    inventory-info
      (let (
        (available-quantity (- (get reserved-emergency inventory-info) (get deployed-count inventory-info)))
      )
        (< available-quantity (get minimum-threshold inventory-info))
      )
    false
  )
)

;; Get next emergency ID
(define-read-only (get-next-emergency-id)
  (var-get next-emergency-id)
)

;; Get next deployment ID
(define-read-only (get-next-deployment-id)
  (var-get next-deployment-id)
)

;; Get emergency coordinator
(define-read-only (get-emergency-coordinator)
  (var-get emergency-coordinator)
)
