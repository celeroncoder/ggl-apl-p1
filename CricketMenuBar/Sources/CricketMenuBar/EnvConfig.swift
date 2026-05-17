import Foundation

struct EnvConfig {
    static let shared = EnvConfig()
    
    private var variables: [String: String] = [:]
    
    private init() {
        loadDotEnv()
    }
    
    private mutating func loadDotEnv() {
        // Read the .env file from the project root
        let envPath = "/Users/khushalbhardwaj/g/celeroncoder/apl/p1/CricketMenuBar/.env"
        
        guard let content = try? String(contentsOfFile: envPath, encoding: .utf8) else {
            print("Warning: Could not load .env file at \(envPath)")
            return
        }
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            let parts = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                variables[key] = value
            }
        }
    }
    
    func value(for key: String) -> String? {
        // Fallback to process environment variables if not found in .env
        return variables[key] ?? ProcessInfo.processInfo.environment[key]
    }
    
    var rapidApiKey: String {
        return value(for: "RAPIDAPI_KEY") ?? ""
    }
    
    var rapidApiHost: String {
        return value(for: "RAPIDAPI_HOST") ?? "cricbuzz-cricket.p.rapidapi.com"
    }
}
