# Consistency audit before CrazyGames (Nov 15, 2026)

Goal: find leftovers from older builds (art, UI, text) in both editions and anything CrazyGames would reject.
Checked: every menu/minigame via `ui_audit_shot` (touch mode), the live `duffquest-crazygames.zip` from the `dev`
release, the asset manifest densities, outbound links, listing copy, and the marketing assets.

## CrazyGames blockers
None hard. The portal zip is 35.6 MB unzipped in 12 files (cap 50 MB / 1500), `DQ_PORTAL=1` is set, no outbound links
or cross-promo in game code or data, listing copy uses public names only, controls in `LISTING.md` match `main.gd`.

## Leftovers, ranked
1. **Loading splash was Godot's default logo** (white page with the Godot robot while the wasm loads, ~9 s on 4G) and
   the app icon was a 16 px placeholder face (favicon, iPhone home-screen icon, APK launcher). FIXED: logo splash on
   the house dark plum, `icon.png` = `docs/itch/icon_512.png`.
2. **Phone avatars (`av_*`) were 1x crops of the pre-overhaul sheets** (blue fringe, dither, blurry). FIXED: head
   crops of the 2x sheets, `tools/make_avatars.py`. The bank icon is unchanged.
3. **Marketing assets predate the 2x cast and the Nov 15 UI**: `docs/portals/preview/*.mp4`, `docs/itch/screens/*`,
   `knockout.gif`, `boss_intro.gif` (Nov 13: old 1x sprites, old dialogue box with no name tab). These are what
   CrazyGames players see first. FIXED: re-shot on the current build (both preview videos open on the porch title
   card, both GIFs, screens 01-04 and 06-09; 05 fridge calendar has no sprites and stays). Render
   `docs/renders/listing_reshoot_before_after.png`.
4. **Covers put the fox tattoo in the middle of the throat** (`docs/portals/covers/*`, `docs/itch/cover.png`). The
   real one sits on the LEFT side of the neck (`docs/ref/duff/duff_fox_neck_tattoo.png`). FIXED without Canva: all four covers are now the porch title art
   (`bg_title`) + the logo, the same card that opens the preview videos.
5. **Blackhead Patrol old flat back**: FIXED, PR #101 merged.
6. **Kitchen minigame centrepieces are chunky old pixel art next to painted backdrops**: prep (tomato + board),
   garnish (Black Forest slab), temp check (patty). Canva repaint, one batch.
7. **Open prop list from the sprite pass**: delivery van (`truck_h`), drone, nft, package, honeybun, freya_peek.
8. **Old sunburst still shows** behind cards when no world snapshot exists (shift menus, cold boot). Swap the fallback
   for a plain dark veil.
9. Dead art still shipped in the packs (unused): fence corners/gates `sd_*_corner|gate`, `sd_political_sun_sign`,
   `bench`, `bus_sign`, `trash_can`, `duff_dress`, `ch_grillboy`. Harmless, a few hundred KB.

## Not leftovers (checked, fine)
Buttons, dialogue tab, veil, HUD tags, tiny text, seams, Back Walk, Stealth floor, symphony, Akarui, Hy-Whee floor,
Walgrumps public sign, gear screen, Word Brawl, settings, credits (public names).
