# Boss knockout cutscenes (Nov 8 2026, Duff's call)

Every boss (17) gets a knockout cutscene when it goes down. Fight style = **Baki the Grappler** (impact,
anatomy, crack-line muscles, freeze frames, spectators reacting) mixed with **Spike Spiegel** (Jeet Kune Do:
loose, bouncy, almost lazy stance; slips instead of blocks; one sudden snap strike; casual walk-away).
Narration = Duff at the bar, present tense, **Chuck Palahniuk** layer (body facts, lists, repetition,
clinical "fun fact" asides, deadpan aphorisms). Scripts: `data/knockouts.json` (all 17 written).

References Duff sent (YouTube blocks downloads from the sandbox, so only titles/thumbnails were seen):
- Baki: https://youtube.com/shorts/Fwqzf7ZEQNQ "THE GREATEST BAKI MOMENT" (manga panel edit, hyper-detailed
  muscles with crack lines, glowing teal outline, raised-arms pose).
- Spike: https://www.youtube.com/watch?v=bZdd8k6wKsI "The Best Fights of Spike Spiegel" (Hall Of Heroes).
If Duff attaches the video files, re-time the beats below against them.

## Beat template (~12 s, tap A to skip)
| t (s) | Beat | Screen | Text key |
|---|---|---|---|
| 0.0 | stance | letterbox bars in; Duff idle-bounce (Spike), boss still A slams in with name card | `stance` |
| 1.5 | slip | boss wind-up, time 0.25x, Duff side-step with afterimage trail | `slip` |
| 3.5 | xray | freeze; screen goes manga monochrome + crack lines + teal glow outline; still B (impact/x-ray); shake + white flash on hit | `xray` |
| 6.0 | finisher | move name stamped across screen (`move`); 3 rapid panel cuts of Duff stills; last hit = full white flash, 0.4 s freeze | `finisher` |
| 9.0 | crowd | spectator portrait + line (speaker-labelled, gets their HD portrait) | `crowd` |
| 10.5 | closer | still C (boss down); Duff turns and walks off, hands in pockets | `closer` |
| 12.0 | — | boss `defeat` line from `boss.gd` as today | |

## Art needed (57 stills, Hazbin cartoon style, match portraits; Baki crack-line rendering on impact frames)
- Per boss x17: **A** wind-up close-up, **B** impact / x-ray panel (monochrome manga, muscle crack lines, teal
  glow), **C** boss down. Files `assets/art/ko/<boss>_a.png` etc., 16:9.
- Shared Duff x6: stance bounce, slip, finisher panels 1-3, walk-away. `assets/art/ko/duff_*.png`.
- Pilot boss: **Gym Bro** (a muscle boss is the natural Baki test). Build the engine + his 3 stills + Duff's 6,
  get Duff's sign-off, then batch the other 16.

## Engine plan
`scripts/knockout.gd`: CanvasLayer overlay at screen resolution (same trick as `hd_portrait_overlay.gd`),
driven by a beat table; effects in code (letterbox, slow-mo, shake, flash, speed lines, crack-line shader,
stamp text). Hook: where a boss's HP hits 0, before the `defeat` line. Falls back to the current defeat
flow if a boss has no `ko/` art yet.

## Style-fusion prompt (Nov 8; worked first try on all 9 Gym Bro stills)
Describe traits, never name the shows (names pull models toward copying those shows' characters).
```
STYLE: bold cartoon characters with thick tapered ink lines, angular shapes and flat cel shading (keep the faces from the attached portraits). Fight-impact rendering: hyper-detailed muscle anatomy drawn with dense black crack-line hatching on every muscle, popping veins, sweat beads flying; extreme low camera and foreshortening; manga-panel composition with diagonal borders and the subject breaking out of the panel edge; background replaced by radiating speed lines on one flat colour; a glowing teal rim-light outline around the figure. Duff moves like a relaxed martial artist: loose bouncing stance, weight on the back foot, lead hand low, half-lidded bored look and a slight smirk, one sudden snapping strike. Duff's frames use a smoky jazz-noir palette (navy, amber, cigarette grey); the boss is saturated neon. 1990s cel-anime film grain. No text, no letters.
```
Status: engine built; Gym Bro live (stills a/b/c + shared Duff x6 in `assets/art/ko/`). Next: A/B/C stills for the other 16, flip `"live": true` per boss.

## Parody bosses redesigned (Duff, Nov 8 23:10)
> **SUPERSEDED Nov 9:** the duck, TV and lightbulb heads below were rejected as Hazbin imitation. The shipped art uses made-up HUMAN faces (art rule P1); the cartoon heads are DLC only. Keep the outfits and props, not the heads.

Husk, Bozos, Fences, The Donald, Willnot keep their NAMES but get original faces (no real-person likeness;
their old portraits/cards/sheets get replaced too). Designs: Husk = wiry, goggles, silver space-cowboy jacket,
jetpack, a dozen phones taped to his chest. Bozos = tiny bald man in a cardboard-box mech, drone hat.
Fences = cardigan, head is a blue computer screen with a cartoon face, loading wheel overhead.
The Donald = giant orange rubber duck in a suit with a floor-length red tie. Willnot = barefoot, torn tank top,
lightbulb head, handgun duct-taped to his back. Step 1: 3-expression face sheets (Canva, 2:1) -> Duff OK ->
portraits_hd, boss_intro cards, ch_ sheets, then ko stills. Batch 1 ko stills (ghoster, djvape, crypto,
sendback, regular) generated, waiting on full-size downloads.

> **SUPERSEDED Nov 9 (gala exes):** husk/bozos/fences/donald are no longer billionaire parodies. They are
> Madison's exes Tyler Pivot, Grant Gratuity, Landlord Lance and Chip Leverage (cast tokens gala_ex_1..4).
> New scripts are in `data/knockouts.json` with `"live": false` until new stills exist; art brief
> `docs/gala_exes_art_brief.md`; old art + scripts in `docs/dlc_concepts/billionaires/`.

Nov 9 (M13): husk, bozos, fences, donald, willnot live (11 of 17). Left: coupon, allergy, camper, bdaydad, dasher, baron.
B-still prompt = ref `ghoster_b` + face sheet; it copies Ghoster's face into the bottom-middle panel unless fixed by an edit.

## Cartoon gore (Nov 9, art rule H2)
In-engine only (Canva blocks blood): `scripts/ko_gore.gd`, a child node of `knockout.gd` that exists only while a
cutscene plays with Settings > "Cartoon gore" ON (default ON, saved as `"gore"` in `user://settings.json` by
`audio.gd`). Hits fire on the KO SFX cue times: x-ray crack = red splat star + 20 ink-outlined teardrops + spit arc
from the mouth + 2 tumbling molars; finisher snaps 1-3 = small sprays per panel (gone before the next cut); boom =
a fountain + spit + 1 tooth. Pure function of (seed, beat, bt), so renders repeat. Per-boss placement, optional, in
`data/knockouts.json`: `"impact": {"xray": {"at": [x, y], "mouth": [x, y], "dir": deg, "spit": deg}}` as shares of
the stage rect (the x-ray crack lines use `at` too). Set for gymbro + ghoster; others use the defaults in
`ko_gore.gd`. Render: `xvfb-run -a godot --path . --rendering-driver opengl3 --fixed-fps 30 --resolution 1280x720
res://tools/ko_shot.tscn -- <boss> gore` then `python3 tools/ko_gore_sheet.py <boss>` -> `docs/renders/ko_gore_<boss>.png`.
