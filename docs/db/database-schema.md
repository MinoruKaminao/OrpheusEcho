# Database Schema

## MVP Tables

```text
sessions
name_candidates
name_variants
trials
reaction_features
media_assets
sync_jobs
consent_records
```

## Later Tables

```text
users
known_animals
owner_profiles
training_sessions
training_trials
image_annotations
country_name_dictionaries
tts_profiles
model_versions
```

## sessions

- id
- user_id
- species
- status
- country
- language
- animal_notes
- location_text
- created_at
- completed_at
- sync_status

## name_candidates

- id
- species
- country
- language
- display_name
- reading
- popularity_rank
- enabled

## trials

- id
- session_id
- candidate_id
- playback_text
- voice_profile_id
- started_at
- ended_at
- manual_reaction
- computed_score
- note

## reaction_features

- id
- trial_id
- head_turn_score
- gaze_shift_score
- approach_score
- vocalization_score
- latency_ms
- repeatability_score
- manual_score
- model_version

## media_assets

- id
- session_id
- trial_id
- media_type
- storage_url
- duration_ms
- consent_record_id
- created_at
