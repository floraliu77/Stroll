# Change log

What changed in Stroll since our **v1 submission (P3.3 Prototype v1)**. Newest first. Each item
links to the pull request it came from.

**Adding to this log:** put each change under **Unreleased** in the same pull request that makes
it. When a new TestFlight build goes out, rename **Unreleased** to that build number and date,
and start a new **Unreleased** section above it.

Groups: **Added** (new features), **Changed** (works differently now), **Fixed** (bugs),
**Content** (places, words, voice), **Design**, **Docs and tools**.

## Unreleased

### Content
- **North Squirrel Hill drafts.** Prompts, reveals, stories and alt text for 8 places in north
  Squirrel Hill, with sources and on-site checks, plus photos for 6 of them. Not in the app yet.

### Design
- New Figma page **"v2 – Design system (from code)"** in AxD-Stroll. It matches the app as
  built, with 21 documented components, 16 text styles, corner radius, spacing and shadow
  variables, and AA category colors. Each section notes what changed since v1. The v1 page is
  kept as it was.

### Docs and tools
- Rewrote the README for the current app: how to install and try it, demo walk vs. real
  location, what's real and what's faked, and how the team works.
- Started this change log.

## Build 3 (version 0.1), Nov 16, 2026

This is the TestFlight build after v1. The v1 submission described build 0.1 (1).

### Added
- **Set walks.** A new **Walks** tab with guided routes past a few stops, in order. It has a
  walk list, a walk detail screen with a route preview, and a full-screen walk in progress
  with a progress card, the next stop's spoken direction, and Pause, End walk and Skip this
  stop. The watch shows a Next stop screen. There are two walks: *Oakland* and *Steeples and
  Spires*. At Concept Lock we switched to freeform only; now both kinds of walk are available.
  ([#8](https://github.com/floraliu77/Stroll/pull/8))
- **Real location.** Places now trigger when you actually walk within their radius. You turn
  it on in Developer tools → Real location; the timed demo walk is still the default.
  In v1, triggering was always a mock run.
  ([#6](https://github.com/floraliu77/Stroll/pull/6))
- **First-launch setup.** An intro ("How a stroll works"), then one screen each for
  location, walking sessions on the watch and notifications. Each asks only after you tap
  Allow, and **Not now** skips it.
  ([#9](https://github.com/floraliu77/Stroll/pull/9), restyled in
  [#11](https://github.com/floraliu77/Stroll/pull/11))
- **Journal.** Cards open to show the photo, the story and **Listen again**. A set walk is
  one card that opens to its stops, and stops you didn't reach show as "Mystery location".
  ([#10](https://github.com/floraliu77/Stroll/pull/10))
- **No-headphones choice and Read mode.** If no earbuds are connected when you start, Stroll
  asks whether to connect them, read the text instead (Read mode), or play out loud. This
  covers the "voice off" option that v1 had in Figma only.
  ([#11](https://github.com/floraliu77/Stroll/pull/11))
- **Photo credits.** The settings button on the map → About → Photo credits lists every photo's photographer,
  license and source. The credit under each Journal photo links to its source.
  ([#12](https://github.com/floraliu77/Stroll/pull/12))

### Changed
- **Accessibility and ethics audit.** Category colors now pass WCAG AA contrast and stay
  distinct with color blindness. Every photo has alt text, VoiceOver stays quiet while the
  guide is talking, and wording is more inclusive.
  ([#10](https://github.com/floraliu77/Stroll/pull/10),
  [#11](https://github.com/floraliu77/Stroll/pull/11))
- **Permissions are asked during setup**, not when you first tap Start Exploring.
  ([#9](https://github.com/floraliu77/Stroll/pull/9))
- **Prompts describe what to look for** instead of starting with "Look at…".
  ([#10](https://github.com/floraliu77/Stroll/pull/10))
- **Set-walk lines follow the streets** instead of drawing straight lines between stops.
  ([#10](https://github.com/floraliu77/Stroll/pull/10))
- **The map opens on your location** and shows how many places are on screen.
  ([#11](https://github.com/floraliu77/Stroll/pull/11))
- **Beige app icon and Explore panel** to match the Figma design.
  ([#6](https://github.com/floraliu77/Stroll/pull/6),
  [#11](https://github.com/floraliu77/Stroll/pull/11))

### Fixed
- **Music resumes after a place.** It now pauses during narration and comes back afterwards.
  ([#6](https://github.com/floraliu77/Stroll/pull/6))
- **Notifications after a watch start.** Notifications are asked for during setup, so
  "something nearby" alerts can appear even if the walk is started from the watch.
  ([#9](https://github.com/floraliu77/Stroll/pull/9))
- **One Journal entry per place.** A place can no longer appear twice.
  ([#11](https://github.com/floraliu77/Stroll/pull/11))

### Content
- **From 4 places to 43.**
  - 8 new places came from Makaela's location research, with researched coordinates and
    trigger radii ([#4](https://github.com/floraliu77/Stroll/pull/4),
    [#6](https://github.com/floraliu77/Stroll/pull/6)).
  - 31 more came from Mara's 40-place drafts
    ([#7](https://github.com/floraliu77/Stroll/pull/7),
    [#11](https://github.com/floraliu77/Stroll/pull/11)).
  - In v1, only a couple of places were in the TestFlight build.
- **New voice.** Every line is now in the Kokoro **Sky** voice, generated for free on our own
  Mac, instead of ElevenLabs. The skip and end-of-walk lines are new too.
  ([#6](https://github.com/floraliu77/Stroll/pull/6),
  [#10](https://github.com/floraliu77/Stroll/pull/10),
  [#11](https://github.com/floraliu77/Stroll/pull/11))
- **Place research.**
  - A 100-place shortlist and 40 ready places with photos and credits
    ([#6](https://github.com/floraliu77/Stroll/pull/6)).
  - Draft prompts, reveals, stories and alt text for those 40 places, including online fact
    checks ([#7](https://github.com/floraliu77/Stroll/pull/7)).

### Docs and tools
- **Content file.** All place content moved into one file, `Shared/Content/stroll-content.json`,
  so adding a place doesn't need code.
  ([#2](https://github.com/floraliu77/Stroll/pull/2))
- **Checks.** `Tools/check-walk-model.sh` now checks the content file, the exploring session,
  set walks and the setup screens.
  ([#2](https://github.com/floraliu77/Stroll/pull/2),
  [#8](https://github.com/floraliu77/Stroll/pull/8),
  [#9](https://github.com/floraliu77/Stroll/pull/9))
- **New tools.** `Tools/voice/generate.py` makes Sky-voice clips, and `Tools/walk-routes.sh`
  draws walk lines along the streets.
  ([#6](https://github.com/floraliu77/Stroll/pull/6),
  [#10](https://github.com/floraliu77/Stroll/pull/10))

## v1 submission (build 0.1 (1))

The starting point for this log, as described in our P3.3 Prototype v1 submission:

- **Apps and access:**
  - Native SwiftUI apps for iPhone and Apple Watch on TestFlight, plus a web demo on Vercel.
  - Freeform exploring, with category filters.
- **What worked:**
  - Wrist haptics on a real watch.
  - Narration through earbuds that pauses music.
- **What was faked or limited:**
  - Places played as a mock run, not by location.
  - The TestFlight build had only a couple of places.
  - The voice was ElevenLabs.
  - The voice-off option was only in Figma.
