# Reference: ethical audit fixes (P3.4), Nov 12

This branch is a **reference** for the three fixes in our P3.4 ethical audit. It builds on
`flora/demo-walk`. Nothing here is merged or in TestFlight yet, and it hasn't been built or run on
a device. Treat it as a starting point: build it in Xcode, test it on a phone, then merge what works.

## 1. Category colors pass contrast and stay distinct with color blindness

`Phone/Theme.swift`. Update the Figma "Stroll" variables to match.

| Category | Before | After | On paper | On white |
|---|---|---|---|---|
| Architecture | #B5652B | #A15C17 | 4.66:1 | 5.17:1 |
| Natural history | #3F7D4F | #1F5144 | 8.16:1 | 9.06:1 |
| Public art | #7A55A6 | #8A4FB0 | 4.95:1 | 5.49:1 |
| History | #2E6A8E | #1E4167 | 9.43:1 | 10.46:1 |

All pass WCAG 2.2 AA (4.5:1). Each color has its own lightness, so the four stay tell-apart with
red-green color blindness. Each pin also has its own icon.

## 2. Prompts describe the thing, and photos have real alt text

- `Shared/Content/stroll-content.json`: the four prompts are reworded to describe the point of
  interest instead of saying "look", "spot" or "find". Each POI has a new `altText`.
- `Shared/StrollContent.swift`: `altText` added to `POI` (optional).
- `Phone/Explore/ExploringPanel.swift`: VoiceOver reads `altText` for the stop photo.
- `Phone/Journal/JournalView.swift`: VoiceOver reads the name plus `altText` in the Journal.

**To do before merging:** regenerate the four prompt clips (`f1-prompt` to `f4-prompt`) with the
new wording. Until then the on-screen text and the audio won't match. Do it in the same pass as the
Mellon "62 tons" fix.

## 3. No audio out loud without asking

- `Phone/Walk/PhoneGuide.swift`: new `ListeningMode`. When Read only is on, clips still run at volume
  0, so timing, Pause and Replay work the same. The `.playback` audio setting is unchanged, so
  narration still works with the screen locked.
- `Phone/Explore/ExploreView.swift`: tapping Start Exploring with no headphones connected asks
  "No headphones connected": **Play out loud**, **Read only**, or Cancel.
- `Phone/Explore/ExploringPanel.swift`: the Exploring panel shows "Read only, no sound" when it's on.
- Listen again in the Journal still plays out loud, since it's a deliberate tap.
- Unchanged: the walk still pauses if headphones disconnect mid-walk.

## Test checklist

- [ ] Builds in Xcode (StrollRemote scheme)
- [ ] `Tools/check-walk-model.sh` passes
- [ ] Start with no headphones: the dialog appears. Read only: no sound, text advances, Pause works
- [ ] Start with AirPods connected: no dialog, plays as before
- [ ] VoiceOver on the stop sheet and Journal reads the new descriptions
- [ ] Screenshots for the audit's before/after
