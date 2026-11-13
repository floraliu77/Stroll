"""Generate narration clips with Kokoro (free, Apache 2.0) for lines that have no recording yet.

Lines with "audio": null in Shared/Content/stroll-content.json are read by the iPhone voice as a
placeholder. This script turns them into clips: Kokoro voice -> .m4a in Resources/Audio/, then points
the line at the new clip. Places whose lines all get clips lose their "audioStatus" placeholder mark
and get "audioVoice" so we know which voice made them. Lines that already have a recording are never
touched.

Setup (once, from the Stroll folder; see docs/content-drafts/README.md):
    python3 -m uv venv --python 3.12 Tools/voice/.venv
    python3 -m uv pip install --python Tools/voice/.venv "onnxruntime==1.23.2" kokoro-onnx
    # plus kokoro-v1.0.onnx and voices-v1.0.bin in Tools/voice/models/

Use:
    Tools/voice/.venv/bin/python Tools/voice/generate.py --list              # what would be generated
    Tools/voice/.venv/bin/python Tools/voice/generate.py --sample heinz-chapel  # one test clip, no changes
    Tools/voice/.venv/bin/python Tools/voice/generate.py                      # generate everything missing
Options: --voice af_sky (default), --speed 1.0 (default).
"""

import argparse
import json
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np
from kokoro_onnx import Kokoro

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "Shared/Content/stroll-content.json"
AUDIO = ROOT / "Resources/Audio"
MODELS = ROOT / "Tools/voice/models"
SAMPLES = ROOT / "Tools/voice/samples"


def missing_lines(content):
    """(place, line dict, clip name) for every line without a recording, in content order."""
    for poi in content["pois"]:
        lines = [("prompt", poi["prompt"]), ("reveal", poi["reveal"])]
        lines += [(f"story{n}", line) for n, line in enumerate(poi["story"], start=1)]
        for kind, line in lines:
            if not line.get("audio"):
                yield poi, line, f"{poi['id']}-{kind}"


def to_m4a(samples, rate, out_path):
    """Write Kokoro's samples as a mono AAC .m4a with the Mac's built-in afconvert."""
    pcm = (np.clip(samples, -1.0, 1.0) * 32767).astype(np.int16)
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = Path(tmp) / "line.wav"
        with wave.open(str(wav_path), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(rate)
            w.writeframes(pcm.tobytes())
        subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "64000", str(wav_path), str(out_path)],
                       check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--list", action="store_true", help="only list the lines that would be generated")
    parser.add_argument("--sample", metavar="PLACE_ID", help="generate that place's question into "
                        "Tools/voice/samples/ without changing anything else")
    parser.add_argument("--voice", default="af_sky")
    parser.add_argument("--speed", type=float, default=1.0)
    args = parser.parse_args()

    content = json.loads(CONTENT.read_text())
    todo = list(missing_lines(content))

    if args.list:
        print(f"{len(todo)} lines without a recording:")
        for poi, line, clip in todo:
            print(f"  {clip}: {line['text']}")
        return

    kokoro = Kokoro(str(MODELS / "kokoro-v1.0.onnx"), str(MODELS / "voices-v1.0.bin"))

    def speak(text, out_path):
        samples, rate = kokoro.create(text, voice=args.voice, speed=args.speed, lang="en-us")
        to_m4a(samples, rate, out_path)

    if args.sample:
        poi = next((p for p in content["pois"] if p["id"] == args.sample), None)
        if poi is None:
            sys.exit(f"No place with id '{args.sample}'")
        SAMPLES.mkdir(parents=True, exist_ok=True)
        out = SAMPLES / f"{args.sample}-prompt-{args.voice}.m4a"
        speak(poi["prompt"]["text"], out)
        print(f"Sample: {out}\nText: {poi['prompt']['text']}")
        return

    if not todo:
        print("Nothing to generate: every line has a recording.")
        return
    for n, (poi, line, clip) in enumerate(todo, start=1):
        print(f"[{n}/{len(todo)}] {clip}")
        speak(line["text"], AUDIO / f"{clip}.m4a")
        line["audio"] = clip

    voice_note = f"kokoro {args.voice} (generated, speed {args.speed}); final voice not decided yet"
    for poi in content["pois"]:
        if "audioStatus" in poi and not any(p is poi for p, _, _ in missing_lines(content)):
            del poi["audioStatus"]
            poi["audioVoice"] = voice_note
    CONTENT.write_text(json.dumps(content, indent=2, ensure_ascii=False) + "\n")
    print(f"Done: {len(todo)} clips in Resources/Audio/. Run Tools/check-walk-model.sh next.")


if __name__ == "__main__":
    main()
