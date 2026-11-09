# Duff Quest — todo

## JAM BLOCKER (found Nov 9, 07:50) — DECISION NEEDED FROM DUFF
- The itch "2026 Jam" (itch.io/jam/2026-jam) rules: "No AI content (no AI stuff in your games, so no AI assets like
  sprites, music, etc), however you may use AI for code assistance." DuffQuest's art is AI-generated -> it does NOT qualify.
- Anything Jam 2026 (closes Feb 1 2027) also bans generative AI. Brackeys, Craftpix, Bara, Indie Jam: same.
- AI-friendly jams exist but are short themed sprints for NEW games (All Tools Allowed by Critics Arcade, ctrl ai jam weekly,
  Jamference AI Game Jam, Epic AI MegaJam = Unreal only). Options: (a) release DuffQuest on itch as a normal game, no jam;
  (b) a short AI-friendly jam if one accepts existing games; (c) check whether Chaos Is the Mother of Order qualifies for the 2026 Jam.

## Soak/perf findings (Nov 9, docs/qa/soak_report.md + perf_report.md) — DECISIONS FOR DUFF
- [ ] **Gala is unreachable:** Octavia's fund can't hit $100k in 30 days, so all 5 gala bosses (incl. the new gala exes) are post-game in practice. Lower the gate (e.g. $10k or a story day) or move the gala into the 30 days.
- [ ] **Happiness bars too strict:** a player who works every day but skips the evening shower + couch never meets the happiness gate for 4 of 5 story bosses and never sees Show & Tell. Teach the evening routine better or loosen the gates.
- [ ] Untested by the soak bot: symphony date, bus pass / car purchase, stock trades.
- [ ] First boot on 4G ~60 s: the 38 MB index.wasm dominates. Check whether itch serves it brotli/gzip (would be ~9 MB); else consider a custom stripped engine build.
- Done: soak test `tools/soak.sh` (30 days x 6 seeds clean), web boot check `ship_itch.sh --web-check`, perf (-23..53% frame cost), auto Lite graphics, KO texture leak fixed.

## IGN-style critique fixes (Nov 9; Duff: "they're warranted")
Score now ~6.5/10; target 7.5-8. Effort: S = hours (one agent), M = a day of agent time, L = multi-day / Canva-bound.
- [ ] (S) **Willnot intro card bug:** `docs/renders/qa_boss_intro.png` shows a gameplay frame instead of his burst card. Verify + fix.
- [ ] (S/M) **HUD declutter for phones:** 5 status panels crowd the landscape screen. One compact top bar (Madison, Energy,
      $, day/time); errand/rent/fund/bag collapse into a tap-to-expand or the phone. Render before/after.
- [ ] (M) **Swap the real-billionaire parodies** (Elon Husk, Jeff Bozos, Bill Fences, The Donald; review Willnot too) for
      original service-industry archetypes like Coupon Carol / Four-Hour Camper. Dated jokes + Google Play risk. Needs: new
      names/scripts (code, fast), new portraits/cards/sheets/KO stills (Canva, ~5 bosses x ~7 images). Old set -> DLC folder.
- [ ] (M) **Core-loop pacing:** does rent + shift grind feel like a second job by day 12? Use the soak test data
      (docs/qa/soak_report.md) + Brittany playtest; tune pay/rent/energy, add skip/autopilot where it drags.
- [ ] (L) **One art direction.** Three styles clash: chibi pixel world / Hazbin-style cards / glossy anime KO panels.
      Decision: pixel world for gameplay + ONE comic style for every HD layer (cards, portraits, KO, loading). Pick the
      card style (cleaner, already consistent across 17 bosses) and regenerate KO + loading stills toward it. Lock Duff's
      face with one canonical face sheet as the first Canva ref every time. ~60 Canva images, one agent at a time.
- [ ] (L) **The town is generic** next to the cards/cutscenes: M7 backgrounds + 2-3 hero landmarks with real Omaha
      character (Canva), plus prop density on the empty right-side lawns.

## JAM PUSH (Nov 9 → Dec 28; itch "2026 Jam" closes Dec 31). Entry: DuffQuest + Chaos if we bust ass.
- [x] **Upload the updated build to itch** (Nov 9: `7cd1f78` live via butler, key in `.env`) (`dufftkyosht.itch.io/duff-quest`). Fastest: Duff makes a butler API key
      (itch.io → Settings → API keys), pastes it once, Claude pushes with butler from the sandbox (itch API reachable,
      tested Nov 9). Key lives only in a temp env var, never in the repo. Fallback: phone upload, `docs/itch_deploy.md`.
