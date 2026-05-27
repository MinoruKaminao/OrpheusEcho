from app.repositories.in_memory import InMemoryStore
from app.services.candidate_service import CandidateService
from app.services.ranking_service import RankingService
from app.services.result_service import ResultService
from app.services.session_service import SessionService
from app.services.trial_service import TrialService

# グローバルなインメモリ・データストアインスタンス
store = InMemoryStore()

session_service = SessionService(store)
candidate_service = CandidateService(store)
trial_service = TrialService(store)
ranking_service = RankingService(store)
result_service = ResultService(store)
