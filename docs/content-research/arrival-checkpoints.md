# Stroll: arrival checkpoints for all 56 places

Drafted November 24, 2026. In user testing, people were still trying to find the place when
the audio moved on to the question. To fix that, each arrival now has a **checkpoint**. The
current prompt is split into a **locate** line and a **question**, and for most places the
guide waits until the person has found the place before asking the question.

The places are grouped by area. Each heading ends with the place's `id` in
`Shared/Content/stroll-content.json`. Reveals and stories don't change. How the app should use
these lines is in [`docs/plans/arrival-checkpoints.md`](../plans/arrival-checkpoints.md).

## The three kinds of arrival

| Kind | Places | What happens |
|---|---|---|
| **Find it** | 47 | Locate line, then the checkpoint. The question plays after **Found it**. **Help me find it** plays the help line, then the checkpoint again. |
| **You're here** | 6 | Locate line, a 3-second pause, then the question. There's nothing to find, because you're already standing in it. |
| **Used to be here** | 3 | Locate line, then the question straight away. There's nothing left to find, so there's no checkpoint. |

- **You're here:** Oakland Square, Schenley Farms, Flagstaff Hill, Junction Hollow, Forbes and
  Murray, Chatham University Arboretum.
- **Used to be here:** Pitt Stadium, Schenley Park Casino, Syria Mosque.
- **Find it:** every other place.

## Shared lines (used at every "find it" place)

| When | Spoken and shown |
|---|---|
| Checkpoint, after the locate line | "Tap **Found it** when you see it." |
| No tap after about 20 seconds | "Still looking? Take your time. The photo on your phone can help." |
| Still no tap after another 20 seconds | "No problem. I'll save this one in your Journal for later." |

**Buttons:** **Found it** · **Help me find it** · **Skip**. On the watch, **Found it** is one
large button, with **Help** below it.

## How these were written

- **Locate** says where the place is and describes what you can see, so people know what to
  search for. It's up to about 25 words.
- **Giving away the answer is fine.** Stroll is about learning, not a scavenger hunt, so a
  locate or help line can name a place or a detail even when that hints at the answer.
- **Question** is the rest of the current prompt. Any detail the question depends on is kept in
  it, even when the locate line already mentions that detail.
- **Help** gives a different clue from the locate line: a cross street, a nearby place that's
  also in Stroll, or another detail from the photo. It never says "on your left" or "on your
  right", because the app doesn't know which way the person is facing, and 10 pins are only
  estimated.
- Like the prompts, these lines don't say "look", "spot" or "find".
- **⚠** marks a clue to confirm on site. **⚠ Site visit** means we don't know enough yet to
  write a good help line.

## Open questions for the team

1. **Journal after "save for later":** should a place nobody found count as found, or show as a
   "Mystery location", like set-walk stops you missed? Until the team decides, the app treats it
   like **Skip** (see `docs/plans/arrival-checkpoints.md`).
2. **Audio:** every place needs new Sky clips for its locate, question and help lines. The
   current prompt clips can't be cut in two cleanly. The three shared lines need clips too.

---

## Oakland, Pittsburgh

### 1. Mellon Institute columns · Find it · `mellon-columns`
- **Locate:** On Fifth Avenue, a huge stone building has a long row of giant columns across its front.
- **Question:** How many pieces of stone do you think make up one column?
- **Help:** The columns line the whole Fifth Avenue front, at the corner of Bellefield Avenue.

### 2. Dippy the dinosaur · Find it · `dippy`
- **Locate:** Outside the Carnegie Museum on Forbes Avenue, a life-size dinosaur stands on the lawn, its long neck curving up.
- **Question:** Is it made of real bone, or something else?
- **Help:** It stands near the corner of Forbes Avenue and South Craig Street, at the east end of the museum. ⚠

### 3. "A Song to Nature" fountain · Find it · `song-to-nature`
- **Locate:** Near Schenley Plaza and the Carnegie Library, a big stone fountain has a wide round basin with bronze figures in the middle.
- **Question:** Around the rim, bronze animals spout water. What kind of animals are they?
- **Help:** It's on Schenley Drive, where the plaza's lawn meets the road.

### 4. Forbes Field wall · Find it · `forbes-wall`
- **Locate:** On Roberto Clemente Drive, a long, old red brick wall stands on its own, with big white numbers painted on it.
- **Question:** What do you think the numbers measure?
- **Help:** It runs alongside the street, across from Pitt's Posvar Hall.

