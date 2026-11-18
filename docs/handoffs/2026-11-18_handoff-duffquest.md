# active-memory handoff: Duff Quest — iPhone hardening, 3D vans, EDM soundtrack

**Handoff #2** · 2026-11-18 · Lineage: #1 (2026-11-17): phone-themed HUD/menus, loading-screen wallpapers, IGN review v4, living town + UI motion + tilt-shift 3D + fight impact; #2 (2026-11-18): store screens re-shot, kitchen text cut, 3D van art, Brittany's iPhone freeze hardening + bug report, DJ Vape dubstep, EDM soundtrack toggle + batch 1

## 0. Instructions for Claude (read first)

You are continuing work from a previous chat. That chat is gone; this file is the complete context and the source of truth.

1. Read this whole file before replying.
2. Follow sections 3 (Style), 4 (Hard rules) and 5 (Corrections) in every reply, for the rest of this chat. They override your defaults.
3. Use the values in section 8 exactly. Never round, re-estimate, or "correct" them.
4. Do not suggest anything listed in section 7 (Changed / rejected) again unless the user brings it up.
5. Code word: None active. If the user types /amcodeword, start every reply with the phrase they choose (default "Yes Boss!").
6. Your first reply: at most 5 lines covering the goal, the current state, and the next step (section 11). Mention any files from section 13 that were not attached. Ask the questions in section 12 if there are any. End with "Ready to continue with <next step>?" Then wait for the user's go.

## 1. Mission
- **Goal:** Keep improving Duff Quest (comedy RPG, Godot 4.5, GDScript, repo `duffpowell-commits/duffquest`) and ship each piece; right now: the optional EDM soundtrack.
- **Done looks like:** merged to main, CI green, live on itch / home-screen web app, and checked by Duff on his phone ("Nothing is "done" until I've checked it").
- **Why it matters / context:** Duff + Brittany play-test on phones; Duff asked for "No issues in the game".

## 2. About the user (as relevant to this work)
- Duff: owner, line cook in Omaha; the game is about his life. Phone-only (Godot Android editor); no desktop steps.
- Playtesters: Duff (Android) and Brittany (iPhone 11, home-screen web app; her Snapchat name is "Mazikeen").
- Repo `CLAUDE.md` is the project handoff and beats the user's general preferences.

## 3. Style & communication
- **Language:** English.
- **Tone:** blunt, short, informal. Lead with the answer. Push back when warranted.
- **Reply length:** short; what shipped + what to check.
- **Formatting:** bullets, bold labels, small tables OK; renders saved in `docs/renders/`, audio previews in `docs/audio/`; send files with SendUserFile, not piles of images in chat.
- **Working style:** do the work, then tell. Ask first only if it costs money, can't be undone, or a wrong guess is expensive: one round, tappable (AskUserQuestion). Check the eval set (`docs/reviews/`) before any big job.
- **Avoid:** desktop-only steps; claiming "done" before Duff checked it live; nagging about the hour.

