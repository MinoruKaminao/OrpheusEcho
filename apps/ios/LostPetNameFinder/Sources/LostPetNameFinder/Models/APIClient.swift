import Foundation

@MainActor
public class APIClient: ObservableObject {
    @Published public var currentSession: Session?
    @Published public var candidates: [Candidate] = []
    @Published public var rankedCandidates: [RankedCandidate] = []
    @Published public var trials: [Trial] = []
    @Published public var history: [Session] = []
    
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var isOffline = false
    @Published public var lastFeatures: ReactionFeatures?
    
    // Phase 2: 同期キュー用のデータ
    @Published public var pendingSessions: [Session] = []
    @Published public var pendingTrials: [Trial] = []
    @Published public var pendingFeatures: [String: ReactionFeatures] = [:]
    
    // Phase 4: 既知名個体・学習データ同期キュー用のデータ
    @Published public var pendingKnownAnimals: [KnownAnimal] = []
    @Published public var pendingTrainingSessions: [TrainingSession] = []
    @Published public var pendingTrainingTrials: [TrainingTrial] = []
    
    @Published public var knownAnimals: [KnownAnimal] = []
    @Published public var trainingSessions: [TrainingSession] = []
    @Published public var currentTrainingSession: TrainingSession?
    @Published public var trainingTrials: [TrainingTrial] = []
    
    @Published public var isSyncing = false
    @Published public var syncMessage: String?
    @Published public var currentModelVersion: String = "1.0.0"

    // Phase 6: 多言語・音声設定
    @Published public var selectedCountryCode: String = "JP"
    @Published public var selectedLanguageCode: String = "ja-JP"
    @Published public var selectedTTSProfileId: String? = nil
    
    @Published public var availableCountries: [Country] = []
    @Published public var availableLanguages: [Language] = []
    @Published public var availableTTSProfiles: [TTSProfile] = []
    
    public var baseURL: URL
    
    public init(baseURL: URL = URL(string: "http://127.0.0.1:8001/api/v1")!) {
        self.baseURL = baseURL
        loadLocalData()
    }
    
    // API応答の共通エンベロープ
    private struct APIResponseEnvelope<T: Codable>: Codable {
        let data: T?
        let meta: ResponseMeta
        let error: APIErrorDetail?
    }

    private struct ResponseMeta: Codable {
        let request_id: String
        let timestamp: String
        let page: Int?
        let page_size: Int?
        let total: Int?
    }

    private struct APIErrorDetail: Codable {
        let code: String
        let message: String
    }
    
    private struct EmptyResponse: Codable {}
    
    // MARK: - Local Persistence (FileManager JSON)
    
