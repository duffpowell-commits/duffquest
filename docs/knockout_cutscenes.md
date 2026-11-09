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