### 5. St. Nicholas Greek Orthodox Cathedral · Find it · `st-nicholas-cathedral`
- **Locate:** On South Dithridge Street, a pale stone church has six tall columns on its front porch and wide steps up to the door.
- **Question:** Each column curls out into a shape at the top. What shape do you think it is?
- **Help:** It's near the corner of Dithridge Street and Forbes Avenue, with a triangular roof above the columns.

### 6. Bellefield Hall · Find it · `bellefield-hall`
- **Locate:** On Bellefield Avenue, a large red brick building on a corner has a tall arched stone doorway at one end.
- **Question:** Words carved above the doorway name who it was built for. Who do you think it was?
- **Help:** It's just up Bellefield Avenue from the Mellon Institute's giant columns. Iron lanterns hang by the main entrance.

### 7. Heinz Memorial Chapel · Find it · `heinz-chapel`
- **Locate:** On Pitt's campus, a pale stone chapel with one very tall, thin, pointed spire stands on its own on a wide lawn.
- **Question:** Shields are carved into its stone walls. What do you think they stand for?
- **Help:** It's right beside the Cathedral of Learning, the tall stone tower.

### 8. Cathedral of Learning · Find it · `cathedral-of-learning`
- **Locate:** A pale stone tower rises high above the campus, with long, narrow pointed windows running up its sides.
- **Question:** How many floors do you think it has?
- **Help:** It's the tallest building around, between Fifth and Forbes Avenues.

### 9. The Hiker · Find it · `the-hiker`
- **Locate:** At the edge of Schenley Park, a bronze soldier in a wide-brimmed hat stands on a stone base, holding a rifle across his body.
- **Question:** Words on the front of the base name the war he fought in. Which war do you think it was?
- **Help:** He stands beside Schenley Drive, at the edge of the park. ⚠ Site visit: add a nearby landmark.

### 10. First Baptist Church · Find it · `first-baptist-church`
- **Locate:** At Bellefield Avenue and Bayard Street, a pale stone church has tall pointed windows and a thin spire that has turned green.
- **Question:** Why do you think the spire is green?
- **Help:** It's on the corner, a block from the Mellon Institute's giant columns. The spire is the tallest thing on the block.

### 11. St. Paul Cathedral · Find it · `st-paul-cathedral`
- **Locate:** On North Dithridge Street at Fifth Avenue, a pale stone cathedral has two tall towers with a big pointed window between them.
- **Question:** A row of arched doorways runs across its front. How many do you think there are?
- **Help:** The brick church right next door has a cross near the top of its tower.

### 12. Fairfax Apartments · Find it · `fairfax-apartments`
- **Locate:** On Fifth Avenue, a tall, wide red brick apartment building has rows of windows and pale stone trim along the roofline.
- **Question:** Fancy carved stone tops crown that roofline. How many do you think there are?
- **Help:** It's a short walk east of St. Paul Cathedral's twin towers, the tallest brick building on that stretch. ⚠

### 13. Allen Hall · Find it · `allen-hall`
- **Locate:** On O'Hara Street, a six-story stone building has four tall columns across the middle and a triangular roof above them.
- **Question:** A bronze plaque by the entrance honors a famous scientist. Who do you think it is?
- **Help:** It's a block up the hill from Fifth Avenue. The plaque is beside the main entrance. ⚠

### 14. Carnegie Institute and Library · Find it · `carnegie-institute-and-library`
- **Locate:** Along Forbes Avenue, a long, grand stone building has a row of arched windows, with bronze figures sitting out front.
- **Question:** There are four of them, two by the concert hall and two by the museum doors. What do they have in common?
- **Help:** It's the huge building across Forbes Avenue from Schenley Plaza, with Dippy the dinosaur on its lawn.

### 15. Main Branch of the Carnegie Library of Pittsburgh · Find it · `main-branch-of-the-carnegie-library-of-pittsburgh`
- **Locate:** In the Carnegie building on Forbes Avenue, the library has a wide stairway up to three arched doors, with a row of columns above.
- **Question:** Words are carved in stone above the doors. What do they promise?
- **Help:** The library entrance is at the end of the building closest to Schenley Plaza. ⚠

### 16. Panther Hollow Bridge · Find it · `panther-hollow-bridge`
- **Locate:** In Schenley Park, a steel arch bridge crosses a deep wooded hollow, with a big bronze animal crouching on a stone base at each corner.
- **Question:** What animal do you think it is?
- **Help:** There are four animals, two at each end of the bridge. It's the Panther Hollow Bridge, on the road through the park. ⚠ Site visit: add a nearby landmark.

