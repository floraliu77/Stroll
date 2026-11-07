(() => {
  "use strict";

  // ---------- Content ----------
  const ICONS = {
    architecture: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round" aria-hidden="true"><path d="M3 9l9-5 9 5H3z"/><path d="M5 9v9M9.5 9v9M14.5 9v9M19 9v9M3 20h18"/></svg>',
    nature: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 18c1.5-4 4-6 8-6h3c2 0 3-1 3.5-3l.5-3c1.5.5 3 2 3 3.5S20 12 18.5 12"/><path d="M8 12v6M14 12v6M3 18h4"/></svg>',
    art: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><path d="M12 3a9 9 0 1 0 0 18c1.2 0 2-.8 2-1.8 0-1.3-1-1.5-1-2.7 0-1 .8-1.5 1.8-1.5H17a4 4 0 0 0 4-4C21 6.5 17 3 12 3z"/><circle cx="7.5" cy="11" r="1.2" fill="currentColor"/><circle cx="10" cy="7" r="1.2" fill="currentColor"/><circle cx="15" cy="7" r="1.2" fill="currentColor"/></svg>',
    history: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 3h12M6 21h12M7 3c0 5 5 6 5 9s-5 4-5 9M17 3c0 5-5 6-5 9s5 4 5 9"/></svg>',
  };

  const FINDS = [
    {
      name: "Mellon Institute columns",
      category: "Architecture",
      icon: "architecture",
      img: "img/mellon-columns.jpg",
      focus: "50% 40%", // object-position: keep the find clear of the watch
      focusM: "40% 50%", // same, for the phone layout
      alt: "A long row of tall, smooth limestone columns with scrolled Ionic tops along the side of a large stone building.",
      credit: { author: "Cbaile19", license: "CC0", licenseUrl: "https://creativecommons.org/publicdomain/zero/1.0/", file: "https://commons.wikimedia.org/wiki/File:Columns_of_the_Mellon_Institute,_2021-12-20,_01.jpg" },
      cue: "Start at Fifth Avenue and Bellefield.",
      prompt: "Look at the giant columns on this building. How many stone pieces make up one column?",
      reveal: "None stacked. Each column is a single piece of stone.",
      story: [
        "Each of the 62 columns here is one solid piece of Indiana limestone, about 60 tons.",
        "When the Mellon Institute opened in 1937, they were the largest monolithic columns in the world.",
        "The building, now part of Carnegie Mellon, reaches six stories underground to bedrock, to keep lab experiments steady.",
      ],
    },
    {
      name: "Dippy the dinosaur",
      category: "Natural history",
      icon: "nature",
      img: "img/dippy.jpg",
      focus: "50% 30%", // object-position: keep the find clear of the watch
      focusM: "24% 50%", // same, for the phone layout
      alt: "A life-size gray long-necked dinosaur statue standing among hedges outside a large stone museum building.",
      credit: { author: "TheZachMorrisExperience", license: "CC BY-SA 3.0", licenseUrl: "https://creativecommons.org/licenses/by-sa/3.0/", file: "https://commons.wikimedia.org/wiki/File:DippyStatuteCarnegiePittsburgh.jpg" },
      cue: "Head down Bellefield to Forbes Avenue.",
      prompt: "Spot the dinosaur outside the museum. Look closely: is it bone, or something else?",
      reveal: "It's a life-size fiberglass copy.",
      story: [
        "This is Dippy, a fiberglass copy of a Diplodocus installed in 1999, 100 years after Andrew Carnegie funded the dig that found the original.",
        "The first bone, a toe, was found in Wyoming on July 4, 1899, earning it the nickname 'the star-spangled dinosaur.'",
        "The real skeleton still stands inside, and Carnegie gave casts to museums in London, Paris, and other cities.",
      ],
    },
    {
      name: "“A Song to Nature” fountain",
      category: "Public art",
      icon: "art",
      img: "img/song-to-nature.jpg",
      focus: "50% 58%", // object-position: keep the find clear of the watch
      focusM: "50% 50%", // same, for the phone layout
      alt: "A bronze fountain sculpture of two figures above a wide stone basin, with small bronze animals sitting on the basin's rim.",
      credit: { author: "Daderot", license: "Public domain", licenseUrl: "", file: "https://commons.wikimedia.org/wiki/File:Mary_Schenley_Fountain_-_Pittsburgh_-_IMG_0755.jpg" },
      cue: "Cross Forbes toward Schenley Plaza and the Frick Fine Arts Building.",
      prompt: "At the fountain, look along the rim of the basin. Find the animals spouting water.",
      reveal: "Turtles. Four bronze turtles spout water into the basin.",
      story: [
        "This 1918 fountain honors Mary Schenley, who donated the land for Schenley Park.",
        "The figures show Humanity playing a lyre to Pan, the earth god.",
        "Its sculptor, Victor David Brenner, also designed the Lincoln penny, so you've probably carried his work in your pocket.",
      ],
    },
    {
      name: "Forbes Field wall",
      category: "History",
      icon: "history",
      img: "img/forbes-wall.jpg",
      focus: "50% 45%", // object-position: keep the find clear of the watch
      focusM: "38% 50%", // same, for the phone layout
      alt: "A long, ivy-covered red brick wall in a shady park, with a white number painted on a section of the wall in the distance.",
      credit: { author: "ccbarr", license: "CC BY-SA 2.0", licenseUrl: "https://creativecommons.org/licenses/by-sa/2.0/", file: "https://commons.wikimedia.org/wiki/File:Forbes_Field_outfield_walls.jpg" },
      cue: "Follow Roberto Clemente Drive to the old brick wall by Mazeroski Field.",
      prompt: "Find the numbers on this brick wall. What do you think they measure?",
      reveal: "Distances from home plate: 457 and 436 feet.",
      story: [
        "This wall is all that's left of the outfield of Forbes Field, home of the Pittsburgh Pirates from 1909 to 1970, and of the Negro League Homestead Grays.",
        "Bill Mazeroski's ninth-inning home run here won the 1960 World Series. Fans still gather at this wall every October 13 to relive it.",
        "Home plate from the last game is preserved in the lobby of Posvar Hall, just across the street.",
      ],
    },
  ];

  const SKIP_LINE = "Okay, onward.";
  const DONE_LINE = "Walk complete. Check your phone for your field journal.";

  // Pre-recorded narration (made with tools/make-voice.mjs), keyed by line text.
  const CLIPS = new Map();
  FINDS.forEach((f, i) => {
    const n = i + 1;
    CLIPS.set(f.cue, `audio/f${n}-cue.mp3`);
    CLIPS.set(f.prompt, `audio/f${n}-prompt.mp3`);
    CLIPS.set(f.reveal, `audio/f${n}-reveal.mp3`);
    f.story.forEach((s, k) => CLIPS.set(s, `audio/f${n}-story${k + 1}.mp3`));
  });
  CLIPS.set(SKIP_LINE, "audio/skip.mp4"); // AAC: re-levelled to match the others
  CLIPS.set(DONE_LINE, "audio/done.mp3");

  // ---------- Elements ----------
  const $ = (id) => document.getElementById(id);
  const screens = { intro: $("screen-intro"), phone: $("screen-phone"), walk: $("screen-walk") };
  const phoneStart = $("phone-start");
  const phoneJournal = $("phone-journal");
  const sceneImg = $("scene-img");
  const watch = $("watch");
  const wCount = $("w-count");
  const wCat = $("w-cat");
  const wBody = $("w-body");
  const caption = $("caption");
  const captionBar = document.querySelector(".caption-bar");

  // ---------- Speech ----------
  const synth = "speechSynthesis" in window ? window.speechSynthesis : null;
  let speechOK = !!synth;
  let voice = null;

  // Prefer on-device voices: network voices (e.g. Chrome's "Google US English")
  // often fail to start or cut off mid-sentence.
  let voiceFallbackUsed = false;
  function pickVoice() {
    if (!synth || voiceFallbackUsed) return;
    const all = synth.getVoices();
    const en = all.filter((v) => /^en([-_]|$)/i.test(v.lang) && v.localService);
    if (!en.length) { voice = null; return; } // let the browser use its default voice
    const enUS = en.filter((v) => /en[-_]US/i.test(v.lang));
    const prefs = [/premium/i, /enhanced/i, /Samantha/i, /Ava/i, /Allison/i, /Alex/i, /Aria/i, /Jenny/i, /Zira/i, /Karen/i, /Daniel/i];
    for (const re of prefs) {
      const hit = enUS.find((v) => re.test(v.name)) || en.find((v) => re.test(v.name));
      if (hit) { voice = hit; return; }
    }
    voice = enUS.find((v) => v.default) || enUS[0] || en[0];
  }
  if (synth) {
    pickVoice();
    if ("onvoiceschanged" in synth) synth.addEventListener("voiceschanged", pickVoice);
  }

  function showNoSpeechNotes() {
    document.querySelectorAll(".no-speech").forEach((el) => { el.hidden = false; });
  }
  if (!speechOK) showNoSpeechNotes();

  // Estimated reading time, used when speech is unavailable and as a safety timeout.
  const readMs = (text) => Math.max(1800, text.split(/\s+/).length * 380);

  // Every sequence gets a run id; starting a new one invalidates the old one.
  let runId = 0;
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  class Cancelled extends Error {}
  function guard(id) { if (id !== runId) throw new Cancelled(); }

  // Pause: the running sequence waits at hold() until Resume.
  let paused = false;
  let pauseCount = 0;
  let resumeWaiters = [];
  async function hold(id) {
    if (paused) await new Promise((r) => resumeWaiters.push(r));
    guard(id);
  }
  async function wait(ms, id) {
    await sleep(ms);
    await hold(id);
  }
  function releaseWaiters() {
    const ws = resumeWaiters;
    resumeWaiters = [];
    ws.forEach((r) => r());
  }

  function stopAll() {
    runId++;
    stopClip();
    if (synth && (synth.speaking || synth.pending)) synth.cancel();
    if (paused) { paused = false; captionBar.classList.remove("paused"); }
    releaseWaiters();
  }

  // ---------- Captions (CC) ----------
  const ccBtn = $("btn-cc");
  function setCaptions(on) {
    captionBar.classList.toggle("off", !on);
    ccBtn.setAttribute("aria-pressed", String(on));
  }
  ccBtn.addEventListener("click", () => setCaptions(ccBtn.getAttribute("aria-pressed") !== "true"));

  function setCaption(text) {
    caption.textContent = text;
    caption.classList.remove("speaking");
    void caption.offsetWidth;
    caption.classList.add("speaking");
  }

  let stalls = 0;
  function speechFailed() {
    speechOK = false;
    if (!clipsOK) setCaptions(true);
    document.querySelectorAll(".no-speech").forEach((el) => {
      if (synth) el.textContent = "Audio isn't playing in this browser; read the captions instead.";
    });
    showNoSpeechNotes();
  }

  // ---------- Narration clips ----------
  const player = new Audio();
  player.preload = "auto";
  let clipsOK = false;
  let clipActive = false;
  let endClip = null;
  fetch(CLIPS.get(FINDS[0].cue), { method: "HEAD" })
    .then((r) => {
      if (!r.ok) return;
      clipsOK = true;
      CLIPS.forEach((url) => fetch(url).catch(() => {})); // warm the cache
    })
    .catch(() => {});

  // Resolves true when the clip played to the end, false if it couldn't play.
  function playClip(url) {
    return new Promise((resolve) => {
      let started = false;
      const done = (ok) => {
        if (endClip !== done) return;
        endClip = null;
        clipActive = false;
        clearTimeout(startWatch);
        player.onplaying = player.onended = player.onerror = null;
        resolve(ok);
      };
      endClip = done;
      clipActive = true;
      player.onplaying = () => { started = true; };
      player.onended = () => done(true);
      player.onerror = () => done(false);
      const startWatch = setTimeout(() => {
        if (!started && !paused) { player.pause(); done(false); }
      }, 6000);
      player.src = url;
      player.play().catch((e) => { if (e.name !== "AbortError") done(false); });
    });
  }

  function stopClip() {
    if (!endClip) return;
    player.pause();
    endClip(true);
  }

  // Speak one line; if Pause interrupts synthesized speech, wait for Resume and start the line over.
  async function speak(text, id) {
    for (;;) {
      await hold(id);
      if ((await speakOnce(text, id)) !== "interrupted") return;
    }
  }

  // Plays the line's clip, or speaks it with the browser's voice if there's no clip.
  // Resolves "done", or "interrupted" when Pause cut off synthesized speech.
  async function speakOnce(text, id) {
    guard(id);
    setCaption(text);
    const clip = clipsOK && CLIPS.get(text);
    if (clip && (await playClip(clip))) { guard(id); return "done"; }
    guard(id);
    const before = pauseCount;
    if (!speechOK) { setCaptions(true); await sleep(readMs(text)); guard(id); return pauseCount === before ? "done" : "interrupted"; }
    // Never let lines queue up behind each other.
    if (synth.speaking || synth.pending) { synth.cancel(); await sleep(120); guard(id); }
    if (synth.paused) synth.resume();
    // Desktop Chrome fills its voice list late; give it a moment before the first line.
    if (!synth.getVoices().length) {
      const t = Date.now();
      while (!synth.getVoices().length && Date.now() - t < 1500) { await sleep(100); guard(id); }
      pickVoice();
    }
    await new Promise((resolve) => {
      let settled = false;
      let started = false;
      let abandoned = false;
      const finish = () => {
        if (settled) return;
        settled = true;
        clearTimeout(safety);
        clearTimeout(startWatch);
        resolve();
      };
      // Fall back to caption timing for this line, measured from when it was shown.
      const t0 = Date.now();
      const fallback = () => sleep(Math.max(0, readMs(text) - (Date.now() - t0))).then(finish);
      const u = new SpeechSynthesisUtterance(text);
      if (voice) { u.voice = voice; u.lang = voice.lang; } else { u.lang = "en-US"; }
      u.rate = 0.95;
      u.onstart = () => { started = true; stalls = 0; };
      u.onend = () => { if (!abandoned) finish(); };
      u.onerror = (e) => {
        if (abandoned) return;
        if (e.error === "not-allowed" || e.error === "synthesis-unavailable" || e.error === "synthesis-failed" || e.error === "audio-busy") {
          speechFailed();
          fallback();
        } else {
          finish();
        }
      };
      // If the engine never starts the line, drop it rather than letting it play late.
      const startWatch = setTimeout(() => {
        if (started || settled) return;
        abandoned = true;
        synth.cancel();
        stalls++;
        // First stall: switch to the browser's default voice for the following lines.
        if (stalls === 1 && voice) { voiceFallbackUsed = true; voice = null; }
        if (stalls >= 3) speechFailed();
        fallback();
      }, 6000);
      // Some browsers occasionally never fire onend; don't let the walk get stuck.
      const safety = setTimeout(finish, readMs(text) * 2.5 + 4000);
      synth.speak(u);
    });
    guard(id);
    return pauseCount === before ? "done" : "interrupted";
  }

  // ---------- Wrist tap (Web Audio buzz + pulse + vibrate) ----------
  let audioCtx = null;
  function unlockAudio() {
    try {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (AC && !audioCtx) audioCtx = new AC();
      if (audioCtx && audioCtx.state === "suspended") audioCtx.resume();
    } catch (_) { audioCtx = null; }
    if (!playerUnlocked) {
      // Playing a silent sound inside the first tap lets iOS Safari play clips later
      // without a tap. It's silence (not a real clip) so nothing is heard even if
      // the browser ignores `muted` or is slow to pause.
      playerUnlocked = true;
      player.muted = true;
      player.src = silentWav();
      player.play()
        .then(() => { if (!clipActive) player.pause(); player.muted = false; })
        .catch(() => { player.muted = false; });
    }
    if (synth && !speechUnlocked) {
      // One quiet utterance inside the first tap unlocks speech on iOS Safari.
      speechUnlocked = true;
      const u = new SpeechSynthesisUtterance("Stroll");
      u.volume = 0;
      if (voice) u.voice = voice;
      synth.speak(u);
    }
  }
  let speechUnlocked = false;
  let playerUnlocked = false;

  // 0.1s of mono silence as a WAV data URL. 44.1 kHz to match the clips: a different
  // rate can make iOS switch the hardware rate and silence the wrist-tap AudioContext.
  function silentWav() {
    const rate = 44100, n = 4410, buf = new DataView(new ArrayBuffer(44 + n * 2));
    const str = (o, s) => [...s].forEach((c, i) => buf.setUint8(o + i, c.charCodeAt(0)));
    str(0, "RIFF"); buf.setUint32(4, 36 + n * 2, true); str(8, "WAVEfmt ");
    buf.setUint32(16, 16, true); buf.setUint16(20, 1, true); buf.setUint16(22, 1, true);
    buf.setUint32(24, rate, true); buf.setUint32(28, rate * 2, true);
    buf.setUint16(32, 2, true); buf.setUint16(34, 16, true);
    str(36, "data"); buf.setUint32(40, n * 2, true);
    let bin = "";
    new Uint8Array(buf.buffer).forEach((b) => { bin += String.fromCharCode(b); });
    return "data:audio/wav;base64," + btoa(bin);
  }

  function tick() {
    if (!audioCtx) return;
    // iOS can leave the context "interrupted" after other audio plays; wake it.
    if (audioCtx.state !== "running") audioCtx.resume().catch(() => {});
    // Two short, soft low buzzes, like the watch's haptic "tap-tap". A triangle wave
    // through a low-pass keeps just enough harmonics to be heard on phone speakers
    // without sounding harsh, and a gentle wobble hints at a vibration motor.
    const t = audioCtx.currentTime;
    [0, 0.2].forEach((offset) => {
      const start = t + offset, len = 0.13;
      const osc = audioCtx.createOscillator();
      osc.type = "triangle";
      osc.frequency.setValueAtTime(170, start);
      const filter = audioCtx.createBiquadFilter();
      filter.type = "lowpass";
      filter.frequency.value = 420;
      const wobble = audioCtx.createOscillator();
      const wobbleDepth = audioCtx.createGain();
      wobble.frequency.value = 30;
      wobbleDepth.gain.value = 0.12;
      const level = audioCtx.createGain();
      level.gain.value = 0.85;
      wobble.connect(wobbleDepth).connect(level.gain);
      const env = audioCtx.createGain();
      env.gain.setValueAtTime(0.0001, start);
      env.gain.exponentialRampToValueAtTime(0.24, start + 0.025);
      env.gain.setValueAtTime(0.24, start + len - 0.05);
      env.gain.exponentialRampToValueAtTime(0.0001, start + len);
      osc.connect(filter).connect(level).connect(env).connect(audioCtx.destination);
      [osc, wobble].forEach((o) => { o.start(start); o.stop(start + len + 0.02); });
    });
  }

  // Extra pause after the buzz (which itself takes 0.7s) before the voice starts.
  const BUZZ_GAP = 800;

  async function wristTap(id) {
    await hold(id);
    tick();
    if (navigator.vibrate) { try { navigator.vibrate(80); } catch (_) {} }
    watch.classList.remove("pulse");
    void watch.offsetWidth;
    watch.classList.add("pulse");
    await sleep(700);
    guard(id);
  }

  // ---------- State ----------
  let index = 0;
  let results = []; // "found" | "skipped"
  let phase = "idle"; // idle | waiting | prompt | story | done
  let replayLines = [];

  function show(name) {
    Object.entries(screens).forEach(([k, el]) => { el.hidden = k !== name; });
    window.scrollTo(0, 0);
  }

  // ---------- Watch rendering ----------
  const REPLAY_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12a9 9 0 1 0 3-6.7"/><path d="M3 4v5h5"/></svg>';
  const PAUSE_ICON = '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><rect x="6" y="5" width="4" height="14" rx="1"/><rect x="14" y="5" width="4" height="14" rx="1"/></svg>';
  const PLAY_ICON = '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M8 5.5v13a1 1 0 0 0 1.5.86l10.5-6.5a1 1 0 0 0 0-1.72L9.5 4.64A1 1 0 0 0 8 5.5z"/></svg>';
  const REPLAY_BTN = `<button class="w-replay" data-act="replay">${REPLAY_ICON}Replay</button>`;
  const PAUSE_BTN = `<button class="w-replay" data-act="pause">${PAUSE_ICON}Pause</button>`;

  let watchState = "waiting";
  function renderWatch(state) {
    watchState = state;
    if (paused) return; // shown again on Resume
    const f = FINDS[index];
    wCount.textContent = state === "done" ? "Stroll" : `${index + 1} of ${FINDS.length}`;
    wCat.innerHTML = state === "done" ? "" : `${ICONS[f.icon]}<span>${f.category}</span>`;

    if (state === "waiting") {
      wBody.innerHTML =
        '<p class="w-status"><strong>Keep walking</strong><span class="w-dots" aria-hidden="true"><span></span><span></span><span></span></span></p>' +
        `<div class="w-row">${PAUSE_BTN}</div>`;
    } else if (state === "alert") {
      // Notification preview: what to look for, shown with the buzz.
      wBody.innerHTML =
        `<img class="w-preview" src="${f.img}" alt="Preview: ${f.name}">` +
        `<div class="w-row">${PAUSE_BTN}</div>`;
    } else if (state === "prompt") {
      wBody.innerHTML =
        '<button class="w-btn w-found" data-act="found">Tell me more</button>' +
        '<button class="w-btn w-skip" data-act="skip">Skip</button>' +
        `<div class="w-row">${REPLAY_BTN}${PAUSE_BTN}</div>`;
    } else if (state === "story") {
      wBody.innerHTML =
        '<p class="w-status"><span class="w-dots" aria-hidden="true"><span></span><span></span><span></span></span></p>' +
        `<button class="w-btn w-skip" data-act="next">${index < FINDS.length - 1 ? "Next stop" : "Finish walk"}</button>` +
        `<div class="w-row">${REPLAY_BTN}${PAUSE_BTN}</div>`;
    } else if (state === "continue") {
      wBody.innerHTML =
        '<button class="w-btn w-found" data-act="continue">Continue walking</button>' +
        `<button class="w-replay" data-act="replay">${REPLAY_ICON}Replay</button>`;
    } else if (state === "skipping") {
      wBody.innerHTML = '<p class="w-status"><strong>Skipped</strong>Onward</p>';
    } else if (state === "done") {
      wBody.innerHTML = `<p class="w-status"><strong>Walk complete</strong>Check your phone</p><button class="w-replay" data-act="replay">${REPLAY_ICON}Replay</button>`;
    }
  }

  function focusWatchButton() {
    const b = wBody.querySelector(".w-btn");
    if (b) b.focus({ preventScroll: true });
  }

  function onPause() {
    if (paused) return;
    paused = true;
    pauseCount++;
    // A clip pauses in place; synthesized speech is cancelled and restarts on Resume.
    if (clipActive) player.pause();
    else if (synth && (synth.speaking || synth.pending)) synth.cancel();
    captionBar.classList.add("paused");
    wBody.innerHTML =
      '<p class="w-status"><strong>Paused</strong></p>' +
      `<button class="w-btn w-found" data-act="resume">${PLAY_ICON}Resume</button>`;
    focusWatchButton();
  }

  function onResume() {
    if (!paused) return;
    paused = false;
    captionBar.classList.remove("paused");
    renderWatch(watchState);
    const b = wBody.querySelector("[data-act=pause]") || wBody.querySelector("button");
    if (b) b.focus({ preventScroll: true });
    if (clipActive) player.play().catch(() => stopClip());
    releaseWaiters();
  }

  // ---------- Flow ----------
  function startFind(i) {
    stopAll();
    const id = runId;
    index = i;
    const f = FINDS[i];
    phase = "waiting";
    sceneImg.src = f.img;
    sceneImg.alt = f.alt;
    sceneImg.style.setProperty("--focus", f.focus);
    sceneImg.style.setProperty("--focus-m", f.focusM);
    setCaption("");
    caption.textContent = "…";
    renderWatch("waiting");
    replayLines = [f.prompt];

    (async () => {
      await wait(1500, id);
      phase = "prompt";
      renderWatch("alert");
      await wristTap(id);
      await wait(BUZZ_GAP, id);
      await speak(f.cue, id);
      renderWatch("prompt");
      await wait(350, id);
      await speak(f.prompt, id);
    })().catch(ignoreCancel);
  }

  async function playStory(id) {
    const f = FINDS[index];
    await speak(f.reveal, id);
    for (const chunk of f.story) {
      await wait(700, id);
      await speak(chunk, id);
    }
    phase = "continue";
    renderWatch("continue");
    focusWatchButton();
  }

  function onFound() {
    stopAll();
    const id = runId;
    results[index] = "found";
    phase = "story";
    renderWatch("story");
    const f = FINDS[index];
    replayLines = [f.reveal, ...f.story];
    wBody.querySelector(".w-replay")?.focus({ preventScroll: true });
    playStory(id).catch(ignoreCancel);
  }

  function onSkip() {
    stopAll();
    const id = runId;
    results[index] = "skipped";
    phase = "skipping";
    renderWatch("skipping");
    (async () => {
      await speak(SKIP_LINE, id);
      next();
    })().catch(ignoreCancel);
  }

  function next() {
    if (index < FINDS.length - 1) {
      startFind(index + 1);
      focusWatchArea();
    } else {
      finishWalk();
    }
  }

  function focusWatchArea() {
    // Keep keyboard users near the watch as content changes.
    if (document.activeElement && document.activeElement !== document.body && !wBody.contains(document.activeElement)) return;
    $("watch-screen").setAttribute("tabindex", "-1");
    $("watch-screen").focus({ preventScroll: true });
  }

  function finishWalk() {
    stopAll();
    const id = runId;
    phase = "done";
    renderWatch("done");
    replayLines = [DONE_LINE];
    (async () => {
      await wait(600, id);
      await wristTap(id);
      await wait(BUZZ_GAP, id);
      await speak(DONE_LINE, id);
      await wait(900, id);
      openJournal();
    })().catch(ignoreCancel);
  }

  function onReplay() {
    const lines = replayLines.slice();
    const wasPhase = phase;
    stopAll();
    const id = runId;
    (async () => {
      if (wasPhase === "story" || wasPhase === "continue") {
        phase = "story";
        renderWatch("story");
        for (let k = 0; k < lines.length; k++) {
          if (k) { await wait(700, id); }
          await speak(lines[k], id);
        }
        phase = "continue";
        renderWatch("continue");
        focusWatchButton();
      } else if (wasPhase === "done") {
        await speak(lines[0], id);
        await wait(900, id);
        openJournal();
      } else {
        await speak(lines[0], id);
      }
    })().catch(ignoreCancel);
  }

  function ignoreCancel(e) { if (!(e instanceof Cancelled)) console.error(e); }

  // ---------- Phone screens ----------
  function openStart() {
    stopAll();
    phoneStart.hidden = false;
    phoneJournal.hidden = true;
    show("phone");
    $("btn-start").focus({ preventScroll: true });
  }

  function openJournal() {
    stopAll();
    const found = results.filter((r) => r === "found").length;
    $("journal-summary").textContent = `You noticed ${found} of ${FINDS.length} things you've walked past.`;
    $("journal-list").innerHTML = FINDS.map((f, i) => {
      const st = results[i] === "found" ? "found" : "skipped";
      return `<li class="j-card ${st}">
        <img src="${f.img}" alt="${f.alt}">
        <div>
          <div class="j-head"><p class="j-name">${f.name}</p><span class="badge ${st}">${st === "found" ? "Found" : "Skipped"}</span></div>
          <p class="j-cat">${f.category}</p>
          <p class="j-reveal">${f.reveal}</p>
        </div>
      </li>`;
    }).join("");
    phoneStart.hidden = true;
    phoneJournal.hidden = false;
    show("phone");
    phoneJournal.querySelector(".journal-title").focus({ preventScroll: true });
  }


  // ---------- Wiring ----------
  $("btn-open").addEventListener("click", () => {
    unlockAudio();
    openStart();
  });

  $("btn-start").addEventListener("click", () => {
    unlockAudio(); // re-unlock in case the context was suspended meanwhile
    results = [];
    show("walk");
    startFind(0);
  });

  $("btn-again").addEventListener("click", () => {
    results = [];
    openStart();
  });

  wBody.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-act]");
    if (!btn) return;
    const act = btn.dataset.act;
    if (act === "found") onFound();
    else if (act === "skip") onSkip();
    else if (act === "continue") next();
    else if (act === "next") { stopAll(); next(); } // leave the story early; still counts as found
    else if (act === "replay") onReplay();
    else if (act === "pause") onPause();
    else if (act === "resume") onResume();
  });

  // Chrome pauses long-running speech queues in background tabs; resume when visible again.
  document.addEventListener("visibilitychange", () => {
    if (!document.hidden && synth && synth.paused) synth.resume();
  });

  // Expose a tiny hook for automated testing only.
  window.__stroll = { get phase() { return phase; }, get index() { return index; }, get results() { return results.slice(); } };
})();
