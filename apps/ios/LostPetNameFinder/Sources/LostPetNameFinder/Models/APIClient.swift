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
    
    public var baseURL: URL
    
    public init(baseURL: URL = URL(string: "http://127.0.0.1:8001/api/v1")!) {
        self.baseURL = baseURL
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
            country_code: "JP",
            language_code: "ja-JP",
            multi_country_mode: false
        )
        
        struct CreateSessionResponse: Codable {
            let session_id: String
            let status: String
        }
        
        do {
            let response: CreateSessionResponse = try await performRequest(
                path: "sessions",
                method: "POST",
                body: reqBody
            )
            
            // 作成されたセッションの詳細を取得
            let session: Session = try await performGetRequest(path: "sessions/\(response.session_id)")
            self.currentSession = session
            
            // 履歴に追加
            if !self.history.contains(where: { $0.session_id == session.session_id }) {
                self.history.insert(session, at: 0)
            }
            self.isOffline = false
        } catch {
            print("API Error: \(error.localizedDescription). Falling back to offline session.")
            self.isOffline = true
            
            // オフライン時のローカルセッション生成 (AGENTS.md 6番規則準拠)
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
            self.errorMessage = "オフラインモードでセッションを開始しました。接続再開時に同期されます。"
        }
        
        self.isLoading = false
    }
    
    public func fetchCandidates(species: Species) async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            let params = [
                "species": species.rawValue,
                "country_code": "JP",
                "language_code": "ja-JP"
            ]
            let list: [Candidate] = try await performGetRequest(path: "candidates", queryParams: params)
            self.candidates = list
            self.isOffline = false
        } catch {
            print("API Error (fetchCandidates): \(error.localizedDescription). Using default candidates.")
            self.isOffline = true
            // ローカルデフォルトデータ
            self.candidates = [
                Candidate(candidate_id: "cand_001", name: "モモ", species: species, country_code: "JP", language_code: "ja-JP"),
                Candidate(candidate_id: "cand_002", name: "モカ", species: species, country_code: "JP", language_code: "ja-JP"),
                Candidate(candidate_id: "cand_003", name: "ルナ", species: species, country_code: "JP", language_code: "ja-JP"),
                Candidate(candidate_id: "cand_004", name: "ココ", species: species, country_code: "JP", language_code: "ja-JP"),
                Candidate(candidate_id: "cand_005", name: "レオ", species: species, country_code: "JP", language_code: "ja-JP")
            ]
        }
        
        self.isLoading = false
    }
    
    public func recordTrial(candidateId: String, name: String, reaction: String) async {
        guard let session = currentSession else { return }
        self.isLoading = true
        self.errorMessage = nil
        
        // 1. 反応に応じたモック特徴量データを生成 (AI/ML Agent シミュレーション)
        let features: ReactionFeatures
        if reaction == "reaction_yes" {
            features = ReactionFeatures(
                gaze_shift_score: Double.random(in: 0.8...0.95),
                ear_motion_score: Double.random(in: 0.6...0.85),
                head_turn_score: Double.random(in: 0.85...0.98),
                posture_change_score: Double.random(in: 0.4...0.7),
                approach_score: Double.random(in: 0.5...0.85),
                vocalization_score: Double.random(in: 0.05...0.2),
                repeatability_score: Double.random(in: 0.75...0.9)
            )
        } else if reaction == "reaction_weak" {
            features = ReactionFeatures(
                gaze_shift_score: Double.random(in: 0.35...0.55),
                ear_motion_score: Double.random(in: 0.4...0.6),
                head_turn_score: Double.random(in: 0.25...0.45),
                posture_change_score: Double.random(in: 0.15...0.35),
                approach_score: Double.random(in: 0.05...0.2),
                vocalization_score: Double.random(in: 0.01...0.1),
                repeatability_score: Double.random(in: 0.3...0.5)
            )
        } else {
            features = ReactionFeatures(
                gaze_shift_score: Double.random(in: 0.05...0.15),
                ear_motion_score: Double.random(in: 0.05...0.2),
                head_turn_score: Double.random(in: 0.02...0.12),
                posture_change_score: Double.random(in: 0.01...0.1),
                approach_score: Double.random(in: 0.0...0.05),
                vocalization_score: Double.random(in: 0.0...0.05),
                repeatability_score: Double.random(in: 0.05...0.25)
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
            
            // ローカルのtrials配列に追加
            let newTrial = Trial(
                trial_id: response.trial_id,
                session_id: session.session_id,
                candidate_id: candidateId,
                variant_text: name,
                voice_type: "female_bright",
                modulation_type: "nickname",
                played_at: Date(),
                manual_flag: reaction
            )
            self.trials.append(newTrial)
            
            // AI特徴量をサーバーへ送信
            await recordTrialFeatures(trialId: response.trial_id, features: features)
            
            // ランキングをサーバーから再取得
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
                played_at: Date(),
                manual_flag: reaction
            )
            self.trials.append(newTrial)
            
            // オフライン用の簡易ランキング計算 (加重特徴量 heuristics 準拠)
            calculateOfflineRanking(latestFeatures: features)
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
        
        for candidate in candidates {
            nameMap[candidate.candidate_id] = candidate.name
        }
        
        var trialCounts: [String: Int] = [:]
        
        for trial in trials {
            nameMap[trial.candidate_id] = trial.variant_text
            trialCounts[trial.candidate_id, default: 0] += 1
            
            var manualScore = 0.1
            if trial.manual_flag == "reaction_yes" {
                manualScore = 0.9
            } else if trial.manual_flag == "reaction_weak" {
                manualScore = 0.45
            }
            
            let featureScore: Double
            if trial.trial_id.contains("offline"), let lf = latestFeatures, trial.trial_id == trials.last?.trial_id {
                featureScore = 0.35 * lf.head_turn_score + 0.35 * lf.gaze_shift_score + 0.15 * lf.ear_motion_score + 0.15 * lf.approach_score
            } else {
                if trial.manual_flag == "reaction_yes" {
                    featureScore = 0.35 * 0.90 + 0.35 * 0.85 + 0.15 * 0.70 + 0.15 * 0.70
                } else if trial.manual_flag == "reaction_weak" {
                    featureScore = 0.35 * 0.35 + 0.35 * 0.45 + 0.15 * 0.50 + 0.15 * 0.15
                } else {
                    featureScore = 0.35 * 0.05 + 0.35 * 0.10 + 0.15 * 0.15 + 0.15 * 0.02
                }
            }
            
            let combined = 0.4 * manualScore + 0.6 * featureScore
            scoreMap[trial.candidate_id] = max(scoreMap[trial.candidate_id] ?? 0.0, min(combined, 0.99))
        }
        
        let sorted = scoreMap.sorted { $0.value > $1.value }
        self.rankedCandidates = sorted.map { id, score in
            RankedCandidate(
                candidate_id: id,
                name: nameMap[id] ?? "Unknown",
                score: score,
                uncertainty_flag: (trialCounts[id] ?? 0) < 2
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
            
            // オフライン用簡易展開
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
        } catch {
            print("API Error (closeSession): \(error.localizedDescription). Closing session locally.")
            self.isOffline = true
            
            session.status = .closed
            self.currentSession = session
            if let idx = history.firstIndex(where: { $0.session_id == session.session_id }) {
                self.history[idx] = session
            }
        }
        
        self.isLoading = false
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
}
