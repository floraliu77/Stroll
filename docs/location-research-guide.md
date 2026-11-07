# Stroll: Location research guide

This guide explains how to find and write up the stops for Stroll's next walk around the
300 SC area. You can follow it by hand, or paste it into Claude and work through it together
(see [Using this guide with Claude](#using-this-guide-with-claude)).

> **Round 1 note.** The first round of testing is **free exploring only** (see `docs/round1-plan.md`):
> there's no set route, so stops don't need a walking order, and the **cue** (direction) line and
> **nearby places** aren't used yet. Fill them in if you have them, since later rounds may use
> them, but don't let them hold anything up.

## What Stroll is, in short

Stroll is an audio walking guide for Apple Watch, iPhone and earbuds. As you walk, the watch
buzzes when you reach a point of interest. It shows a photo, then asks you to **look for one
specific detail**. If you tap *Tell me more*, you hear the answer and a short story. The iPhone
app shows points of interest on a map and keeps a journal of everything you've found.

Every stop follows the same pattern:

1. **Cue** *(optional; not used in round 1)*: how to get there, or where to stand.
2. **Prompt**: a question that makes you look closely at one detail.
3. **Reveal**: the answer to the question.
4. **Story**: three short lines with surprising facts.

Here is a real stop from the first walk, to show the tone and length:

| Field | Example |
| --- | --- |
| Name | Mellon Institute columns |
| Category | Architecture |
| Cue | Start at Fifth Avenue and Bellefield. |
| Prompt | Look at the giant columns on this building. How many stone pieces make up one column? |
| Reveal | None stacked. Each column is a single piece of stone. |
| Story 1 | Each of the 62 columns here is one solid piece of Indiana limestone, about 60 tons. |
| Story 2 | When the Mellon Institute opened in 1937, they were the largest monolithic columns in the world. |
| Story 3 | The building, now part of Carnegie Mellon, reaches six stories underground to bedrock, to keep lab experiments steady. |

## What we need

- **4 to 6 stops** around the 300 SC area, in any order. Four is enough for the first test.
- **A photo of each stop.**
- **A source for every fact.**
- *Later rounds, optional:* 2 to 4 nearby places for each stop, for the map in the iPhone app.

The first tests use a scripted "demo walk", so participants don't need to be at the real places.
Still, choose stops about 2 to 5 minutes' walk apart, so someone wandering the area would come
across them, because real GPS triggers will come later and use the same places.

## What makes a good stop

A good stop has all of these:

- **Something visible to look at.** The prompt asks people to notice a detail, so there has
  to be one: a carving, a number, an odd shape, a plaque, a material, an animal in a sculpture.
  "This building has an interesting history" isn't enough on its own.
- **A question with a clear, surprising answer.** People should be able to find the answer by
  looking, and be a little surprised by it.
- **A story worth hearing.** Facts most passers-by don't know: who made it, a record, a strange
  event, a connection to something famous.
- **Facts you can check.** Each one has a reliable source: an official site, a museum or
  university page, a historical society, a newspaper, a book. Not just a blog or an AI answer.
- **A safe, easy place to stand.** Out of traffic, on public ground, reachable for someone
  using a wheelchair if possible.

A mix of categories makes the walk more interesting. The first walk used *Architecture*,
*Natural history*, *Public art* and *History*. Other categories are fine, such as *Science*,
*Food*, *Nature* or *Music*.

## How to write each field

The text is turned into recorded narration, and the watch screen is small. Write for the
**ear**: short sentences, plain words, no parentheses or abbreviations. Spell out anything
that's awkward to say aloud.

| Field | What to write | Length |
| --- | --- | --- |
| **Name** | What the place is called. | A few words |
| **Category** | One word or short phrase, like *Public art*. | 1 to 3 words |
| **Latitude, Longitude** | Where to stand to see the detail (see [Getting coordinates](#getting-coordinates)). | 6 decimal places |
| **Cue** *(optional; not used in round 1)* | A direction or where to stand. Use street names and landmarks. | One sentence, up to about 15 words |
| **Prompt** | A question that makes people look for one detail. | Up to about 25 words |
| **Reveal** | The answer to the prompt. | One sentence |
| **Story 1, 2, 3** | Three facts, from the most surprising to the most interesting background. Each should make sense on its own. | One or two sentences each, up to about 30 words |
| **Photo file** | File name of the photo, like `stop1-columns.jpg`. | |
| **Photo credit** | Who took it, and the license if it isn't yours. | |
| **Sources** | Links for every fact in the reveal and story. | |
| **Notes** | Anything else: opening hours, things to watch out for, ideas. | |

## Nearby places

*Later rounds, optional: not shown in the round 1 app.*

For each stop, list 2 to 4 places within a short walk that a curious person might like:
a café, a small museum, a mural, a park, a viewpoint, a building with a story.

| Field | What to write |
| --- | --- |
| **Stop number** | Which stop it's near. |
| **Name** | What it's called. |
| **Type** | For example *Café*, *Museum*, *Mural*, *Park*. |
| **Description** | One sentence on why it's worth a look. |
| **Latitude, Longitude** | Its location. |
| **Source** | A link: its website, or a reliable page about it. |

## Getting coordinates

- **Google Maps (computer):** right-click the exact spot. The first line of the menu shows
  the coordinates, and clicking it copies them.
- **Apple Maps (iPhone):** press and hold the spot to drop a pin, then swipe up on the pin's
  card to see the coordinates.

Use the spot where people should **stand to see the detail**, not the middle of the
building. Keep 6 decimal places, for example `40.446100, -79.951000`.

## Photos

- Your own photos are best. If you use someone else's, it must allow reuse (for example
  Wikimedia Commons), and you need to note the credit and license.
- **Landscape** orientation, at least **1200 pixels wide**, JPG.
- The detail people are asked to find should be **in the middle of the frame**. The watch
  crops the photo to a wide strip, so anything near the top or bottom may be cut off.
- Name them by stop number, for example `stop1-columns.jpg`.

## How to hand it over

Put everything in a **Google Sheet** with two tabs, and use these column headings exactly,
so it can be converted into the app automatically.

**Tab 1: `Stops`**

```
stop_number | name | category | latitude | longitude | cue | prompt | reveal | story_1 | story_2 | story_3 | photo_file | photo_credit | sources | notes
```

**Tab 2: `Nearby`**

```
stop_number | name | type | description | latitude | longitude | source
```

Put the photos in a shared folder, named to match `photo_file`. Then share the sheet and the
folder with Flora.

## Checklist before handing over

- [ ] 4 to 6 stops, about 2 to 5 minutes' walk apart
- [ ] Every stop has something specific to look at, and the prompt asks about it
- [ ] Every reveal answers its prompt
- [ ] Every fact has a source, and you've checked it
- [ ] Texts are short and read well aloud (try reading them out)
- [ ] Coordinates are where to stand, checked on a map
- [ ] Every stop has a photo with the detail in the middle, plus a credit
- [ ] *(Optional, later rounds)* 2 to 4 nearby places for each stop

## Using this guide with Claude

Claude can help you brainstorm places, draft the texts and fill in the sheet. Paste this
whole guide into a chat, then start with something like:

> I'm researching stops for Stroll, using the guide above. Suggest 8 to 10 candidate stops
> within a 10-minute walk of the 300 SC area, with what people could look for at each one.
> For each, give the sources you're relying on.

Then choose the best 4 to 6 together and ask Claude to draft each field in the format above.

**Check what Claude gives you.** Claude can get facts, dates and places wrong, or describe
details that don't exist. Before anything goes into the sheet:

- open every source link and confirm it says what the text says;
- check every coordinate on a map;
- if possible, visit the spot, or look at it in Street View, to confirm the detail in the
  prompt is really there and visible.
