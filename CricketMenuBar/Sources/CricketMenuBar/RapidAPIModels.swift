import Foundation

struct RapidAPIResponse: Codable {
    let typeMatches: [TypeMatch]?
}

struct TypeMatch: Codable {
    let matchType: String?
    let seriesMatches: [SeriesMatch]?
}

struct SeriesMatch: Codable {
    let seriesAdWrapper: SeriesAdWrapper?
}

struct SeriesAdWrapper: Codable {
    let seriesId: Int?
    let seriesName: String?
    let matches: [RapidMatch]?
}

struct RapidMatch: Codable {
    let matchInfo: MatchInfo?
    let matchScore: MatchScore?
}

struct MatchInfo: Codable {
    let matchId: Int?
    let seriesName: String?
    let matchDesc: String?
    let matchFormat: String?
    let state: String?
    let status: String?
    let team1: RapidTeam?
    let team2: RapidTeam?
}

struct RapidTeam: Codable {
    let teamId: Int?
    let teamName: String?
    let teamSName: String?
    let imageId: Int?
}

struct MatchScore: Codable {
    let team1Score: TeamScore?
    let team2Score: TeamScore?
}

struct TeamScore: Codable {
    let inngs1: Innings?
    let inngs2: Innings?
    
    var displayScore: String {
        var parts: [String] = []
        if let i1 = inngs1 {
            parts.append("\(i1.runs ?? 0)/\(i1.wickets ?? 0)")
        }
        if let i2 = inngs2 {
            parts.append(" & \(i2.runs ?? 0)/\(i2.wickets ?? 0)")
        }
        return parts.joined()
    }
    
    var displayOvers: String {
        if let i2 = inngs2 {
            return "\(i2.overs ?? 0.0)v"
        } else if let i1 = inngs1 {
            return "\(i1.overs ?? 0.0)v"
        }
        return ""
    }
}

struct Innings: Codable {
    let runs: Int?
    let wickets: Int?
    let overs: Double?
}

// MARK: - Commentary Endpoint Models

struct CommResponse: Codable {
    let comwrapper: [ComWrapper]?
    let miniscore: MiniScore?
    let inningsid: Int?
}

struct ComWrapper: Codable {
    let commentary: Commentary?
}

struct Commentary: Codable {
    let commtxt: String?
    let timestamp: Int64?
    let overnum: Double?
    let eventtype: String?
    let ballnbr: Int?
    let commentaryformats: [CommentaryFormat]?
}

struct CommentaryFormat: Codable {
    let type: String?
    let value: [CommentaryFormatValue]?
}

struct CommentaryFormatValue: Codable {
    let id: String?
    let value: String?
}

extension Commentary {
    /// Returns commtxt with all `id` tokens (e.g. "B0$") replaced by their `value`.
    var resolvedText: String {
        var text = commtxt ?? ""
        guard let formats = commentaryformats else { return text }
        for group in formats {
            for item in group.value ?? [] {
                if let id = item.id, let val = item.value {
                    text = text.replacingOccurrences(of: id, with: val)
                }
            }
        }
        return text
    }
}

struct MiniScore: Codable {
    let batsmanstriker: Batsman?
    let batsmannonstriker: Batsman?
    let bowlerstriker: Bowler?
    let crr: Double?
    let rrr: Double?
    let lastwkt: String?
    let curovsstats: String?
    let inningsnbr: String?
    let partnership: String?
    let inningsscores: InningsScores?
}

struct InningsScores: Codable {
    let inningsscore: [InningsScore]?
}

struct InningsScore: Codable {
    let runs: Int?
    let wickets: Int?
    let overs: Double?
    let batteamshortname: String?
    let target: Int?
}

struct Batsman: Codable {
    let name: String?
    let runs: Int?
    let balls: Int?
    let fours: Int?
    let sixes: Int?
    let strkrate: String?
}

struct Bowler: Codable {
    let name: String?
    let overs: String?
    let wickets: Int?
    let runs: Int?
    let economy: String?
}

