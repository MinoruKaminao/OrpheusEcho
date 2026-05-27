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
    approach_score = Column(Numeric(3, 2), nullable=False, default=0.0)
    vocalization_score = Column(Numeric(3, 2), nullable=False, default=0.0)
    latency_ms = Column(Integer, nullable=True)
    repeatability_score = Column(Numeric(3, 2), nullable=False, default=0.0)
    manual_score = Column(Numeric(3, 2), nullable=True)
    model_version = Column(String(50), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    # Relationships
    trial = relationship("DbTrial", back_populates="features")
