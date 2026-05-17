import SwiftUI

struct PopoverView: View {
    @ObservedObject private var viewModel = LiveMatchViewModel.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // SignInView()
            // Divider()

            if viewModel.matches.isEmpty {
                Text("Loading matches...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let selectedId = viewModel.selectedMatchId, let match = viewModel.matches.first(where: { $0.id == selectedId }) {
                headerView(match: match)
                
                Divider()
                
                // Sticky mini score panel
                if let mini = viewModel.commResponse?.miniscore {
                    MiniScorePanel(mini: mini)
                    Divider()
                }
                
                // Scrollable commentary feed
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if let comms = viewModel.commResponse?.comwrapper, !comms.isEmpty {
                            let items = comms.prefix(30).compactMap { $0.commentary }
                            ForEach(Array(items.enumerated()), id: \.offset) { idx, comm in
                                CommentaryTimelineRow(
                                    commentary: comm,
                                    isFirst: idx == 0,
                                    isLast: idx == items.count - 1
                                )
                            }
                        } else {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading commentary...")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 24)
                        }
                    }
                    .padding()
                }
                .mask(
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [.black.opacity(0), .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 16)
                        Rectangle().fill(Color.black)
                        LinearGradient(
                            colors: [.black, .black.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 16)
                    }
                )
            } else {
                matchListView
            }
            
            Divider()

            footerView
        }
        .frame(width: 360, height: 500)
        .onAppear {
            viewModel.startPolling()
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }
    
    var matchListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Live & Recent Matches")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ForEach(viewModel.matches) { match in
                    Button(action: {
                        withAnimation {
                            viewModel.selectedMatchId = match.id
                        }
                    }) {
                        MatchListRow(match: match)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    func headerView(match: Match) -> some View {
        VStack(spacing: 0) {
            // Top Title Bar
            HStack {
                Button(action: {
                    withAnimation {
                        viewModel.selectedMatchId = nil
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.trailing, 4)
                }
                .buttonStyle(.plain)
                
                Text(match.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            
            // Scoreboard Area
            VStack(spacing: 12) {
                // IPL & Live Status
                HStack {
                    Text(match.tournament ?? "Tournament")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if match.isLive == true {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Live")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Teams and Scores
                HStack(alignment: .center, spacing: 8) {
                    // Team 1: icon + score to the right
                    if let team1 = match.team1 {
                        HStack(spacing: 8) {
                            VStack(spacing: 4) {
                                TeamBadgeView(imageId: team1.imageId, fallbackColor: .blue)
                                    .frame(width: 28, height: 28)
                                Text(team1.abbreviation)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                if let score = team1.score {
                                    Text(score)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                        .contentTransition(.numericText())
                                        .animation(.snappy, value: score)
                                } else {
                                    Text("Yet to bat")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if let overs = team1.overs {
                                    Text(overs)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 4)
                    Text("vs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer(minLength: 4)
                    
                    // Team 2: score to the left + icon
                    if let team2 = match.team2 {
                        HStack(spacing: 8) {
                            VStack(alignment: .trailing, spacing: 2) {
                                if let score = team2.score {
                                    Text(score)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                        .contentTransition(.numericText())
                                        .animation(.snappy, value: score)
                                } else {
                                    Text("Yet to bat")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if let overs = team2.overs {
                                    Text(overs)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            VStack(spacing: 4) {
                                TeamBadgeView(imageId: team2.imageId, fallbackColor: .red)
                                    .frame(width: 28, height: 28)
                                Text(team2.abbreviation)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                
                // Bottom Match Info
                VStack(spacing: 4) {
                    if let statusText = match.statusText {
                        Text(statusText)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    if let format = match.matchFormat {
                        Text(format)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.thinMaterial)
        }
    }
    
    var footerView: some View {
        HStack {
            Button(action: {
                if let appDelegate = NSApp.delegate as? AppDelegate {
                    appDelegate.openSettings()
                }
            }) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button("Quit Cricket Score") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Mini Score Panel
struct MiniScorePanel: View {
    let mini: MiniScore
    
    var body: some View {
        VStack(spacing: 8) {
            // Batsmen
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let b1 = mini.batsmanstriker {
                        HStack(spacing: 4) {
                            Circle().fill(Color.yellow).frame(width: 6, height: 6)
                            Text(b1.name ?? "")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(b1.runs ?? 0)(\(b1.balls ?? 0))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: b1.runs ?? 0)
                        }
                    }
                    if let b2 = mini.batsmannonstriker {
                        HStack(spacing: 4) {
                            Circle().fill(Color.clear).frame(width: 6, height: 6)
                            Text(b2.name ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(b2.runs ?? 0)(\(b2.balls ?? 0))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: b2.runs ?? 0)
                        }
                    }
                }
                
                Divider().frame(height: 32)
                
                // Bowler
                if let bowler = mini.bowlerstriker {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(bowler.name ?? "")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("\(bowler.wickets ?? 0)/\(bowler.runs ?? 0) (\(bowler.overs ?? ""))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Current over - visual ball display
            if let curov = mini.curovsstats, !curov.isEmpty {
                OverBallsView(curovsstats: curov)
            }
            
            // CRR
            if let crr = mini.crr {
                HStack {
                    Text("CRR: \(String(format: "%.2f", crr))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if let rrr = mini.rrr, rrr > 0 {
                        Text("· RRR: \(String(format: "%.2f", rrr))")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    if let inn = mini.inningsnbr {
                        Text(inn)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Over Balls Visual
struct OverBallsView: View {
    let curovsstats: String
    
    /// Parse the curovsstats string into segments separated by "|"
    /// Each segment is one over, balls separated by spaces.
    /// e.g. "...  | 0 1 1 1 4 4  | 1 4 1 6"
    var overs: [[String]] {
        let segments = curovsstats
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0 != "..." && !$0.hasPrefix(".") }
        return segments.map { seg in
            seg.components(separatedBy: .whitespaces)
               .map { $0.trimmingCharacters(in: .whitespaces) }
               .filter { !$0.isEmpty }
        }.filter { !$0.isEmpty }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("This over")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(overs.enumerated()), id: \.offset) { overIdx, balls in
                        // Show a small separator between overs (except the first)
                        if overIdx > 0 {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 1, height: 20)
                                .padding(.horizontal, 2)
                        }
                        ForEach(Array(balls.enumerated()), id: \.offset) { _, ball in
                            BallView(value: ball)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BallView: View {
    let value: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(bgColor)
                .frame(width: 26, height: 26)
            
            if isDashed {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                    .foregroundColor(borderColor)
                    .frame(width: 26, height: 26)
            } else {
                Circle()
                    .strokeBorder(borderColor, lineWidth: 1)
                    .frame(width: 26, height: 26)
            }
            
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
        }
    }
    
    var label: String {
        switch value.uppercased() {
        case "W":  return "W"
        case "WD": return "Wd"
        case "NB": return "Nb"
        case "0":  return "•"
        default:   return value
        }
    }
    
    var bgColor: Color {
        switch value.uppercased() {
        case "W":       return Color.red.opacity(0.85)
        case "6":       return Color.green.opacity(0.85)
        case "4":       return Color.blue.opacity(0.75)
        case "WD":      return Color.yellow.opacity(0.2)
        case "NB":      return Color.orange.opacity(0.2)
        case "0":       return Color(NSColor.controlBackgroundColor)
        default:        return Color(NSColor.controlBackgroundColor)
        }
    }
    
    var borderColor: Color {
        switch value.uppercased() {
        case "W":  return Color.red
        case "6":  return Color.green
        case "4":  return Color.blue
        case "WD": return Color.yellow
        case "NB": return Color.orange
        case "0":  return Color.secondary.opacity(0.4)
        default:   return Color.secondary.opacity(0.4)
        }
    }
    
    var textColor: Color {
        switch value.uppercased() {
        case "W": return .white
        case "6": return .white
        case "4": return .white
        default:  return .primary
        }
    }
    
    var isDashed: Bool {
        return value.uppercased() == "WD" || value.uppercased() == "NB"
    }
}

// MARK: - Commentary Timeline
struct CommentaryTimelineRow: View {
    let commentary: Commentary
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Left rail: connector line + dot
            ZStack(alignment: .top) {
                // Vertical line
                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 1.5)
                    .padding(.top, isFirst ? 14 : 0)
                    .padding(.bottom, isLast ? nil : 0)

                // Dot
                Circle()
                    .fill(accentColor)
                    .frame(width: 9, height: 9)
                    .overlay(
                        Circle()
                            .stroke(Color(NSColor.controlBackgroundColor), lineWidth: 2)
                    )
                    .padding(.top, 9)
            }
            .frame(width: 14)

            VStack(alignment: .leading, spacing: 4) {
                // Metadata row: over • event tag • relative time
                HStack(spacing: 6) {
                    if let over = commentary.overnum, over > 0 {
                        Text("Over \(formatOver(over))")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    if let event = commentary.eventtype,
                       !event.isEmpty, event != "NONE" {
                        Text(event.capitalized)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(accentColor.opacity(0.18))
                            .foregroundColor(accentColor)
                            .cornerRadius(3)
                    }
                    Spacer()
                    if let ts = commentary.timestamp {
                        Text(relativeTime(from: ts))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Text(commentary.resolvedText)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 14)
        }
    }

    private func formatOver(_ over: Double) -> String {
        // Cricbuzz over format: integer.ball (e.g. 18.3 = 19th over, 3rd ball)
        let intPart = Int(over)
        let ball = Int((over * 10).rounded()) % 10
        return "\(intPart).\(ball)"
    }

    private func relativeTime(from ms: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var accentColor: Color {
        switch commentary.eventtype?.uppercased() ?? "" {
        case "WICKET": return .red
        case "SIX":    return .green
        case "FOUR", "BOUNDARY": return .blue
        default:       return .secondary
        }
    }
}

// MARK: - Team Badge
@MainActor
final class TeamBadgeCache: ObservableObject {
    static let shared = TeamBadgeCache()
    private var cache: [Int: NSImage] = [:]
    private var inflight: [Int: Task<NSImage?, Never>] = [:]

    func image(for imageId: Int) async -> NSImage? {
        if let img = cache[imageId] { return img }
        if let task = inflight[imageId] { return await task.value }
        let task = Task<NSImage?, Never> {
            do {
                if let data = try await APIService.shared.fetchTeamImage(imageId: imageId),
                   let img = NSImage(data: data) {
                    return img
                }
            } catch {
                print("Badge fetch failed for \(imageId): \(error)")
            }
            return nil
        }
        inflight[imageId] = task
        let result = await task.value
        inflight[imageId] = nil
        if let result { cache[imageId] = result }
        return result
    }
}

struct TeamBadgeView: View {
    let imageId: Int?
    let fallbackColor: Color
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "shield.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(fallbackColor)
            }
        }
        .task(id: imageId) {
            guard let imageId else { return }
            image = await TeamBadgeCache.shared.image(for: imageId)
        }
    }
}

struct MatchListRow: View {
    let match: Match
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(match.tournament ?? "Tournament")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
                if match.isLive == true {
                    Text("Live")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            HStack {
                Text(match.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
            }
            
            if !match.score.isEmpty {
                HStack {
                    Text(match.score)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                }
            }
        }
        .padding()
        .background(isHovered ? Color(NSColor.unemphasizedSelectedContentBackgroundColor) : Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .onHover { hovering in
            self.isHovered = hovering
        }
    }
}
