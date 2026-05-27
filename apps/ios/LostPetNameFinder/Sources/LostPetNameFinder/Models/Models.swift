import Foundation

public enum Species: String, Codable, CaseIterable {
    case dog = "dog"
    case cat = "cat"
}

public enum SessionStatus: String, Codable {
    case created = "created"
    case active = "active"
    case closed = "closed"
}

public struct Session: Identifiable, Codable {
    public var id: String { session_id }
    public let session_id: String
    public let species: Species
    public var temp_animal_id: String?
    public var location_text: String?
    public var coat_color: String?
    public var age_hint: String?
    public var country_code: String?
    public var language_code: String?
    public var multi_country_mode: Bool
    public var notes: String?
    public var status: SessionStatus
    public var created_at: Date
    public var updated_at: Date

    public init(
        session_id: String,
        species: Species,
        temp_animal_id: String? = nil,
        location_text: String? = nil,
        coat_color: String? = nil,
        age_hint: String? = nil,
        country_code: String? = nil,
        language_code: String? = nil,
        multi_country_mode: Bool = false,
        notes: String? = nil,
        status: SessionStatus = .created,
        created_at: Date = Date(),
        updated_at: Date = Date()
    ) {
        self.session_id = session_id
        self.species = species
        self.temp_animal_id = temp_animal_id
        self.location_text = location_text
        self.coat_color = coat_color
        self.age_hint = age_hint
        self.country_code = country_code
        self.language_code = language_code
        self.multi_country_mode = multi_country_mode
        self.notes = notes
        self.status = status
        self.created_at = created_at
        self.updated_at = updated_at
    }
}

public struct Candidate: Identifiable, Codable {
    public var id: String { candidate_id }
    public let candidate_id: String
    public let name: String
    public let species: Species
    public var country_code: String?
    public var language_code: String?
    public var active: Bool

    public init(
        candidate_id: String,
        name: String,
        species: Species,
        country_code: String? = nil,
        language_code: String? = nil,
        active: Bool = true
    ) {
        self.candidate_id = candidate_id
        self.name = name
        self.species = species
        self.country_code = country_code
        self.language_code = language_code
        self.active = active
    }
}

public struct RankedCandidate: Identifiable, Codable {
    public var id: String { candidate_id }
    public let candidate_id: String
    public let name: String
    public let score: Double
    public let uncertainty_flag: Bool
    
    // Phase 3
    public let confidence: String?
    public let explanation: String?
    public let source: String?
    public let model_version: String?

    public init(
        candidate_id: String,
        name: String,
        score: Double,
        uncertainty_flag: Bool,
        confidence: String? = nil,
        explanation: String? = nil,
        source: String? = nil,
        model_version: String? = nil
    ) {
        self.candidate_id = candidate_id
        self.name = name
        self.score = score
        self.uncertainty_flag = uncertainty_flag
        self.confidence = confidence
        self.explanation = explanation
        self.source = source
        self.model_version = model_version
    }
}

public struct Trial: Identifiable, Codable {
    public var id: String { trial_id }
    public let trial_id: String
    public let session_id: String
    public let candidate_id: String
    public let variant_text: String
    public let voice_type: String
    public let modulation_type: String
    public let played_at: Date
    public var manual_flag: String?
}

public struct ReactionFeatures: Codable {
    public let gaze_shift_score: Double
    public let ear_motion_score: Double
    public let head_turn_score: Double
    public let posture_change_score: Double
    public let approach_score: Double
    public let vocalization_score: Double
    public let repeatability_score: Double
    
    // Phase 3
    public let latency_ms: Int?
    public let manual_score: Double?
    public let model_version: String?

    public init(
        gaze_shift_score: Double,
        ear_motion_score: Double,
        head_turn_score: Double,
        posture_change_score: Double,
        approach_score: Double,
        vocalization_score: Double,
        repeatability_score: Double,
        latency_ms: Int? = nil,
        manual_score: Double? = nil,
        model_version: String? = nil
    ) {
        self.gaze_shift_score = gaze_shift_score
        self.ear_motion_score = ear_motion_score
        self.head_turn_score = head_turn_score
        self.posture_change_score = posture_change_score
        self.approach_score = approach_score
        self.vocalization_score = vocalization_score
        self.repeatability_score = repeatability_score
        self.latency_ms = latency_ms
        self.manual_score = manual_score
        self.model_version = model_version
    }
}

public struct KnownAnimal: Identifiable, Codable {
    public var id: String { known_animal_id }
    public let known_animal_id: String
    public let species: Species
    public let true_name: String
    public var aliases: [String]?
    public var sex: String?
    public var age_range: String?
    public var breed: String?
    public var coat_color: String?
    public var owner_consent_status: String
    public var created_at: String?

    enum CodingKeys: String, CodingKey {
        case known_animal_id = "id"
        case species
        case true_name
        case aliases
        case sex
        case age_range
        case breed
        case coat_color
        case owner_consent_status
        case created_at
    }

