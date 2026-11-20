# Drillside 🏝️⛏️

A cozy, gamified habit & focus app for iPhone. Build daily momentum with the **DRILL** method, then spend what you earn on your own little island, where **Bitsy the mole** hangs out with the props you place.

- **Island:** an isometric island drawn live in SwiftUI `Canvas`, with a day/night cycle, campfire glow and companions. Bitsy walks to your props on her own (pathfinding) and uses them.
- **DRILL:** habits and focus blocks grouped under five pillars: **D**efine · **R**outine · **I**terate · **L**earn · **L**ock-in. You can rename the pillars in Settings.
  - Schedules: daily, every N days, or N× per week. Streaks are tracked.
  - Reorder habits with Edit. You can check off up to **2 days back**.
  - Tap any habit to start the **Focus Timer**. Work/break/rounds are configurable, and each completed minute pays **+1 XP + 1 🐚**.
- **Log:** a 60-second daily retro with **What went well**, **What went wrong** and a one-line fix.
  - Views: timeline, 13-week consistency heatmap, and trends (focus chart, weak habits, pillar balance, recurring friction).
- **Shop:** buy props and companions and expand the island from 6×6 to 9×9.
  - **Edit Mode:** drag props around, or place items from inventory.
  - **Reset Layout:** refund your shells, or return everything to inventory.
- **Settings:** pillar names, timer defaults, a local daily reminder, theme, and **JSON export/import** backups.

## Privacy & constraints
- 100% local: everything is stored in **SwiftData** on device.
- No network calls, accounts, analytics, ads or subscriptions.
- **No iCloud/CloudKit or other entitlements**, so free-Apple-ID sideloading works.
- No third-party dependencies. Built only with SwiftUI, SwiftData, Swift Charts and UserNotifications.
- iOS 17.0+, iPhone, portrait.

## Get the app (unsigned .ipa)
Every push to `main` runs **Build unsigned IPA** (`.github/workflows/build-ipa.yml`). To install:
1. Open the latest successful run under **Actions → Build unsigned IPA**.
2. Download the **Drillside-unsigned-ipa** artifact and unzip it to get `Drillside-unsigned.ipa`.
3. Sign and install it with **AltStore**, **SideStore** or **Sideloadly** using your Apple ID.
   - With a free Apple ID, apps must be re-signed every 7 days. AltStore/SideStore can refresh them automatically.

You can also start a build by hand from the Actions tab (**Run workflow**).

## Build locally
Open `Drillside.xcodeproj` in Xcode 16 or later, pick your team under *Signing & Capabilities*, and run.
- The project uses Xcode 16 *folder-synced groups*: any file added under `Drillside/` or `DrillsideTests/` is picked up automatically, so the project file never needs regenerating.

```bash
# unit tests
xcodebuild test -project Drillside.xcodeproj -scheme Drillside -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Project layout
```
Drillside/
  App/        app entry, tab root, router
  Models/     SwiftData models (Profile, Habit, FocusSession, LogEntry, PlacedProp)
  Logic/      day keys, scheduling/streak rules, economy, catalog, game actions, backup, notifications
  Art/        vector art for props, companions and Bitsy (GraphicsContext)
  Island/     island engine (projection, pathfinding, rendering) + view
  Drill/ Focus/ Log/ Shop/ Settings/   feature screens
DrillsideTests/   unit tests for rules, economy and the focus timer
docs/mockup.html  the original interactive HTML mock-up
```
