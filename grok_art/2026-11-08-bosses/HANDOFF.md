# All 17 bosses handoff, Nov 8 2026

Hi Claude. Duff approved this set to send and merge. Do not invent extra poses. Nothing here is wired into the game.

Both zip parts are one batch. Files sit flat in `grok_art/2026-11-08-bosses/`. Full delivery notes are `boss_all17_README.txt`. Per-boss limits are `boss_all17_quality_notes.json`. Inventory and hashes are `boss_all17_file_manifest.json` (and the CSV). Format checks are `boss_batch2_checks.json`.

Bosses, in order: husk, bozos, fences, baron, donald, ghoster, gymbro, djvape, crypto, willnot, regular, sendback, coupon, allergy, camper, bdaydad, dasher. Every boss must stay visually unlike the others. These are original humans. The names are parody labels, not real-person likenesses.

## Files per boss
- `ch_<name>.png` walking sheet.
- `ch_<name>_walk.gif` four-direction walk preview (768×224, asphalt background, preview only).
- `ch_<name>_asphalt_test.png` all 16 frames at 3× on `#5A5A5A` (3072×220).
- `new_portrait_<name>.png` dialogue portraits.
- `new_boss_intro_<name>.png` keyed intro splash with the exact sheet name lettered on it.
- `new_boss_intro_<name>_burst_preview.png` colourful burst version. Duff liked these. They are not a keyed game sheet.

Lineups: `boss_batch1_lineup.png` (first 4, sprites corrected, portraits and intros unchanged), `boss_batch2_lineup.png` (next 7), `boss_batch2_lineup_2.png` (last 6), `boss_all17_sprite_lineup.png`, plus `boss_all17_sprite_checks_1..3.png` and `boss_all17_asphalt_checks_1..3.png`.

Husk, Bozos, Fences, and Baron sprite PNGs and GIFs were corrected after review. Their portraits and both intros are the previously approved files, unchanged.

## Walking sheets
256×256, 4×4 of 64px cells. Rows down / up / right / left. Columns stand, step A, step B, attack. Origin 32,60. 52px silhouettes: stand and attack occupy y8–59; step frames bob 1px down (top y9, feet still on y59). That bob is intentional. Left row is mirrored from the right. Rim light is there so dark clothes read on asphalt.

## Portraits and intros
Portraits are 1536×512, three 512px cells: smug, shocked, enraged, on exact `#00FF00`, at least 16px margin.

Keyed intros are 1920×1080 with the exact name lettering and at least 48px margin. Burst previews are the same size and are the flat-colour alternative, not the keyed sheet.

## Keys
Sprites and keyed intros use green when the character has pink or magenta, otherwise magenta. Every portrait is `#00FF00`. The file manifest does not store keys; these come from `boss_batch2_checks.json`.

| boss | sprite and keyed intro | portrait |
|---|---|---|
| husk | `#FF00FF` | `#00FF00` |
| bozos | `#00FF00` | `#00FF00` |
| fences | `#FF00FF` | `#00FF00` |
| baron | `#00FF00` | `#00FF00` |
| donald | `#FF00FF` | `#00FF00` |
| ghoster | `#FF00FF` | `#00FF00` |
| gymbro | `#00FF00` | `#00FF00` |
| djvape | `#00FF00` | `#00FF00` |
| crypto | `#FF00FF` | `#00FF00` |
| willnot | `#FF00FF` | `#00FF00` |
| regular | `#FF00FF` | `#00FF00` |
| sendback | `#FF00FF` | `#00FF00` |
| coupon | `#00FF00` | `#00FF00` |
| allergy | `#00FF00` | `#00FF00` |
| camper | `#00FF00` | `#00FF00` |
| bdaydad | `#00FF00` | `#00FF00` |
| dasher | `#FF00FF` | `#00FF00` |

Sheets are opaque RGB. Key the flat border to transparency. No text on sprites or portraits.

## Known weak points
- Attack frames share a similar forward-extension pose. Dasher is a charge (bent arms, box, forward head, speed ticks), not a punch. Unique attacks may come later. The attack cell is one key pose, not a windup and recovery.
- Front and back strides are subtler than the side strides.
- Tiny props lose detail at native scale (phones, tablets, guns, plates, onions, cake boxes, laptops).
- Godot timing, hitboxes, and projectile anchors are untested. Check 1.45× game rendering, timing, collision, and where projectiles attach. No hitbox changes are in this drop.
- Legs and attacks are simpler pixel clusters than the generated heads and clothes.
- Hashes do not prove the acting. Use the sprite pages, asphalt pages, and lineups.

## Quality notes
- **husk:** Phone and rocket-cue gesture read at sprite scale; the phone is only a few pixels. Contacts, bob, strike, and dark-jacket rim were corrected.
- **bozos:** Round silhouette and moustache stay distinct; the strike stretches the round body. Contacts, bob, and violet-outfit rim were corrected.
- **fences:** Blue glasses and ochre sweater read well; the tablet is small at native scale. Contacts, bob, strike, and rim were corrected.
- **baron:** White wing-hair and mulberry coat stand out; the long coat partly masks the front/back stride. Side contacts, bob, strike, and rim were fixed.
- **donald:** Ivory suit and dark rhomboid face differ from the other bosses. The sprite face is darker and less detailed than the portrait.
- **ghoster:** Fringe, seafoam jacket, and phone are clear. Skin reads warmer than the ash-pale concept at sprite scale.
- **gymbro:** Broadest silhouette, lime tank, fuchsia band. Still 52px tall, so the head is smaller against the shoulders than Duff's.
- **djvape:** Violet double-bun and coral headphones are the silhouette. The sprite outfit is simpler than the portrait.
- **crypto:** Orange buzz cut and cobalt-yellow tracksuit read clearly. Tablet and rug become tiny symbols.
- **willnot:** Olive face, widow's peak, barefoot action hero. The gun is miniature and the toes only resolve when enlarged. Not an actor likeness.
- **regular:** Heavy rust-plaid, mug, and grey moustache read. Front/back strides are compact under the stocky body.
- **sendback:** Emerald jacket, napkin bib, and red side-part. The plate is a narrow ellipse in profile.
- **coupon:** Braid crown, turquoise coat, coral bag. The long coat hides some front/back leg depth. The coupon fan is simplified.
- **allergy:** Frizz halo, burgundy glasses, maroon trousers. The onion is tiny at native scale.
- **camper:** Lavender curls, moss cardigan, headphones, and laptop. Laptop detail is abstract pixels.
- **bdaydad:** Paper crown, teal polo, shorts, cake box. The cake box is a cream block at native scale.
- **dasher:** Yellow jacket, maroon twists, red shoes. The attack is a shoulder charge, not a punch.