    public init(
        known_animal_id: String,
        species: Species,
        true_name: String,
        aliases: [String]? = nil,
        sex: String? = nil,
        age_range: String? = nil,
        breed: String? = nil,
        coat_color: String? = nil,
        owner_consent_status: String = "agreed",
        created_at: String? = nil
    ) {
        self.known_animal_id = known_animal_id
        self.species = species
        self.true_name = true_name
        self.aliases = aliases
        self.sex = sex
        self.age_range = age_range
        self.breed = breed
        self.coat_color = coat_color
        self.owner_consent_status = owner_consent_status
        self.created_at = created_at
    }
}

public struct ImageUploadResponse: Codable {
    public let image_id: String
    public let upload_url: String
}

public struct ImageAnnotation: Codable {
    public let image_id: String
    public var pose_type: String?
    public var image_quality: String?
    public var annotations: String?
}

public struct TrainingSession: Identifiable, Codable {
    public var id: String { training_session_id }
    public let training_session_id: String
    public let known_animal_id: String
    public let speaker_type: String
    public let environment_type: String
    public let purpose: String
    public var status: String
    public var created_at: String?
    public var completed_at: String?

    enum CodingKeys: String, CodingKey {
        case training_session_id = "id"
        case known_animal_id
        case speaker_type
        case environment_type
        case purpose
        case status
        case created_at
        case completed_at
    }

    public init(
        training_session_id: String,
        known_animal_id: String,
        speaker_type: String,
        environment_type: String,
        purpose: String,
        status: String = "created",
        created_at: String? = nil,
        completed_at: String? = nil
    ) {
        self.training_session_id = training_session_id
        self.known_animal_id = known_animal_id
        self.speaker_type = speaker_type
        self.environment_type = environment_type
        self.purpose = purpose
        self.status = status
        self.created_at = created_at
        self.completed_at = completed_at
    }
}

public struct TrainingTrial: Identifiable, Codable {
    public var id: String { trial_id }
    public let trial_id: String
    public let training_session_id: String
    public let called_name: String
    public let is_true_name: Bool
    public let is_alias: Bool
    public let modulation_type: String
    public let playback_source: String
    public var manual_reaction: String?

    enum CodingKeys: String, CodingKey {
        case trial_id = "id"
        case training_session_id
        case called_name
        case is_true_name
        case is_alias
        case modulation_type
        case playback_source
        case manual_reaction
    }

    public init(
        trial_id: String,
        training_session_id: String,
        called_name: String,
        is_true_name: Bool,
        is_alias: Bool,
        modulation_type: String,
        playback_source: String,
        manual_reaction: String? = nil
    ) {
        self.trial_id = trial_id
        self.training_session_id = training_session_id
        self.called_name = called_name
        self.is_true_name = is_true_name
        self.is_alias = is_alias
        self.modulation_type = modulation_type
        self.playback_source = playback_source
        self.manual_reaction = manual_reaction
    }
}

public struct MLModelInfo: Identifiable, Codable {
    public var id: String { model_id }
    public let model_id: String
    public let version: String
    public let description: String?
    public let accuracy_score: Double?
    public let status: String
    public let download_url: String

    enum CodingKeys: String, CodingKey {
        case model_id = "id"
        case version
        case description
        case accuracy_score
        case status
        case download_url
    }
}

public struct ModelUpdateCheckResponse: Codable {
    public let update_available: Bool
    public let latest_version: String
    public let download_url: String
}

public struct SyncJobStatus: Codable {
    public let sync_job_id: String
    public let status: String
    public let progress: Double
    public let result_metadata: SyncJobMetadata?

    public struct SyncJobMetadata: Codable {
        public let new_version: String?
        public let accuracy_score: Double?
        public let download_url: String?
        public let error: String?
    }
}


public struct Country: Identifiable, Codable {
    public var id: String { code }
    public let code: String
    public let name: String
    public let default_language: String

    public init(code: String, name: String, default_language: String) {
        self.code = code
        self.name = name
        self.default_language = default_language
    }
}

public struct Language: Identifiable, Codable {
    public var id: String { code }
    public let code: String
    public let name: String

    public init(code: String, name: String) {
        self.code = code
        self.name = name
    }
}

public struct DictionaryItem: Identifiable, Codable {
    public let id: Int
    public let country_code: String
    public let language_code: String
    public let species: Species
    public let name: String
    public let reading: String?
    public let category: String
    public let popularity_rank: Int

    public init(id: Int, country_code: String, language_code: String, species: Species, name: String, reading: String? = nil, category: String, popularity_rank: Int) {
        self.id = id
        self.country_code = country_code
        self.language_code = language_code
        self.species = species
        self.name = name
        self.reading = reading
        self.category = category
        self.popularity_rank = popularity_rank
    }
}

public struct TTSProfile: Identifiable, Codable {
    public let id: String
    public let language_code: String
    public let voice_name: String
    public let gender: String
    public let speaking_rate: Double
    public let pitch: Double
    public let engine_type: String

    public init(id: String, language_code: String, voice_name: String, gender: String, speaking_rate: Double, pitch: Double, engine_type: String) {
        self.id = id
        self.language_code = language_code
        self.voice_name = voice_name
        self.gender = gender
        self.speaking_rate = speaking_rate
        self.pitch = pitch
        self.engine_type = engine_type
    }
}

public struct TTSPreviewResponse: Codable {
    public let audio_url: String
    public let status: String
}


