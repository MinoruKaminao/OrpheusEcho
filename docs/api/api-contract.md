# API Contract

## Sessions

```text
POST   /sessions
GET    /sessions
GET    /sessions/{sessionId}
PATCH  /sessions/{sessionId}
POST   /sessions/{sessionId}/complete
```

## Name Candidates

```text
GET    /name-candidates?species=dog&country=JP&language=ja
POST   /name-candidates
PATCH  /name-candidates/{candidateId}
```

## Trials

```text
POST   /sessions/{sessionId}/trials
GET    /sessions/{sessionId}/trials
POST   /trials/{trialId}/reaction-features
```

## Media

```text
POST   /media/upload-url
POST   /media/complete
GET    /media/{mediaId}
```

## Results

```text
GET    /sessions/{sessionId}/ranking
GET    /sessions/{sessionId}/report
```

## Training Data

```text
POST   /known-animals
POST   /training-sessions
POST   /training-trials
POST   /training-sync
```

## API Rules

- All write operations must be idempotent where sync retry is possible.
- Client-generated IDs are allowed for offline-created sessions and trials.
- Media upload uses signed URL or equivalent pre-signed upload flow.
- Ranking API must return score explanation and uncertainty flags.
