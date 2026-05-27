from typing import Generator

from fastapi import Depends
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.repositories.db_repositories import CandidateRepository, SessionRepository, TrialRepository
from app.repositories.known_animal_repository import KnownAnimalRepository
from app.repositories.training_repository import TrainingRepository
from app.services.candidate_service import CandidateService
from app.services.known_animal_service import KnownAnimalService
from app.services.ranking_service import RankingService
from app.services.result_service import ResultService
from app.services.session_service import SessionService
from app.services.trial_service import TrialService
from app.services.training_service import TrainingService


# DBセッションのライフサイクル管理
def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_session_service(db: Session = Depends(get_db)) -> SessionService:
    repo = SessionRepository(db)
    return SessionService(repo)


def get_candidate_service(db: Session = Depends(get_db)) -> CandidateService:
    repo = CandidateRepository(db)
    return CandidateService(repo)


def get_trial_service(db: Session = Depends(get_db)) -> TrialService:
    repo = TrialRepository(db)
    return TrialService(repo)


# 依存関係として機能するランキング用/結果用リポジトリおよびサービスの組み立て
def get_ranking_service(db: Session = Depends(get_db)) -> RankingService:
    # ランキング計算のロジックをSQLAlchemy経由で行うため、仮モックストアの代わりに直接DBを注入できるようにするか、
    # あるいはDB専用のRankingService（SQLクエリベース）へ移行するための仕組み。
    # 簡易的に、既存のRankingServiceが求めるstoreインターフェイスに近い一時的なDB参照アダプタを用意
    class DbStoreAdapter:
        def __init__(self, db: Session) -> None:
            self.db = db
            
            # 既存のRankingServiceが .sessions / .trials / .features / .candidates を辞書参照するため、
            # SQLAlchemyモデルオブジェクトを適切に読み出すプロパティを追加
            from app.models.entities import Session as EntSession, Trial as EntTrial, Candidate as EntCand, ReactionFeatures as EntFeatures
            from app.models.db_models import DbSession, DbTrial, DbCandidate, DbReactionFeatures

        @property
        def sessions(self) -> dict:
            from app.models.db_models import DbSession
            from app.models.entities import Session as EntSession
            # IDによる疑似的なキー引き用ラッパー
            class SessionMap:
                def __init__(self, db: Session) -> None:
                    self.db = db
                def __contains__(self, key: object) -> bool:
                    return self.db.query(DbSession).filter(DbSession.id == str(key)).first() is not None
                def get(self, key: object) -> EntSession | None:
                    row = self.db.query(DbSession).filter(DbSession.id == str(key)).first()
                    if not row:
                        return None
                    temp_id = None
                    coat = None
                    age = None
                    notes = row.animal_notes

                    if row.animal_notes:
                        parts = row.animal_notes.split(" | ")
                        notes_parts = []
                        for part in parts:
                            if part.startswith("TempID: "):
                                temp_id = part.replace("TempID: ", "")
                            elif part.startswith("Coat: "):
                                coat = part.replace("Coat: ", "")
                            elif part.startswith("Age: "):
                                age = part.replace("Age: ", "")
                            else:
                                notes_parts.append(part)
                        notes = " | ".join(notes_parts) if notes_parts else None

                    return EntSession(
                        session_id=row.id,
                        species=row.species,
                        temp_animal_id=temp_id,
                        location_text=row.location_text,
                        coat_color=coat,
                        age_hint=age,
                        country_code=row.country,
                        language_code=row.language,
                        multi_country_mode=False,
                        notes=notes,
                        status=row.status,
                        created_at=row.created_at,
                        updated_at=row.updated_at
                    )
            return SessionMap(self.db)

        @property
        def trials(self) -> dict:
            from app.models.db_models import DbTrial
            from app.models.entities import Trial
            rows = self.db.query(DbTrial).all()
            return {
                t.id: Trial(
                    trial_id=t.id,
                    session_id=t.session_id,
                    candidate_id=t.candidate_id,
                    variant_text=t.playback_text,
                    voice_type=t.voice_profile_id or "",
                    modulation_type="unknown",
                    played_at=t.started_at,
                    manual_flag=t.manual_reaction
                ) for t in rows
            }

        @property
        def features(self) -> dict:
            from app.models.db_models import DbReactionFeatures
            from app.models.entities import ReactionFeatures
            rows = self.db.query(DbReactionFeatures).all()
            return {
                f.trial_id: ReactionFeatures(
                    trial_id=f.trial_id,
                    gaze_shift_score=float(f.gaze_shift_score),
                    ear_motion_score=float(f.ear_motion_score),
                    head_turn_score=float(f.head_turn_score),
                    posture_change_score=0.0,
                    approach_score=float(f.approach_score),
                    vocalization_score=float(f.vocalization_score),
                    repeatability_score=float(f.repeatability_score),
                    latency_ms=f.latency_ms,
                    manual_score=float(f.manual_score) if f.manual_score is not None else None,
                    model_version=f.model_version
                ) for f in rows
            }

        @property
        def candidates(self) -> dict:
            from app.models.db_models import DbCandidate
            from app.models.entities import Candidate
            rows = self.db.query(DbCandidate).filter(DbCandidate.enabled == True).all()
            return {
                c.id: Candidate(
                    candidate_id=c.id,
                    name=c.display_name,
                    species=c.species,
                    country_code=c.country,
                    language_code=c.language,
                    active=c.enabled
                ) for c in rows
            }

    adapter = DbStoreAdapter(db)
    return RankingService(adapter)


