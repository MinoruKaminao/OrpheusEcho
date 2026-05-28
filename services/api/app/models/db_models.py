from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class DbSession(Base):
    __tablename__ = "sessions"

    id = Column(String(50), primary_key=True)
    user_id = Column(String(50), nullable=True)
    species = Column(String(20), nullable=False) # "dog" | "cat"
    status = Column(String(20), nullable=False, default="created") # "created" | "active" | "closed"
    country = Column(String(10), nullable=True)
    language = Column(String(15), nullable=True)
    animal_notes = Column(Text, nullable=True)
    location_text = Column(Text, nullable=True)
    latitude = Column(Numeric(9, 6), nullable=True)
    longitude = Column(Numeric(9, 6), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)
    sync_status = Column(String(20), nullable=False, default="completed")
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    trials = relationship("DbTrial", back_populates="session", cascade="all, delete-orphan")


class DbCandidate(Base):
    __tablename__ = "name_candidates"

    id = Column(String(50), primary_key=True)
    species = Column(String(20), nullable=False)
    country = Column(String(10), nullable=True)
    language = Column(String(15), nullable=True)
    display_name = Column(String(100), nullable=False)
    reading = Column(String(100), nullable=True)
    popularity_rank = Column(Integer, nullable=True)
    enabled = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class DbTrial(Base):
    __tablename__ = "trials"

    id = Column(String(50), primary_key=True)
    session_id = Column(String(50), ForeignKey("sessions.id", ondelete="CASCADE"), nullable=False)
    candidate_id = Column(String(50), ForeignKey("name_candidates.id"), nullable=False)
    playback_text = Column(String(100), nullable=False)
    voice_profile_id = Column(String(50), nullable=True)
    started_at = Column(DateTime, nullable=False)
    ended_at = Column(DateTime, nullable=True)
    manual_reaction = Column(String(50), nullable=True) # "reaction_yes" | "reaction_weak" | "reaction_no"
    computed_score = Column(Numeric(3, 2), nullable=True)
    ambient_noise_db = Column(Numeric(4, 1), nullable=True)
    note = Column(Text, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    # Relationships
    session = relationship("DbSession", back_populates="trials")
    features = relationship("DbReactionFeatures", back_populates="trial", uselist=False, cascade="all, delete-orphan")


class DbReactionFeatures(Base):
    __tablename__ = "reaction_features"

    id = Column(String(50), primary_key=True)
    trial_id = Column(String(50), ForeignKey("trials.id", ondelete="CASCADE"), nullable=False)
    head_turn_score = Column(Numeric(3, 2), nullable=False, default=0.0)
    gaze_shift_score = Column(Numeric(3, 2), nullable=False, default=0.0)
    ear_motion_score = Column(Numeric(3, 2), nullable=False, default=0.0)
    approach_score = Column(Numeric(3, 2), nullable=False, default=0.0)
    vocalization_score = Column(Numeric(3, 2), nullable=False, default=0.0)
    latency_ms = Column(Integer, nullable=True)
    repeatability_score = Column(Numeric(3, 2), nullable=False, default=0.0)
    manual_score = Column(Numeric(3, 2), nullable=True)
    model_version = Column(String(50), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    # Relationships
    trial = relationship("DbTrial", back_populates="features")


class DbKnownAnimal(Base):
    __tablename__ = "known_animals"

    id = Column(String(50), primary_key=True)
    species = Column(String(20), nullable=False) # "dog" | "cat"
    true_name = Column(String(100), nullable=False)
    aliases = Column(Text, nullable=True) # JSON serialized list of strings
    sex = Column(String(20), nullable=True) # "male" | "female" | "unknown"
    age_range = Column(String(20), nullable=True)
    breed = Column(String(100), nullable=True)
    coat_color = Column(String(100), nullable=True)
    owner_consent_status = Column(String(20), nullable=False, default="agreed") # "agreed" | "withdrawn"
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    # Relationships
    media_assets = relationship("DbMediaAsset", back_populates="known_animal", cascade="all, delete-orphan")
    training_sessions = relationship("DbTrainingSession", back_populates="known_animal", cascade="all, delete-orphan")


class DbMediaAsset(Base):
    __tablename__ = "media_assets"

    id = Column(String(50), primary_key=True)
    session_id = Column(String(50), ForeignKey("sessions.id", ondelete="CASCADE"), nullable=True)
    trial_id = Column(String(50), ForeignKey("trials.id", ondelete="SET NULL"), nullable=True)
    known_animal_id = Column(String(50), ForeignKey("known_animals.id", ondelete="CASCADE"), nullable=True)
    media_type = Column(String(20), nullable=False) # "video" | "image" | "audio"
    storage_url = Column(String(512), nullable=False)
    duration_ms = Column(Integer, nullable=True)
    consent_record_id = Column(String(50), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    # Relationships
    known_animal = relationship("DbKnownAnimal", back_populates="media_assets")
    annotations = relationship("DbImageAnnotation", back_populates="media_asset", uselist=False, cascade="all, delete-orphan")


class DbImageAnnotation(Base):
    __tablename__ = "image_annotations"

    id = Column(String(50), primary_key=True)
    media_asset_id = Column(String(50), ForeignKey("media_assets.id", ondelete="CASCADE"), nullable=False)
    pose_type = Column(String(50), nullable=True)
    image_quality = Column(String(50), nullable=True)
    annotations = Column(Text, nullable=True) # JSON serialized annotations
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    # Relationships
    media_asset = relationship("DbMediaAsset", back_populates="annotations")


class DbTrainingSession(Base):
    __tablename__ = "training_sessions"

    id = Column(String(50), primary_key=True)
    known_animal_id = Column(String(50), ForeignKey("known_animals.id", ondelete="CASCADE"), nullable=False)
    speaker_type = Column(String(50), nullable=False) # "owner" | "family" | "stranger"
    environment_type = Column(String(50), nullable=False) # "indoor" | "outdoor"
    purpose = Column(String(100), nullable=False)
    status = Column(String(20), nullable=False, default="created") # "created" | "active" | "completed"
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)

    # Relationships
    known_animal = relationship("DbKnownAnimal", back_populates="training_sessions")
    trials = relationship("DbTrainingTrial", back_populates="training_session", cascade="all, delete-orphan")


class DbTrainingTrial(Base):
    __tablename__ = "training_trials"

    id = Column(String(50), primary_key=True)
    training_session_id = Column(String(50), ForeignKey("training_sessions.id", ondelete="CASCADE"), nullable=False)
    called_name = Column(String(100), nullable=False)
    is_true_name = Column(Boolean, nullable=False)
    is_alias = Column(Boolean, nullable=False)
    modulation_type = Column(String(50), nullable=False)
    playback_source = Column(String(50), nullable=False) # "owner_live_voice" | "tts"
    manual_reaction = Column(String(50), nullable=True) # "reaction_yes" | "reaction_weak" | "reaction_no"
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    # Relationships
    training_session = relationship("DbTrainingSession", back_populates="trials")


class DbMLModel(Base):
    __tablename__ = "ml_models"

    id = Column(String(50), primary_key=True)
    version = Column(String(20), unique=True, nullable=False)
    description = Column(Text, nullable=True)
    accuracy_score = Column(Numeric(5, 4), nullable=True)
    status = Column(String(20), nullable=False, default="draft")  # "active" | "draft" | "deprecated"
    download_url = Column(String(255), nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)


class DbSyncJob(Base):
    __tablename__ = "ml_sync_jobs"

    id = Column(String(50), primary_key=True)
    job_type = Column(String(50), nullable=False)  # "export" | "sync_learning"
    status = Column(String(20), nullable=False, default="pending")  # "pending" | "running" | "completed" | "failed"
    progress = Column(Numeric(5, 2), nullable=False, default=0.0)
    result_metadata = Column(Text, nullable=True)  # JSON string
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class DbCountry(Base):
    __tablename__ = "countries"

    code = Column(String(2), primary_key=True)
    name = Column(String(100), nullable=False)
    default_language = Column(String(10), nullable=False)


class DbLanguage(Base):
    __tablename__ = "languages"

    code = Column(String(10), primary_key=True)
    name = Column(String(100), nullable=False)


class DbCountryDictionary(Base):
    __tablename__ = "country_dictionaries"

    id = Column(Integer, primary_key=True, autoincrement=True)
    country_code = Column(String(2), ForeignKey("countries.code"), nullable=False)
    language_code = Column(String(10), ForeignKey("languages.code"), nullable=False)
    species = Column(String(10), nullable=False)  # "dog" | "cat"
    name = Column(String(100), nullable=False)
    reading = Column(String(200), nullable=True)
    category = Column(String(50), nullable=False)
    popularity_rank = Column(Integer, nullable=False)


class DbTTSProfile(Base):
    __tablename__ = "tts_profiles"

    id = Column(String(50), primary_key=True)
    language_code = Column(String(10), ForeignKey("languages.code"), nullable=False)
    voice_name = Column(String(100), nullable=False)
    gender = Column(String(10), nullable=False)  # "female" | "male"
    speaking_rate = Column(Numeric, nullable=False, default=1.0)
    pitch = Column(Numeric, nullable=False, default=1.0)
    engine_type = Column(String(20), nullable=False, default="mock")


class DbJokeNameProfile(Base):
    __tablename__ = "joke_name_profiles"

    id = Column(String(50), primary_key=True)
    name = Column(String(100), nullable=False)
    type = Column(String(50), nullable=False)  # "common_name" | "nickname" | "joke_safe"
    language_code = Column(String(15), nullable=True)
    country_code = Column(String(10), nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class DbJokeSession(Base):
    __tablename__ = "joke_sessions"

    id = Column(String(50), primary_key=True)
    selected_country = Column(String(10), nullable=True)
    selected_language = Column(String(15), nullable=True)
    selected_age_band = Column(String(50), nullable=True)
    tone_type = Column(String(50), nullable=True)
    image_path = Column(String(512), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)

    # Relationships
    reactions = relationship("DbJokeReactionLog", back_populates="session", cascade="all, delete-orphan")


class DbJokeReactionLog(Base):
    __tablename__ = "joke_reaction_logs"

    id = Column(String(50), primary_key=True)
    joke_session_id = Column(String(50), ForeignKey("joke_sessions.id", ondelete="CASCADE"), nullable=False)
    joke_profile_id = Column(String(50), ForeignKey("joke_name_profiles.id", ondelete="CASCADE"), nullable=False)
    smile_score = Column(Numeric(3, 2), nullable=False, default=0.0)
    laugh_score = Column(Numeric(3, 2), nullable=False, default=0.0)
    manual_reaction = Column(String(50), nullable=True)  # "reaction_yes" | "reaction_no" | "reaction_meh"
    composite_score = Column(Numeric(3, 2), nullable=False, default=0.0)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    # Relationships
    session = relationship("DbJokeSession", back_populates="reactions")
    profile = relationship("DbJokeNameProfile")


