# System Architecture

## Overview

```text
Mobile App
  ├─ Session UI
  ├─ Camera Preview
  ├─ Audio Playback / TTS
  ├─ Manual Reaction Input
  ├─ Local DB
  └─ Sync Queue

Backend API
  ├─ Auth
  ├─ Sessions
  ├─ Name Candidates
  ├─ Trials
  ├─ Media Upload
  ├─ Reports
  └─ Model Version API

Data Layer
  ├─ PostgreSQL
  ├─ Object Storage
  ├─ Queue
  └─ Model Registry

AI / ML
  ├─ Rule-based Scoring
  ├─ Feature Extraction
  ├─ Training Dataset Builder
  ├─ Batch Training
  └─ Model Distribution
```

## Design Principles

- Mobile offline first
- API contract first
- Media upload separated from structured logs
- ML pipeline separated from exploration workflow
- Explicit consent for video, audio, location, and training data
