# Stroll: round 1 plan

Briefing for anyone (person or AI assistant) working on Stroll: Mara (design lead), Flora (Xcode /
watch), MJ, and whoever handles location. It summarizes what exists, what has been decided, and
what is open. Read it before changing code or proposing data formats.

Last updated: 2026-11-07. Where this plan and older docs disagree, **this plan wins** (team
decision). Key points: exploring only, no moderator remote, a scripted **demo walk** for testing.

Related docs:
- `docs/WATCH-EXPLORING-CHANGES.md`: exact watch-app changes for exploring mode (Flora).
- `docs/location-research-guide.md`: how to research and write up new stops (Flora's guide).

---

## 1. What Stroll is

Stroll is an audio-first walking guide for **Apple Watch + earbuds**, with an **iPhone companion
app**. When you're near a *point of interest* (POI), the watch buzzes, shows a photo preview,
and a narrator tells you what to look for. You tap **Tell me more** to hear the story, or
**Skip**. Everything you find goes into a **Journal** on the phone.

Round 1 content: the **4 existing POIs in Oakland, Pittsburgh, PA** (§4). New stops around
300 S Craig St are being researched with `docs/location-research-guide.md` for later rounds.

---

## 2. Round 1 plan (decided)

- **Exploring only.** Users tap **Start Exploring** and wander; any POI can come up in any order.
  Pre-set walks are deferred (Figma screens 05–07 wait).
- **No moderator remote.** The separate "Stroll Remote" app and the phone-to-phone link are
  dropped. The iPhone app is the **real participant companion app**, paired with the watch.
- **Lent devices.** Participants use a team-owned iPhone + Apple Watch (+ earbuds). Test settings
  can be visible on those devices; nothing needs hiding from real users yet.
- **Demo walk if real location isn't ready.** The team is unsure about both POI coordinates and
  reliable live detection. So the companion app gets a **Demo walk** setting: after Start
  Exploring, the phone plays a scripted route and triggers the POIs, wherever the participant
  actually is. Testing may happen outside Oakland; the team will explain to participants that the
  photos won't match their surroundings.
- **No session log / timestamps** for research. (The Journal still shows when something was found.)
- **No direction ("cue") lines** in round 1: a buzz goes photo preview → prompt. Each prompt stands
  alone ("Spot the dinosaur outside the museum…").
- Each POI buzzes **once per session**, only for **enabled categories**, with **no minimum gap**
  between buzzes (product decision). Users can turn the **buzz haptic off** in Settings.

### Demo walk pacing (decided)

Paced to the participant, not a fixed clock, so a buzz never cuts off a story:

- **First buzz:** ~20 s after Start Exploring.
- **Each next buzz:** a random **30–60 s** after the participant is done with the previous POI
  (Skip finished, story finished, or they tapped Keep exploring). Randomness keeps it from feeling
  mechanical.
- **Pause** on the watch pauses the countdown.
- **After the last POI:** no more buzzes; the session continues until the participant taps **End**.
- **Order:** fixed, defined in the data file (doesn't have to be 1-2-3-4).
- Heads-up: with 4 POIs a demo lasts roughly **5–7 minutes**. For longer sessions, add POIs or
  widen the gap.

Implementation note: the demo should **feed fake locations into the same detection code** that will
later read real GPS (not call the watch directly). Then every demo also tests the real trigger
logic, and switching to live location is a setting, not a rebuild.

### Build order

1. **Watch exploring mode** (Flora; see `docs/WATCH-EXPLORING-CHANGES.md`).
2. **Shared POI data file** with placeholder coordinates + the demo route.
3. **Companion app, round-1 screens** in SwiftUI from Figma: Welcome, Explore map, Explore – walk
   started, Explore – walk in progress, Journal (expandable cards), Settings (Buzz on wrist,
   category toggles, **Demo walk**).
4. **Location/trigger engine** with two inputs: demo route (now) and Core Location (later).
5. **Journal** saved on the phone from what happens on the watch.
6. **Live location** once coordinates and detection are reliable.

All work happens in the **GitHub repo `floraliu77/Stroll`**. The old zip and Mara's original
`~/Stroll` folder are out of date.

---

## 3. Where things are

| What | Where |
|---|---|
| Code | GitHub repo **`floraliu77/Stroll`** (branch `main`). Builds with the team's Apple developer account; bundle IDs `com.teamgreen.stroll.*`. |
| iPhone app designs | Figma **AxD-Stroll**: https://www.figma.com/design/ugzO5w47ET8hP77zIDJvPM/AxD-Stroll, page **"iPhone app – MVP"** (screens 01–09) |
| Web prototype (first interview round) | `web-prototype/` |
| Narration clips | `Resources/Audio/` (26 clips, ElevenLabs voice "Carolyn"; `skip.m4a`, rest `.mp3`) |
| Photos | `Resources/Assets.xcassets/` (Wikimedia Commons; credits in `web-prototype/app.js`) |

### Repo layout (as of the scaffold)

```
Shared/          Content + phone↔watch messages (both apps)
  Finds.swift          The 4 POIs: text, category, image, clip names (NO coordinates yet)
  RemoteMessages.swift Codable messages over WatchConnectivity
Watch/           watchOS app (SwiftUI)
  WalkModel.swift      State machine. Entry point for a POI: trigger(find:)
  WalkView.swift       Watch screens
  NarrationPlayer.swift  Plays clips to Bluetooth earbuds
  WatchServices.swift  Haptics, HKWorkoutSession (keeps app alive), WatchConnectivity
Phone/           iPhone app. Currently the old moderator remote; becomes the companion app.
                 Keep the iOS target: the watch app installs through it.
Tools/           check-walk-model.sh: runs WalkModel through a scripted walk on a Mac
project.yml      XcodeGen spec (iOS 17 / watchOS 10, Swift 5 mode)
```

---

## 4. Current POIs

| # | Name | Category | Where (street-level description) |
|---|---|---|---|
| 1 | Mellon Institute columns | Architecture | Fifth Ave & Bellefield Ave (Mellon Institute, 4400 Fifth Ave) |
| 2 | Dippy the dinosaur | Natural history | Outside Carnegie Museum of Natural History, Forbes Ave |
| 3 | "A Song to Nature" fountain | Public art | Schenley Plaza, by the Frick Fine Arts Building |
| 4 | Forbes Field wall | History | Roberto Clemente Dr, by Mazeroski Field |

Text (prompt, reveal, 3 story lines; plus the now-unused cue) is in `Shared/Finds.swift`.
Categories (fixed for MVP): **Architecture, Natural history, Public art, History**.

---

## 5. Product decisions (reflected in Figma; ask Mara before changing)

- **Map pins show only the category**, never name or photo. Tapping a pin does nothing. Names and
  photos appear only in the Journal after a find.
- Free-walk button: **"Start Exploring"**. Wording throughout: **"points of interest"**.
- Watch accent colour is **Stroll green** (`#2F6B4F`, Flora's change), matching the iPhone designs.
- **Not in round 1:** direction ("cue") lines, walking order, "nearby places" on the map, and a
  narration transcript. (Flora's guide mentions these; they're kept for later rounds.)
- Category filter chips on the map; category toggles in Settings limit pins *and* buzzes.
- **"Buzz on wrist"** toggle in Settings (narration still plays when off).
- Journal cards expand to show the photo, full story, and where/when it was found; skipped finds
  hide the story and "Listen again".
- The deferred pre-set walk is titled just **"Oakland"** (code still says "Oakland: Things You've Walked Past").

---

## 6. Geolocation work (not blocking round 1)

Thanks to the demo walk, this can proceed in parallel. Suggested deliverables:

1. **Coordinates for the 4 POIs**: the best viewing spot, plus a suggested trigger radius. Note
   anything that affects triggering (the Forbes Field wall is long; the fountain is in an open
   plaza; tall buildings on Fifth Ave → GPS drift).
2. **POI data format** shared by both apps, replacing the hard-coded `Walk.finds`, including the
   demo route. Content is authored in the **Google Sheet** described in
   `docs/location-research-guide.md` (`Stops` tab) and converted into this file; round 1 ignores
   the `cue` column and the `Nearby` tab. Starting point for the app's file (adjust freely):

   ```json
   {
     "pois": [{
       "id": "dippy",
       "name": "Dippy the dinosaur",
       "category": "natural-history",
       "lat": 0.0, "lon": 0.0,
       "triggerRadiusMeters": 40,
       "image": "dippy",
       "photoCredit": { "author": "", "license": "", "url": "" },
       "lines": {
         "prompt": "Spot the dinosaur outside the museum. Look closely: is it bone, or something else?",
         "reveal": "It's a life-size fiberglass copy.",
         "story": ["…", "…", "…"]
       },
       "audio": { "prompt": "f2-prompt", "reveal": "f2-reveal", "story": ["f2-story1", "f2-story2", "f2-story3"] }
     }],
     "demoWalk": { "order": ["dippy", "mellon-columns", "forbes-wall", "song-to-nature"], "firstBuzzSeconds": 20, "gapSeconds": [30, 60] },
     "walks": []
   }
   ```

   If pre-set walks return, direction lines belong to a **walk stop**, not the POI.
3. **More POIs + licences.** Candidates: OpenStreetMap (Overpass; ODbL, which requires attribution
   and share-alike), Wikidata (CC0), Wikimedia Commons geotagged photos (per-file licences),
   WPRDC (City of Pittsburgh public art, historic markers; check each dataset), PHLF plaques.
   Every POI also needs written prompt/reveal/story and recorded audio.
4. **Live triggering** (recommendations to validate): Core Location on the iPhone; `CLMonitor`
   (iOS 17+) or region monitoring; **max ~20 monitored regions**, so watch the nearest ~20 and
   refresh as the user moves; radius ~30–50 m, tuned on real streets; respect category toggles;
   once per session; "While Using" + background updates during an active session (avoid "Always").
5. **Desk testing:** Xcode can replay GPX routes; the demo walk route can double as one.

---

## 7. Open questions

- How many POIs for later rounds, and how dense?
- What the companion should show after the last demo POI (e.g. "You've found everything nearby").
- Whether to store a session's route at all (privacy).

---

## 8. Practical notes

- Mara is a designer; explain technical trade-offs in plain language and give a recommendation.
- Don't push to the shared repo or change the plan above without the team's say-so.
- Narration voice: ElevenLabs "Carolyn" (voice ID `4rgssJ1pg3E9c0U78Iid`, model `eleven_v4`).
  Generator script: `web-prototype/tools/make-voice.mjs` (needs the user's own key in
  `ELEVENLABS_API_KEY`; never paste keys into chat).
