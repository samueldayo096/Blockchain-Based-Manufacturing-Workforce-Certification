;; Skill Certification Contract
;; Records training and qualifications

(define-data-var admin principal tx-sender)

;; Data map to store skill certifications
(define-map certifications
  {
    employee-id: (string-utf8 36),
    skill-id: (string-utf8 36)
  }
  {
    skill-name: (string-utf8 100),
    level: uint,
    expiration: uint,
    issuer: principal,
    timestamp: uint
  }
)

;; List to track all skills for an employee
(define-map employee-skills
  { employee-id: (string-utf8 36) }
  { skill-list: (list 20 (string-utf8 36)) }
)

;; Public function to add a skill certification
(define-public (add-certification
    (employee-id (string-utf8 36))
    (skill-id (string-utf8 36))
    (skill-name (string-utf8 100))
    (level uint)
    (expiration uint))
  (let (
    (current-skills (default-to { skill-list: (list) } (map-get? employee-skills { employee-id: employee-id })))
    (skill-exists (map-get? certifications { employee-id: employee-id, skill-id: skill-id }))
  )
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))

      ;; Add or update the certification
      (map-set certifications
        { employee-id: employee-id, skill-id: skill-id }
        {
          skill-name: skill-name,
          level: level,
          expiration: expiration,
          issuer: tx-sender,
          timestamp: block-height
        }
      )

      ;; Add skill to employee's skill list if it doesn't exist
      (if (is-none skill-exists)
        (map-set employee-skills
          { employee-id: employee-id }
          { skill-list: (unwrap! (as-max-len? (append (get skill-list current-skills) skill-id) u20) (err u500)) }
        )
        true
      )

      (ok true)
    )
  )
)

;; Read-only function to get a certification
(define-read-only (get-certification (employee-id (string-utf8 36)) (skill-id (string-utf8 36)))
  (map-get? certifications { employee-id: employee-id, skill-id: skill-id })
)

;; Read-only function to get all skills for an employee
(define-read-only (get-employee-skills (employee-id (string-utf8 36)))
  (get skill-list (default-to { skill-list: (list) } (map-get? employee-skills { employee-id: employee-id })))
)

;; Read-only function to check if a certification is valid
(define-read-only (is-certification-valid (employee-id (string-utf8 36)) (skill-id (string-utf8 36)))
  (let ((cert (map-get? certifications { employee-id: employee-id, skill-id: skill-id })))
    (and
      (is-some cert)
      (> (get expiration (unwrap! cert false)) block-height)
    )
  )
)

;; Function to transfer admin rights
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
