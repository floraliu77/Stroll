# Plan: arrival checkpoints

Owner: Flora (build) · Content: Mara · Written Nov 24, 2026

**Content to use:** [`docs/content-research/arrival-checkpoints.md`](../content-research/arrival-checkpoints.md)
has the new lines for all 56 places. This plan says how the app should use them.

## Why

In user testing, people were still trying to find the place when the guide moved on to the
question. Today an arrival goes buzz → photo (2.5 s) → prompt → **Tell me more / Skip**, so the
question starts before they've found the building.

The fix: split each prompt into a **locate** line and a **question**, and, where there's
something to find, **wait for the person to tap Found it** before asking the question.

Stroll is about learning, not a scavenger hunt. It's fine if a locate or help line hints at the
answer.

## The new arrival, step by step

Each place has an `arrival` kind. Everything before the locate line (buzz, notification, photo,
2.5 s preview) and everything after the question (Tell me more / Skip, reveal, story) stays as
it is today.

### "find": something to find (47 places)

1. Buzz, photo, preview: no change.
2. The **locate** line plays, then the shared **checkpoint** line: "Tap Found it when you see it."
3. The guide **waits**. Buttons: **Found it** (main), **Help me find it**, **Skip**, plus Replay
   and Pause.
4. **Found it** → the **question** plays. The buttons become **Tell me more / Skip**, as today.
5. **Help me find it** → the place's **help** line plays, then the checkpoint line again, and
   the waiting starts over. After that, the Help button goes away; Replay plays the help line
   again. If a place has no help line, the Help button isn't shown at all.
6. **No tap for 20 s** → the **nudge** line plays: "Still looking? Take your time. The photo on
   your phone can help." The guide keeps waiting.
