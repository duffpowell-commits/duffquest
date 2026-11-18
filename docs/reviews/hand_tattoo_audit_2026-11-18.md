# Duff's hand tattoos: audit (Nov 18, 2026)

Truth (Duff, Nov 18): LEFT hand = eye mandala, matches the left blackout sleeve. RIGHT hand = calligraphy "This Red Right Hand Points Me South".
Photos: duff-reference/hand_tattoo_eye_mandala.jpg, hand_tattoo_script_lettering.jpg.

Details pulled from the photos that no art has yet:
- NO ring (Duff, Nov 18 later: "Take the ring off tho"). The first photo shows one; leave it out of all art.
- Finger dots on the left hand: three stacked dots on the ring finger, small dots on the middle and index fingers.
- Eye mandala: eye in the centre, ring of triangle teeth, spiked sun whose points run onto the backs of the fingers; blackwork runs straight into the sleeve.
- Right hand: four lines of calligraphy with a swirl flourish on top, knuckles to wrist; fingers bare.

## What's wrong now

| Art | Where players see it | Hands | Verdict |
|---|---|---|---|
| Walking sprite, 3D default (`assets/art3d/duff_home_hd3d.png`) | every street/fight frame | both fists bare skin; both forearms the same thin line tattoos (no blackout left sleeve) | WRONG: no hand tattoos at all, left sleeve missing |
| Walking sprites, 2x (`duff_*` outfits, 2D view) | 2D view, kitchen | same as above | WRONG |
| True-3D model (`assets/model3d/duff_atlas.png`) | `#true3d` link only | baked from the sprite, so same | WRONG |
| KO / fight stills (`assets/art/ko/*`, 19 bosses + 6 Duff finishers) | after every boss KO; trailer; GIFs | blackout arm with an eye on the fist and script on the other hand: the idea is right | CLOSE: invented script words, no finger dots, generic mandala, side not checked per image |
| Loading screens (`assets/art/loading/*`, 14) | between rooms | same as KO stills | CLOSE, same gaps |
| Title / covers / YouTube thumbnail (porch art) | itch, YouTube | hands tiny, holding a mug; arms show light tattoos on both | WRONG at a glance (no dark left arm/hand) |
| Trailer + GIFs (`duffquest-youtube/`, `duffquest-ads/`) | YouTube, itch | built from the sprites + KO stills above | inherits both problems |
| Dialogue portraits | dialogue | head and shoulders, no hands | n/a |

## Order of fixes
1. Canon reference + repo rules (so new art stops drifting).
2. Sprites (what players see every second): stamp the real designs onto every hand frame, pixel-exact.
3. KO stills + loading screens: graft the real designs onto each hand, batch 1 for Duff's look first.
4. Title/covers/thumbnail, then re-cut trailer + GIFs.

## Status (Nov 18, 23:20 UTC): every item matched
- Sprites + 3D atlas: PRs #141, #143, #150 (traced script master).
- KO stills: #142, #144, #150, #154. All 60 audited; only Duff frames (_b, duff_*) needed work.
- Loading screens: #155 (9 fixed, 5 already fine / no Duff hands).
- Title, itch cover, portal covers, YouTube thumbnail: #156 (pixel-size hands: red right-hand ink, black left hand with the eye).
- Trailer (both cuts), portal previews, boss_intro.gif: patched frame by frame with `tools/hand_tattoos/video_patch.py`
  (ORB homography finds each changed still in every frame and swaps in the fixed one). knockout.gif needed nothing.
  Old copies: project files `duffquest-youtube/old_pre_hand_fix/`, `duffquest-ads/old_pre_hand_fix/`.
- Any NEW still/promo: run still_fix.py for the still, then video_patch.py on any cut that uses it.
