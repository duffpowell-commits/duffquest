# Portrait touch-ups handoff, Nov 8 2026

Hi Claude. Duff approved this batch. These files are the new masters. Do not edit the live portrait files in this drop. Copy them over, then re-import.

The sheets are `duffquesthd/portraits/madison_portraits_hazbin.png` and `duffquesthd/portraits/octavia_portraits_hazbin.png` inside this folder. `portraits_touchup_preview.png` is the contact sheet. Commands and limits are in `README.txt`.

## 1. Madison
`madison_portraits_hazbin.png`: the middle expression's teal irises are now brown, matching her other two portraits. Pupils, catchlights, and lids were left as they were before the small framing nudge.

## 2. Octavia
`octavia_portraits_hazbin.png`: the three expressions are reworked into giggling, curious, and wailing, and the adult teeth are removed. The wail is toothless. The pink wailing irises stay. Duff already approved that accent.

## 3. Canvas
Both keep the same 1280×720 canvas, the same one-row layout, and the `#00FF00` key. 1280 does not divide by 3. The importer still cuts at 0, 427, 853, 1280. Faces were nudged slightly so nothing crosses those cell dividers. That nudge moves pixels outside the feature edits too, so the outer panels are not byte-identical to the previous masters.

## 4. How to install
These replace the masters at `duffquesthd/portraits/`. Copy the two PNGs onto those paths, then run the existing portrait importer and refresh Godot's texture imports:

```
python3 tools/import_portrait.py duffquesthd/portraits/madison_portraits_hazbin.png madison --cell 512 --margin 16
python3 tools/import_portrait.py duffquesthd/portraits/octavia_portraits_hazbin.png octavia --cell 512 --margin 16
```

That refreshes `assets/art/portraits_hd/madison.png` and `assets/art/portraits_hd/octavia.png`. Do not replace those runtime sheets with the green-key masters.

## 5. Boss intro backgrounds
Duff's decision on the M7 question: switch the boss intro splashes to the burst-preview backgrounds, `new_boss_intro_<name>_burst_preview.png` from PR #12, instead of the keyed versions.
