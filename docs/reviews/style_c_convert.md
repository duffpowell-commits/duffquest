# Style C conversion (Nov 9, 2026, branch `style-c-convert`)

Old anime-style HD art redrawn in locked house style C (`docs/art_direction/STYLE_LOCK.md`), same file names, sizes and
formats (1280x720 JPG q88), so no code changed. Old files: `grok_art/2026-11-09-style-c-convert/old/`. Masters
(1920x1080 Canva exports): `grok_art/2026-11-09-style-c-convert/` (rejects in `rejected/`).
Refs for every Duff image: canonical face sheet `MAHacL92VLk` FIRST, then the old still (composition), then the
approved style-C stance master (`MAHacddYdLM`, = `grok_art/2026-11-09-art-direction/stance_C.png`) as the style ref.
Scratch export design `DAHacBeu8SQ` (pages 25+). Every image graded at full size against ST1-ST7 + D1-D7.

## Batch 1: Duff's 6 shared KO frames

Renders: `docs/renders/style_c_convert_duff_ko.jpg` (old vs new), `docs/renders/style_c_convert_ko_gymbro_beats.jpg`
(engine, all beats of one KO).

| file | grade | notes |
|---|---|---|
| duff_stance | PASS | The approved `stance_C` master from the style pick (fox already fixed there), shipped as-is. |
| duff_slip | PASS after 1 fix | Try 1 put the fox on the visible neck side, which is his RIGHT (D5/ST7). Canva edit removed it on him and the afterimages. Blackout sleeve on his left (viewer's right), creature forearm + blackletter hand on the near arm. |
| duff_fin1 | PASS after 1 fix | Same fox miss as slip (head turned to the viewer's right shows his right neck). Edit removed it. Eye-in-triangles on the blackout fist. Knee has no crack hatching (ST3 allows none). |
| duff_fin2 | PASS | Flying kick, no city/smoke now. Blackout upper arm with eye hand, grey-wash + creature + script on the other arm, no neck ink on the visible (right) side. |
| duff_fin3 | PASS | Eye-in-triangles blackout fist through a flat white/amber ring, creature forearm on the other arm, visible neck clean. Light grain on the sleeve and burst, reads flat at 1280. |
| duff_walk | PASS (soft) | From behind: blackout forearm on his left, grey-wash + bracelet on his right, visible neck clean. Soft note: the lamp cone is a soft gradient (ST2 nit, background only). |

Gotcha (again): any time Duff's head turns toward the viewer's right, the visible neck is his RIGHT side and Canva
still paints the fox there even when the prompt says "only on the viewer's right". One cheap edit fixes it ("remove the
neck tattoo, plain skin"); with the face sheet as the first ref the edit kept everything else.