### 17. Pittsburgh Athletic Association · Find it · `pittsburgh-athletic-association`
- **Locate:** On Fifth Avenue, an eight-story stone clubhouse has tall arched windows and carved decoration.
- **Question:** It was modeled on palaces in an Italian city. Which city do you think?
- **Help:** It's at Fifth Avenue and Bigelow Boulevard, across from the Cathedral of Learning.

### 18. Pittsburgh Chinese Church · Find it · `pittsburgh-chinese-church`
- **Locate:** On North Dithridge Street, a brick church has a tall square tower with a cross near the top.
- **Question:** Words run down the front of the tower in two languages. Which two?
- **Help:** It's right next door to St. Paul Cathedral and its two tall towers.

### 19. Schenley Bridge · Find it · `schenley-bridge`
- **Locate:** Behind the Carnegie Museum, a long steel arch bridge carries the road over a deep wooded valley.
- **Question:** Small metal objects are clipped all along its railings. What are they?
- **Help:** It runs from Schenley Drive by the museum toward Flagstaff Hill. The objects are on the railings on both sides.

### 20. Main Building, U.S. Bureau of Mines · Find it · `main-building-u-s-bureau-of-mines`
- **Locate:** Along Forbes Avenue, at the edge of Carnegie Mellon's campus, a long pale brick building has a row of tall arched windows on its lower floor.
- **Question:** It was built for the U.S. government. What do you think it studied?
- **Help:** It's across Forbes Avenue from Carnegie Mellon's main campus. ⚠ Confirm the cross street.

### 22. Bindley Hardware Company Building · Find it · `bindley-hardware-company-building`
- **Locate:** On Amberson Avenue, a large three-story red brick warehouse sits right beside the railroad tracks.
- **Question:** Why do you think it was built here?
- **Help:** It's at the bottom of Amberson Avenue, where the road meets the tracks and the busway. ⚠

### 23. Church of the Ascension · Find it · `church-of-the-ascension`
- **Locate:** At Ellsworth Avenue and North Neville Street, a dark gray stone church has a tall square tower.
- **Question:** Its first stone was laid on a famous holiday. Which one?
- **Help:** Its front door is painted red.

### 24. McCook Family Estate · Find it · `mccook-family-estate`
- **Locate:** On Fifth Avenue, a large gray stone mansion has tall chimneys, bay windows and a stone balustrade.
- **Question:** What do you think it is today?
- **Help:** It's nearly across Fifth Avenue from a white house with arched windows. ⚠

### 25. Moreland-Hoffstot House · Find it · `moreland-hoffstot-house`
- **Locate:** On Fifth Avenue, a white two-story mansion sits behind two clipped hedges and a lawn.
- **Question:** The ground floor has a row of arched openings, front door included. How many do you think there are?
- **Help:** It's nearly across Fifth Avenue from the big gray stone McCook mansion. ⚠

### 26. Shadyside Presbyterian Church · Find it · `shadyside-presbyterian-church`
- **Locate:** On Westminster Place, a large stone church has a broad, steep roof that rises to a point over the middle.
- **Question:** A small window pokes out on each side of that roof. What does it remind you of?
- **Help:** It's at the corner of Westminster Place and Amberson Avenue, with a small tower at the very top of the roof. ⚠

### 27. Bellefield Boiler Plant · Find it · `bellefield-boiler-plant`
- **Locate:** Down in the hollow behind the Carnegie Museum, a brick building has a very tall, thin concrete smokestack rising out of it.
- **Question:** What do you think this plant heats?
- **Help:** The smokestack is easiest to see from the Schenley Bridge, rising above the trees.

### 28. Log Cabin · Find it · `log-cabin`
- **Locate:** On the lawn beside the Cathedral of Learning, a small log cabin with a stone chimney and a porch sits below the tall tower.
- **Question:** What do you think it's used for now?
- **Help:** It's close to the base of the tower, on the lawn. ⚠ Confirm which side.

### 29. Oakland Square Historic District · You're here · `oakland-square-historic-district`
- **Locate:** You're in Oakland Square. The houses around you circle a small park, like the squares of London and Dublin.
- **Question:** What do most of them have on the front?

### 30. Pitt Stadium · Used to be here · `pitt-stadium`
- **Locate:** A huge football stadium stood right around here for 75 years. The old photo on your phone shows it packed with fans.
- **Question:** What do you think was built on this spot after it?

### 31. Salk Hall · Find it · `salk-hall`
- **Locate:** On Terrace Street, a tall tan brick building rises in steps, with narrow rows of windows running up it.
- **Question:** It was built in 1941 for something very different from teaching. What do you think it was?
- **Help:** It's up the hill on Pitt's upper campus, near the Petersen Events Center. ⚠

