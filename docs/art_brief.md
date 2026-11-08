> **SUPERSEDED (Nov 7, 2026): art direction changed away from EarthBound.** New direction:
> world + sprites in modern high-detail pixel art like *Sea of Stars*; dialogue portraits and boss
> intros in a bold cartoon look like *Hazbin Hotel* (humans, not demons). Current prompts live in the
> Drive doc "DuffQuest — Style bible + Grok prompts": https://docs.google.com/document/d/1lmADUpw6NO0A_rvmwdox_t2oJoh8yZVLc1AXliRUwnE/edit
> The folder layout and workflow below still apply; the EarthBound base prompt does not.

# DuffQuest art brief: personality pass (for Grok)

**Where it goes:** Google Drive → `DuffQuest Art Inbox`. One folder per design. Save the best image
from each option (A, B, C) into that design's folder, so each folder ends up with 3 pictures.
File names don't matter. To pick a winner, put a ⭐ in its file name or just tell Claude.
Claude pulls the art from Drive, cleans it up (snaps it to the pixel grid, cuts out the magenta
background, resizes and recolours it to the game's palette) and puts it in the game.

**Order:** do `00 Style board` first and pick a winner. Then add that winner's colour line to every
other prompt, so all the art matches.

**Attach `reference_current_HD.png`** (it's in the inbox) to every prompt and say "match this
camera angle and character size". That helps more than any wording.

---

## The base prompt (paste first, every time)

```
16-bit pixel art for a cozy comedy RPG in the spirit of EarthBound, set in Omaha, Nebraska.
Chibi proportions, 3/4 top-down view (we see the front wall and a bit of the roof), same camera
angle as the attached screenshot. Crisp 1-pixel dark outlines, flat colors with one shadow tone
and one highlight tone, no gradients, no blur, no anti-aliasing, no text unless I ask for a sign.
A character is about two 32-pixel tiles tall; size the asset to match.
Solid flat magenta background (#FF00FF), nothing else in frame, no ground shadow on the background.
```

Then add the design line below. Run A, B and C as **three separate prompts**.

---

## 00 Style board (pick the look first)
Prompt: *"A small street corner: one house, one little shop, two trees, a bench, a lamp post,
sidewalk and road. Show the whole scene, no magenta background for this one."* Plus one of:
- **A. Saturday Morning EarthBound:** bold saturated colors, mint grass, candy-colored roofs, sunny and goofy.
- **B. Omaha Autumn:** burnt orange and red trees, golden late-afternoon light, brick and faded siding.
- **C. Dive-bar Dusk:** purple-blue evening, warm yellow windows, glowing neon signs, wet pavement shine.

Then add the winner's line to everything below ("color palette: …").

---

## 01 Storefronts
The whole building including the roof fills the frame edge to edge. Signs show the exact name given.
The aspect ratio in brackets is the shape it needs; pick the closest one Grok offers.

**Home (Duff's house)** [3:2]: a small rented 1950s Omaha bungalow, porch, Halloween-leftover pumpkin.
- A. Cozy-messy: toys on the porch, a cat in the window, mismatched lawn chairs.
- B. Broke-but-proud: patched screen door, fresh paint on half the house, a tiny garden.
- C. Duplex vibes: two mailboxes, a bike chained to the rail, a string of lights.

**Neighbor house** [4:3]: the house next door.
- A. Retiree's palace: perfect lawn, garden gnomes, a flag, a "keep off grass" sign.
- B. Party-guy rental: red cups on the lawn, a couch on the porch, a speaker in the window.
- C. Creepy-quiet: blinds always shut, dead plant, a security camera pointed at Duff's house.

**KWIK-N-GO** [16:9]: a gas station convenience store, sign "KWIK-N-GO".
- A. Classic 90s: red-and-yellow canopy, gas pumps, ice machine, "HOT DOGS 2 FOR $3" window.
- B. Sketchy 24-hour: flickering sign, bars on windows, a lottery banner, a raccoon by the dumpster.
- C. Overly branded: mascot sign, slushie poster, "NOW WITH MORE CHEESE" banner.

**THE TWISTED FORK** [2:1]: the diner where Duff works the line, sign "THE TWISTED FORK".
- A. Retro roadside diner: chrome trim, neon fork sign, booths in the windows.
- B. Tired chain restaurant: faded logo, "NOW HIRING" sign, kitchen door propped open with a bucket.
- C. Hipster-reno: Edison bulbs, chalkboard specials, an exposed-brick facade.

**HOA HQ** [16:9]: the homeowners association office, sign "HOA HQ".
- A. Suburban fortress: beige, ten clipboards in the window, a measuring tape on the lawn.
- B. Fancy fake-columns office: a fountain, a "VIOLATIONS" mailbox.
- C. Strip-mall bureaucracy: tinted glass, a "TAKE A NUMBER" sign, a parked golf cart.

**SEEN CAFE** [3:2]: a trendy coffee shop (the ghoster boss lives here), sign "SEEN CAFE".
- A. Minimalist white cafe: neon "seen ✓✓" sign, plants, one sad customer.
- B. Cozy indie: chalkboard, string lights, latte-art mural.
- C. Influencer trap: ring lights in the window, a pastel wall, a "post us" sign.

**IRON TEMPLE** [1:1]: the gym (the gym-bro boss), sign "IRON TEMPLE".
- A. Old-school sweat box: garage door, chalk dust, barbell logo.
- B. Supplement-shop gym: protein tubs in the window, "NO DAYS OFF" banner.
- C. Temple joke: Greek columns made of dumbbells, a statue of a flexing guy.

**CLUB CLOUD 9** [3:2]: a nightclub (the DJ vape boss), sign "CLUB CLOUD 9".
- A. Neon cloud sign, a velvet rope, a bouncer's stool.
- B. Vape-cloud haze pouring out of the door, purple lights, a line of people.
- C. Dive nightclub in a converted warehouse: graffiti, a bass-shaking door.

**MINING RIG** [4:3]: a crypto mining shack (the crypto-bro boss), sign "MINING RIG".
- A. Garage full of GPUs: fans blowing, a power cable mess, a "TO THE MOON" banner.
- B. Shipping container with a rocket decal, steam, blinking lights.
- C. A suburban house overheating: AC units everywhere, a melting snowman out front.

**NAKATOMEH PLAZA** [2:3]: a corporate tower (the final boss), sign "NAKATOMEH PLAZA".
- A. 80s action-movie skyscraper: gold glass, helipad on the roof.
- B. Evil-corporate monolith: black glass, a tiny red light at the top.
- C. Too-big-for-Omaha tower: shiny and new, with a cornfield right beside it.

**WALGRUMPS PHARMACY** [2:1]: a drugstore, sign "WALGRUMPS".
- A. Red-cursive chain drugstore parody, drive-thru window, a long line.
- B. Grumpy-face logo, "PHARMACY CLOSED FOR LUNCH" sign.
- C. Small-town pharmacy: awning, a soda-fountain look, a "REFILLS" neon.

**HY-WHEE MARKET** [16:9]: a grocery store, sign "HY-WHEE MARKET", slogan "A helpful smile in every aisle-ish".
- A. Midwestern grocery: red sign, cart corral, produce stand out front.
- B. Discount grocery: "SALE" signs everywhere, a hand-written price board.
- C. Big friendly store: a smiling-cart mascot, flower buckets by the door.

**PLAZMART PLASMA** [16:9]: a plasma donation center, sign "PLAZMART PLASMA".
- A. Clinical strip-mall unit: a red drop logo, "$$$ FOR NEW DONORS" banner.
- B. Gamer-energy rebrand: neon blood-drop, "LEVEL UP YOUR WALLET".
- C. Sad and honest: buzzing sign, a bench full of tired people, a snack vending machine.

---

## 02 Trees and greenery [1:1]
*"A sprite sheet of 6 trees and bushes, evenly spaced, each separate"* plus one of:
- A. Omaha fall: maple, oak, a scraggly ash, a pine, two bushes, in orange, red and brown.
- B. Summer: full green, a crabapple in bloom, a lilac bush, hedges.
- C. Weird EarthBound: lollipop trees, a tree with a face, mushroom bushes, a cactus somehow.

## 03 Street clutter [1:1]
*"A sprite sheet of 12 small street objects, evenly spaced, each separate, sized for a 32-pixel tile"* plus one of:
- A. Omaha everyday: a recycling bin, a fire hydrant, a newspaper box, a bus bench with an ad, a political yard sign, a Huskers flag, a pothole cone, a Little Free Library, a mailbox, a bike rack, a shopping cart, leaves.
- B. Comedy chaos: a lost-cat poster, an overflowing trash can, a couch on the curb, a "FREE" TV, a scooter in a bush, a traffic cone on a pole, a sad balloon, a lawn flamingo, a raccoon in a box, a pizza box, a puddle, a shoe.
- C. Night life: a lit vending machine, a phone booth, a neon "OPEN" sign, a food truck, string lights, a parking meter, a hot-dog cart, a payphone, a manhole with steam, a glowing ATM, a parking sign, cones.

---

## Notes for Claude (pickup)
- Inbox folder IDs: root `1axKztjLwkqYBuO89YvjQ2M-LVioGqoYA`; storefront folders under
  `1qBspEd4iDL2nkpEC0pfKqmVLUjD9W-Wc`.
- Buildings: footprints are `buildings` in `scripts/main.gd` (world units; art is 2 px per unit).
  Today the facades are baked into `assets/art/map_outside.png` (1280×720). Composite the
  approved facades onto that map at each footprint, with nearest-neighbour downscaling and a
  palette quantize to the winning style board. Keep collisions unchanged.
- Pull images with a subagent (Drive results arrive as base64 and are large).