## 4. Hard rules (word for word)
1. "Phone only. No desktop steps, or say up front it can't be done from a phone."
2. "Nothing is "done" until I've checked it: on main, live, actually installed."
3. "A repo's CLAUDE.md beats this list."
4. "Check the eval set before any big job."
5. "You can merge them as they test green" (Duff, Nov 17: merge PRs yourself once CI passes).
6. CLAUDE.md house rules: GitHub main only, never force push, `git fetch` before starting/pushing, run `test_daily` before every push (must print `ALL PASS (0 failed)`, then `git checkout -- .godot/exported`), up to three milestones per session, update CLAUDE.md + TRACKER.md after each milestone, show real engine renders for visual decisions.
7. CLAUDE.md: Madison is a real person — Duff approves EVERY line about her EDS, autism and ADHD before it ships.
8. CLAUDE.md: no keys/tokens in repo, commits, logs or chat.
9. Write `{coworker}` (not Brittany's name) and `{fork_nick}` in new game strings; test_daily fails on a bare "Fork".
10. CLAUDE.md (Nov 18, another session): Duff's hands — LEFT = eye mandala + finger dots, NO RING; RIGHT = "This Red / Right Hand / Points Me / South". Copy masters in `docs/ref/duff/hand_*.png`, never invent.

## 5. Corrections log
| # | Claude did | The user wanted |
|---|---|---|
| 1 | Planned to stop after 3 milestones and hand off (#1) | Kept working in the same chat |
| 2 | Held merges for Duff's "merge" (#1) | Merge as soon as CI tests green |
| 3 | 3D vans: first fix laid the top-down art as a roof on a box (#138) | Duff: "fix the vans" → real standing van art (#139) |
| 4 | Guessed the DJ Vape freeze was the 3D view | Brittany: "turning the 3d off still didnt work" → not 3D; fixed with iPhone hardening (#140), then "it worked for her" |
| 5 | Sent MP3 previews as attachments | Duff: "i still havent heard what you made" → re-sent with display "render" + raw GitHub links (repo is public) |

## 6. Decisions
| Decision | Why |
|---|---|
| EDM soundtrack is a Settings toggle ("EDM soundtrack", off by default); Duff's music stays default | Duff: "Yeah make the toggle thats smart" |
| All new music synthesized in code (numpy), no samples | No licensing; credits say so |
| DJ Vape's fight plays dubstep (`mus_club`) in both soundtracks | Club Cloud 9 theme |
| EDM plan: town day = future bass 150 (half-time), town night = synthwave 100, kitchen = electro house 128, bosses = big room 128, home/title = lo-fi house 112, gala = deep/tech house 122, Willnot = drum & bass 174, date = chillwave 90 (Brahms melody kept), credits = progressive house 124; stings: ex KO drop hit, rent paid arpeggio, evicted/game-over tape-stop, level-up riser | Duff asked "layout an edm themed soundtrack" and approved |
| 3D vans: standing side/front/back art; 2D keeps top-down `truck_h/v` | Duff's phone test |
| iPhones start Lite graphics once; art cache drops big backdrops on room change; tap anywhere advances dialogue; loading watchdog; Settings > Send a bug report | Fixed Brittany's iPhone 11 freeze on the DJ Vape intro |

## 7. Changed / rejected
- Vans as roof-on-a-box (#138) → standing Canva van art (#139)
- "Freeze = 3D view on iPhone" → ruled out (3D off still froze); fix was general iPhone memory/input hardening
- Replace Duff's music with EDM → toggle instead (Duff's pick)
- ❌ Canva repaint of kitchen centrepieces (cake, patty): already HD since Nov 16 (consistency audit item 6 closed)
- ❌ Trimming dead fence/sun-sign art from packs: only ~16 KB, left as is
- ❌ Full 3D recreation, kitchen ticket-rail HUD, `ch_cashier` as a walker (from #1)

## 8. Data & facts (exact)
| PR | What | State |
|---|---|---|
| #136 | Store screens re-shot on Duffphone UI + kitchen screens talk less (fryer gauge, ticket icon specs) | merged |
| #137 | Handoff + consistency audit update (docs) | merged |
| #138 | 3D vans roof-on-box (superseded) | merged |
| #139 | 3D vans: standing `van_side`/`van_front`/`van_back` | merged |
| #140 | iPhone freeze hardening + Send a bug report | merged, sha `344a867` |
| #145 | Club Cloud 9 dubstep `mus_club.ogg` | merged, sha `b89771e` |
| #146 | EDM toggle + batch 1 | merged, sha `32746db` |
- Branch used: `ccr-9a7f3c05-pki71a`. Other sessions also merged to main Nov 18 (#141-#143 hand tattoos, #128 true3d slice).
- Music format: mono 22050 Hz Ogg Vorbis q2, loops ~25-30 s, level-matched RMS 0.17 (`mus_boss` = 0.173).
- `mus_club`: 140 BPM F minor, 16 bars, 27.43 s, 157 KB.
- EDM batch 1: `mus_edm_neighborhood` 25.60 s 113 KB; `mus_edm_night` 28.80 s 131 KB; `mus_edm_kitchen` 30.00 s 160 KB; `mus_edm_boss` 30.00 s 144 KB.
- Night music window: clock >= 1200 (20:00) or < 330 (05:30) → music id `night`.
- Bosses: 19 (5 story exes: Ghoster, Gym Bro Supreme, DJ Vape Lord, Mr. Crypto, Bruce Willnot / public Rex Tankton; 5 gala: Tyler Pivot, Grant Gratuity, Landlord Lance, Baron Von Trustfund, Chip Leverage; 9 alley: The Regular, Sir Sends-It-Back, Coupon Carol, The Allergy Liar, The Four-Hour Camper, Birthday Party Dad, The Dine-and-Dasher, Marketplace Mike, The Grease Trap). Cheeto Chad = street enemy.
- Watchdog: STUCK_LOAD 10.0 s. Art.drop_big prefixes: `bg_`, `arena_`, `gala`. HD overlay keeps portraits duff, madison, brittany, octavia.
- Preview links (public repo): `https://github.com/duffpowell-commits/duffquest/raw/main/docs/audio/edm_neighborhood_preview.mp3`, `.../edm_night_preview.mp3`.

## 9. People, terms & names
- **People:** Duff (owner); Brittany (coworker `{coworker}`, iPhone 11 tester); Madison (partner, real person, approval rule); Octavia (baby).
- **Terms:** Duffphone = phone-themed UI; the Spatula = public Fork (`{fork_nick}`); world.pck/street.pck/extra.pck = web packs; "open world" = the town.
- **Names in use:** `tools/edm/synth.py` (synth kit), `tools/edm/make.py` (EDM tracks, `TRACKS` dict, `--preview DIR`), `tools/synth_dubstep.py`, `tools/import_vans.py`, `audio.edm`, `audio.set_edm`, `audio._music_candidates`, `MUSIC_FALLBACK = {"night": "neighborhood"}`, `main.music_track()`, `main.bug_report()`, `main.send_bug_report()`, `main._watchdog`, `Art.drop_big`, `perf_guard` cfg `ios_lite`, `view3d._van`, `minigame.ticket_spec()`, `fryer._draw_gauge`, arena_shot ids `ask`, `gala_say:<boss>`.

## 10. Work state
| Item | Status | Version / location | Notes |
|---|---|---|---|
| EDM toggle + batch 1 | live | main #146; previews `docs/audio/edm_*_preview.mp3` | Duff hasn't heard them yet (re-sent) |
| EDM batch 2 (home, gala, willnot, date, credits, stings) | not started | add to `tools/edm/make.py TRACKS` + test_daily list | wait for Duff's go |
| Dubstep `mus_club` | live | main #145; `docs/audio/club_dubstep_preview.mp3` | |
| iPhone hardening + bug report | live, confirmed | main #140 | Brittany: DJ Vape works now |
| 3D vans | live | main #139 | not yet phone-checked by Duff |
| Store screens | current | `docs/itch/screens/` | re-shoot ids in CLAUDE.md |

## 11. Next steps
1. **Next action:** get Duff's reaction to the open-world EDM tracks (`edm_neighborhood`, `edm_night`) and tweak per his notes (tempo, darker/brighter, bass).
2. On Duff's go: EDM batch 2 (home/title lo-fi house, gala deep house, Willnot drum & bass, date chillwave Brahms, credits progressive, stings) + MP3 previews, tests, PR, merge on green.
3. Duff phone-checks vans, new UI, tilt-shift; pastes itch page from `docs/itch/PAGE.md`; arm play alerts on debut.

## 12. Open questions ⚠️
- How do the EDM batch-1 tracks sound to Duff? (Claude can't listen; only checked loudness/spectrograms.)
- Batch 2: go now, or after batch-1 changes?

## 13. Re-attach checklist
- Nothing to attach (everything is in the repo; a new cloud session re-clones it).

---
<sub>Audit: 13/13 sections · 10 rules · 5 corrections · 24 data points · secrets removed: none found · generated by active-memory</sub>