### 32. Schenley Farms Historic District · You're here · `schenley-farms-historic-district`
- **Locate:** You're in Schenley Farms, a neighborhood of grand stone buildings and big old houses.
- **Question:** Many big buildings around you resemble Greek temples or Italian palaces. Why do you think they match?

### 33. Schenley Park Casino · Used to be here · `schenley-park-casino`
- **Locate:** Right where the art building beside you stands, there used to be a big arena with towers. The old photo on your phone shows it.
- **Question:** It held an ice rink. What do you think made it special?

### 34. Soldiers and Sailors Memorial Hall and Museum · Find it · `soldiers-and-sailors-memorial-hall-and-museum`
- **Locate:** On Fifth Avenue, a huge, square stone memorial hall with columns sits back behind a wide lawn with cannons.
- **Question:** Which war do you think it was first built to honor?
- **Help:** It's a short walk from the Pittsburgh Athletic Association's stone clubhouse, across Fifth Avenue from Pitt's campus.

### 35. Stephen Foster Memorial · Find it · `stephen-foster-memorial`
- **Locate:** On Forbes Avenue, beside the Cathedral of Learning, stands a Gothic-style stone building with red double doors. A stone sundial is on the grounds nearby.
- **Question:** Something important is missing from the sundial. What?
- **Help:** ⚠ Site visit: where the sundial is on the grounds.

### 36. Syria Mosque · Used to be here · `syria-mosque`
- **Locate:** A grand concert hall with 3,700 seats stood right around here, on Bigelow Boulevard, until 1991. The old photo on your phone shows it.
- **Question:** What do you think replaced it?

### 37. Neill Log House · Find it · `neill-log-house`
- **Locate:** In Schenley Park, a small one-story house of dark hewn logs sits on a stone foundation, with a stone chimney.
- **Question:** On one side is a tiny window, about one foot high and two feet wide. Why do you think it's so small?
- **Help:** ⚠ Site visit: a nearby path or road, and which side the small window is on. People can't tell east from west, so the question no longer says "the east side".

### 38. Rodef Shalom Temple · Find it · `rodef-shalom-temple`
- **Locate:** At Fifth and Morewood Avenues, a wide yellow brick temple has a broad arched entrance and colorful terra cotta trim.
- **Question:** A huge dome covers the main hall. What do you think holds it up?
- **Help:** The broad arched entrance faces Fifth Avenue.

### 39. Phipps Conservatory and Botanical Gardens · Find it · `phipps-conservatory-and-botanical-gardens`
- **Locate:** At the edge of Schenley Park, a Victorian glass and iron greenhouse has a large glass dome, surrounded by gardens.
- **Question:** It opened in 1893. Where do you think its very first plants came from?
- **Help:** It's on Schenley Drive, with the big glass dome at the front.

### 40. Flagstaff Hill · You're here · `flagstaff-hill`
- **Locate:** You're on Flagstaff Hill, the wide grassy slope across Schenley Drive from Carnegie Mellon.
- **Question:** It fills up with picnics, frisbees and sleds. What do you think once stood on it?

### 41. Junction Hollow · You're here · `junction-hollow`
- **Locate:** You're at Junction Hollow, the deep wooded valley below Carnegie Mellon's campus.
- **Question:** It's named after something that runs along its floor. What do you think it is?

### 42. Christopher Lyman Magee Memorial · Find it · `christopher-lyman-magee-memorial`
- **Locate:** Near the Carnegie Museum, a tall granite slab has a bronze woman holding a horn of fruit, above a curved stone bench.
- **Question:** At the bottom, water once poured from a bronze animal's mouth. Which animal?
- **Help:** It's at the corner of Forbes Avenue and Schenley Drive, by the museum. ⚠

### 43. Westinghouse Memorial · Find it · `westinghouse-memorial`
- **Locate:** In Schenley Park, three bronze panels stand in a half circle beside a lily pond, with a statue of a boy facing them.
- **Question:** Small bronze animals hold up each of the picture panels. What animal are they?
- **Help:** ⚠ Site visit: which path leads down to the pond from the road.

## Squirrel Hill, Pittsburgh

### 21. Wightman School · Find it · `wightman-school`
- **Locate:** In Squirrel Hill, a three-story red brick school building has arched windows and a black iron fire escape.
- **Question:** It hasn't had pupils since 1980. What do you think it's used for now?
- **Help:** It's on Solway Street, right next to Wightman Park. ⚠

