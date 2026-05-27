-- OrpheusEcho Database Schema DDL (PostgreSQL)
-- Conforms to docs/db/database-schema.md

-- Enums
CREATE TYPE species_type AS ENUM ('dog', 'cat');
CREATE TYPE session_status AS ENUM ('created', 'active', 'closed');
CREATE TYPE sync_status_type AS ENUM ('pending', 'completed', 'failed');
CREATE TYPE consent_status_type AS ENUM ('agreed', 'withdrawn');
CREATE TYPE reaction_flag AS ENUM ('reaction_yes', 'reaction_weak', 'reaction_no');

-- 1. Consent Records
CREATE TABLE consent_records (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    consent_type VARCHAR(50) NOT NULL, -- 'recording', 'location', 'training_use' 等
    status consent_status_type NOT NULL DEFAULT 'agreed',
    signed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    withdrawn_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 2. Sessions
CREATE TABLE sessions (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50),
    species species_type NOT NULL,
    status session_status NOT NULL DEFAULT 'created',
    country VARCHAR(10),
    language VARCHAR(15),
    animal_notes TEXT,
    location_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    sync_status sync_status_type NOT NULL DEFAULT 'completed',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 3. Name Candidates
CREATE TABLE name_candidates (
    id VARCHAR(50) PRIMARY KEY,
    species species_type NOT NULL,
    country VARCHAR(10),
    language VARCHAR(15),
    display_name VARCHAR(100) NOT NULL,
    reading VARCHAR(100),
    popularity_rank INT,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 4. Name Variants (Nickname variations)
CREATE TABLE name_variants (
    id VARCHAR(50) PRIMARY KEY,
    candidate_id VARCHAR(50) REFERENCES name_candidates(id) ON DELETE CASCADE,
    variant_name VARCHAR(100) NOT NULL,
    variant_type VARCHAR(50) NOT NULL, -- 'nickname', 'stretched' 等
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 5. Trials
CREATE TABLE trials (
    id VARCHAR(50) PRIMARY KEY,
    session_id VARCHAR(50) REFERENCES sessions(id) ON DELETE CASCADE NOT NULL,
    candidate_id VARCHAR(50) REFERENCES name_candidates(id) NOT NULL,
    playback_text VARCHAR(100) NOT NULL,
    voice_profile_id VARCHAR(50),
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE,
    manual_reaction reaction_flag,
    computed_score NUMERIC(3, 2), -- 0.00 〜 0.99
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 6. Reaction Features (AI Inference Raw Features)
CREATE TABLE reaction_features (
    id VARCHAR(50) PRIMARY KEY,
    trial_id VARCHAR(50) REFERENCES trials(id) ON DELETE CASCADE NOT NULL,
    head_turn_score NUMERIC(3, 2) NOT NULL DEFAULT 0.0,
    gaze_shift_score NUMERIC(3, 2) NOT NULL DEFAULT 0.0,
    approach_score NUMERIC(3, 2) NOT NULL DEFAULT 0.0,
    vocalization_score NUMERIC(3, 2) NOT NULL DEFAULT 0.0,
    latency_ms INT,
    repeatability_score NUMERIC(3, 2) NOT NULL DEFAULT 0.0,
    manual_score NUMERIC(3, 2),
    model_version VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 7. Media Assets (Photos/Videos/Audio)
CREATE TABLE media_assets (
    id VARCHAR(50) PRIMARY KEY,
    session_id VARCHAR(50) REFERENCES sessions(id) ON DELETE CASCADE,
    trial_id VARCHAR(50) REFERENCES trials(id) ON DELETE SET NULL,
    media_type VARCHAR(20) NOT NULL, -- 'video', 'image', 'audio'
    storage_url VARCHAR(512) NOT NULL,
    duration_ms INT,
    consent_record_id VARCHAR(50) REFERENCES consent_records(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 8. Sync Jobs
CREATE TABLE sync_jobs (
    id VARCHAR(50) PRIMARY KEY,
    client_session_id VARCHAR(50) NOT NULL,
    status sync_status_type NOT NULL DEFAULT 'pending',
    attempts INT NOT NULL DEFAULT 0,
    last_error TEXT,
    synced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);
