import Foundation
import SwiftUI
import UserNotifications

@MainActor
class LiveMatchViewModel: ObservableObject {
    static let shared = LiveMatchViewModel()
    
    @Published var matches: [Match] = []
    @Published var commResponse: CommResponse?
    @Published var selectedMatchId: String? {
        didSet {
            if let id = selectedMatchId {
                UserDefaults.standard.set(id, forKey: "selectedMatchId")
                Task { await loadCommentary(for: id) }
            } else {
                UserDefaults.standard.removeObject(forKey: "selectedMatchId")
                commResponse = nil
            }
        }
    }
    
    private var timer: Timer?
    private var lastSeenActivityIds: Set<String> = []
    
    private init() {
        self.selectedMatchId = UserDefaults.standard.string(forKey: "selectedMatchId")
        requestNotificationPermissions()
    }
    
    func startPolling() {
        // Load initial data
        loadData()
        
        // Also load commentary if a match was previously selected
        if let id = selectedMatchId {
            Task { await loadCommentary(for: id) }
        }
        
        let interval = SettingsManager.shared.pollingInterval
        
        // Start polling based on settings
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.loadData()
            }
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    func loadData() {
        Task {
            do {
                let allFetched = try await APIService.shared.fetchLiveMatches()
                let fetchedMatches = allFetched.filter { $0.isLive == true }
                
                // For notifications, we want to see what's new
                if !self.matches.isEmpty {
                    self.checkForNewActivities(in: fetchedMatches)
                } else {
                    // Initialize last seen IDs on first load
                    for match in fetchedMatches {
                        for activity in match.activities {
                            self.lastSeenActivityIds.insert(activity.id.uuidString)
                        }
                    }
                }
                
                self.matches = fetchedMatches
            } catch {
                print("Error loading live data: \(error)")
            }
        }
    }
    
    func loadCommentary(for matchId: String) async {
        do {
            let response = try await APIService.shared.fetchCommentary(matchId: matchId)
            self.commResponse = response
        } catch {
            print("Error loading commentary: \(error)")
        }
    }
    
    private func checkForNewActivities(in newMatches: [Match]) {
        for match in newMatches {
            for activity in match.activities {
                // In a real app we'd use a unique ID from the backend. 
                // Since our model uses a generated UUID, let's use the timestamp + description as a unique key for now.
                let uniqueKey = "\(activity.timestamp ?? "")-\(activity.description)"
                
                if !lastSeenActivityIds.contains(uniqueKey) {
                    lastSeenActivityIds.insert(uniqueKey)
                    
                    // Trigger notification for significant events
                    if isSignificantEvent(activity) && SettingsManager.shared.notificationsEnabled {
                        scheduleNotification(for: activity, match: match)
                    }
                }
            }
        }
    }
    
    private func isSignificantEvent(_ activity: Activity) -> Bool {
        let type = activity.type.lowercased()
        return type == "wicket" || type == "six" || type == "four" || type == "milestone"
    }
    
    private func requestNotificationPermissions() {
        guard Bundle.main.bundleIdentifier != nil else {
            print("Notifications disabled: No bundle identifier found (running as CLI executable).")
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permissions granted.")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func scheduleNotification(for activity: Activity, match: Match) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        
        let content = UNMutableNotificationContent()
        
        let prefix: String
        switch activity.type.lowercased() {
        case "wicket": prefix = "🟥 WICKET!"
        case "six": prefix = "💥 SIX!"
        case "four": prefix = "✨ FOUR!"
        case "milestone": prefix = "🏆 MILESTONE!"
        default: prefix = "🏏 UPDATE:"
        }
        
        content.title = "\(prefix) - \(match.title)"
        content.body = activity.description
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
