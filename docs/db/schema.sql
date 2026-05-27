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

-- 2. Known Animals
CREATE TABLE known_animals (
    id VARCHAR(50) PRIMARY KEY,
    species species_type NOT NULL,
    true_name VARCHAR(100) NOT NULL,
    aliases TEXT, -- JSON serialized list of strings
    sex VARCHAR(20), -- 'male' | 'female' | 'unknown'
    age_range VARCHAR(20),
    breed VARCHAR(100),
    coat_color VARCHAR(100),
    owner_consent_status consent_status_type NOT NULL DEFAULT 'agreed',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 3. Sessions
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

-- 4. Name Candidates
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

-- 5. Name Variants (Nickname variations)
CREATE TABLE name_variants (
    id VARCHAR(50) PRIMARY KEY,
    candidate_id VARCHAR(50) REFERENCES name_candidates(id) ON DELETE CASCADE,
    variant_name VARCHAR(100) NOT NULL,
    variant_type VARCHAR(50) NOT NULL, -- 'nickname', 'stretched' 等
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 6. Trials
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

-- 7. Media Assets (Photos/Videos/Audio)
CREATE TABLE media_assets (
    id VARCHAR(50) PRIMARY KEY,
    session_id VARCHAR(50) REFERENCES sessions(id) ON DELETE CASCADE,
    trial_id VARCHAR(50) REFERENCES trials(id) ON DELETE SET NULL,
    known_animal_id VARCHAR(50) REFERENCES known_animals(id) ON DELETE CASCADE,
    media_type VARCHAR(20) NOT NULL, -- 'video', 'image', 'audio'
    storage_url VARCHAR(512) NOT NULL,
    duration_ms INT,
    consent_record_id VARCHAR(50) REFERENCES consent_records(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 8. Reaction Features (AI Inference Raw Features)
CREATE TABLE reaction_features (
    id VARCHAR(50) PRIMARY KEY,
    trial_id VARCHAR(50) REFERENCES trials(id) ON DELETE CASCADE NOT NULL,
    head_turn_score NUMERIC(3, 2) NOT NULL DEFAULT 0.0,
    gaze_shift_score NUMERIC(3, 2) NOT NULL DEFAULT 0.0,
    ear_motion_score NUMERIC(3, 2) NOT NULL DEFAULT 0.0,
    approach_score NUMERIC(3, 2) NOT NULL DEFAULT 0.0,
    vocalization_score NUMERIC(3, 2) NOT NULL DEFAULT 0.0,
    latency_ms INT,
    repeatability_score NUMERIC(3, 2) NOT NULL DEFAULT 0.0,
    manual_score NUMERIC(3, 2),
    model_version VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 9. Sync Jobs
CREATE TABLE sync_jobs (
    id VARCHAR(50) PRIMARY KEY,
    client_session_id VARCHAR(50) NOT NULL,
    status sync_status_type NOT NULL DEFAULT 'pending',
    attempts INT NOT NULL DEFAULT 0,
    last_error TEXT,
    synced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 10. Image Annotations
CREATE TABLE image_annotations (
    id VARCHAR(50) PRIMARY KEY,
    media_asset_id VARCHAR(50) REFERENCES media_assets(id) ON DELETE CASCADE NOT NULL,
    pose_type VARCHAR(50),
    image_quality VARCHAR(50),
    annotations TEXT, -- JSON string representing bounding boxes or landmark points
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 11. Training Sessions
CREATE TABLE training_sessions (
    id VARCHAR(50) PRIMARY KEY,
    known_animal_id VARCHAR(50) REFERENCES known_animals(id) ON DELETE CASCADE NOT NULL,
    speaker_type VARCHAR(50) NOT NULL, -- 'owner' | 'family' | 'stranger' 等
    environment_type VARCHAR(50) NOT NULL, -- 'indoor' | 'outdoor' 等
    purpose VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'created', -- 'created' | 'active' | 'completed'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 12. Training Trials
CREATE TABLE training_trials (
    id VARCHAR(50) PRIMARY KEY,
    training_session_id VARCHAR(50) REFERENCES training_sessions(id) ON DELETE CASCADE NOT NULL,
    called_name VARCHAR(100) NOT NULL,
    is_true_name BOOLEAN NOT NULL,
    is_alias BOOLEAN NOT NULL,
    modulation_type VARCHAR(50) NOT NULL,
    playback_source VARCHAR(50) NOT NULL, -- 'owner_live_voice' | 'tts' 等
    manual_reaction VARCHAR(50), -- 'reaction_yes' | 'reaction_weak' | 'reaction_no'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 13. ML Models Registry
CREATE TABLE ml_models (
    id VARCHAR(50) PRIMARY KEY,
    version VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    accuracy_score NUMERIC(5, 4),
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    download_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 14. ML Sync & Training Jobs
CREATE TABLE ml_sync_jobs (
    id VARCHAR(50) PRIMARY KEY,
    job_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    progress NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    result_metadata TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 15. Countries
CREATE TABLE countries (
    code VARCHAR(2) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    default_language VARCHAR(10) NOT NULL
);

-- 16. Languages
CREATE TABLE languages (
    code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- 17. Country Dictionaries
CREATE TABLE country_dictionaries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_code VARCHAR(2) NOT NULL,
    language_code VARCHAR(10) NOT NULL,
    species VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    reading VARCHAR(200),
    category VARCHAR(50) NOT NULL,
    popularity_rank INTEGER NOT NULL,
    FOREIGN KEY(country_code) REFERENCES countries(code),
    FOREIGN KEY(language_code) REFERENCES languages(code)
);

-- 18. TTS Profiles
CREATE TABLE tts_profiles (
    id VARCHAR(50) PRIMARY KEY,
    language_code VARCHAR(10) NOT NULL,
    voice_name VARCHAR(100) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    speaking_rate REAL NOT NULL DEFAULT 1.0,
    pitch REAL NOT NULL DEFAULT 1.0,
    engine_type VARCHAR(20) NOT NULL DEFAULT 'mock',
    FOREIGN KEY(language_code) REFERENCES languages(code)
);

-- Seed Data for Localization
INSERT INTO countries (code, name, default_language) VALUES ('JP', '日本', 'ja-JP');
INSERT INTO countries (code, name, default_language) VALUES ('US', 'United States', 'en-US');
INSERT INTO countries (code, name, default_language) VALUES ('GB', 'United Kingdom', 'en-GB');

INSERT INTO languages (code, name) VALUES ('ja-JP', '日本語');
INSERT INTO languages (code, name) VALUES ('en-US', 'English (US)');
INSERT INTO languages (code, name) VALUES ('en-GB', 'English (UK)');

-- Japan Seeds (Dog)
INSERT INTO country_dictionaries (country_code, language_code, species, name, reading, category, popularity_rank) VALUES ('JP', 'ja-JP', 'dog', 'モモ', 'モモ', 'popular', 1);
INSERT INTO country_dictionaries (country_code, language_code, species, name, reading, category, popularity_rank) VALUES ('JP', 'ja-JP', 'dog', 'モカ', 'モカ', 'popular', 2);
INSERT INTO country_dictionaries (country_code, language_code, species, name, reading, category, popularity_rank) VALUES ('JP', 'ja-JP', 'dog', 'ココ', 'ココ', 'popular', 3);
-- Japan Seeds (Cat)
INSERT INTO country_dictionaries (country_code, language_code, species, name, reading, category, popularity_rank) VALUES ('JP', 'ja-JP', 'cat', 'タマ', 'タマ', 'popular', 1);
INSERT INTO country_dictionaries (country_code, language_code, species, name, reading, category, popularity_rank) VALUES ('JP', 'ja-JP', 'cat', 'ミーコ', 'ミーコ', 'popular', 2);

-- US Seeds (Dog)
INSERT INTO country_dictionaries (country_code, language_code, species, name, reading, category, popularity_rank) VALUES ('US', 'en-US', 'dog', 'Max', 'mæks', 'popular', 1);
INSERT INTO country_dictionaries (country_code, language_code, species, name, reading, category, popularity_rank) VALUES ('US', 'en-US', 'dog', 'Bella', 'ˈbɛlə', 'popular', 2);
INSERT INTO country_dictionaries (country_code, language_code, species, name, reading, category, popularity_rank) VALUES ('US', 'en-US', 'dog', 'Charlie', 'ˈtʃɑːrli', 'popular', 3);
-- US Seeds (Cat)
INSERT INTO country_dictionaries (country_code, language_code, species, name, reading, category, popularity_rank) VALUES ('US', 'en-US', 'cat', 'Luna', 'ˈluːnə', 'popular', 1);
INSERT INTO country_dictionaries (country_code, language_code, species, name, reading, category, popularity_rank) VALUES ('US', 'en-US', 'cat', 'Oliver', 'ˈɒlɪvər', 'popular', 2);

-- TTS Profiles
INSERT INTO tts_profiles (id, language_code, voice_name, gender, speaking_rate, pitch, engine_type) VALUES ('tts_jp_female', 'ja-JP', 'Kyoko', 'female', 1.0, 1.0, 'mock');
INSERT INTO tts_profiles (id, language_code, voice_name, gender, speaking_rate, pitch, engine_type) VALUES ('tts_jp_male', 'ja-JP', 'Otoya', 'male', 1.0, 1.0, 'mock');
INSERT INTO tts_profiles (id, language_code, voice_name, gender, speaking_rate, pitch, engine_type) VALUES ('tts_en_female', 'en-US', 'Samantha', 'female', 1.0, 1.0, 'mock');
INSERT INTO tts_profiles (id, language_code, voice_name, gender, speaking_rate, pitch, engine_type) VALUES ('tts_en_male', 'en-US', 'Daniel', 'male', 1.0, 1.0, 'mock');


