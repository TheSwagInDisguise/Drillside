# Drillside 🏝️⛏️

A cozy, gamified habit & focus app for iPhone. Build daily momentum with the **DRILL** method, then spend what you earn on your own little island, where **Bitsy the mole** hangs out with the props you place.

- **Island:** an isometric island drawn live in SwiftUI `Canvas`, with a real **day–night cycle** that follows your clock and the season.
  - There's a golden sunrise and sunset, a moving sun and moon, and stars at night. Every light source switches on at dusk and lights up its surroundings.
  - Nine companions live on the island.
  - Bitsy walks to your props on her own (pathfinding) and uses them.
  - Pinch to zoom and drag to pan; that's how you get around islands up to 16×16.
- **DRILL:** habits and focus blocks grouped under five pillars: **D**efine · **R**outine · **I**terate · **L**earn · **L**ock-in. You can rename the pillars in Settings.
  - Schedules: daily, every N days, or N× per week. Streaks are tracked.
  - Reorder habits with Edit. You can check off up to **2 days back**.
  - Tap any habit to start the **Focus Timer**. Work/break/rounds are configurable, and each completed minute pays **+1 XP + 1 🐚**.
  - A running session shows up as a **Live Activity** in the Dynamic Island and on the Lock Screen.
- **Log:** a 60-second daily retro with **What went well**, **What went wrong** and a one-line fix.
  - Views: timeline, 13-week consistency heatmap, and trends (focus chart, weak habits, pillar balance, recurring friction).
- **Shop:** 65 props across Nature, Cozy, Landmarks, Study, Lights and walkable Terrain tiles, plus 9 companions. Most unlock as you level up.
  - Prestige pieces go up to a hot air balloon and a Golden Bitsy statue at level 15.
  - Expand the island step by step from 6×6 to **16×16**. Each step costs more shells and needs a higher level.
  - **Edit Mode:** drag props around, or place items from inventory.
  - **Reset Layout:** refund your shells, or return everything to inventory.
- **Settings:** pillar names, timer defaults, a local daily reminder, theme, and **JSON export/import** backups.

## Privacy & constraints
- 100% local: everything is stored in **SwiftData** on device.
- No network calls, accounts, analytics, ads or subscriptions.
- **No iCloud/CloudKit or other entitlements**, so free-Apple-ID sideloading works.
- No third-party dependencies. Built only with SwiftUI, SwiftData, Swift Charts, ActivityKit/WidgetKit and UserNotifications.
- Live Activities are local-only (no push token), so they need no entitlement either.
- iOS 17.0+, iPhone, portrait.

## Get the app
Every push to `main` runs **Build unsigned IPA** (`.github/workflows/build-ipa.yml`). The workflow:
- runs the unit tests,
- archives the app with code signing turned off,
- publishes a normal **GitHub release** marked *Latest*, tagged `vX.Y.Z.BUILD` (for example `v1.2.0.4`), with `Drillside-vX.Y.Z.BUILD-unsigned.ipa` attached.

To install:
1. Open **[Releases](../../releases/latest)** and download the `.ipa`.
2. Sign and install it with **AltStore**, **SideStore** or **Sideloadly** using your Apple ID.
   - The app ships with a Live Activity extension, so it uses 2 of a free account's 10 App IDs per week.
   - Free Apple IDs need a re-sign every 7 days. AltStore/SideStore can refresh automatically.

Pull requests are only built and tested. They don't create releases.

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
DrillsideShared/  Live Activity attributes (compiled into the app and the widget extension)
DrillsideWidgets/ Live Activity UI: Dynamic Island + Lock Screen
DrillsideTests/   unit tests for rules, economy, catalogue and the focus timer
docs/mockup.html  the original interactive HTML mock-up
```