### 51. Manor Theatre · Find it · `manor-theatre`
- **Locate:** On Murray Avenue, a two-story corner building has timber beams set into its walls, like an old English cottage.
- **Question:** What do you think has been inside it for over a hundred years?
- **Help:** It's a short walk south of Forbes Avenue, with steep brown roofs.

### 52. Forbes and Murray · You're here · `forbes-and-murray`
- **Locate:** You're at Forbes and Murray, where two busy streets cross, lined with bakeries, delis and shops.
- **Question:** Locals have a nickname for this shopping strip. What do you think they call it?

### 53. Temple Sinai (Worthington Mansion) · Find it · `temple-sinai`
- **Locate:** On Forbes Avenue, a big stone mansion with tall chimneys and leaded windows sits back behind a lawn and a curving path.
- **Question:** It was built in 1914 for an oil company executive. What do you think it has been since the 1940s?
- **Help:** It's set well back from the street, behind old trees, a few blocks west of Murray Avenue.

### 54. Sunnyledge · Find it · `sunnyledge`
- **Locate:** On Fifth Avenue, a large red brick house has a big round tower at one corner, under a cone-shaped roof.
- **Question:** What do you think the room in that tower was used for?
- **Help:** It sits above the street on a sloping lawn, with a tall chimney behind the tower.

### 55. Andrew Mellon Hall · Find it · `andrew-mellon-hall`
- **Locate:** On Chatham's campus, off Woodland Road, a large red brick Tudor-style mansion has three pointed gables and tall chimneys.
- **Question:** In 1917, banker Andrew Mellon bought this house and more than doubled its size. One addition was rare in a home back then. What do you think it was?
- **Help:** Its front door is set in a carved stone doorway, behind trimmed shrubs.

### 56. Chatham University Arboretum · You're here · `chatham-university-arboretum`
- **Locate:** You're on Chatham University's campus, among old trees and wide lawns.
- **Question:** This was once one man's private estate. Today the whole campus counts as something special. What do you think it is?

## Niles, Fremont

### 44. Niles Depot and Town Plaza · Find it · `niles-depot`
- **Locate:** On Niles Boulevard, a long, low yellow wooden train station has a wide gray roof, with a red caboose at the far end.
- **Question:** When it came back downtown in 2009, movers changed one thing about the way it sits. What do you think they changed?
- **Help:** It's beside the town plaza, near the railroad tracks, with its long front facing the plaza.

### 45. Transcontinental Railroad marker · Find it · `niles-transcontinental-marker`
- **Locate:** Near Niles Boulevard, a short pillar of rough gray stones has a bronze plaque on its front.
- **Question:** Most people think the Transcontinental Railroad was finished with a golden spike in Utah. How long after that do you think the last link through this canyon opened?
- **Help:** It stands in front of an old green passenger car. ⚠ Confirm the car is still there.

### 46. Hillside NILES sign · Find it · `niles-hillside-sign`
- **Locate:** Up on the dry hillside above town, giant white letters spell out the town's name.
- **Question:** When the sign first went up, who do you think it was meant to help?
- **Help:** The letters are on the hills behind Niles Boulevard, high above the rooftops.

### 47. Niles Essanay Silent Film Museum · Find it · `niles-essanay-museum`
- **Locate:** On Niles Boulevard, a two-story white building with dark green trim has a row of shopfronts and a museum sign over the middle door.
- **Question:** Under the museum's sign hangs a second sign, with the building's name from 1913. What do you think it says?
- **Help:** It's about half a block from the red brick fire station.

### 48. Essanay Studio site · Find it · `niles-essanay-studio-site`
- **Locate:** On Niles Boulevard, a two-story red brick fire station on a corner has arched garage doors and a band of diamond tiles along its base.
- **Question:** A plaque here marks where a film studio once stood, in what it calls America's first Hollywood. Which famous comedian do you think made movies here?
- **Help:** It's about half a block from the silent film museum. ⚠ Site visit: where the plaque is on the building.

### 49. Vallejo Flour Mill · Find it · `vallejo-flour-mill`
- **Locate:** Near Mission Boulevard, a plaque remembers an old flour mill. Its roofless stone walls still stand nearby, behind a chain-link fence.
- **Question:** José de Jesús Vallejo built that mill. Before this town was called Niles, what do you think it was named?
- **Help:** ⚠ Site visit: where the plaque is, and a landmark next to it.

### 50. Jane R. Clouch Memorial Library · Find it · `niles-library`
- **Locate:** On I Street, a small white library with a red tile roof and tall many-paned windows sits on a street corner.
- **Question:** It's older than the city it stands in. Who do you think still owns it?
- **Help:** It's a single-story building on the corner, smaller than its neighbors. ⚠ Add a cross street.
