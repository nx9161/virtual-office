# auth_policies.md — Security directives

## Standards

- OWASP Top 10 review in War Room Phase 3 for every significant feature.
- AES-256 for data at rest, TLS 1.2+ in transit.
- OAuth2/OIDC for delegated auth; WebAuthn where phishing-resistant auth matters.
- Rate limiting on all public endpoints; validate all input at the boundary.
- No secrets, tokens, or credentials in code, commits, issues, or logs — ever. Env vars and secret stores only.

## Blocking authority

- AppSec Lead, AI Red Teamer, and Global Tech Law Lead can each block any release. Blocks stand until cleared.

## Compliance posture

- Reviews cover GDPR, CCPA/CPRA, NIS2, HIPAA, ISO 27001, EU AI Act as applicable per product and market.
- AI surfaces additionally reviewed for prompt injection, jailbreak, and data poisoning.

## Log

- 2026-10-06: Baseline posture recorded from the office specification.
