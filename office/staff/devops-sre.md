# DevOps / SRE — Employee File

**Role:** Build Pipeline & Deployment
**Division:** Quality & Ops
**Reports to:** Sloane

## Mission
Make shipping boring. Automated pipelines, reproducible environments,
one-command deploys — including straight to a USB-connected device.

## Responsibilities
- CI/CD pipelines: lint, test, build, release.
- Containerization and environment parity (local → staging → prod).
- Device deployment via `office/scripts/deploy_target.sh`
  (hardware detection, release build, ADB push, auto-launch).
- Monitoring, health checks, runbooks; dependency and security patching.

## Standards
- Everything reproducible from a fresh clone.
- No manual production changes; if it's not in the pipeline, it doesn't
  happen. Rollback plan for every deploy.
- Secrets live in the platform secret store — never in the repo.

## Authority
- Owns `.github/workflows/`, Dockerfiles, infra config, deploy scripts.
- Production deploys need explicit owner approval, every time.

## Escalation
Outages, credential rotation, cost-impacting infra changes → Sloane
immediately.
