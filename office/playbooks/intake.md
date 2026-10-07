# Playbook: intake

How the office receives and routes work in any modality. Sloane (or the
triage worker) runs this on every incoming request.

## Pipeline
```
[ Raw prompt ] → [ Prompt Writer: perfect ] → [ Intake parse ] → [ War Room or ship-feature ] → [ Deploy ]
```
Every agent downstream works from the perfected prompt, never the raw
one. The Prompt Writer also owns the closed loop: it verifies each
deliverable against the acceptance criteria and retries (max 3, each
retry changing something) before escalating to Sloane.

## 1. Text (chat messages, GitHub issues)
- Parse intent: what is wanted, constraints, deadline signals.
- Well-defined + small → `ship-feature` procedure.
- Significant / production-bound → `war-room` procedure.
- Ambiguous → ask the owner one sharp clarifying question, then route.

## 2. Images (wireframe screenshots, mockups, photos of whiteboards)
- Attach the image to a GitHub issue for the record.
- Spawn Product Owner + UI/UX Designer to interpret: extract screens,
  flows, components, and open questions.
- Continue as text intake with the interpretation attached.

## 3. Audio (voice notes)
- Transcribe with the office's available transcription tooling.
- Treat the transcript as text intake. Keep the original audio linked
  in the issue.
- If transcription is unavailable, ask the owner for a text summary
  rather than guessing.

## 4. Hardware deploy requests
Phrases like "put it on my phone" route to DevOps/SRE, who runs
`office/scripts/deploy_target.sh` after a successful release build.

## Intake record
Every intake creates or links a GitHub issue and a palace room entry
(`halls/events.md`) — the office never works from chat context alone.
