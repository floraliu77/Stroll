# Location research: POIs near 300 S Craig

Researched coordinates, trigger radii and content for 13 points of interest in Oakland.
This folder is **data and docs only**. Nothing here is loaded by the app or changes the build.

Last updated: 2026-11-07, by MJ.

## What's here

| File | What it is |
|---|---|
| `poi-locations.json` | All 13 POIs in the same shape as `Shared/Content/stroll-content.json` (PR #2), plus `standingSpot`, `sources` and `notes` for each |
| `CraigStLoop.gpx` | A 2.5 km loop from 300 S Craig that passes all 13 POIs, for Xcode's location simulator |

The same content is in the Google Sheet **Stroll POIs near 300 S Craig** (tabs `POIs` and `Nearby`),
in the format from `docs/location-research-guide.md`, minus the `cue` column since round 1 has no cues.
Ask MJ for the link.

## The coordinates

Every coordinate is **where you'd stand to see the thing**, not the middle of the building.

| id | Category | Lat, Lon | Radius | Notes |
|---|---|---|---|---|
| `mellon-columns` | Architecture | 40.446630, -79.951100 | 40 m | Fifth Ave sidewalk. Tall buildings, so expect GPS drift. |
| `dippy` | Natural history | 40.443553, -79.951498 | 30 m | OSM and Google agree within 6 m. |
| `song-to-nature` | Public art | 40.441995, -79.951900 | 35 m | Open plaza, good GPS. |
| `forbes-wall` | History | 40.441250, -79.952660 | 40 m | The wall is about 60 m long, so the radius is wider. |
| `serra-carnegie` | Public art | 40.444050, -79.949250 | 35 m | Art museum's Forbes Ave plaza. |
| `st-nicholas-cathedral` | History | 40.444600, -79.950250 | 30 m | S Dithridge St, by the columned porch. |
| `bellefield-hall` | History | 40.445380, -79.951450 | 30 m | Bellefield Ave, by the arched doorway. |
| `heinz-chapel` | Architecture | 40.445150, -79.952300 | 25 m | West side, so it doesn't overlap Bellefield Hall. |
| `cathedral-of-learning` | Architecture | 40.444323, -79.953191 | 50 m | Open lawn, wider radius. |
| `the-hiker` | History | 40.441852, -79.950492 | 25 m | Statue on Schenley Dr by the Frick Fine Arts Building. |
| `first-baptist-church` | Architecture | 40.447693, -79.952977 | 40 m | Bellefield Ave and Bayard St. |
| `st-paul-cathedral` | Architecture | 40.447010, -79.949800 | 40 m | Fifth Ave sidewalk. |
| `fairfax-apartments` | Architecture | 40.447000, -79.948120 | 30 m | Across Fifth Ave from the building. |

- **No two trigger circles overlap.** Every pair is at least 10 m apart at the edges, so two POIs
  never buzz from the same spot.
- **Will they work with GPS?** Phone GPS on a city street usually drifts 5 to 20 m, more near tall
  buildings. The 25 to 50 m radii allow for that. They're a starting point: do one real walk, then
  shrink a radius if it buzzes too early, or grow it if it gets missed.
- `coordinateStatus` is `"researched"`: checked against map data, Google Maps and photos, but
  nobody has walked it with the app yet.

### The 4 existing POIs vs. the placeholders in PR #2

| id | Placeholder in PR #2 | Researched | Off by |
|---|---|---|---|
| `mellon-columns` | 40.4462, -79.9512 | 40.446630, -79.951100 | about 50 m |
| `dippy` | 40.4436, -79.9497 | 40.443553, -79.951498 | about 150 m |
| `song-to-nature` | 40.4417, -79.9520 | 40.441995, -79.951900 | about 35 m |
| `forbes-wall` | 40.4428, -79.9566 | 40.441250, -79.952660 | about 370 m |

## How to use this once PR #2 is merged

1. **Coordinates for the 4 existing POIs:** copy `coordinate` and `triggerRadiusMeters` into
   `stroll-content.json`, and change `coordinateStatus` from `"placeholder"` to `"researched"`.
2. **Text fixes for 3 of the existing POIs** (see below): update the text, then re-record those clips.
3. **The 9 new POIs** need three more things before they can play on the watch:
   - an image set in `Resources/Assets.xcassets`, named by `id` (photo and credit are in `photoCredit`)
   - Carolyn audio (`web-prototype/tools/make-voice.mjs`). `audio` is `null` until then.
   - an entry in `pois`, and in `demoWalk.order` if it should be in the demo
4. Leave out `standingSpot`, `sources` and `notes` if the app's format doesn't use them.

## Fact checks and text fixes

Every fact was checked against at least one source besides Wikipedia: Pitt, Carnegie Museums,
CMU, SAH Archipedia, the Historical Marker Database, SABR and others. Each POI's sources are in
`sources`.

Three of the original POIs had lines that didn't match their sources. The fixed text is in
`poi-locations.json`. **These 4 clips need re-recording:**

| Clip | Was | Now | Why |
|---|---|---|---|
| `f1-story1` | "about 60 tons" | "about 62 tons" | CMU's history of the building |
| `f1-story3` | "reaches six stories underground to bedrock, to keep lab experiments steady" | "reaches three stories underground" | CMU and SAH Archipedia both say three. No source for the bedrock or lab reason. |
| `f2-story2` | "on July 4, 1899" | "around the Fourth of July, 1899" | Sources disagree on July 3 vs. July 4 |
| `f4-story3` | "in the lobby of Posvar Hall" | "inside Posvar Hall" | It's set in the floor inside the building |

The new POIs' text is a draft. Please review it.

## Photos

`photoCredit` has a photo for every POI. Most are from Wikimedia Commons (CC0 or CC BY-SA).
Two are from Flickr under **CC BY-NC-SA 2.0** (non-commercial, credit required): Serra's
*Carnegie* (a copyrighted sculpture, so Commons has no photos of it) and The Hiker. That's fine for
a class project, but swap them for team photos if Stroll ever ships. Several photos are portrait,
so crop them to landscape with the detail in the middle.

## Desk testing with the GPX file

In Xcode, add `CraigStLoop.gpx` to the project, then pick it under
*Debug → Simulate Location* while running. It walks the loop at about 1.3 m/s. At walking pace,
the 13 POIs fire over about 28 minutes.

Note: the round 1 **demo walk** is paced by `demoWalk` timings, not by this route. The GPX file is
for testing real Core Location triggering later.

## Where the coordinates came from

- **OpenStreetMap**, read through the official OSM API on 2026-11-07. OSM data is under the
  ODbL, so the app needs a "© OpenStreetMap contributors" credit somewhere, like an About line
  in Settings.
- **Google Maps** was used only to double-check. Google's terms don't allow storing its
  coordinates, so none are saved here. Where both have the spot, they agree within 2 to 20 m.
- **Photos** (Wikimedia Commons, Flickr) were used to confirm details: where the Serra tower
  stands on the plaza, which way St. Nicholas's porch and Bellefield Hall's carved doorway face,
  and St. Paul's five doorways.
