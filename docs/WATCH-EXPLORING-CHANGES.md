# Watch app: exploring-mode changes (for Flora)

Spec for switching the watch app from a set walk to **exploring** for round 1. Written against the
original scaffold (`watch-app-scaffold`); if your copy has moved on, apply the intent, not the line
numbers. Background and the full team plan: `docs/round1-plan.md`.

Scope: **watch app + shared messages + the Mac check script.** The companion app screens and the
demo-walk engine come next and are not part of this change.

---

## Summary

| # | Change | Why |
|---|---|---|
| 1 | Session ends **only on End** (from the phone), never automatically after the 4th POI | In exploring, any POI can come last; today reaching find index 3 ends the walk |
| 2 | **No cue line**: buzz → photo preview → prompt | Cue lines are route directions; there's no route |
| 3 | **"Keep exploring"** wording | "Next stop" / "Finish walk" / "Continue walking" imply a route |
| 4 | Messages: `startExploring`, `trigger`, `end`, `setBuzz`; drop `reset` | The phone is now the participant's companion app, not a moderator remote |
| 5 | Buzz respects the **Buzz on wrist** setting | Settings toggle in the companion app |
| 6 | Ignore triggers for a POI already found/skipped this session | Each POI buzzes once per session |
| 7 | Update `Tools/check-walk-model.sh` checks | Keep the scripted walk passing |

---

## 1. End only on End — `Watch/WalkModel.swift`

- In `afterFind()`, remove the `isLastFind` branch: after any POI, always go to `.waiting`.
- Add `func end()`: cancel whatever is running, set `.done`, then say `Walk.doneLine`
  ("Walk complete. Check your phone for your field journal."). **No buzz**: the participant
  started the ending themselves.
- Remove `isLastFind` (and its use in `WalkView`, see §3).
- Replay on `.done` keeps working as today.

## 2. No cue line — `WalkModel.trigger(find:)`

New sequence:

1. `findIndex = index`, `set(.alert)` (photo preview), buzz (see §5).
2. Hold the preview for **2.5 s** (`pausableSleep`), so it's not a flash now that the cue is gone.
   Suggest renaming `buzzToVoice` → `previewSeconds = 2.5`.
3. `set(.prompt)`, then `say(find.narration(.prompt))`.

Remove `cueToPrompt`. Keep `Find.cue` and the `f*-cue` clips in the project (unused for now);
pre-set walks may come back.

## 3. Wording — `Watch/WalkView.swift`

| Screen | Now | Change to |
|---|---|---|
| `WaitingScreen` | "Keep walking" | **"Keep exploring"** |
| `StoryScreen` button | "Next stop" / "Finish walk" (via `isLastFind`) | **"Keep exploring"** (always) |
| `FinishedScreen` button | "Continue walking" | **"Keep exploring"** |

`StoryScreen`'s button still calls `nextStop()` and `FinishedScreen`'s still calls
`continueWalking()`; renaming those methods (e.g. `leaveStory()` / `done()`) is optional.
The outcome stays **found** when someone leaves a story early.

## 4. Messages — `Shared/RemoteMessages.swift`

Rename `RemoteCommand` → `PhoneCommand` (optional but clearer) with:

```swift
enum PhoneCommand: Codable, Equatable {
    case startExploring            // new session: clear outcomes, go to .waiting
    case trigger(find: Int)        // buzz + play this POI (sent by the demo walk now, live location later)
    case end                       // participant tapped End on the phone → WalkModel.end()
    case setBuzz(Bool)             // Buzz on wrist setting
    case requestStatus
}
```

- `startExploring` replaces `reset` (same effect: clear `findIndex` / `outcomes`, go to `.waiting`
  if ready).
- `WatchEvent` and `WalkStatus` stay as they are: the companion app uses `outcomes` and the actions
  to build the Journal. (`ParticipantAction.nextStop` / `.continueWalking` can keep their names.)
- `WalkScreen` doesn't need new cases.

## 5. Buzz setting — `WalkModel` / `WatchServices.swift`

- Add `var buzzEnabled = true` to `WalkModel`; `handle(.setBuzz(on))` sets it.
- In `trigger`, call `haptics.buzz()` only when `buzzEnabled`. Everything else (preview, narration)
  is unchanged when the buzz is off.

## 6. Once per session

At the top of `trigger(find:)`: `guard outcomes[index] == nil else { return }`. The phone should
also avoid sending repeats, but the watch shouldn't double-play if it does. A trigger mid-story
still interrupts and starts the new POI, as today.

## 7. Check script — `Tools/WalkModelCheck/main.swift`

Update the scripted walk so it still passes:

- "cue then prompt are spoken" → expect only `f1-prompt` after a trigger.
- Replace "Next stop on the last find completes the walk" and "walk complete buzzes (4 finds + done)"
  with:
  - Next stop on find 4 returns to `.waiting` (no auto-complete).
  - `end()` (or `handle(.end)`) → `.done`, `done` clip plays, **no extra buzz** (4 buzzes total).
- Add: a second `trigger` for an already-found POI does nothing.
- Add: with `setBuzz(false)`, a trigger plays narration but `haptics.buzzes` doesn't increase.
- Replace the `reset` usage with `startExploring`.

Run on any Mac (no Xcode needed): `Tools/check-walk-model.sh`.

---

## Not in this change

- **Phone app:** the current `Phone/` remote stays as a dev tool to fire `trigger`/`end` until the
  companion app replaces it. Keep the iOS target either way: the watch app installs through it.
  Update its message calls to the new `PhoneCommand` names, and drop its "next find" highlight.
- Demo walk engine, data file, companion screens: next steps in the team plan.
