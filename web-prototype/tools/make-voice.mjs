// Generates Stroll's narration clips with ElevenLabs.
//
// Reads every spoken line straight from app.js, so the audio always
// matches the captions, and writes one MP3 per line into audio/.
//
// Usage (from the project folder):
//   node tools/make-voice.mjs --lines              preview the lines (no key needed)
//   node tools/make-voice.mjs --list-voices        list your voices and their IDs
//   node tools/make-voice.mjs                      generate any missing clips (Carolyn)
//   node tools/make-voice.mjs --voice <VOICE_ID>   use a different voice
//   node tools/make-voice.mjs --voice <VOICE_ID> --force    regenerate all clips
//   node tools/make-voice.mjs --voice <VOICE_ID> --only f2-prompt,skip
//
// The API key is read from the ELEVENLABS_API_KEY environment variable.

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const appJs = readFileSync(join(root, "app.js"), "utf8");
const outDir = join(root, "audio");

// Same model and voice as the clips already made with the ElevenLabs connector,
// using the voice's default settings, so every clip sounds like one narrator.
const MODEL_ID = "eleven_v4";
const DEFAULT_VOICE_ID = "4rgssJ1pg3E9c0U78Iid"; // Carolyn - Warm Grounded Narrator

// ---------- Lines (same ids the prototype uses) ----------
function extract(re, what) {
  const m = appJs.match(re);
  if (!m) throw new Error(`Couldn't find ${what} in app.js`);
  return m[1];
}
const FINDS = new Function(`return ${extract(/const FINDS = (\[[\s\S]*?\n {2}\]);/, "FINDS")}`)();
const SKIP_LINE = JSON.parse(extract(/const SKIP_LINE = ("[^"]*");/, "SKIP_LINE"));
const DONE_LINE = JSON.parse(extract(/const DONE_LINE = ("[^"]*");/, "DONE_LINE"));

const clips = [];
FINDS.forEach((f, i) => {
  const n = i + 1;
  const seq = [
    [`f${n}-cue`, f.cue],
    [`f${n}-prompt`, f.prompt],
    [`f${n}-reveal`, f.reveal],
    ...f.story.map((s, k) => [`f${n}-story${k + 1}`, s]),
  ];
  seq.forEach(([id, text], k) => {
    clips.push({ id, text, prev: seq[k - 1]?.[1], next: seq[k + 1]?.[1] });
  });
});
clips.push({ id: "skip", text: SKIP_LINE });
clips.push({ id: "done", text: DONE_LINE });

// ---------- CLI ----------
const args = process.argv.slice(2);
const flag = (name) => args.includes(name);
const opt = (name) => { const i = args.indexOf(name); return i >= 0 ? args[i + 1] : undefined; };

if (flag("--lines")) {
  for (const c of clips) console.log(`${c.id.padEnd(10)} ${c.text}`);
  process.exit(0);
}

const apiKey = process.env.ELEVENLABS_API_KEY;
if (!apiKey) {
  console.error("Set ELEVENLABS_API_KEY first. See the steps in the chat.");
  process.exit(1);
}
const api = (path, init = {}) =>
  fetch(`https://api.elevenlabs.io${path}`, { ...init, headers: { "xi-api-key": apiKey, ...(init.headers || {}) } });

if (flag("--list-voices")) {
  const res = await api("/v1/voices");
  if (!res.ok) { console.error(`ElevenLabs said ${res.status}: ${await res.text()}`); process.exit(1); }
  const { voices } = await res.json();
  for (const v of voices) {
    const l = v.labels || {};
    console.log(`${v.voice_id}  ${v.name}  (${[l.gender, l.accent, l.description || l.descriptive].filter(Boolean).join(", ")})`);
  }
  process.exit(0);
}

const voiceId = opt("--voice") || process.env.ELEVENLABS_VOICE_ID || DEFAULT_VOICE_ID;
if (!voiceId) {
  console.error("Pick a voice: run with --list-voices, then pass --voice <VOICE_ID>.");
  process.exit(1);
}
const only = opt("--only")?.split(",").map((s) => s.trim());
const force = flag("--force");

mkdirSync(outDir, { recursive: true });
const todo = clips.filter((c) => (!only || only.includes(c.id)) && (force || only || !existsSync(join(outDir, `${c.id}.mp3`))));
console.log(`${clips.length} lines, ${todo.length} to generate, ${todo.reduce((n, c) => n + c.text.length, 0)} characters.`);

for (const c of todo) {
  const body = { text: c.text, model_id: MODEL_ID };
  const res = await api(`/v1/text-to-speech/${voiceId}?output_format=mp3_44100_128`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "audio/mpeg" },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    console.error(`✗ ${c.id}: ElevenLabs said ${res.status}: ${await res.text()}`);
    process.exit(1);
  }
  writeFileSync(join(outDir, `${c.id}.mp3`), Buffer.from(await res.arrayBuffer()));
  console.log(`✓ ${c.id}.mp3  "${c.text.slice(0, 50)}${c.text.length > 50 ? "…" : ""}"`);
}
console.log(`Done. Clips are in audio/.`);
