# AGENTS.md

## Project

迷い犬・迷い猫の推定呼称探索支援アプリ。
保護された犬・猫に対して一般的な名前候補を音声再生し、反応ログを記録・解析して、有力な呼称候補の絞り込みを支援する。

本システムは名前の確定を保証しない。UI文言では必ず「推定」「有力候補」「参考スコア」「反応が強かった候補」を使用し、「特定」「確定」「正解」は避ける。

## Development Environment

- Primary IDE / Agent environment: Antigravity
- Primary AI agent model family: Gemini
- Primary mobile target: iPhone / mobile phone
- Preferred mobile implementation: SwiftUI first
- Backend: API service + PostgreSQL + object storage + async workers
- ML: rule-based MVP first, model-assisted scoring later

## Global Rules for All Agents

1. Contract First: API, DB, UI state, and data model contracts must be written before implementation.
2. Mobile First: All UX decisions must be validated for phone-size operation.
3. Apple HIG First: Prefer standard Apple navigation, controls, permissions, feedback, and accessibility.
4. One Screen, One Primary Purpose: Do not overload exploration screens.
5. State Complete: normal, loading, empty, error, permission denied, offline, sync pending, success states are mandatory.
6. Offline Capable: exploration sessions must be recordable without network access.
7. Privacy by Default: video, audio, location, and owner data require explicit consent and limited retention.
8. Explain Uncertainty: scoring and ranking must communicate uncertainty.
9. No Unsafe Attribute Guessing: joke or human-facing features must not infer real identity, nationality, ethnicity, gender, or other sensitive attributes.
10. Small PRs: each agent should produce narrow, reviewable changes.

## Agent Roles

### Product Agent
Owns product scope, PRD, MVP definition, phase roadmap, acceptance criteria, terminology.

### UI/UX Agent
Owns Apple HIG compliant mobile interface, screen specifications, state design, accessibility, and UI review.

### Mobile Agent
Owns SwiftUI app, AVFoundation audio playback, camera preview, local DB, offline queue, mobile state management.

### Backend Agent
Owns API implementation, auth, session CRUD, name dictionary APIs, media upload, sync endpoints.

### Data Agent
Owns PostgreSQL schema, migrations, data dictionary, object storage layout, retention policies.

### AI/ML Agent
Owns scoring interface, rule-based scoring, feature schema, training data format, model evaluation.

### TTS/Audio Agent
Owns TTS profile, candidate pronunciation, replay control, voice modulation, audio timing logs.

### Sync Agent
Owns offline session persistence, sync queue, retry, conflict handling, idempotency.

### Security Agent
Owns permissions, consent, privacy review, encryption, masking, safe sharing, audit logs.

### QA Agent
Owns unit, UI, integration, offline, permission, and scenario tests.

### DevOps Agent
Owns repository structure, CI/CD, environments, secrets, deployment, observability.

## Required Workflow

```text
1. Product Agent defines issue and acceptance criteria
2. Data Agent defines data contract
3. Backend Agent defines API contract
4. UI/UX Agent defines screen and state contract
5. Mobile Agent implements against mock API
6. Backend Agent implements real API
7. AI/ML Agent integrates scoring interface
8. Sync Agent validates offline behavior
9. Security Agent reviews permissions and data handling
10. QA Agent validates acceptance criteria
11. Integrator Agent reviews cross-agent consistency
```

## UI Instruction

Before proposing, generating, or revising UI, read:

- `docs/ui/mobile-ui-policy.md`
- `docs/ui/screen-specifications.md`
- `docs/ui/ui-review-checklist.md`

Mandatory UI output headings:

- Purpose
- Apple HIG Basis
- NeXT / OPENSTEP / GNUstep Influence
- Layout Description
- Interaction Behavior
- Visual Styling Notes
- Accessibility Notes
- Implementation Considerations
- Self-Check Result

If Apple HIG and NeXT / OPENSTEP / GNUstep inspired visual direction conflict, preserve Apple usability, accessibility, and platform behavior first.

## Completion Definition

A feature is not complete unless it includes:

- implementation
- state handling
- accessibility notes or implementation
- error handling
- offline behavior where applicable
- tests
- documentation update
- security/privacy review when media, location, or personal data is involved
