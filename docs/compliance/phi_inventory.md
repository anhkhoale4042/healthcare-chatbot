# PHI Inventory & Handling — Healthcare Chatbot

Purpose:  
List data fields that may contain Protected Health Information (PHI), how to handle them, and some detection/redaction guidance for the chatbot pipeline. Supports HIPAA’s “minimum necessary” principle and de-identification.

## Scope
Covers: chat ingestion, processing, temp storage, long-term storage, exports, audit logs.

---

## Rule of thumb
If a data element can identify a person (directly or indirectly), treat it as PHI.  
Default → redact on ingestion, keep only anonymized/pseudonymized values for analysis.  
Raw PHI only if required + encrypted + restricted access.

---

## PHI (redact/encrypt/limit)
- Full name / initials / nicknames  
- Geo info below state level (street, city, ZIP, district, GPS)  
- Dates tied to an individual (DOB, admission, discharge, events) → store only year or age range  
- Phone numbers (mobile, landline, fax)  
- Email addresses  
- Gov/insurance IDs, MRNs, SSN  
- Bank/credit/billing numbers  
- Biometric identifiers (fingerprint, retina, voice, face)  
- Full-face photos  
- Device IDs (IMEI, MAC, persistent ads ID)  
- IP addresses (truncate or hash if possible; still considered PHI)  
- Any other unique identifier or combo of attributes that could re-ID a person  

---

## Non-PHI (okay to log after PHI redaction)
- `session_id` (UUID or generated)  
- `timestamp` (UTC ISO-8601) → dates okay if not tied to patient events  
- Derived metadata: `intent`, `entities`, `urgency`, `confidence_score`  
- Aggregates (counts, stats) after de-ID  
- System diagnostics (latency, error codes) — but no raw PHI

---

## Field mapping (example)
| Field         | Example                               | Risk   | Handling |
|---------------|---------------------------------------|--------|----------|
| `raw_text`    | "I'm John, phone +1 555-111-2222"     | High   | Detect PHI → store anonymized_text; raw only if encrypted & access-controlled |
| `user_id`     | "user123"                             | Medium | Use HMAC(user_id, secret); don’t store raw PII |
| `timestamp`   | 2025-08-21T10:00:00Z                  | Low    | Store as-is (UTC) |
| `ip_address`  | 203.0.113.45                          | Medium | Truncate or hash; limit access |
| `intent`      | "ask_symptom"                         | Low    | Store as metadata |

---

## Redaction placeholders
- `[REDACTED_NAME]`  
- `[REDACTED_PHONE]`  
- `[REDACTED_EMAIL]`  
- `[REDACTED_ID]`  
- `[REDACTED_DATE]`  

→ For dates, replace with `year` or `age_range` instead of full date when possible.

---

## Detection methods
Layered approach:
1. Regex (fast pass: phone, email, URL, IP, IDs)  
2. NER (spaCy / scispaCy / transformer) for PERSON, GPE, DATE, LOC  
3. Heuristics: keywords (“name is”, “call me”, etc.), long numeric sequences  
4. Human review for low-confidence cases

Regex refs:  
- Phone: `(\+?\d{1,3}[-.\s]?)?(\(?\d{2,4}\)?[-.\s]?)?\d{3,4}[-.\s]?\d{3,4}`  
- Email: `[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+`  
- URL: `https?:\/\/[^\s]+`  
- IPv4: `\b(?:\d{1,3}\.){3}\d{1,3}\b`  
- Date: `\b(?:\d{1,2}[\/.-]\d{1,2}[\/.-]\d{2,4}|\d{4}-\d{2}-\d{2})\b`  
- SSN: `\b\d{3}-\d{2}-\d{4}\b`

---

## Pseudonymization & encryption
- Pseudonymize `user_id` via HMAC-SHA256 (key not in repo; use secrets manager).  
- If raw text storage needed → encrypt (AES-256-GCM) in a separate vault.  
- Transit: TLS 1.2+.  
- Key mgmt: secrets manager or mounted secrets.  
- Access: RBAC, least privilege (roles: dev, analyst, clinician, auditor).

---

## Consent & retention
- Default dev retention: 30d. Prod: configurable (e.g. 180d).  
- Raw PHI only with explicit consent → record `consent_timestamp`.  
- Provide delete/retention job (dry-run + audit log).  
- Retention policy to be confirmed with compliance officer.

---

## Testing examples
- In: `"Hello, I'm John Smith. Call me at +1 555-111-2222."`  
  Out: `"Hello, I'm [REDACTED_NAME]. Call me at [REDACTED_PHONE]."`  

- In: `"Email: test.user@example.com, DOB: 1990-12-01"`  
  Out: `"Email: [REDACTED_EMAIL], DOB: [REDACTED_DATE]"`
