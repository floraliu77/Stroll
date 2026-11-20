# Stroll

Stroll is a walking companion that helps you notice the places you walk past every day. It's
currently available in **Oakland, Pittsburgh**. Wander anywhere: when you're near a point of
interest, Stroll lets you know with a tap on your wrist or a buzz from your phone. It asks a short
question about the place, then shares the story behind it, as audio or text. Everything you
explore is saved in your field journal.

**Prototype v2** · iPhone app with an optional Apple Watch companion · Team: Flora, Mara, MJ

---

## How to open it

### Option A: TestFlight (easiest, no Mac needed)
1. On your iPhone, install **TestFlight** from the App Store.
2. Open the invite link from the team, then tap **Accept** and **Install**.
3. Open **Stroll**. The first launch shows a short intro and asks for location, notifications
   and (if you have a watch) Health. You can say "Not now" to any of them.
4. If your iPhone is paired with an Apple Watch, the watch app installs with it.

### Option B: Build from source (Mac with Xcode)
1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen), then in this folder run:
   ```bash
   xcodegen generate
   open Stroll.xcodeproj
   ```
2. Pick the **StrollRemote** scheme and your iPhone, and press Run. The watch app installs with it.
   (Signing team and bundle ID `com.teamgreen.stroll` are already set in `project.yml`.)
3. The project file is generated, so run `xcodegen generate` again after pulling new files.

### Trying it
- **You don't need to be in Oakland.** Stroll starts in **Demo mode**: points of interest come up
  on a timer wherever you are. Switch to **Real location** in Settings (the slider button on the
  map) → Walk mode.
- **Explore tab:** tap **Start Exploring**. The first place comes up after about 20 seconds.
- **Walks tab:** pick a set walk and tap **Start walk**.
- **No headphones?** Stroll asks first: connect them, **Read mode** (text only, no sound), or
  **Play out loud**.
- **Journal tab:** everything you explored or skipped, with walks grouped into one card.

## Which device

| | Needed? | Version |
|---|---|---|
| **iPhone** | Yes. The phone runs the walk, plays the audio and shows the text. | iOS 17 or later |
| **Apple Watch** | Optional. It buzzes, shows the photo and mirrors the buttons. | watchOS 10 or later, paired to the iPhone |
| **Headphones** | Optional. Any wired or Bluetooth headphones; or use Read mode or the speaker. | |

Building from source needs a Mac with Xcode 15 or later.

## What's still faked or unfinished

| Area | What's faked | Why |
|---|---|---|
| **Location** | **Demo mode is the default.** It feeds made-up positions on a timer into the same detection code that real GPS uses. Real location works (Settings → Walk mode) and was tested on an outdoor walk in Oakland: places triggered promptly as intended. | Lets anyone test anywhere, and lets us run sessions without walking the route each time. |
| **Content** | 39 of the 43 places are marked "needs review": facts come from Wikipedia and haven't all been checked on site. 3 map pins are estimated. | We drafted 31 places quickly from open sources to have enough to walk. |
| **Voice** | Every line is an AI voice (Kokoro, "Sky") generated on our Macs, a stand-in until the team picks a final voice. | Free, offline, and quick to regenerate when text changes. |
| **Photos** | From Wikimedia Commons, not our own. A few are low quality or don't quite show the detail asked about. Credited in Settings → Photo credits. | Free licences let us show every place now; our own photos come later. |
| **Area** | Oakland only. The "Oakland, Pittsburgh" pill at the top of the map looks like a search bar but does nothing yet. | Other cities are future work. |
| **Walks** | 2 set walks (Oakland, Steeples and Spires), 4 stops each. Routes are precomputed. | Enough to test the set-walk flow. |
| **Journal** | Saved on the phone only. No account, no sync, no sharing. | Privacy and scope: nothing leaves the device. |
| **Watch** | Starting from the watch can lag a moment before both devices update. | Known issue, parked. |

---

## Change log: since v1

**v1 (Nov 7)** was a watch-first prototype for moderated tests: the participant wore a team watch,
and a moderator on an iPhone "remote" tapped each of 4 places to buzz their watch. Narration
was pre-recorded in a different voice, and there was no map, journal or real location.

### v2 (Nov 7–16)

| What changed | Why |
|---|---|
| **The phone leads; the watch is optional.** The moderator remote is gone. Your own iPhone runs the walk, speaks the guide and shows the transcript; the watch mirrors it and either device's buttons work. | Most people don't own a watch, and a moderator tapping a remote doesn't scale beyond lab tests. |
| **Explore map and real location.** A map of places by category (names stay a surprise), a Demo/Real switch, and a quiet 30-second gap after each stop. The map opens on you at street level and counts only the places on screen. | Our users explore their own neighbourhood; a zoomed-out city map wasn't useful. |
| **Set walks** (Walks tab): routes along the streets, spoken directions between stops, and a walk demo mode. | Some people want a ready-made route rather than wandering. |
| **Field journal.** Every place appears the moment it's explored or skipped. Walks show as one card, with unvisited stops as "Mystery location". One entry per place outside walks. | People wanted to look back at what they found. |
| **43 places instead of 4**, in four categories, with photos, credits and alt text. | 4 places weren't enough for a real walk. |
| **One voice for everything** (Sky), with natural reading of years and initials. | The old recordings and the new lines didn't match. |
| **First-launch intro** and one screen per permission, in our beige, green and dark palette, with wording that doesn't assume any sense or device. | Asking for permissions with no context felt abrupt. |
| **Accessibility and ethics fixes** (see below). | From our ethical audit and critique. |
| **Developer tools** (slider button on the map): Demo/Real switch, GPS readout, bring up any place now, restart, photo credits. All text passes contrast in light and dark mode. | Needed to run test sessions smoothly. |

### What critique told us, and what we changed

**Ethical audit (P3.4, MJ).** We reviewed v2 against Universal Design and Design Justice:

| Finding | Who it harmed | What we changed |
|---|---|---|
| Category colours (architecture orange, natural history green) failed WCAG AA contrast. | People with low vision or reading in bright sun, which matters for an outdoor app. | New category colours that all pass 4.5:1 and differ in lightness, so they stay distinct with red-green colour blindness. |
| Questions said "look", "spot" or "find", and photos had no real description for VoiceOver. | Blind and low-vision walkers, and anyone walking in the dark. It assumed an "unmarked", sighted user. | Every question now **describes** the detail; every photo has alt text that doesn't give away the answer; VoiceOver stays quiet while the guide is speaking. |
| With no headphones, audio played out loud, even on silent, without asking. | Anyone in a quiet place; it overrode a choice they'd made. | Start now asks: connect headphones (starts by itself when they connect), **Read mode** (all text, no sound), or Play out loud. Headphones unplugged mid-walk pause the walk. |

**Our outdoor walk in Oakland** with Real location showed places triggering promptly, as
intended. The one problem was background music competing with the voice; now Stroll pauses other
music for each place and lets it resume afterwards.

**Our own testing on the phone and watch** also led to: removing grabber bars from panels that
can't be dragged (they looked interactive), Read mode showing the whole text at once instead of
timing it to an assumed reading speed, and dropping "earbuds" from the app's wording.

**Class team-to-team critique.** _MJ to update: what the other team found and how it shaped
these changes._

---

Building or editing the app? See [docs/DEVELOPING.md](docs/DEVELOPING.md).
