import Foundation

@MainActor
public class MockAPIClient: ObservableObject {
    @Published public var currentSession: Session?
    @Published public var candidates: [Candidate] = []
    @Published public var rankedCandidates: [RankedCandidate] = []
    @Published public var trials: [Trial] = []
    @Published public var history: [Session] = []
    
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var isOffline = false
    
    // Phase 6 placeholders
    @Published public var selectedCountryCode: String = "JP"
    @Published public var selectedLanguageCode: String = "ja-JP"
    @Published public var selectedTTSProfileId: String? = nil
    
    @Published public var availableCountries: [Country] = []
    @Published public var availableLanguages: [Language] = []
    @Published public var availableTTSProfiles: [TTSProfile] = []
    
    public init() {
        // 初期シードデータ
        self.candidates = [
            Candidate(candidate_id: "cand_001", name: "モモ", species: .dog, country_code: "JP", language_code: "ja-JP"),
            Candidate(candidate_id: "cand_002", name: "モカ", species: .dog, country_code: "JP", language_code: "ja-JP"),
            Candidate(candidate_id: "cand_003", name: "ルナ", species: .cat, country_code: "JP", language_code: "ja-JP"),
            Candidate(candidate_id: "cand_004", name: "ココ", species: .dog, country_code: "JP", language_code: "ja-JP"),
            Candidate(candidate_id: "cand_005", name: "レオ", species: .cat, country_code: "JP", language_code: "ja-JP")
        ]
    }
    
    public func createSession(species: Species, tempId: String?, notes: String?) async {
        self.isLoading = true
        self.errorMessage = nil
        
        // ネットワーク遅延シミュレート
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        if isOffline {
            // オフライン時のローカル保存
            let offlineId = "ses_offline_\(UUID().uuidString.prefix(6))"
            let session = Session(
                session_id: offlineId,
                species: species,
                temp_animal_id: tempId,
                notes: notes,
                status: .created
            )
            self.currentSession = session
            self.history.insert(session, at: 0)
            self.isLoading = false
            return
        }
        
        let newId = "ses_\(UUID().uuidString.prefix(8).lowercased())"
        let session = Session(
            session_id: newId,
            species: species,
            temp_animal_id: tempId,
            notes: notes,
            status: .created
        )
        
        self.currentSession = session
        self.history.insert(session, at: 0)
        self.isLoading = false
    }
    
    public func fetchCandidates(species: Species, country: String? = nil, language: String? = nil) async {
        self.isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        self.isLoading = false
    }
    
    public func recordTrial(candidateId: String, name: String, reaction: String) async {
        guard let session = currentSession else { return }
        self.isLoading = true
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        let newTrial = Trial(
            trial_id: "trl_\(UUID().uuidString.prefix(6))",
            session_id: session.session_id,
            candidate_id: candidateId,
            variant_text: name,
            voice_type: "female_bright",
            modulation_type: "nickname",
            played_at: Date(),
            manual_flag: reaction
        )
        self.trials.append(newTrial)
        
        // ランキングの簡易シミュレート計算
        self.calculateMockRanking()
        self.isLoading = false
    }
    
    private func calculateMockRanking() {
        var scoreMap: [String: Double] = [:]
        var nameMap: [String: String] = [:]
        
        for candidate in candidates {
            nameMap[candidate.candidate_id] = candidate.name
        }
        for trial in trials {
            nameMap[trial.candidate_id] = trial.variant_text
            var score = 0.1
            if trial.manual_flag == "reaction_yes" {
                score = 0.8
            } else if trial.manual_flag == "reaction_weak" {
                score = 0.4
            }
            scoreMap[trial.candidate_id] = max(scoreMap[trial.candidate_id] ?? 0.0, score)
        }
        
        let sorted = scoreMap.sorted { $0.value > $1.value }
        self.rankedCandidates = sorted.map { id, score in
            RankedCandidate(
                candidate_id: id,
                name: nameMap[id] ?? "Unknown",
                score: score,
                uncertainty_flag: trials.filter { $0.candidate_id == id }.count < 2
            )
        }
    }
    
    public func refineCandidates() async {
        guard let session = currentSession else { return }
        self.isLoading = true
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        var refinedList: [RankedCandidate] = []
        for ranked in rankedCandidates.prefix(3) {
            refinedList.append(ranked)
            refinedList.append(
                RankedCandidate(
                    candidate_id: "\(ranked.candidate_id)_refined",
                    name: "\(ranked.name)ちゃん",
                    score: max(ranked.score - 0.05, 0.0),
                    uncertainty_flag: true
                )
            )
        }
        self.rankedCandidates = refinedList
        self.isLoading = false
    }
    
    public func closeSession() async {
        guard var session = currentSession else { return }
        self.isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        session.status = .closed
        self.currentSession = session
        
        // 履歴の更新
        if let idx = history.firstIndex(where: { $0.session_id == session.session_id }) {
            self.history[idx] = session
        }
        
        self.isLoading = false
    }

    public func fetchCountries() async {
        self.availableCountries = [
            Country(code: "JP", name: "日本", default_language: "ja-JP"),
            Country(code: "US", name: "United States", default_language: "en-US")
        ]
    }
    public func fetchLanguages() async {
        self.availableLanguages = [
            Language(code: "ja-JP", name: "日本語"),
            Language(code: "en-US", name: "English (US)")
        ]
    }
    public func fetchTTSProfiles() async {
        self.availableTTSProfiles = [
            TTSProfile(id: "tts_jp_female", language_code: "ja-JP", voice_name: "Kyoko", gender: "female", speaking_rate: 1.0, pitch: 1.0, engine_type: "mock"),
            TTSProfile(id: "tts_en_female", language_code: "en-US", voice_name: "Samantha", gender: "female", speaking_rate: 1.0, pitch: 1.0, engine_type: "mock")
        ]
    }
    public func requestTTSPreview(text: String, profileId: String) async -> TTSPreviewResponse? {
        return TTSPreviewResponse(audio_url: "http://localhost:8001/exports/tts/mock.m4a", status: "ready")
    }
}
