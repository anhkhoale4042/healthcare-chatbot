# HIPAA Compliance Notes

Purpose:
Summarize HIPAA considerations, PHI handling rules, and required controls for the healthcare chatbot. This document complements docs/compliance/phi_inventory.md.

## Data flow (high-level)
User -> Ingestion -> Processing (PHI detection & redaction) -> Temporary storage -> Long-term storage (encrypted) -> Access (restricted roles)

At each stage:
- Apply the minimum necessary principle.
- Perform PHI detection and redaction as early as possible (at ingestion).
- Log redaction and access events (see Audit Trails).

Roles:
- Developer: access to masked/anonymized logs only. Access to raw PHI requires explicit authorization.
- Analyst: works with de-identified/aggregated datasets only.
- Clinician: may access PHI via authorized channels with audit logging.
- Compliance/security: reviews access logs, handles breach reporting.

Reference PHI inventory: docs/compliance/phi_inventory.md

## PHI vs Non-PHI (summary)
- PHI examples: full name, address (below state), phone, email, DOB, MRN, SSN, insurance IDs, account numbers, IP/device IDs (when linkable to an individual), biometric data, full-face photos, any combos that identify a person.
- Non-PHI examples: session_id (UUID), UTC timestamps not tied to identity, derived metadata (intent, entities, urgency), aggregated counts after de-identification.
- Default: treat any uncertain field as PHI until reviewed and approved.

## Redaction rules
- Replace sensitive spans with placeholders before storage or transmission:
  - [REDACTED_NAME]
  - [REDACTED_PHONE]
  - [REDACTED_EMAIL]
  - [REDACTED_ID]
  - [REDACTED_IP]
  - [REDACTED_DATE]
- For dates, prefer year or age_range instead of full date when possible.
- Keep an auditable mapping of redaction rules and versions (so we can reproduce behavior).
- Implement layered detection: regex first-pass, NER for PERSON/GPE/DATE, heuristics, and human review for ambiguous cases.

## Encryption and key management
- At rest: use AES-256-GCM or equivalent for PHI stored in databases or file storage.
- In transit: require TLS 1.2 or higher for all services, APIs, and DB connections.
- Encryption is an addressable HIPAA control: if encryption is not implemented for a component, document the risk assessment and compensating controls.
- Key management:
  - Store keys in a secrets manager (e.g., cloud KMS or Vault); keys must not be in source control.
  - Rotate keys periodically (define schedule, e.g., annually or per org policy).
  - Maintain secure backups of keys and document recovery procedures.
  - Separate duties: key management access restricted to security roles.
- Document encryption configurations and proof of encryption for audits.

## Access control
- Enforce RBAC with least privilege.
- Define roles and privileges explicitly, and document owners for each role.
- Use strong authentication for admin/clinician access (MFA recommended).
- Periodically review and certify role memberships and permissions.

## Audit trails and logging
- Maintain immutable audit logs recording:
  - Principal (who accessed data)
  - Operation (read/write/delete/redact/export)
  - Target (which resource or record)
  - Timestamp and reason (if provided)
  - Redaction events (what was redacted, rule version)
- Store audit logs in append-only storage with restricted access.
- Monitor logs for anomalous access patterns and trigger alerts.
- Retain audit logs per retention policy (see Consent & retention).

## Business associates and contracts
- Any third-party vendor processing PHI (DB, storage, analytics, hosting, secret manager) must sign a Business Associate Agreement (BAA).
- Maintain a registry of BAAs and vendor responsibilities.

## Breach reporting
- Follow HIPAA Breach Notification Rule:
  - Notify affected individuals without unreasonable delay and no later than 60 days after discovery.
  - Notify HHS as required (including media notice when 500+ individuals affected).
  - Business associates must notify covered entities promptly (per contract/BAA).
- Maintain a breach response playbook with roles, timelines, and templates.

## Consent and retention
- Default retention (development): 30 days. Production retention: configurable (e.g., 180 days) and approved by compliance.
- Store raw PHI only with explicit consent; record consent_timestamp and scope of consent.
- Implement retention job for deletions with dry-run mode and audit logs; owner of retention policy should be documented.

## Testing and validation
- Unit tests for redaction rules (examples in docs/compliance/phi_inventory.md).
- Periodic validation runs on synthetic and sampled real logs to measure detection performance (false negatives flagged for review).
- Document acceptable thresholds (e.g., target recall) and remediation plan for model drift or regex failures.
- Security/test plan for key management and encryption verification.

## Risks and mitigations
- Misclassification of PHI: default to redact and require mentor/compliance review for reclassification.
- Over-collection of data: apply minimum necessary and review logging needs.
- Breach detection delays: implement monitoring/alerting and periodic audit reviews.
- Third-party risk: require BAAs and periodic vendor security reviews.

## References
- HHS Breach Notification Rule: https://www.hhs.gov/hipaa/for-professionals/breach-notification/index.html
- HIPAA security rule references: 45 CFR Part 164 (see sections on access controls and transmission security)
- NIST guidance: SP 800-111 (data at rest), SP 800-52 (TLS recommendations)

