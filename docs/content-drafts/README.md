# Content to-do: review, photos, recordings

The app has 12 places: the original 4, plus 8 of MJ's new ones (added Nov 12). Her 9th,
Richard Serra's *Carnegie*, is waiting in `new-places.json` for a photo.

The status fields below are notes for the team. The app doesn't read them or show them.

## 1. Team review (`"reviewStatus": "needs-review"`)

MJ wrote the questions, answers and stories for her 8 new places and marked each one for team
review. Check facts and wording, then change `reviewStatus` to `"reviewed"` in
`Shared/Content/stroll-content.json`. Her sources and notes are next to each place in the file.

- st-nicholas-cathedral · bellefield-hall · heinz-chapel · cathedral-of-learning
- the-hiker · first-baptist-church · st-paul-cathedral · fairfax-apartments

## 2. Recordings (`"audioStatus": "iphone-voice-placeholder"`)

Lines without a recording have `"audio": null`. The phone reads them with the **iPhone's
built-in voice** as a placeholder, so the places work now. To see the current list, run:

```bash
Tools/check-walk-model.sh
```

It prints "To record later: … lines in … places use the iPhone voice".

**40 lines to record**: 5 per place (question, answer, 3 story lines) for the 8 places above.
To add a recording: put the clip in `Resources/Audio/` (mp3 or m4a), set that line's `"audio"`
to the file name without the extension, and once all of a place's lines are recorded, remove its
`audioStatus`.

**Also re-record 4 existing clips** that MJ found didn't match sources (`textFixes` in
`docs/location/poi-locations.json`): Mellon columns ×2, Dippy ×1, Forbes Field wall ×1.

## 3. Photos (`"photoStatus"`)

- **the-hiker:** a free photo (CC BY-SA 3.0) replaces a non-commercial one. It's small and from
  the 1980s; a new photo from a walk would look better.
- **serra-carnegie:** keeps its current photo for now (CC BY-NC-SA, non-commercial). It must be
  downloaded by hand from its Flickr page, or replaced by Flora's own photo. Then add it to the
  asset catalog and move the place into the app.
- cathedral-of-learning and st-paul-cathedral were cropped from portrait to landscape.

## 4. Credits to show before a public release

- Photo credits are in each place's `photoCredit`.
- Coordinates: © OpenStreetMap contributors, ODbL (see `coordinateSource` in the content file).
