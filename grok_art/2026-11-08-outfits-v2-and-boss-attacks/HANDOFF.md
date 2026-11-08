# Outfits v2 and boss attacks handoff, Nov 8 2026

Hi Claude. Duff approved this batch. Nothing here is wired into the game. Re-import over the sheets already in the game. Do not touch portraits, intros, or hitboxes unless a re-import forces it.

## 1. Duff outfits v2 (`outfits/`)

`duff_outfits_v2_batch.zip` is a redraw of all 11 Duff outfit sheets. Same filenames as `grok_art/2026-11-08-duff-outfits/`, same 256×256 4×4 layout: rows down / up / right / left, columns stand, step A, step B, attack. Origin 32,60.

Sheets: `duff_home`, `duff_apron_black`, `duff_apron_red`, `duff_clogs_black`, `duff_clogs_red`, `duff_coat_black`, `duff_coat_red`, `duff_dad_black`, `duff_dad_red`, `duff_sleeves_black`, `duff_sleeves_red`. Each has a `<id>_walk.gif`. Also `duff_outfits_v2_lineup.png`, `duff_outfits_v2_asphalt_test.png`, the checks JSON, the file manifest, and `duff_outfits_v2_README.txt`.

This pass answers the reviewer notes:

- Crisp side-view stride, plus a head bob.
- A real wind-up / strike attack pose (frying pan).
- Rim light on the dark outfits so they read on asphalt.
- Clogs redone with chunky bright soles and a shoulder towel, so they no longer read as the home outfit.

These replace the earlier `grok_art` outfit sheets (PR #8). Re-import them over the copies PR #9 wired in.

The v2 README says the visible feet were shifted onto baseline 60 already. Check a cell before stacking the old ~3px foot drop on top of that.

## 2. Boss attacks v2 (`boss_attacks/`)

`boss_attacks_v2.zip` has all 17 `ch_<boss>.png` sheets with only the attack column changed. Walk frames are untouched (the first three columns match the PR #12 sheets; the included `ch_<boss>_walk.gif` files are the originals). Each boss now has its own attack pose.

Bosses: husk, bozos, fences, baron, donald, ghoster, gymbro, djvape, crypto, willnot, regular, sendback, coupon, allergy, camper, bdaydad, dasher.

Also in the folder: a `ch_<boss>_attack_v2.gif` per boss (idle/attack preview, not a full attack sequence), `boss_attacks_v2_preview.png`, the checks JSON, the file manifest, and `boss_attacks_v2_README.txt`.

These replace the attack column of the PR #12 boss sheets. Re-import them over those.

Gestures, from the delivery notes: husk phone thrust, bozos parcel toss, fences open-palm push, baron coin fan, donald ruler wind-up, ghoster guarded phone peek, gymbro two-fist slam, djvape lean-back cloud, crypto rug yank, willnot braced spray, regular mug toss, sendback plate shove, coupon overhead whip, allergy onion brandish, camper laptop shield, bdaydad hire gesture, dasher shoulder charge.

## 3. Known limits

- Front and back attack poses are somewhat compressed. Profiles read more clearly.
- Each attack is one strong key pose, not a multi-frame animation. There is no recovery frame.
- Godot timing, hitboxes, and projectile anchors were not tested. Bozos' parcel is a visual motif; the fight still uses drones and shine, not a new parcel projectile.
