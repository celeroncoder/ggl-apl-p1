import SwiftUI

@MainActor
class SettingsManager: ObservableObject {
    @AppStorage("pollingInterval") var pollingInterval: Double = 60.0
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    
    static let shared = SettingsManager()
}

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("Data Updates")) {
                Picker("Refresh Interval", selection: $settings.pollingInterval) {
                    Text("10 Seconds").tag(10.0)
                    Text("30 Seconds").tag(30.0)
                    Text("60 Seconds").tag(60.0)
                    Text("5 Minutes").tag(300.0)
                }
            }
            
            Section(header: Text("Notifications")) {
                Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}
