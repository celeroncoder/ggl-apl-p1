import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case missingData
    case decodingError(Error)
}

final class APIService: Sendable {
    static let shared = APIService()
    
    private init() {}
    
    func fetchLiveMatches() async throws -> [Match] {
        let host = EnvConfig.shared.rapidApiHost
        let key = EnvConfig.shared.rapidApiKey
        
        guard !key.isEmpty else {
            print("Error: RAPIDAPI_KEY is not set in .env")
            return []
        }
        
        // This is a common endpoint for Cricbuzz RapidAPI.
        // You might need to change this based on the exact API you subscribed to.
        guard let url = URL(string: "https://\(host)/matches/v1/live") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(key, forHTTPHeaderField: "x-rapidapi-key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            print("API Error: Status code \(httpResponse.statusCode)")
            if let errorStr = String(data: data, encoding: .utf8) {
                print("Error response: \(errorStr)")
            }
            throw APIError.invalidResponse
        }
        
        // Print raw JSON for debugging so you can see the structure
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw API Response received. Length: \(jsonString.count) bytes")
            // Uncomment the line below to see the full JSON in the console
            // print(jsonString)
        }
        
        do {
            let decoded = try JSONDecoder().decode(RapidAPIResponse.self, from: data)
            var liveMatches: [Match] = []
            
            // Traverse the nested structure
            if let typeMatches = decoded.typeMatches {
                for typeMatch in typeMatches {
                    if let seriesMatches = typeMatch.seriesMatches {
                        for series in seriesMatches {
                            if let wrapper = series.seriesAdWrapper, let rapidMatches = wrapper.matches {
                                for rMatch in rapidMatches {
                                    guard let info = rMatch.matchInfo else { continue }
                                    
                                    let team1Name = info.team1?.teamName ?? "T1"
                                    let team2Name = info.team2?.teamName ?? "T2"
                                    
                                    let t1ScoreStr = rMatch.matchScore?.team1Score?.displayScore
                                    let t2ScoreStr = rMatch.matchScore?.team2Score?.displayScore
                                    
                                    let t1Overs = rMatch.matchScore?.team1Score?.displayOvers
                                    let t2Overs = rMatch.matchScore?.team2Score?.displayOvers
                                    
                                    let team1Info = TeamInfo(name: team1Name,
                                                             abbreviation: info.team1?.teamSName ?? "",
                                                             score: t1ScoreStr,
                                                             overs: t1Overs,
                                                             status: nil,
                                                             imageId: info.team1?.imageId)

                                    let team2Info = TeamInfo(name: team2Name,
                                                             abbreviation: info.team2?.teamSName ?? "",
                                                             score: t2ScoreStr,
                                                             overs: t2Overs,
                                                             status: nil,
                                                             imageId: info.team2?.imageId)
                                    
                                    // Construct an overall score string as fallback
                                    var fallbackScore = ""
                                    if let s1 = t1ScoreStr { fallbackScore += "\(info.team1?.teamSName ?? "") \(s1) " }
                                    if let s2 = t2ScoreStr { fallbackScore += "v \(info.team2?.teamSName ?? "") \(s2)" }
                                    if fallbackScore.isEmpty { fallbackScore = "Match Scheduled" }
                                    
                                    let match = Match(
                                        id: "\(info.matchId ?? 0)",
                                        title: "\(team1Name) vs \(team2Name)",
                                        score: fallbackScore,
                                        tournament: info.seriesName,
                                        isLive: info.state == "In Progress",
                                        team1: team1Info,
                                        team2: team2Info,
                                        statusText: info.status,
                                        matchFormat: info.matchFormat,
                                        commentary_chunks: [], // We don't have commentary from this endpoint
                                        activities: [] // We don't have activities from this endpoint natively
                                    )
                                    
                                    liveMatches.append(match)
                                }
                            }
                        }
                    }
                }
            }
            
            return liveMatches
        } catch {
            print("Decoding error: \(error)")
            return []
        }
    }
    
    func fetchTeamImage(imageId: Int) async throws -> Data? {
        let host = EnvConfig.shared.rapidApiHost
        let key = EnvConfig.shared.rapidApiKey
        guard !key.isEmpty else { return nil }
        guard let url = URL(string: "https://\(host)/img/v1/i1/c\(imageId)/i.jpg?p=thumb") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(key, forHTTPHeaderField: "x-rapidapi-key")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }
        return data
    }

    func fetchCommentary(matchId: String) async throws -> CommResponse? {
        let host = EnvConfig.shared.rapidApiHost
        let key = EnvConfig.shared.rapidApiKey
        
        guard !key.isEmpty else { return nil }
        guard let url = URL(string: "https://\(host)/mcenter/v1/\(matchId)/comm") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(key, forHTTPHeaderField: "x-rapidapi-key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(CommResponse.self, from: data)
    }
}
