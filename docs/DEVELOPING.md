# Developing Stroll

```
Phone/           iPhone app: Explore map, Walks, Journal, intro screens, Developer tools
  Walk/          The walk itself: ExploreSession (logic), PhoneGuide (audio), DemoWalk, LiveLocation
Watch/           Watch app: mirrors the phone, buzzes, sends taps back
Shared/          Content model and phone↔watch messages
  Content/stroll-content.json   Every place, walk and line of text
Resources/       Voice clips (Audio/) and photos (Assets.xcassets)
Tools/           Checks, voice generator, walk-route builder
docs/            Plans, content research and drafts, updates
web-prototype/   The browser prototype from the first round of interviews
```

**Checks** (any Mac, no Xcode needed): content file, walk logic, Journal, phone↔watch messages
and the intro flow.
```bash
Tools/check-walk-model.sh
```

**Adding places or changing text:** edit `Shared/Content/stroll-content.json` (with alt text,
photo credit and a descriptive question), add the photo to `Resources/Assets.xcassets`, then
generate the voice clips with `Tools/voice/generate.py` (setup in `docs/content-drafts/README.md`)
and run `xcodegen generate`.

**TestFlight:** bump `CURRENT_PROJECT_VERSION` in `project.yml`, run `xcodegen generate`, archive
the **StrollRemote** scheme (*Product → Archive*) and upload. Give new builds to the internal
group first, and to external testers once they're checked.