7. **Still no tap 20 s after the nudge** → the **give-up** line plays ("No problem. I'll save this
   one in your Journal for later.") and the place is handled **exactly like Skip**: recorded as
   `.skipped` (so it's in the Journal as a skipped place), then back to exploring, or on to the
   next stop on a set walk. The team may change this later (see open questions).
8. **Skip** during the wait works like Skip today: the skip line, recorded as `.skipped`, move on.

### "here": you're already in it (6 places)

Locate line → **3 s pause** → question, with no tap needed. Then Tell me more / Skip as today.
During the locate line and the pause, the buttons are the same as while the prompt plays today
(Tell me more, Skip, Replay, Pause), so nobody has to wait.

### "gone": it used to be here (3 places)

Locate line → question straight away, with no pause and no tap. Buttons as for "here".

### Everywhere

- **Timers:** the 3 s pause and the 20 s waits use the existing `pausableSleep`, so **Pause**
  stops them and app suspension counts as time passing. Any tap restarts or cancels them.
- **Replay** during the wait plays the locate line (and the help line, if it has been heard),
  then the checkpoint line, and restarts the 20 s wait.
- **Read mode:** the locate line and the checkpoint line show at once, with the same buttons. **No
  nudge or give-up timers**, because people read at their own speed (that's how Read mode works
  everywhere else). Help adds the help line to the text.
- **Demo walk:** no change. The checkpoint waits for a tap there too, which is what testers want.
  At a desk, the give-up line skips the place after 40 s.
- **Set walks:** the same flow at every stop. The checkpoint doesn't change how stops count:
  "Found it" isn't "found" for the Journal, only **Tell me more** is, as today.
- **VoiceOver:** when the wait starts, focus moves to **Found it** (the same pattern as
  `focusedControl = .tellMeMore` in `ExploringPanel`).
- **Watch:** shows the locate text (the same `ReadText` pattern as `PromptScreen`), with one
  large **Found it** button and **Help** and **Skip** below it. Taps go to the phone, like every
  other watch button.

## Content file changes (`Shared/Content/stroll-content.json`)

Each place gets these fields. `prompt` is replaced by `locate` and `question`.

```json
"arrival": "find",
"locate":   { "text": "On Fifth Avenue, a huge stone building has a long row of giant columns across its front.", "audio": null },
"question": { "text": "How many pieces of stone do you think make up one column?", "audio": null },
"findHelp": { "text": "The columns line the whole Fifth Avenue front, at the corner of Bellefield Avenue.", "audio": null }
```

- `arrival`: `"find"`, `"here"` or `"gone"`. The mapping is in the headings of the content doc
  ("Find it", "You're here", "Used to be here"). Each heading ends with the place's `id`.
- `findHelp`: optional, and only for `"find"` places. **When copying help lines from the content
  doc, take the text before any ⚠ and drop the rest.** If nothing is left (for example "⚠ Site
  visit: …"), leave `findHelp` out. That applies to 4 places (Stephen Foster Memorial, Neill Log
  House, Westinghouse Memorial and Vallejo Flour Mill) until the site visits.
- Skip any **Note:** lines in the content doc. They're for the team, not the app.
- `"audio": null` until clips are made: the iPhone voice reads the line in the meantime, as it
  already does for any line without a recording.
- New shared lines in `lines`, next to `skip` and `done`:

```json
"checkpoint": { "text": "Tap Found it when you see it.", "audio": null },
"nudge":      { "text": "Still looking? Take your time. The photo on your phone can help.", "audio": null },
"giveUp":     { "text": "No problem. I'll save this one in your Journal for later.", "audio": null }
```

The reveal, story, alt text, photos and everything else stay as they are.

## Code changes

These are suggestions from reading the code at `1ed1396`, not the only way to do it.

| Where | Change |
|---|---|
| `Shared/StrollContent.swift` | `POI`: add `arrival` (an enum: `find`, `here`, `gone`), `locate`, `question`, `findHelp?`; remove `prompt`. `Lines`: add `checkpoint`, `nudge`, `giveUp`. |
| `Shared/RemoteMessages.swift` | `ExplorePhase`: add `locating` (between `preview` and `prompt`, only for `"find"` places). `MirrorState`: add `helpGiven` so the watch knows whether to show Help. `WatchAction`: add `foundIt` and `helpMeFind`. |
| `Phone/Walk/ExploreSession.swift` | `arrive(at:)`: after the preview, branch on `arrival`. For `find`: phase `.locating`, say locate + checkpoint, start the nudge timer. New `foundIt()` and `helpMeFind()`. Give-up = the same path as `skip()`, but say `lines.giveUp` instead of the skip line. For `here` and `gone`: phase `.prompt`, say locate, sleep 3 s (`here` only), say question. `replay()`: handle `.locating`, and in `.prompt` replay locate + question. `playStory`: the transcript starts with locate (+ help if heard) + question instead of prompt. `Timing`: add `nudgeAfter = 20`, `giveUpAfter = 20`, `herePause = 3`. `handle(_:)`: the two new watch actions. |
| `Phone/Explore/ExploringPanel.swift` | `controls`: a `.locating` case with Found it (filled), Help me find it (hidden once used or when there's no `findHelp`), Skip and `listeningRow`. VoiceOver focus on Found it. `lines`: use locate/question instead of prompt. |
| `Watch/WalkView.swift` | A `LocatingScreen` for `.locating`, built like `PromptScreen`. `PromptScreen` shows the question text. |
| `Shared/Finds.swift` | The watch's old pre-set walk (`Walk.finds`) still reads `prompt`, but at `1ed1396` nothing seems to use `Walk.finds`. Remove it if that's still true; otherwise use the question. |
| `Phone/Journal/*` | No change if give-up is treated as Skip. |

**Search for every other use of `prompt`** before removing it, for example with
`grep -rn "\.prompt" Phone Watch Shared Tools`. At `1ed1396` there are uses in the files above,
plus `Tools/ContentCheck`, `Tools/ExploreSessionCheck` and `Tools/voice/generate.py`. The
locked-screen notification ("Something to notice nearby" in `PhoneGuide.swift`) doesn't use
the prompt and doesn't change.

## Tools and checks

- `Tools/ContentCheck/main.swift`: check `locate`, `question` and (if present) `findHelp` like
  the other lines. `findHelp` only on `"find"` places. `arrival` must be one of the three values.
  Allow the new shared lines to have no audio yet (count them as iPhone-voice lines instead of
  failing, like place lines).
- `Tools/ExploreSessionCheck/main.swift`: update the existing prompt checks, and add checks for:
  - **find:** the locate line plays, the session waits in `.locating`, and **Found it** plays
    the question
  - **help:** the help line, then the checkpoint again, and Help isn't offered twice
  - the **nudge**, then **give-up** recorded as `.skipped` (use tiny `Timing` values)
  - **Pause** during the wait stops the timers
  - **here** (the pause, then the question with no tap) and **gone** (no pause)
  - **Read mode:** no timers
  - **set walk:** give-up moves on to the next stop
  - the two new **watch actions**
- `Tools/voice/generate.py`: `all_lines()` should list `locate`, `question` and `findHelp`
  (clip names `mellon-columns-locate`, `mellon-columns-question` and `mellon-columns-help`, following the current `{id}-prompt` naming) instead of
  `prompt`. The new shared lines are picked up already, because `missing_other_lines()` covers
  everything in `lines`.
- Run `Tools/check-walk-model.sh` before the pull request, and add a line to `CHANGELOG.md` under
  **Unreleased → Changed**.

## Rough order

1. Content file: add the fields for all 56 places from the content doc (a small script that
   reads the doc by `id` is quickest), and the three shared lines.
2. `StrollContent` + `ExploreSession` + checks. Get `Tools/check-walk-model.sh` passing.
3. Phone panel, then the watch screen.
4. Try it on a phone in Demo walk mode, with the iPhone voice reading the new lines.
5. Generate the Sky clips with `generate.py`. That's about 150 new clips, so check the run time
   first with `--list`.
6. Outdoor test at a few "find" places, including one with no help line.

## Open questions (defaults are above, so the build doesn't need to wait)

1. **Giving up:** the default is to treat it like Skip. The team may prefer to show it in the
   Journal as a "Mystery location", like missed set-walk stops.
2. **Help line wording:** 22 help lines are marked ⚠ to confirm on site. They can be
   changed in the content file later without code changes.
3. **The 20 s waits** are a first guess. They're in `Timing`, so they're easy to tune after
   testing.