    private var localDataURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("orpheus_local_data.json")
    }
    
    struct LocalPersistedData: Codable {
        let history: [Session]
        let pendingSessions: [Session]
        let pendingTrials: [Trial]
        let pendingFeatures: [String: ReactionFeatures]
        // Phase 4
        let pendingKnownAnimals: [KnownAnimal]
        let pendingTrainingSessions: [TrainingSession]
        let pendingTrainingTrials: [TrainingTrial]
        let knownAnimals: [KnownAnimal]
        let currentModelVersion: String?
        // Phase 6
        let selectedCountryCode: String?
        let selectedLanguageCode: String?
        let selectedTTSProfileId: String?
    }
    
    public func saveLocalData() {
        let dataToSave = LocalPersistedData(
            history: self.history,
            pendingSessions: self.pendingSessions,
            pendingTrials: self.pendingTrials,
            pendingFeatures: self.pendingFeatures,
            pendingKnownAnimals: self.pendingKnownAnimals,
            pendingTrainingSessions: self.pendingTrainingSessions,
            pendingTrainingTrials: self.pendingTrainingTrials,
            knownAnimals: self.knownAnimals,
            currentModelVersion: self.currentModelVersion,
            selectedCountryCode: self.selectedCountryCode,
            selectedLanguageCode: self.selectedLanguageCode,
            selectedTTSProfileId: self.selectedTTSProfileId
        )
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(dataToSave)
            try data.write(to: localDataURL)
            print("Successfully saved local data to disk.")
        } catch {
            print("Failed to save local data: \(error.localizedDescription)")
        }
    }
    
    public func loadLocalData() {
        guard FileManager.default.fileExists(atPath: localDataURL.path) else {
            print("No local data file found on disk.")
            return
        }
        do {
            let data = try Data(contentsOf: localDataURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)
                let formatter = DateFormatter()
                formatter.calendar = Calendar(identifier: .iso8601)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                let formats = [
                    "yyyy-MM-dd'T'HH:mm:ss'Z'",
                    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                    "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                ]
                for format in formats {
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateStr) {
                        return date
                    }
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateStr)")
            }
            let persisted = try decoder.decode(LocalPersistedData.self, from: data)
            self.history = persisted.history
            self.pendingSessions = persisted.pendingSessions
            self.pendingTrials = persisted.pendingTrials
            self.pendingFeatures = persisted.pendingFeatures
            self.pendingKnownAnimals = persisted.pendingKnownAnimals
            self.pendingTrainingSessions = persisted.pendingTrainingSessions
            self.pendingTrainingTrials = persisted.pendingTrainingTrials
            self.knownAnimals = persisted.knownAnimals
            self.currentModelVersion = persisted.currentModelVersion ?? "1.0.0"
            
            // Phase 6
            self.selectedCountryCode = persisted.selectedCountryCode ?? "JP"
            self.selectedLanguageCode = persisted.selectedLanguageCode ?? "ja-JP"
            self.selectedTTSProfileId = persisted.selectedTTSProfileId
            print("Loaded local data. Pending sessions count: \(self.pendingSessions.count)")
        } catch {
            print("Failed to load local data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - API Requests
    
    public func createSession(species: Species, tempId: String?, notes: String?) async {
        self.isLoading = true
        self.errorMessage = nil
        self.lastFeatures = nil
        
        struct CreateSessionRequest: Codable {
            let species: String
            let temp_animal_id: String?
            let notes: String?
            let location_text: String?
            let coat_color: String?
            let age_hint: String?
            let country_code: String?
            let language_code: String?
            let multi_country_mode: Bool
        }
        
        let reqBody = CreateSessionRequest(
            species: species.rawValue,
            temp_animal_id: tempId,
            notes: notes,
            location_text: nil,
            coat_color: nil,
            age_hint: nil,
            country_code: selectedCountryCode,
            language_code: selectedLanguageCode,
            multi_country_mode: false
        )
        
        struct CreateSessionResponse: Codable {
            let session_id: String
            let status: String
        }
        
        do {
            if isOffline {
                throw URLError(.notConnectedToInternet)
            }
            
            let response: CreateSessionResponse = try await performRequest(
                path: "sessions",
                method: "POST",
                body: reqBody
            )
            
            let session: Session = try await performGetRequest(path: "sessions/\(response.session_id)")
            self.currentSession = session
            
            if !self.history.contains(where: { $0.session_id == session.session_id }) {
                self.history.insert(session, at: 0)
            }
            self.isOffline = false
            saveLocalData()
        } catch {
            print("API Error: \(error.localizedDescription). Falling back to offline session.")
            self.isOffline = true
            
            let offlineId = "ses_offline_\(UUID().uuidString.prefix(6))"
            let session = Session(
                session_id: offlineId,
                species: species,
                temp_animal_id: tempId,
                country_code: selectedCountryCode,
                language_code: selectedLanguageCode,
                notes: notes,
                status: .created
            )

            self.currentSession = session
            self.history.insert(session, at: 0)
            self.pendingSessions.append(session)
            self.errorMessage = "オフラインモードでセッションを開始しました。接続再開時に同期されます。"
            saveLocalData()
        }
        
        self.isLoading = false
    }
    
    public func fetchCandidates(species: Species, country: String? = nil, language: String? = nil) async {
        self.isLoading = true
        self.errorMessage = nil
        
        let targetCountry = country ?? selectedCountryCode
        let targetLanguage = language ?? selectedLanguageCode
        
        do {
            let params = [
                "species": species.rawValue,
                "country_code": targetCountry,
                "language_code": targetLanguage
            ]
            let list: [Candidate] = try await performGetRequest(path: "candidates", queryParams: params)
            self.candidates = list
            self.isOffline = false
        } catch {
            print("API Error (fetchCandidates): \(error.localizedDescription). Using default candidates.")
            self.isOffline = true
            if targetCountry == "US" {
                self.candidates = [
                    Candidate(candidate_id: "cand_us_001", name: "Max", species: species, country_code: targetCountry, language_code: targetLanguage),
                    Candidate(candidate_id: "cand_us_002", name: "Bella", species: species, country_code: targetCountry, language_code: targetLanguage),
                    Candidate(candidate_id: "cand_us_003", name: "Charlie", species: species, country_code: targetCountry, language_code: targetLanguage)
                ]
            } else {
                self.candidates = [
                    Candidate(candidate_id: "cand_001", name: "モモ", species: species, country_code: targetCountry, language_code: targetLanguage),
                    Candidate(candidate_id: "cand_002", name: "モカ", species: species, country_code: targetCountry, language_code: targetLanguage),
                    Candidate(candidate_id: "cand_003", name: "ルナ", species: species, country_code: targetCountry, language_code: targetLanguage),
                    Candidate(candidate_id: "cand_004", name: "ココ", species: species, country_code: targetCountry, language_code: targetLanguage),
                    Candidate(candidate_id: "cand_005", name: "レオ", species: species, country_code: targetCountry, language_code: targetLanguage)
                ]
            }
        }
        
        self.isLoading = false
    }
    
    public func recordTrial(candidateId: String, name: String, reaction: String) async {
        guard let session = currentSession else { return }
        self.isLoading = true
        self.errorMessage = nil
        
        let features: ReactionFeatures
        if reaction == "reaction_yes" {
            features = ReactionFeatures(
                gaze_shift_score: Double.random(in: 0.8...0.95),
                ear_motion_score: Double.random(in: 0.6...0.85),
                head_turn_score: Double.random(in: 0.85...0.98),
                posture_change_score: Double.random(in: 0.4...0.7),
                approach_score: Double.random(in: 0.5...0.85),
                vocalization_score: Double.random(in: 0.05...0.2),
                repeatability_score: Double.random(in: 0.75...0.9),
                latency_ms: Int.random(in: 200...800),
                manual_score: 0.9,
                model_version: self.currentModelVersion
            )
        } else if reaction == "reaction_weak" {
            features = ReactionFeatures(
                gaze_shift_score: Double.random(in: 0.35...0.55),
                ear_motion_score: Double.random(in: 0.4...0.6),
                head_turn_score: Double.random(in: 0.25...0.45),
                posture_change_score: Double.random(in: 0.15...0.35),
                approach_score: Double.random(in: 0.05...0.2),
                vocalization_score: Double.random(in: 0.01...0.1),
                repeatability_score: Double.random(in: 0.3...0.5),
                latency_ms: Int.random(in: 900...1800),
                manual_score: 0.45,
                model_version: self.currentModelVersion
            )
        } else {
            features = ReactionFeatures(
                gaze_shift_score: Double.random(in: 0.05...0.15),
                ear_motion_score: Double.random(in: 0.05...0.2),
                head_turn_score: Double.random(in: 0.02...0.12),
                posture_change_score: Double.random(in: 0.01...0.1),
                approach_score: Double.random(in: 0.0...0.05),
                vocalization_score: Double.random(in: 0.0...0.05),
                repeatability_score: Double.random(in: 0.05...0.25),
                latency_ms: Int.random(in: 2000...3000),
                manual_score: 0.1,
                model_version: self.currentModelVersion
            )
        }
        self.lastFeatures = features
        
        struct RecordTrialRequest: Codable {
            let candidate_id: String
            let variant_text: String
            let voice_type: String
            let modulation_type: String
            let played_at: Date
            let manual_flag: String
        }
        
        let reqBody = RecordTrialRequest(
            candidate_id: candidateId,
            variant_text: name,
            voice_type: "female_bright",
            modulation_type: "nickname",
            played_at: Date(),
            manual_flag: reaction
        )
        
        struct RecordTrialResponse: Codable {
            let trial_id: String
            let status: String
        }
        
        do {
            if isOffline || session.session_id.contains("offline") {
                throw URLError(.notConnectedToInternet)
            }
            
            let response: RecordTrialResponse = try await performRequest(
                path: "sessions/\(session.session_id)/trials",
                method: "POST",
                body: reqBody
            )
            
            let newTrial = Trial(
                trial_id: response.trial_id,
                session_id: session.session_id,
                candidate_id: candidateId,
                variant_text: name,
                voice_type: "female_bright",
                modulation_type: "nickname",
                played_at: reqBody.played_at,
                manual_flag: reaction
            )
            self.trials.append(newTrial)
            
            await recordTrialFeatures(trialId: response.trial_id, features: features)
            
            struct RankResponse: Codable {
                let top_candidates: [RankedCandidate]
            }
            let rankData: RankResponse = try await performRequest(
                path: "sessions/\(session.session_id)/rank",
                method: "POST",
                body: nil as EmptyResponse?
            )
            self.rankedCandidates = rankData.top_candidates
            self.isOffline = false
            saveLocalData()
        } catch {
            print("API Error (recordTrial): \(error.localizedDescription). Recording trial locally.")
            self.isOffline = true
            
            let localTrialId = "trl_offline_\(UUID().uuidString.prefix(6))"
            let newTrial = Trial(
                trial_id: localTrialId,
                session_id: session.session_id,
                candidate_id: candidateId,
                variant_text: name,
                voice_type: "female_bright",
                modulation_type: "nickname",
                played_at: reqBody.played_at,
                manual_flag: reaction
            )
            self.trials.append(newTrial)
            
            self.pendingTrials.append(newTrial)
            self.pendingFeatures[localTrialId] = features
            
            calculateOfflineRanking(latestFeatures: features)
            saveLocalData()
        }
        
        self.isLoading = false
    }
    
    public func recordTrialFeatures(trialId: String, features: ReactionFeatures) async {
        guard let session = currentSession else { return }
        do {
            let _: EmptyResponse = try await performRequest(
                path: "sessions/\(session.session_id)/trials/\(trialId)/features",
                method: "POST",
                body: features
            )
        } catch {
            print("API Error (recordTrialFeatures): \(error.localizedDescription)")
        }
    }
    
    private func calculateOfflineRanking(latestFeatures: ReactionFeatures? = nil) {
        var scoreMap: [String: Double] = [:]
        var nameMap: [String: String] = [:]
        var bestFeatures: [String: ReactionFeatures] = [:]
        var trialCounts: [String: Int] = [:]
        
        for candidate in candidates {
            nameMap[candidate.candidate_id] = candidate.name
        }
        
        for trial in trials {
            nameMap[trial.candidate_id] = trial.variant_text
            trialCounts[trial.candidate_id, default: 0] += 1
            
            var base = 0.1
            if trial.manual_flag == "reaction_yes" {
                base = 0.9
            } else if trial.manual_flag == "reaction_weak" {
                base = 0.45
            }
            
            let feat: ReactionFeatures
            if trial.trial_id.contains("offline"), let lf = latestFeatures, trial.trial_id == trials.last?.trial_id {
                feat = lf
            } else {
                if trial.manual_flag == "reaction_yes" {
                    feat = ReactionFeatures(
                        gaze_shift_score: 0.85, ear_motion_score: 0.70, head_turn_score: 0.90,
                        posture_change_score: 0.50, approach_score: 0.70, vocalization_score: 0.10,
                        repeatability_score: 0.80, latency_ms: 400, manual_score: 0.9, model_version: self.currentModelVersion
                    )
                } else if trial.manual_flag == "reaction_weak" {
                    feat = ReactionFeatures(
                        gaze_shift_score: 0.45, ear_motion_score: 0.50, head_turn_score: 0.35,
                        posture_change_score: 0.20, approach_score: 0.15, vocalization_score: 0.05,
                        repeatability_score: 0.40, latency_ms: 1200, manual_score: 0.45, model_version: self.currentModelVersion
                    )
                } else {
                    feat = ReactionFeatures(
                        gaze_shift_score: 0.10, ear_motion_score: 0.15, head_turn_score: 0.05,
                        posture_change_score: 0.05, approach_score: 0.02, vocalization_score: 0.01,
                        repeatability_score: 0.15, latency_ms: 2500, manual_score: 0.1, model_version: self.currentModelVersion
                    )
                }
            }
            
            let latencyVal = Double(feat.latency_ms ?? 3000)
            let latencyScore = max(0.0, min(1.0, 1.0 - (latencyVal / 3000.0)))
            
            let combined = (
                0.20 * feat.head_turn_score
                + 0.15 * feat.gaze_shift_score
                + 0.05 * feat.ear_motion_score
                + 0.10 * feat.approach_score
                + 0.03 * feat.vocalization_score
                + 0.05 * latencyScore
                + 0.02 * feat.repeatability_score
                + 0.40 * base
            )
            
            if scoreMap[trial.candidate_id] == nil || combined > scoreMap[trial.candidate_id]! {
                scoreMap[trial.candidate_id] = min(combined, 0.99)
                bestFeatures[trial.candidate_id] = feat
            }
        }
        
        let sorted = scoreMap.sorted { $0.value > $1.value }
        self.rankedCandidates = sorted.map { id, score in
            let trialsCnt = trialCounts[id] ?? 0
            let feat = bestFeatures[id]
            
            var confidence = "low"
            var explanation = "試行回数が不足しているため、参考スコアの信頼性が低い状態です。複数回の呼びかけテストを行ってください。"
            
            if let f = feat {
                if trialsCnt >= 2 {
                    confidence = f.repeatability_score >= 0.60 ? "high" : "medium"
                }
                
                var obs: [String] = []
                if f.head_turn_score >= 0.70 { obs.append("素早い頭部回転") }
                if f.gaze_shift_score >= 0.70 { obs.append("強い注視（視線移動）") }
                if f.approach_score >= 0.70 { obs.append("スピーカーへの接近行動") }
                if f.ear_motion_score >= 0.70 { obs.append("耳の方向転換") }
                if f.vocalization_score >= 0.50 { obs.append("鳴き声・発声") }
                
                if obs.isEmpty && f.manual_score == 0.9 {
                    obs.append("目視での明らかな反応")
                }
                
                if !obs.isEmpty {
                    let obsStr = obs.joined(separator: "、")
                    let sec = Double(f.latency_ms ?? 0) / 1000.0
                    explanation = "呼びかけに対し、\(obsStr)が観察されました（反応遅延: \(String(format: "%.1f", sec))秒）。"
                    if trialsCnt >= 2 {
                        explanation += " 反応の再現性（\(Int(f.repeatability_score * 100))%）が認められます。"
                    }
                } else {
                    explanation = "呼びかけに対し、AI動作マーカー上の顕著な動作変化は観察されませんでした。"
                }
            }
            
            return RankedCandidate(
                candidate_id: id,
                name: nameMap[id] ?? "Unknown",
                score: score,
                uncertainty_flag: trialsCnt < 2,
                confidence: confidence,
                explanation: explanation,
                source: feat != nil ? "model_assisted" : "manual",
                model_version: feat != nil ? self.currentModelVersion : nil
            )
        }
    }
    
    public func refineCandidates() async {
        guard let session = currentSession else { return }
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            if isOffline || session.session_id.contains("offline") {
                throw URLError(.notConnectedToInternet)
            }
            
            struct RefineResponse: Codable {
                let refined_candidates: [RankedCandidate]
            }
            
            let response: RefineResponse = try await performRequest(
                path: "sessions/\(session.session_id)/refine",
                method: "POST",
                body: nil as EmptyResponse?
            )
            self.rankedCandidates = response.refined_candidates
            self.isOffline = false
        } catch {
            print("API Error (refineCandidates): \(error.localizedDescription). Processing offline refinement.")
            self.isOffline = true
            
            var refinedList: [RankedCandidate] = []
            for ranked in rankedCandidates.prefix(3) {
                refinedList.append(ranked)
                refinedList.append(
                    RankedCandidate(
                        candidate_id: "\(ranked.candidate_id)_nick",
                        name: "\(ranked.name)ちゃん",
                        score: max(ranked.score - 0.05, 0.0),
                        uncertainty_flag: true,
                        confidence: "low",
                        explanation: "有力候補「\(ranked.name)」から展開された愛称候補です。追加検証を行ってください。",
                        source: "model_assisted",
                        model_version: "lightweight-nick-v" + self.currentModelVersion
                    )
                )
            }
            self.rankedCandidates = refinedList
        }
        
        self.isLoading = false
    }
    
    public func closeSession() async {
        guard var session = currentSession else { return }
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            if isOffline || session.session_id.contains("offline") {
                throw URLError(.notConnectedToInternet)
            }
            
            struct CloseResponse: Codable {
                let session_id: String
                let status: String
            }
            
            let _: CloseResponse = try await performRequest(
                path: "sessions/\(session.session_id)/close",
                method: "POST",
                body: nil as EmptyResponse?
            )
            
            session.status = .closed
            self.currentSession = session
            
            if let idx = history.firstIndex(where: { $0.session_id == session.session_id }) {
                self.history[idx] = session
            }
            self.isOffline = false
            saveLocalData()
        } catch {
            print("API Error (closeSession): \(error.localizedDescription). Closing session locally.")
            self.isOffline = true
            
            session.status = .closed
            self.currentSession = session
            if let idx = history.firstIndex(where: { $0.session_id == session.session_id }) {
                self.history[idx] = session
            }
            if let idx = pendingSessions.firstIndex(where: { $0.session_id == session.session_id }) {
                pendingSessions[idx].status = .closed
            }
            saveLocalData()
        }
        
        self.isLoading = false
    }
    
    // MARK: - Phase 2: Synchronize Queue
    
    public func syncOfflineData() async {
        guard !isSyncing else { return }
        isSyncing = true
        syncMessage = "同期中..."
        errorMessage = nil
        
        var sessionIdMap: [String: String] = [:]
        var trialIdMap: [String: String] = [:]
        var knownAnimalIdMap: [String: String] = [:]
        var trainingSessionIdMap: [String: String] = [:]
        
        // 1. 既知名個体の同期
        let animalsToSync = pendingKnownAnimals
        pendingKnownAnimals.removeAll()
        
        struct RegisterRequest: Codable {
            let species: String
            let true_name: String
            let aliases: [String]?
            let sex: String?
            let age_range: String?
            let breed: String?
            let coat_color: String?
            let owner_consent_status: String
        }
        
        for animal in animalsToSync {
            let reqBody = RegisterRequest(
                species: animal.species.rawValue,
                true_name: animal.true_name,
                aliases: animal.aliases,
                sex: animal.sex,
                age_range: animal.age_range,
                breed: animal.breed,
                coat_color: animal.coat_color,
                owner_consent_status: animal.owner_consent_status
            )
            do {
                let response: KnownAnimal = try await performRequest(
                    path: "known-animals",
                    method: "POST",
                    body: reqBody
                )
                knownAnimalIdMap[animal.known_animal_id] = response.known_animal_id
                if let idx = self.knownAnimals.firstIndex(where: { $0.known_animal_id == animal.known_animal_id }) {
                    self.knownAnimals[idx] = response
                }
            } catch {
                print("Failed to sync known animal \(animal.known_animal_id): \(error.localizedDescription)")
                pendingKnownAnimals.append(animal)
            }
        }
        
        // 2. セッションの同期
        let sessionsToSync = pendingSessions
        pendingSessions.removeAll()
        
        struct CreateSessionRequest: Codable {
            let species: String
            let temp_animal_id: String?
            let notes: String?
            let location_text: String?
            let coat_color: String?
            let age_hint: String?
            let country_code: String?
            let language_code: String?
            let multi_country_mode: Bool
        }
        
        struct CreateSessionResponse: Codable {
            let session_id: String
            let status: String
        }
        
        for session in sessionsToSync {
            let reqBody = CreateSessionRequest(
                species: session.species.rawValue,
                temp_animal_id: session.temp_animal_id,
                notes: session.notes,
                location_text: session.location_text,
                coat_color: session.coat_color,
                age_hint: session.age_hint,
                country_code: session.country_code ?? "JP",
                language_code: session.language_code ?? "ja-JP",
                multi_country_mode: session.multi_country_mode
            )
            
            do {
                let response: CreateSessionResponse = try await performRequest(
                    path: "sessions",
                    method: "POST",
                    body: reqBody
                )
                sessionIdMap[session.session_id] = response.session_id
                
                // 履歴データのIDも更新
                if let idx = self.history.firstIndex(where: { $0.session_id == session.session_id }) {
                    let updated = Session(
                        session_id: response.session_id,
                        species: session.species,
                        temp_animal_id: session.temp_animal_id,
                        location_text: session.location_text,
                        coat_color: session.coat_color,
                        age_hint: session.age_hint,
                        country_code: session.country_code,
                        language_code: session.language_code,
                        multi_country_mode: session.multi_country_mode,
                        notes: session.notes,
                        status: session.status,
                        created_at: session.created_at,
                        updated_at: session.updated_at
                    )
                    self.history[idx] = updated
                }
                
                if self.currentSession?.session_id == session.session_id {
                    self.currentSession = Session(
                        session_id: response.session_id,
                        species: session.species,
                        temp_animal_id: session.temp_animal_id,
                        location_text: session.location_text,
                        coat_color: session.coat_color,
                        age_hint: session.age_hint,
                        country_code: session.country_code,
                        language_code: session.language_code,
                        multi_country_mode: session.multi_country_mode,
                        notes: session.notes,
                        status: session.status,
                        created_at: session.created_at,
                        updated_at: session.updated_at
                    )
                }
            } catch {
                print("Failed to sync session \(session.session_id): \(error.localizedDescription)")
                pendingSessions.append(session)
            }
        }
        
        // 3. 学習セッションの同期
        let trainingSessionsToSync = pendingTrainingSessions
        pendingTrainingSessions.removeAll()
        
        struct CreateTrainingSessionRequest: Codable {
            let known_animal_id: String
            let speaker_type: String
            let environment_type: String
            let purpose: String
        }
        
        for trs in trainingSessionsToSync {
            let mappedAnimalId = knownAnimalIdMap[trs.known_animal_id] ?? trs.known_animal_id
            if mappedAnimalId.contains("offline") {
                pendingTrainingSessions.append(trs)
                continue
            }
            
            let reqBody = CreateTrainingSessionRequest(
                known_animal_id: mappedAnimalId,
                speaker_type: trs.speaker_type,
                environment_type: trs.environment_type,
                purpose: trs.purpose
            )
            
            do {
                let response: TrainingSession = try await performRequest(
                    path: "training-sessions",
                    method: "POST",
                    body: reqBody
                )
                trainingSessionIdMap[trs.training_session_id] = response.training_session_id
                
                if self.currentTrainingSession?.training_session_id == trs.training_session_id {
                    self.currentTrainingSession = response
                }
            } catch {
                print("Failed to sync training session \(trs.training_session_id): \(error.localizedDescription)")
                pendingTrainingSessions.append(trs)
            }
        }
        
        // 4. 探索試行（Trials）の同期
        let trialsToSync = pendingTrials
        pendingTrials.removeAll()
        
        struct RecordTrialRequest: Codable {
            let candidate_id: String
            let variant_text: String
            let voice_type: String
            let modulation_type: String
            let played_at: Date
            let manual_flag: String
        }
        
        struct RecordTrialResponse: Codable {
            let trial_id: String
            let status: String
        }
        
        for trial in trialsToSync {
            let mappedSessionId = sessionIdMap[trial.session_id] ?? trial.session_id
            
            if mappedSessionId.contains("offline") {
                pendingTrials.append(trial)
                continue
            }
            
            let reqBody = RecordTrialRequest(
                candidate_id: trial.candidate_id,
                variant_text: trial.variant_text,
                voice_type: trial.voice_type,
                modulation_type: trial.modulation_type,
                played_at: trial.played_at,
                manual_flag: trial.manual_flag ?? "reaction_none"
            )
            
            do {
                let response: RecordTrialResponse = try await performRequest(
                    path: "sessions/\(mappedSessionId)/trials",
                    method: "POST",
                    body: reqBody
                )
                trialIdMap[trial.trial_id] = response.trial_id
                
                if let idx = self.trials.firstIndex(where: { $0.trial_id == trial.trial_id }) {
                    let updated = Trial(
                        trial_id: response.trial_id,
                        session_id: mappedSessionId,
                        candidate_id: trial.candidate_id,
                        variant_text: trial.variant_text,
                        voice_type: trial.voice_type,
                        modulation_type: trial.modulation_type,
                        played_at: trial.played_at,
                        manual_flag: trial.manual_flag
                    )
                    self.trials[idx] = updated
                }
            } catch {
                print("Failed to sync trial \(trial.trial_id): \(error.localizedDescription)")
                pendingTrials.append(trial)
            }
        }
        
        // 5. 学習試行（Training Trials）の同期
        let trainingTrialsToSync = pendingTrainingTrials
        pendingTrainingTrials.removeAll()
        
        struct RecordTrainingTrialRequest: Codable {
            let called_name: String
            let is_true_name: Bool = false
            let is_true_name_val: Bool
            let is_alias: Bool
            let modulation_type: String
            let playback_source: String
            let manual_reaction: String?
            
            enum CodingKeys: String, CodingKey {
                case called_name
                case is_true_name_val = "is_true_name"
                case is_alias
                case modulation_type
                case playback_source
                case manual_reaction
            }
        }
        
        for trt in trainingTrialsToSync {
            let mappedTrsId = trainingSessionIdMap[trt.training_session_id] ?? trt.training_session_id
            if mappedTrsId.contains("offline") {
                pendingTrainingTrials.append(trt)
                continue
            }
            
            let reqBody = RecordTrainingTrialRequest(
                called_name: trt.called_name,
                is_true_name_val: trt.is_true_name,
                is_alias: trt.is_alias,
                modulation_type: trt.modulation_type,
                playback_source: trt.playback_source,
                manual_reaction: trt.manual_reaction
            )
            
            do {
                let response: TrainingTrial = try await performRequest(
                    path: "training-sessions/\(mappedTrsId)/trials",
                    method: "POST",
                    body: reqBody
                )
                if let idx = self.trainingTrials.firstIndex(where: { $0.trial_id == trt.trial_id }) {
                    self.trainingTrials[idx] = response
                }
            } catch {
                print("Failed to sync training trial \(trt.trial_id): \(error.localizedDescription)")
                pendingTrainingTrials.append(trt)
            }
        }
        
        // 6. AI特徴量（Features）の同期
        let featuresToSync = pendingFeatures
        pendingFeatures.removeAll()
        
        for (localTrialId, features) in featuresToSync {
            guard let mappedTrialId = trialIdMap[localTrialId] else {
                pendingFeatures[localTrialId] = features
                continue
            }
            
            let targetSessionId = trialsToSync.first(where: { $0.trial_id == localTrialId })?.session_id ?? ""
            let mappedSessionId = sessionIdMap[targetSessionId] ?? targetSessionId
            
            do {
                let _: EmptyResponse = try await performRequest(
                    path: "sessions/\(mappedSessionId)/trials/\(mappedTrialId)/features",
                    method: "POST",
                    body: features
                )
            } catch {
                print("Failed to sync features for trial \(mappedTrialId): \(error.localizedDescription)")
                pendingFeatures[localTrialId] = features
            }
        }
        
        // 7. 探索セッションのクローズ同期
        for (_, onlineSessionId) in sessionIdMap {
            if let sessionInHistory = self.history.first(where: { $0.session_id == onlineSessionId }),
               sessionInHistory.status == .closed {
                do {
                    struct CloseResponse: Codable {
                        let session_id: String
                        let status: String
                    }
                    let _: CloseResponse = try await performRequest(
                        path: "sessions/\(onlineSessionId)/close",
                        method: "POST",
                        body: nil as EmptyResponse?
                    )
                } catch {
                    print("Failed to close synced session \(onlineSessionId): \(error.localizedDescription)")
                }
            }
        }
        
        // 8. 学習セッションの完了同期
        for (localTrsId, onlineTrsId) in trainingSessionIdMap {
            if let originalTrs = trainingSessionsToSync.first(where: { $0.training_session_id == localTrsId }),
               originalTrs.status == "completed" {
                do {
                    let _: TrainingSession = try await performRequest(
                        path: "training-sessions/\(onlineTrsId)/complete",
                        method: "POST",
                        body: nil as EmptyResponse?
                    )
                    if self.currentTrainingSession?.training_session_id == onlineTrsId {
                        self.currentTrainingSession?.status = "completed"
                    }
                } catch {
                    print("Failed to complete synced training session \(onlineTrsId): \(error.localizedDescription)")
                }
            }
        }
        
        saveLocalData()
        
        if pendingSessions.isEmpty && pendingTrials.isEmpty && pendingFeatures.isEmpty &&
           pendingKnownAnimals.isEmpty && pendingTrainingSessions.isEmpty && pendingTrainingTrials.isEmpty {
            self.isOffline = false
            self.syncMessage = "同期が完了しました！"
            
            if let current = currentSession {
                struct RankResponse: Codable {
                    let top_candidates: [RankedCandidate]
                }
                if let rankData: RankResponse = try? await performRequest(
                    path: "sessions/\(current.session_id)/rank",
                    method: "POST",
                    body: nil as EmptyResponse?
                ) {
                    self.rankedCandidates = rankData.top_candidates
                }
            }
        } else {
            self.syncMessage = "同期処理が完了しましたが、一部のデータが未送信です。"
            self.errorMessage = "通信接続を確認のうえ、再試行してください。"
        }
        self.isSyncing = false
    }
    
    // MARK: - Phase 4: Known Animals API
    
    public func registerKnownAnimal(
        species: Species,
        trueName: String,
        aliases: [String]?,
        sex: String?,
        ageRange: String?,
        breed: String?,
        coatColor: String?,
        consent: String
    ) async {
        self.isLoading = true
        self.errorMessage = nil
        
        struct RegisterRequest: Codable {
            let species: String
            let true_name: String
            let aliases: [String]?
            let sex: String?
            let age_range: String?
            let breed: String?
            let coat_color: String?
            let owner_consent_status: String
        }
        
        let reqBody = RegisterRequest(
            species: species.rawValue,
            true_name: trueName,
            aliases: aliases,
            sex: sex,
            age_range: ageRange,
            breed: breed,
            coat_color: coatColor,
            owner_consent_status: consent
        )
        
        do {
            if isOffline {
                throw URLError(.notConnectedToInternet)
            }
            
            let response: KnownAnimal = try await performRequest(
                path: "known-animals",
                method: "POST",
                body: reqBody
            )
            
            if !self.knownAnimals.contains(where: { $0.known_animal_id == response.known_animal_id }) {
                self.knownAnimals.append(response)
            }
            self.isOffline = false
            saveLocalData()
        } catch {
            print("API Error (registerKnownAnimal): \(error.localizedDescription). Falling back to offline known animal.")
            self.isOffline = true
            
            let offlineId = "ka_offline_\(UUID().uuidString.prefix(6))"
            let offlineAnimal = KnownAnimal(
                known_animal_id: offlineId,
                species: species,
                true_name: trueName,
                aliases: aliases,
                sex: sex,
                age_range: ageRange,
                breed: breed,
                coat_color: coatColor,
                owner_consent_status: consent
            )
            self.knownAnimals.append(offlineAnimal)
            self.pendingKnownAnimals.append(offlineAnimal)
            saveLocalData()
        }
        
        self.isLoading = false
    }

    public func uploadAnimalImage(knownAnimalId: String, fileName: String, contentType: String) async -> String? {
        self.isLoading = true
        self.errorMessage = nil
        
        struct ImageRegisterRequest: Codable {
            let file_name: String
            let content_type: String
        }
        
        let reqBody = ImageRegisterRequest(file_name: fileName, content_type: contentType)
        
        do {
            if isOffline || knownAnimalId.contains("offline") {
                throw URLError(.notConnectedToInternet)
            }
            
            let response: ImageUploadResponse = try await performRequest(
                path: "known-animals/\(knownAnimalId)/images",
                method: "POST",
                body: reqBody
            )
            self.isOffline = false
            self.isLoading = false
            return response.image_id
        } catch {
            print("API Error (uploadAnimalImage): \(error.localizedDescription)")
            self.isOffline = true
            self.isLoading = false
            return nil
        }
    }

    // MARK: - Phase 4: Training Sessions API
    
    public func createTrainingSession(
        knownAnimalId: String,
        speaker: String,
        environment: String,
        purpose: String
    ) async {
        self.isLoading = true
        self.errorMessage = nil
        self.trainingTrials = []
        
        struct CreateTrainingSessionRequest: Codable {
            let known_animal_id: String
            let speaker_type: String
            let environment_type: String
            let purpose: String
        }
        
        let reqBody = CreateTrainingSessionRequest(
            known_animal_id: knownAnimalId,
            speaker_type: speaker,
            environment_type: environment,
            purpose: purpose
        )
        
        do {
            if isOffline || knownAnimalId.contains("offline") {
                throw URLError(.notConnectedToInternet)
            }
            
            let response: TrainingSession = try await performRequest(
                path: "training-sessions",
                method: "POST",
                body: reqBody
            )
            
            self.currentTrainingSession = response
            self.isOffline = false
            saveLocalData()
        } catch {
            print("API Error (createTrainingSession): \(error.localizedDescription). Falling back to offline training session.")
            self.isOffline = true
            
            let offlineId = "trs_offline_\(UUID().uuidString.prefix(6))"
            let offlineSession = TrainingSession(
                training_session_id: offlineId,
                known_animal_id: knownAnimalId,
                speaker_type: speaker,
                environment_type: environment,
                purpose: purpose,
                status: "created"
            )
            self.currentTrainingSession = offlineSession
            self.pendingTrainingSessions.append(offlineSession)
            saveLocalData()
        }
        
        self.isLoading = false
    }

    public func recordTrainingTrial(
        calledName: String,
        isTrueName: Bool,
        isAlias: Bool,
        modulation: String,
        source: String,
        reaction: String?
    ) async {
        guard let session = currentTrainingSession else { return }
        self.isLoading = true
        self.errorMessage = nil
        
        struct RecordTrainingTrialRequest: Codable {
            let called_name: String
            let is_true_name: Bool = false
            let is_true_name_val: Bool
            let is_alias: Bool
            let modulation_type: String
            let playback_source: String
            let manual_reaction: String?
            
            enum CodingKeys: String, CodingKey {
                case called_name
                case is_true_name_val = "is_true_name"
                case is_alias
                case modulation_type
                case playback_source
                case manual_reaction
            }
        }
        
        let reqBody = RecordTrainingTrialRequest(
            called_name: calledName,
            is_true_name_val: isTrueName,
            is_alias: isAlias,
            modulation_type: modulation,
            playback_source: source,
            manual_reaction: reaction
        )
        
        do {
            if isOffline || session.training_session_id.contains("offline") {
                throw URLError(.notConnectedToInternet)
            }
            
            let response: TrainingTrial = try await performRequest(
                path: "training-sessions/\(session.training_session_id)/trials",
                method: "POST",
                body: reqBody
            )
            
            self.trainingTrials.append(response)
            self.isOffline = false
            saveLocalData()
        } catch {
            print("API Error (recordTrainingTrial): \(error.localizedDescription). Recording trial locally.")
            self.isOffline = true
            
            let offlineId = "trt_offline_\(UUID().uuidString.prefix(6))"
            let offlineTrial = TrainingTrial(
                trial_id: offlineId,
                training_session_id: session.training_session_id,
                called_name: calledName,
                is_true_name: isTrueName,
                is_alias: isAlias,
                modulation_type: modulation,
                playback_source: source,
                manual_reaction: reaction
            )
            self.trainingTrials.append(offlineTrial)
            self.pendingTrainingTrials.append(offlineTrial)
            saveLocalData()
        }
        
        self.isLoading = false
    }

    public func completeTrainingSession() async {
        guard var session = currentTrainingSession else { return }
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            if isOffline || session.training_session_id.contains("offline") {
                throw URLError(.notConnectedToInternet)
            }
            
            let _: TrainingSession = try await performRequest(
                path: "training-sessions/\(session.training_session_id)/complete",
                method: "POST",
                body: nil as EmptyResponse?
            )
            
            session.status = "completed"
            self.currentTrainingSession = session
            self.isOffline = false
            saveLocalData()
        } catch {
            print("API Error (completeTrainingSession): \(error.localizedDescription). Completing locally.")
            self.isOffline = true
            
            session.status = "completed"
            self.currentTrainingSession = session
            if let idx = pendingTrainingSessions.firstIndex(where: { $0.training_session_id == session.training_session_id }) {
                pendingTrainingSessions[idx].status = "completed"
            }
            saveLocalData()
        }
        
        self.isLoading = false
    }
    
    // MARK: - Phase 2: Privacy Masking for Sharing Report
    
    public func exportShareText(
        includeLocation: Bool,
        includeMedia: Bool,
        includeNotes: Bool
    ) -> String {
        guard let session = currentSession else { return "探索結果セッションがありません。" }
        
        var text = "【Orpheus Echo 推定呼称探索レポート】\n"
        text += "セッションID: \(session.session_id)\n"
        text += "対象動物: \(session.species == .dog ? "犬" : "猫")\n"
        
        let loc = includeLocation ? (session.location_text ?? "未指定") : "[位置情報非公開]"
        text += "探索場所: \(loc)\n"
        
        let note = includeNotes ? (session.notes ?? "なし") : "[個体メモ非公開]"
        text += "備考: \(note)\n"
        
        text += "\n--- 推定有力呼称候補 ---\n"
        for (idx, item) in rankedCandidates.prefix(3).enumerated() {
            text += "\(idx + 1). \(item.name) (参考スコア: \(String(format: "%.2f", item.score)))\n"
            if let explanation = item.explanation {
                text += "   [分析判定]: \(explanation)\n"
            }
        }
        
        text += "\n--- 試行履歴 (総試行数: \(trials.count)) ---\n"
        for (idx, trial) in trials.enumerated() {
            let reaction = trial.manual_flag == "reaction_yes" ? "反応あり" : (trial.manual_flag == "reaction_weak" ? "弱い" : "反応なし")
            let voice = includeMedia ? trial.voice_type : "[音声情報非公開]"
            let modulation = includeMedia ? trial.modulation_type : "[音声情報非公開]"
            text += "[\(idx + 1)] 名前: \(trial.variant_text) | 反応: \(reaction) | 音声プロファイル: \(voice) (\(modulation))\n"
        }
        
        text += "\n※本レポートは名前の確定・特定を保証するものではありません。"
        return text
    }
    
    // MARK: - Phase 2: Report Export API
    
    public struct ExportResponse: Codable {
        public let session_id: String
        public let format: String
        public let status: String
        public let download_url: String
    }
    
    public func exportReport(sessionId: String, format: String) async throws -> ExportResponse {
        let params = ["format": format]
        return try await performRequest(
            path: "sessions/\(sessionId)/export",
            method: "GET",
            queryParams: params,
            body: nil as EmptyResponse?
        )
    }
    
    // MARK: - Network Request Helper
    
    private func performRequest<Req: Codable, Res: Codable>(
        path: String,
        method: String,
        queryParams: [String: String]? = nil,
        body: Req? = nil
    ) async throws -> Res {
        var url = baseURL.appendingPathComponent(path)
        
        if let queryParams = queryParams, var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
            if let newURL = components.url {
                url = newURL
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            ]
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: dateStr) {
                    return date
                }
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateStr)")
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            let envelope = try decoder.decode(APIResponseEnvelope<Res>.self, from: data)
            if let responseData = envelope.data {
                return responseData
            } else if Res.self == EmptyResponse.self {
                return EmptyResponse() as! Res
            } else {
                throw NSError(domain: "APIClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Response data was null"])
            }
        } else {
            if let errorEnvelope = try? decoder.decode(APIResponseEnvelope<EmptyResponse>.self, from: data),
               let errorDetail = errorEnvelope.error {
                throw NSError(domain: "APIClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorDetail.message])
            } else {
                throw NSError(domain: "APIClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
            }
        }
    }
    
    private func performGetRequest<Res: Codable>(
        path: String,
        queryParams: [String: String]? = nil
    ) async throws -> Res {
        let dummyBody: EmptyResponse? = nil
        return try await performRequest(path: path, method: "GET", queryParams: queryParams, body: dummyBody)
    }

    // MARK: - Phase 5: Model Registry & Updates

    public func fetchCurrentModel() async -> MLModelInfo? {
        self.isLoading = true
        self.errorMessage = nil
        do {
            let res: MLModelInfo = try await performRequest(
                path: "models/current",
                method: "GET",
                body: nil as EmptyResponse?
            )
            self.isLoading = false
            return res
        } catch {
            print("API Error (fetchCurrentModel): \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return nil
        }
    }

    public func checkModelUpdate() async -> ModelUpdateCheckResponse? {
        self.isLoading = true
        self.errorMessage = nil
        do {
            struct CheckUpdateReq: Codable {
                let current_version: String
            }
            let req = CheckUpdateReq(current_version: currentModelVersion)
            let res: ModelUpdateCheckResponse = try await performRequest(
                path: "models/check-update",
                method: "POST",
                body: req
            )
            self.isLoading = false
            return res
        } catch {
            print("API Error (checkModelUpdate): \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return nil
        }
    }

    public func applyModelUpdate(version: String) async -> Bool {
        self.isLoading = true
        self.errorMessage = nil
        do {
            struct ApplyReq: Codable {
                let version: String
            }
            let req = ApplyReq(version: version)
            
            struct ApplyRes: Codable {
                let success: Bool
                let version: String
            }
            
            let res: ApplyRes = try await performRequest(
                path: "models/apply-update",
                method: "POST",
                body: req
            )
            if res.success {
                self.currentModelVersion = res.version
                saveLocalData()
                self.isLoading = false
                return true
            }
            self.isLoading = false
            return false
        } catch {
            print("API Error (applyModelUpdate): \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return false
        }
    }

    // MARK: - Phase 5: Training Data Sync & Export

    public func exportTrainingData(sessionIds: [String], trainingSessionIds: [String]) async -> String? {
        self.isLoading = true
        self.errorMessage = nil
        do {
            struct ExportReq: Codable {
                let session_ids: [String]
                let training_session_ids: [String]
                var anonymize: Bool = true
            }
            let req = ExportReq(session_ids: sessionIds, training_session_ids: trainingSessionIds)
            
            struct ExportRes: Codable {
                let job_id: String
                let status: String
                let download_url: String
            }
            
            let res: ExportRes = try await performRequest(
                path: "training-data/export",
                method: "POST",
                body: req
            )
            self.isLoading = false
            return res.job_id
        } catch {
            print("API Error (exportTrainingData): \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return nil
        }
    }

    public func syncTrainingData(exportJobId: String) async -> String? {
        self.isLoading = true
        self.errorMessage = nil
        do {
            struct SyncReq: Codable {
                let export_job_id: String
            }
            let req = SyncReq(export_job_id: exportJobId)
            
            struct SyncRes: Codable {
                let sync_job_id: String
                let status: String
            }
            
            let res: SyncRes = try await performRequest(
                path: "training-data/sync",
                method: "POST",
                body: req
            )
            self.isLoading = false
            return res.sync_job_id
        } catch {
            print("API Error (syncTrainingData): \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return nil
        }
    }

    public func getSyncJobStatus(jobId: String) async -> SyncJobStatus? {
        do {
            let res: SyncJobStatus = try await performRequest(
                path: "training-data/sync-status/\(jobId)",
                method: "GET",
                body: nil as EmptyResponse?
            )
            return res
        } catch {
            print("API Error (getSyncJobStatus): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Phase 6: Internationalization API
    
    public func fetchCountries() async {
        self.isLoading = true
        self.errorMessage = nil
        do {
            let list: [Country] = try await performGetRequest(path: "countries")
            self.availableCountries = list
            self.isOffline = false
        } catch {
            print("API Error (fetchCountries): \(error.localizedDescription)")
            self.isOffline = true
            self.availableCountries = [
                Country(code: "JP", name: "日本", default_language: "ja-JP"),
                Country(code: "US", name: "United States", default_language: "en-US"),
                Country(code: "GB", name: "United Kingdom", default_language: "en-GB")
            ]
        }
        self.isLoading = false
    }

    public func fetchLanguages() async {
        self.isLoading = true
        self.errorMessage = nil
        do {
            let list: [Language] = try await performGetRequest(path: "languages")
            self.availableLanguages = list
            self.isOffline = false
        } catch {
            print("API Error (fetchLanguages): \(error.localizedDescription)")
            self.isOffline = true
            self.availableLanguages = [
                Language(code: "ja-JP", name: "日本語"),
                Language(code: "en-US", name: "English (US)"),
                Language(code: "en-GB", name: "English (UK)")
            ]
        }
        self.isLoading = false
    }

    public func fetchTTSProfiles() async {
        self.isLoading = true
        self.errorMessage = nil
        do {
            let list: [TTSProfile] = try await performGetRequest(path: "tts/profiles")
            self.availableTTSProfiles = list
            self.isOffline = false
        } catch {
            print("API Error (fetchTTSProfiles): \(error.localizedDescription)")
            self.isOffline = true
            self.availableTTSProfiles = [
                TTSProfile(id: "tts_jp_female", language_code: "ja-JP", voice_name: "Kyoko", gender: "female", speaking_rate: 1.0, pitch: 1.0, engine_type: "mock"),
                TTSProfile(id: "tts_jp_male", language_code: "ja-JP", voice_name: "Otoya", gender: "male", speaking_rate: 1.0, pitch: 1.0, engine_type: "mock"),
                TTSProfile(id: "tts_en_female", language_code: "en-US", voice_name: "Samantha", gender: "female", speaking_rate: 1.0, pitch: 1.0, engine_type: "mock"),
                TTSProfile(id: "tts_en_male", language_code: "en-US", voice_name: "Daniel", gender: "male", speaking_rate: 1.0, pitch: 1.0, engine_type: "mock")
            ]
        }
        self.isLoading = false
    }

    public func requestTTSPreview(text: String, profileId: String) async -> TTSPreviewResponse? {
        self.isLoading = true
        self.errorMessage = nil
        
        struct PreviewReq: Codable {
            let text: String
            let tts_profile_id: String
        }
        let req = PreviewReq(text: text, tts_profile_id: profileId)
        
        do {
            let res: TTSPreviewResponse = try await performRequest(
                path: "tts/preview",
                method: "POST",
                body: req
            )
            self.isOffline = false
            self.isLoading = false
            return res
        } catch {
            print("API Error (requestTTSPreview): \(error.localizedDescription)")
            self.isOffline = true
            self.isLoading = false
            return nil
        }
    }
}
