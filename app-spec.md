# App Specification: Cricket Menu Bar (macOS)

## 1. Overview
A lightweight macOS menu bar application that provides real-time cricket scores and event updates. The app lives in the system status bar, offering glanceable scores and a detailed activity timeline via a popup UI, along with system-level notifications for key match events.

## 2. Core Features
- **Glanceable Status Bar Score**: Real-time score (e.g., `IND 184/4 (17.2)`) displayed directly in the macOS menu bar.
- **Activity Timeline Popover**: A custom `NSPopover` containing a scrollable feed of recent match activities (wickets, boundaries, milestones).
- **Smart Notifications**: Push notifications for critical events (Wickets, 4s, 6s, 50/100s, Match Start/Finish).
- **Polling Service**: Background service to fetch and diff live commentary/scores at configurable intervals (default 60s).
- **Match Selection**: UI to choose between multiple live matches.

## 3. Tech Stack
- **Language**: Swift 6.0+
- **Frameworks**: 
    - **AppKit**: For `NSStatusItem`, `NSStatusBar`, and `NSPopover`.
    - **SwiftUI**: For the rich UI inside the Popover and Settings.
    - **UserNotifications**: For system alerts.
- **Networking**: `URLSession` with `Async/Await`.
- **Concurrency**: `DispatchSourceTimer` for background polling.
- **Persistence**: `UserDefaults` for user preferences and last-seen event IDs.

## 4. UI/UX Design

### 4.1 Menu Bar (Status Item)
- **Idle State**: 🏏 (Default Icon)
- **Active State**: `[Short Team Names] [Score] ([Overs])` 
    - Example: `IND 184/4 (17.2)`
- **Interaction**: Single click opens the Popover.

### 4.2 Activity Popover (SwiftUI)
- **Header**: Match Title (e.g., "IND vs AUS - T20 World Cup"), Current Score (Large), Run Rate, and Required Run Rate.
- **Activity Feed**: 
    - **Event Cards**: Distinctive styling for different event types.
        - **Wicket**: Red border/icon, batsman name, and fall of wicket details.
        - **Six/Four**: Highlighted badges, bowler/batsman info.
        - **Milestone**: Golden/Star icon for 50s/100s.
    - **Commentary Text**: Short snippet of the latest commentary line.
- **Footer**: "Settings" (Gear icon), "Refresh" button, and "Quit" option.

### 4.3 Notifications
- **Title**: Event Type (e.g., "💥 SIX!", "🟥 WICKET!")
- **Body**: Concise detail (e.g., "Virat Kohli hits a massive six over long-on off Cummins.")
- **Sound**: Optional custom cricket-themed sound (e.g., bat-ball contact).

## 5. Technical Architecture

### 5.1 Data Polling & Extraction
1. **Fetch**: Query the Cricbuzz/Cricket API endpoint for match details and commentary.
2. **Diff**: Compare the latest `commentaryId` or timestamp against the locally stored `lastEventId`.
3. **Parse**: Extract event types using regex or keyword matching from the commentary text.
4. **Dispatch**: 
    - Update the `ScoreViewModel` (UI update).
    - Trigger `NotificationService` (if event is new and significant).
    - Append to `ActivityHistory` (Popover update).

### 5.2 App Lifecycle
- `LSUIElement = true`: Ensures the app doesn't show in the Dock or `Cmd+Tab`.
- Background execution enabled to ensure polling continues while the popover is closed.

## 6. Development Phases (MVP)
1. **Phase 1**: Project setup, Menu Bar `NSStatusItem` integration with static data.
2. **Phase 2**: Networking layer and basic score polling.
3. **Phase 3**: SwiftUI Popover with a simple list of activities.
4. **Phase 4**: Event detection logic and System Notifications.
5. **Phase 5**: Settings (Refresh interval, notification toggles) and Polish.

## 7. Potential Constraints & Risks
- **API Reliability**: Reliance on third-party unofficial APIs may lead to breaking changes.
- **Rate Limiting**: Polling too frequently might trigger IP blocks.
- **Battery Impact**: Frequent networking and UI updates should be optimized for macOS power management.