- [x] Rebuild the web zip AFTER the art fixes + KO sfx land (zip from 06:51 Nov 9 = commit dc217e1, stale).
- [ ] Submit DuffQuest to the 2026 Jam once the itch page is current; keep pushing updates until Dec 28.
- [ ] Itch page: screenshots, GIF, controls, AI-use disclosure, content tag (cartoon blood/violence).
- [ ] Shrink the web build (90 MB zipped; mostly KO/loading JPGs) — try q80 + 1024w for loading screens.
- [x] Art fixes from `docs/reviews/*.md` (Canva agent running Nov 9): 19 KO stills, loading screens, crypto/fences cards, octavia/bdaydad portraits.
- [x] Duff sprite tattoos via `tools/tattoo_sprites.py` (pixel recolor agent running Nov 9).
- [x] KO sfx + stat screen overflow fix (agent running Nov 9) — review, test, commit.
- [ ] Title screen `bg_title.png`: Duff has bare arms, tattoo him (D1-D7).
- [ ] Bug: new-game intro says Monday costs $150 (RENT+BILLS) but `weekly_base()` charges $195+ (adds HOUSEHOLD $45 + plans). Fix the intro text.
- [ ] Doc drift found by reference.md (end of its section 9): stale .png names, M7 counts, voice.md 480x270, cast.gd DEFAULTS missing `stray`/`gala_baron`. Fix those docs/code.
- [ ] In-engine cartoon blood/spit/teeth particles on KO x-ray + finisher hits (art rule H2).
- [ ] KO stills for the last 6 bosses: coupon, allergy, camper, bdaydad, dasher, baron.
- [ ] Restyle 21 old chibi sprite sheets (see `docs/reviews/loading_sprites.md`).
- [ ] Portrait cut-out green halo cleanup script (all 21 portraits).
- [ ] Chaos Is the Mother of Order: separate repo/session; check where its jam slice stands.

## M1: Duff outfit sheets (Nov 8) — done
- [x] Key the 10 outdoor sheets from `grok_art/2026-11-08-duff-outfits/` (`tools/import_sheet.py`, drop 3)
- [x] Redraw `duff_shades.png` for the new head (`tools/make_shades.py`); old overlay sat on the hair
- [x] In-engine check: `tools/outfit_shot.tscn` + `tools/outfit_sheet.py` -> `docs/renders/duff_outfits_ingame.png`

## M2: street dressing (Nov 8) — done
- [x] Import trees/clutter/fences (`tools/import_dressing.py`), place via `data/town_dressing.json`
- [x] Depth sort + see-through canopy for Duff; `tools/dressing_check.gd` for blocked spots
- [x] Review fixes: bench by the bus sign, cones on the road, bin at the curb, props at Fork/Kwik/Walgrumps, stray picket removed

## Leftovers from the M2 review
- [x] Fade trees for NPCs/enemies/cats behind them too (M4, Nov 8: `see_through_actors.png`)
- [ ] Depth order for non-Duff actors: front-layer items are picked by DUFF's feet, so an enemy standing
      in FRONT of such a tree still draws under it (now faded, so visible, but wrong layering). Real fix =
      y-sort actors + dressing together (bigger refactor; only if it shows in play)
- [ ] Grok redraws: Waffle Haus pole sign, bus-stop sign, cats (old flat art)
- [ ] Right-hand lawns still big and empty; more props / a second yard once art allows

## Art follow-ups from the M1 review (Grok redraws, not code)
- [ ] Step frames (cols 1-2): clean legs on side rows, add a 1 px head bob
- [ ] Attack frame (col 3): real wind-up / extended swing + a smear frame (GBA DBZ pillar)
- [ ] Make outfits readable at a glance: real clogs, a light apron or coloured jacket; dark outfits vanish on asphalt
- [ ] Clean the speckled dark outline around hair/ponytail (in Grok's source)
- [ ] Hair: move from ginger toward the approved portrait's dirty blond

## M3: combat feel (Nov 8) — done
- [x] Hit-stop, shake (limit-clamped + zoom punch), sparks, popping numbers (`scripts/juice.gd`)
- [x] Review fixes: brulee/tempura ticks no longer freeze; spatula "flip" no longer counts as heavy; crits do; no late shake after the 86 cinematic/pause
- [ ] Try it on the phone: is 70 ms light hit-stop too sticky on fast combos?
- [ ] Enemy speech bubbles still cover damage numbers when 3+ enemies bunch up
- [x] (Nov 9) Stat points screen: Defense and Grit button labels ran past the button edge. Fixed in `UiStyle.button`: labels now go through `UiStyle.fit_text` (wrap to the lines the button holds, then shrink to 6, then "..."), so every button is covered. Check in test_daily; render `docs/renders/stat_screen_fixed.png` (`tools/stat_shot.tscn`).
