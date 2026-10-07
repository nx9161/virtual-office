# Security Policy

## Supported versions

The `main` branch is the supported version. Security fixes land on
`main` via pull request.

## Reporting a vulnerability

**Do not open a public issue.** Instead, open a private Security
Advisory: this repo's **Security** tab → **Advisories** → **New draft
advisory**.

Include:

- A description of the vulnerability
- Steps to reproduce
- Affected files / versions
- Any suggested fix, if you have one

We aim to acknowledge reports within 72 hours.

## Scope notes

This repository is prompt definitions, procedures, and documentation
for AI agents — there is no hosted service and no executable attack
surface beyond `office/scripts/`. The standing rule applies everywhere:
**no secrets, tokens, keys, or credentials** in code, commits, issues,
or logs — ever.
