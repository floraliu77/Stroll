# Stroll

An audio-first walking guide for iPhone, Apple Watch and earbuds. Walk around Oakland,
Pittsburgh with your phone in your pocket. When you're near a point of interest, Stroll taps
your wrist (or buzzes your phone), shows a photo, and describes what to look for. Tap
**Tell me more** for the story, or **Skip** to keep walking. Everything you find is saved in
your **Journal**.

There are two ways to walk:

- **Explore (freeform):** wander anywhere. Any point of interest can come up.
- **Walks (set routes):** follow a short route past a few chosen stops, in order, with spoken
  directions between them.

Current build: **version 0.1, build 3** on TestFlight. What changed since our v1 submission is
in [CHANGELOG.md](CHANGELOG.md).

## Try it

### On an iPhone (TestFlight)

1. Accept the TestFlight invitation sent to your Apple ID email, then install **Stroll Walks**
   from TestFlight.
2. You need an **iPhone with iOS 17 or later**. An **Apple Watch** (watchOS 10+) paired to that
   iPhone and **earbuds** are optional but recommended. Without a watch, the phone buzzes
   instead. Without earbuds, Stroll asks whether to read the text instead or play out loud.
3. Open **Stroll**. The first time, a short setup explains how it works and asks for
   location, walking sessions on the watch (Health) and notifications. Each one can be
   skipped with **Not now**.
4. To explore, tap **Start Exploring** on the map, then put your phone away. To take a set
   walk, open the **Walks** tab, pick a walk and tap **Start walk**. Afterwards, open the
   **Journal** tab to see what you found.

**Demo walk vs. real location.** The app starts in **Demo walk** mode, so it works anywhere
(at a desk, or outside Oakland). Places come up on a timer, wherever you are: the first
after about 20 seconds, then one every 30–60 seconds (every 30 seconds on a set walk). To use your real position instead, tap the settings button (top right of
the map) → **Developer tools** → **Real location**, then walk to the places on the map.

### In a browser (backup demo)

If you can't install from TestFlight, open the web demo on any device (it's designed for an
iPhone screen): **[add Vercel demo link]**. In the web demo, location is simulated, you tap a
place to "arrive" at it, and no Apple Watch is needed.

## What's real and what's faked

| | Status |
|---|---|
| Location | **Real** with Real location turned on: places trigger when you walk within their radius (25–50 m, usually 30 m). **Faked** by default: the Demo walk plays places on a timer, wherever you are. |
| Watch haptics | **Real**: the Apple Watch taps your wrist and mirrors the phone. Tapping a button on either device updates both. |
| Narration | **Real** audio through earbuds or the phone, which pauses your music and resumes it afterwards. **Read mode** shows the text without sound. |
| Voice | **AI-generated**: every line uses the Kokoro "Sky" voice, generated free on our own Mac. The final voice isn't decided yet. |
| Places | **43 places** in North Oakland and 2 set walks. 39 places are marked *needs review*: their facts and coordinates come from research (Wikidata, OpenStreetMap, Wikimedia Commons) and haven't all been checked on site yet. |
| Photos | Real photos from Wikimedia Commons, credited under each Journal entry and in the settings button on the map → **About** → **Photo credits**. |

## Repository

```
Phone/           iPhone app: Explore map, Walks, Journal, first-launch setup, voice guide
Watch/           Apple Watch app: mirrors the phone, wrist taps, walking session
Shared/          Content file (places, walks, lines) and phone↔watch messages
Resources/       Narration clips and photos
Tools/           Checks and content tools (see below)
docs/            Plans, place research, content drafts
web-prototype/   Browser demo (also deployed on Vercel)
CHANGELOG.md     What changed since the v1 submission
```

All the place content is in one file, `Shared/Content/stroll-content.json`. To add or edit a
place, change that file. No Swift code needs to change.

## For the team

### Build and run from source

Needs a Mac with **Xcode 15 or later**.

```bash
brew install xcodegen
```

```bash
xcodegen
```

```bash
open Stroll.xcodeproj
```

The team ID and bundle IDs (`com.teamgreen.stroll`) are already set in `project.yml`. Choose the
**StrollRemote** scheme and your iPhone, and press Run. This also installs the watch app on
the paired watch. Turn on Developer Mode on both devices first (Settings → Privacy &
Security → Developer Mode).

To upload a TestFlight build, raise `CURRENT_PROJECT_VERSION` in `project.yml`, run
`xcodegen`, then choose **Product → Archive** in Xcode and upload it.

### Tools

| Command | What it does |
|---|---|
| `Tools/check-walk-model.sh` | Checks the content file (every clip, photo and category exists), then runs the exploring session, the set walks and the setup screens through scripted tests. Needs only the Swift command-line tools. Run it before every pull request. |
| `Tools/voice/generate.py` | Generates Sky-voice clips for any line without audio. Setup is in `docs/content-drafts/README.md`. |
| `Tools/walk-routes.sh` | Redraws a set walk's map line along the streets using Apple Maps walking directions. |

### How we work in Git

- Never push to `main`.
- One branch per task, named `yourname/task` (for example `mara/set-walks`).
- Open a pull request for every change, and run `Tools/check-walk-model.sh` first.
- Add a line to [CHANGELOG.md](CHANGELOG.md) under **Unreleased** in the same pull request.

### Design

The Figma file **AxD-Stroll** has the v1 screens on the "iPhone app – MVP" page and the
current components on the "v2 – Design system (from code)" page. Colors in
`Phone/Theme.swift` match the Figma variables.

## Credits

- Photos: Wikimedia Commons contributors, under CC0, CC BY and CC BY-SA licenses (full list
  in the app).
- Voice: [Kokoro](https://github.com/hexgrad/kokoro) (Apache 2.0), Sky voice.
- Built with help from Claude Code. Place research cross-checked against OpenStreetMap,
  Wikidata and Google Maps.
