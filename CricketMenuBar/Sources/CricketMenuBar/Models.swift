import Foundation

struct CricketData: Codable {
    let matches: [Match]
}

struct Match: Codable, Identifiable {
    let id: String
    let title: String
    let score: String // Keep for fallback or simple display
    
    // New fields for rich header
    let tournament: String?
    let isLive: Bool?
    let team1: TeamInfo?
    let team2: TeamInfo?
    let statusText: String?
    let matchFormat: String?
    
    let commentary_chunks: [String]
    let activities: [Activity]
}

struct TeamInfo: Codable {
    let name: String
    let abbreviation: String
    let score: String?
    let overs: String?
    let status: String?
    let imageId: Int?
}

struct Activity: Codable, Identifiable {
    var id: UUID { UUID() }
    let type: String
    let event: String
    let description: String
    let commentary_snippet: String
    let timestamp: String?
    
    enum CodingKeys: String, CodingKey {
        case type, event, description, commentary_snippet, timestamp
    }
}
