# Update: companion app and watch, Nov 7

Everything here is in the branch **`flora/demo-walk`**, which builds on Mara's Explore map branch
(`mara/explore-map`). Merge Mara's pull request first, then this one.

## The phone runs the walk and speaks the guide

- Tap **Start Exploring** and the demo walk begins. The first point of interest comes up after
  about 20 seconds; the next one comes 30–60 seconds after you tap **Keep exploring** or **Skip**.
- The **voice plays from the iPhone**, so it works with **any headphones** connected to the phone,
  or the speaker. No watch needed.
- Each spot: the phone buzzes, shows the photo, then asks the question. **Tell me more** plays the
  answer and story; **Skip** moves on.
- **Transcript:** once the story starts, all the text is on screen. The line being read is dark,
  the rest grey, so people can read ahead or look back. While the question is asked, only the
  question shows, so the answer isn't given away.
- Big **Pause / Resume** and **Replay** buttons. Pausing also stops the next spot from popping
  up, which helps when a participant pauses to talk to us.
- If a timer, alarm or call interrupts the audio, or headphones disconnect, the walk **pauses**
  instead of getting stuck.

## The watch mirrors the phone

- One walk, one voice: the phone's. The watch buzzes, shows the photo, and has **Tell me more /
  Skip / Keep exploring / Pause / Replay / End**. A tap on either device updates both.
- The photo stays on screen through the question and story, so people can compare it with what's
  in front of them. Replay and Pause sit on the photo's top corners.
- **Done** on the Walk complete screen returns both devices to the start.
- Start Exploring on the phone opens Stroll on the watch automatically.
- **Known issue:** tapping Start Exploring *on the watch* can lag before both devices update.
  Parked for later; next step is checking Xcode's live logs while reproducing it.

## Live Journal

- Each point of interest appears **the moment it's explored or skipped**, newest first, and is
  saved on the phone, so it's still there after the walk and after closing the app.
- Cards open to the photo, the full story, when it was found, the photo credit and **Listen
  again**. Skipped ones hide the story. Only the card's top row opens and closes it.
- **Clear** (top right) empties it, e.g. between participants.

## Looks

- Brand green (`#2F6B4F`) on the watch and phone.
- **Dark mode:** the map goes dark; the bottom card, the tab bar and the Journal stay light so
  everything is readable. We now have our own tab bar, with the selected tab in green in both
  modes.

## Behind the scenes

- The old moderator remote is gone. **Developer tools** (the settings button on the map) shows
  the watch connection and can bring up any point of interest instantly, for testing.
- The demo walk feeds **fake locations** into the same detection code real GPS will use later,
  so switching to live location will be a setting, not a rebuild.
- The watch no longer runs its own walk or plays narration; `docs/WATCH-EXPLORING-CHANGES.md` is
  superseded by this.
- Automated checks cover the walk logic, the phone–watch messages and the Journal:
  `Tools/check-walk-model.sh` (runs on any Mac, no Xcode needed).

## To discuss

- **Bundle ID:** changed to `com.teamgreen.stroll` (and `com.teamgreen.stroll.watchkitapp`),
  dropping the old `.remote`. It becomes permanent at our first TestFlight upload, so let's agree
  on it first. Users never see it; the app name can change anytime.
- **Round 1 plan:** `docs/round1-plan.md` still says "the watch leads". We changed that to **the
  phone leads** (phone plays the voice, watch mirrors), so the plan needs updating together.

## Coming up

- **TestFlight**, so everyone can install the app on their own iPhone. No Xcode or watch needed;
  the watch app comes along automatically for anyone with an Apple Watch.
- **Narration fixes** from Makaela's research (e.g. the Mellon columns are about 62 tons, not 60)
  need re-recording, and her coordinates need merging into `Shared/Content/stroll-content.json`.
- Later: real GPS triggers, the watch Start lag, and possibly letting the watch speak out loud
  when no headphones are connected to the phone.
- Before a public beta: a privacy policy link, the app privacy form, and a clear explanation of
  why the watch uses a HealthKit walking session (to stay awake with the wrist down).
