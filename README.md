# Stroll

Audio-first walking guide for Apple Watch and earbuds. The watch buzzes when you reach
something worth noticing, shows a photo of it, and tells you what to look for.

This repo has two apps for moderated field tests:

- **Stroll (watch)**: what the participant wears. Same flow as the web prototype:
  buzz → photo preview → directions → *Tell me more* / *Skip* → story (with *Next stop*) →
  *Continue walking*. Real wrist haptics and narration in Bluetooth earbuds.
- **Stroll Remote (iPhone)**: what the moderator holds. Tap a find as the participant
  reaches it to buzz their watch. A live status shows what they're seeing, and the session
  log records each tap with a timestamp. You can export the log.

The participant's watch must be **paired to the moderator's iPhone**, because the two apps
talk over WatchConnectivity. Use a team-owned watch and give it to each participant.

```
Shared/          Walk content (text matches the prototype) and iPhone↔watch messages
Watch/           Watch app: walk logic, screens, narration, haptics, workout session
Phone/           iPhone remote
Resources/       26 narration clips (Carolyn, ElevenLabs) and photos, for the watch
Tools/           check-walk-model.sh: runs the walk logic through a scripted walk on a Mac
web-prototype/   The browser prototype used in the first round of interviews
```

## Set up (one time)

Needs a Mac with **Xcode 15 or later**, an iPhone (iOS 17+) and an Apple Watch
(watchOS 10+) paired to it, plus AirPods or other Bluetooth earbuds.

1. **Generate the Xcode project.**
   ```bash
   brew install xcodegen
   xcodegen
   open Stroll.xcodeproj
   ```
   If XcodeGen isn't an option, see [Without XcodeGen](#without-xcodegen) below.
2. **Sign both apps with your team.** In Xcode, select the **Stroll** project, then for
   both the *StrollRemote* and *StrollWatch* targets, open *Signing & Capabilities*:
   - set **Team** to your developer team;
   - change the bundle identifiers from `org.example.stroll.remote` and
     `org.example.stroll.remote.watchkitapp` to your own prefix. The watch ID must stay the
     iPhone ID plus `.watchkitapp`. Update `WKCompanionAppBundleIdentifier` in the
     StrollWatch build settings to match.

   To skip this step on future regenerations, put your Team ID and prefix in `project.yml`.
3. **Check the watch target's capabilities** (*StrollWatch → Signing & Capabilities*):
   **HealthKit**, and **Background Modes** with *Workout processing* and *Audio* turned on.
   They come from `project.yml`; with automatic signing, Xcode registers them on the App ID.
4. **Turn on Developer Mode** on the iPhone and the watch (Settings → Privacy & Security →
   Developer Mode), then connect the iPhone to the Mac.
5. **Run.** Choose the *StrollRemote* scheme and your iPhone, and press Run. This installs
   the watch app too. The first install to the watch can take several minutes. To debug the
   watch directly, choose the *StrollWatch* scheme and the watch as the destination.

## Running a session

1. Give the participant the watch and earbuds. On the watch, open **Stroll** and tap
   **Get ready**. The first time, watchOS asks for Health access (needed to keep the app
   running with the wrist down) and to pick the earbuds.
2. On the iPhone, open **Stroll Remote**. The status should say *Connected* and
   *Keep walking: ready for the next find*.
3. Walk the route. When the participant reaches each spot, tap that find in **Buzz a find**.
   The next find is highlighted. Tapping a find mid-story interrupts the story, so you can
   recover if someone lingers.
4. After find 4, the watch says *Walk complete*. Use **Export** in the session log to save
   or share the log, then **Reset** for the next participant.

Nothing is saved to the Health app: the watch runs a walking session only to stay awake.

## Testing without the watch

`Tools/check-walk-model.sh` compiles the walk logic for a Mac and runs it through a
scripted walk with a fake narrator: buzz, Tell me more, Next stop, Skip, Pause, Reset, and
a trigger mid-story. It needs only the Swift command-line tools, not Xcode.

```bash
Tools/check-walk-model.sh
```

## Without XcodeGen

1. In Xcode: *File → New → Project → watchOS → App*, product name **Stroll**, interface
   SwiftUI, and choose **Watch App with New Companion iOS App**.
2. Delete the template's Swift files and asset catalogs. Then drag in:
   - `Watch/` (except `Info.plist`), `Resources/` and `Shared/` → the watch app target
   - `Phone/` and `Shared/` → the iOS app target
3. In the watch target, add the **HealthKit** capability and **Background Modes**
   (*Workout processing*, *Audio*). Under *Info*, add the two Health usage descriptions
   from `project.yml`.
4. Set the deployment targets to iOS 17 and watchOS 10, and the Swift language version to 5.

## Next steps

- **Location triggers**: fire each find from Core Location near its coordinates, with the
  remote kept as an override. Tune the distances on the real route, because GPS drifts near
  tall buildings.
- **Field journal**: the participant-facing iPhone screens from the web prototype.
- **App icon**: `Resources/Assets.xcassets` and `Phone/Assets.xcassets` hold a placeholder.
- **TestFlight**: archive the *StrollRemote* scheme (*Product → Archive*) and upload it.
  Team members in App Store Connect can install builds without App Review.