def get_result_service(db: Session = Depends(get_db)) -> ResultService:
    # 既存のResultServiceは内部で store と RankingService(store) を組み立てているため、
    # 同様のアダプタを注入する。
    class DbStoreAdapter:
        def __init__(self, db: Session) -> None:
            self.db = db
        
        @property
        def sessions(self) -> dict:
            from app.models.db_models import DbSession
            from app.models.entities import Session as EntSession
            
            class SessionMap:
                def __init__(self, db: Session) -> None:
                    self.db = db
                def __contains__(self, key: object) -> bool:
                    return self.db.query(DbSession).filter(DbSession.id == str(key)).first() is not None
                def get(self, key: object) -> object:
                    row = self.db.query(DbSession).filter(DbSession.id == str(key)).first()
                    if not row:
                        return None
                    
                    # メモのパース (db_repositories と同様に notes, coat, age, temp_id をパース)
                    temp_id = None
                    coat = None
                    age = None
                    notes = row.animal_notes

                    if row.animal_notes:
                        parts = row.animal_notes.split(" | ")
                        notes_parts = []
                        for part in parts:
                            if part.startswith("TempID: "):
                                temp_id = part.replace("TempID: ", "")
                            elif part.startswith("Coat: "):
                                coat = part.replace("Coat: ", "")
                            elif part.startswith("Age: "):
                                age = part.replace("Age: ", "")
                            else:
                                notes_parts.append(part)
                        notes = " | ".join(notes_parts) if notes_parts else None

                    return EntSession(
                        session_id=row.id,
                        species=row.species,
                        temp_animal_id=temp_id,
                        location_text=row.location_text,
                        coat_color=coat,
                        age_hint=age,
                        country_code=row.country,
                        language_code=row.language,
                        multi_country_mode=False,
                        notes=notes,
                        status=row.status,
                        created_at=row.created_at,
                        updated_at=row.updated_at
                    )
            return SessionMap(self.db)

        @property
        def trials(self) -> dict:
            from app.models.db_models import DbTrial
            from app.models.entities import Trial
            rows = self.db.query(DbTrial).all()
            return {
                t.id: Trial(
                    trial_id=t.id,
                    session_id=t.session_id,
                    candidate_id=t.candidate_id,
                    variant_text=t.playback_text,
                    voice_type=t.voice_profile_id or "",
                    modulation_type="unknown",
                    played_at=t.started_at,
                    manual_flag=t.manual_reaction
                ) for t in rows
            }

        @property
        def features(self) -> dict:
            from app.models.db_models import DbReactionFeatures
            from app.models.entities import ReactionFeatures
            rows = self.db.query(DbReactionFeatures).all()
            return {
                f.trial_id: ReactionFeatures(
                    trial_id=f.trial_id,
                    gaze_shift_score=float(f.gaze_shift_score),
                    ear_motion_score=float(f.ear_motion_score),
                    head_turn_score=float(f.head_turn_score),
                    posture_change_score=0.0,
                    approach_score=float(f.approach_score),
                    vocalization_score=float(f.vocalization_score),
                    repeatability_score=float(f.repeatability_score),
                    latency_ms=f.latency_ms,
                    manual_score=float(f.manual_score) if f.manual_score is not None else None,
                    model_version=f.model_version
                ) for f in rows
            }

        @property
        def candidates(self) -> dict:
            from app.models.db_models import DbCandidate
            from app.models.entities import Candidate
            rows = self.db.query(DbCandidate).filter(DbCandidate.enabled == True).all()
            return {
                c.id: Candidate(
                    candidate_id=c.id,
                    name=c.display_name,
                    species=c.species,
                    country_code=c.country,
                    language_code=c.language,
                    active=c.enabled
                ) for c in rows
            }

    adapter = DbStoreAdapter(db)
    return ResultService(adapter)


def get_known_animal_service(db: Session = Depends(get_db)) -> KnownAnimalService:
    repo = KnownAnimalRepository(db)
    return KnownAnimalService(repo)


def get_training_service(db: Session = Depends(get_db)) -> TrainingService:
    repo = TrainingRepository(db)
    return TrainingService(repo)


def get_model_service(db: Session = Depends(get_db)) -> ModelService:
    from app.repositories.model_repository import ModelRepository
    from app.services.model_service import ModelService
    repo = ModelRepository(db)
    return ModelService(repo, db)


def get_country_dictionary_service(db: Session = Depends(get_db)) -> CountryDictionaryService:
    from app.repositories.country_dictionary_repository import CountryDictionaryRepository
    from app.services.country_dictionary_service import CountryDictionaryService
    repo = CountryDictionaryRepository(db)
    return CountryDictionaryService(repo)


def get_tts_service(db: Session = Depends(get_db)) -> TTSService:
    from app.repositories.tts_repository import TTSRepository
    from app.services.tts_service import TTSService
    repo = TTSRepository(db)
    return TTSService(repo)


