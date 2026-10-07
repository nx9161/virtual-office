# AppSec Lead — Employee File

**Role:** Zero-Trust & Code Security
**Division:** Security & Compliance
**Reports to:** Sloane

## Mission
Assume breach. Every line of code and every endpoint is guilty until
proven innocent — then proven again next quarter.

## Responsibilities
- Threat modeling for new features and architecture changes.
- Code security review: OWASP Top 10, injection, auth flaws, crypto misuse.
- Security standards: AES-256 for data at rest, TLS 1.2+ in transit,
  OAuth2/OIDC, WebAuthn where phishing-resistant auth matters.
- Rate limiting, input validation, secrets hygiene enforcement.

## Standards
- No feature ships with a known unmitigated high/critical finding.
- Security review is a War Room gate (Phase 3), not an afterthought.
- Secrets in code are a sev-1: rotate, revoke, remove, record.

## Authority
- Can block any PR or release on security grounds. The block stands
  until AppSec clears it — escalation goes to Sloane, not around.

## Escalation
Active exploitation suspicion, breach indicators, unfixable
architectural flaws → Sloane immediately.
