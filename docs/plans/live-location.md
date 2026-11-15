# Plan: real GPS for the free walk

Owner: Flora · Branch: `flora/demo-walk` · Written Nov 12

Goal: points of interest come up when someone **actually walks near them**, instead of the
demo walk's timer. Phone and watch keep working the same way (the phone speaks, the watch
buzzes and mirrors).

**Not in this plan** (future work, not started): Routes, and importing places from Wikipedia or
other sources. This plan also doesn't edit the Explore map screen (Mara's).

## What gets built

| # | Piece | What it does | Estimate |
|---|---|---|---|
| 1 | **Real GPS source** | A new location source that feeds the phone's real position into the existing place detection (the same slot the demo walk uses). Ignores fixes less accurate than about 30 m, which tall buildings cause. | ~1.5 h |
| 2 | **Works with the phone locked** | Adds the "location" background mode and a background location session for the length of the walk. iOS shows a blue location indicator. Permission stays "While Using the App"; nobody is asked for "Always". | ~0.5 h |
| 3 | **30-second gap** | After a stop ends (Keep exploring or Skip), no new place comes up for 30 seconds. If the person is still near a place when the gap ends, it comes up then; if they've walked on, it's let go. Pausing also pauses the gap. | ~0.75 h |
| 4 | **Demo / Real switch** | In Developer tools: **Demo walk** or **Real location**, remembered between launches, only changeable before a walk starts. Also shows live GPS accuracy and the distance to the nearest place, for outdoor testing. | ~1 h |
| | **Checks and builds** | Mac checks for the gap and the switch; phone and watch builds compile. | ~1 h |
| | **Total build time** | | **~4–5 h** |

Then Flora tests it: a quick check at a desk with the switch, then **one outdoor walk in Oakland
(~45–60 min)** past the current places to see where they trigger.

## Files touched (all on Flora's branch)

- New: `Phone/Walk/LiveLocation.swift`
- `Phone/Walk/ExploreSession.swift` (choose the source before a walk starts)
- `Phone/Walk/PhoneGuide.swift`, `Phone/StrollApp.swift` (which source the app uses)
- `Phone/DeveloperToolsView.swift` (the switch and GPS readout)
- `Phone/Info.plist` (background location)
- `Tools/ExploreSessionCheck/main.swift` (checks)

## What it depends on

- **Place coordinates and trigger radii** come from the content file. The 4 current places have
  rough coordinates (about ±10 m) and 40 m radii, which is enough to start. Makaela's exact
  coordinates can replace them later with no code changes.
- **Indoors, GPS is unreliable**, so use the Demo walk switch for demos and desk testing.

## Later, not today

- A simulated walk file (GPX) so Xcode can "walk" the phone past places at a desk.
- Tuning radii and the gap after outdoor tests.
- Routes reuse this real GPS source; they only limit which places can trigger.
