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
