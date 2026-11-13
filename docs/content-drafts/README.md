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

## 2. Narration voice (`"audioVoice"`)

The 40 lines of the 8 new places (5 each: question, answer, 3 story lines) were **generated with
Kokoro's Sky voice** (`af_sky`, normal speed) on Nov 13. Each of these places has
`"audioVoice": "kokoro af_sky … final voice not decided yet"`. The original 4 places keep their
earlier recordings, so **two voices are mixed for now** until the team picks the final voice.

**How the voice tool works** (`Tools/voice/generate.py`, free and local, Kokoro is Apache 2.0):
it generates a clip for every line with `"audio": null` and never touches lines that already have
a recording. One-time setup on a Mac, from the Stroll folder:

```bash
python3 -m uv venv --python 3.12 Tools/voice/.venv
python3 -m uv pip install --python Tools/voice/.venv "onnxruntime==1.23.2" kokoro-onnx
```

Then download `kokoro-v1.0.onnx` and `voices-v1.0.bin` from the kokoro-onnx GitHub releases
(`model-files-v1.0`) into `Tools/voice/models/`. These are excluded from Git (353 MB).

```bash
Tools/voice/.venv/bin/python Tools/voice/generate.py --list            # lines without audio
Tools/voice/.venv/bin/python Tools/voice/generate.py --sample PLACE_ID  # one test clip
Tools/voice/.venv/bin/python Tools/voice/generate.py                    # generate all missing
```

New places added with `"audio": null` (for example from another city) are read by the iPhone
voice until the tool is run. `Tools/check-walk-model.sh` lists any such lines.

**To switch to a different voice later:** set the lines' `"audio"` back to `null`, delete their
clips, and run the tool with `--voice NAME` (or record them by hand).

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
