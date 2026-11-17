# active-memory handoff: Duff Quest — Duffphone UI + visual plan

**Handoff #1** · 2026-11-17 · Lineage: #1 (2026-11-17): phone-themed HUD/menus, loading-screen wallpapers, IGN review v4, living town + UI motion + tilt-shift 3D + fight impact

## 0. Instructions for Claude (read first)

You are continuing work from a previous chat. That chat is gone; this file is the complete context and the source of truth.

1. Read this whole file before replying.
2. Follow sections 3 (Style), 4 (Hard rules) and 5 (Corrections) in every reply, for the rest of this chat. They override your defaults.
3. Use the values in section 8 exactly. Never round, re-estimate, or "correct" them.
4. Do not suggest anything listed in section 7 (Changed / rejected) again unless the user brings it up.
5. Code word: None active. If the user types /amcodeword, start every reply with the phrase they choose (default "Yes Boss!").
6. Your first reply: at most 5 lines covering the goal, the current state, and the next step (section 11). Mention any files from section 13 that were not attached. Ask the questions in section 12 if there are any. End with "Ready to continue with <next step>?" Then wait for the user's go.

## 1. Mission
- **Goal:** Make Duff Quest (comedy RPG, Godot 4.5, GDScript, repo `duffpowell-commits/duffquest`) more visually appealing and alive, and ship each piece.
- **Done looks like:** merged to main, CI green, live on itch / home-screen web app, and checked by Duff on his phone ("Nothing is done until I've checked it").
- **Why it matters / context:** IGN-style review v4 scored it 8.4/10; biggest wins left are the itch page, phone testing, and life/motion.

## 2. About the user (as relevant to this work)
- Duff: owner, line cook in Omaha, the game is about his life. Phone-only (Godot Android editor); no desktop steps.
- Playtesters: Duff (Android) and Brittany (iPhone).
- Repo `CLAUDE.md` is the handoff for the project and beats the user's general preferences.

## 3. Style & communication
- **Language:** English.
- **Tone:** blunt, short, informal. Lead with the answer. Push back when warranted.
- **Reply length:** short; lists of what shipped + what to check.
- **Formatting:** bullets, bold labels; real engine renders sent as files, saved in `docs/renders/`; no piles of images in chat.
- **Working style:** do the work, then tell. Ask first only if it costs money, can't be undone, or a wrong guess is expensive: one round, tappable (AskUserQuestion). Check the eval set (`docs/reviews/`) before any big job.
- **Avoid:** desktop-only steps; claiming "done" before Duff checked it live; don't nag about the hour.

## 4. Hard rules (word for word)
1. "Phone only. No desktop steps, or say up front it can't be done from a phone."
2. "Nothing is "done" until I've checked it: on main, live, actually installed."
3. "A repo's CLAUDE.md beats this list."
4. "Check the eval set before any big job."
5. "You can merge them as they test green" (Duff, Nov 17: merge PRs yourself once CI passes).
6. CLAUDE.md house rules: GitHub main only, never force push, run `test_daily` before every push (must print `ALL PASS (0 failed)`, then `git checkout -- .godot/exported`), up to three milestones per session, update CLAUDE.md + TRACKER.md after each milestone, show real engine renders for visual decisions.
7. CLAUDE.md: Madison is a real person — Duff approves EVERY line about her EDS, autism and ADHD before it ships.
8. CLAUDE.md: no keys/tokens in repo, commits, logs or chat.
9. Write `{coworker}` (not Brittany's name) and `{fork_nick}` in new game strings; test_daily fails on a bare "Fork".

## 5. Corrections log
| # | Claude did | The user wanted |
|---|---|---|
| 1 | Planned to stop after 3 milestones and hand off to a new session | "Build the visual plan" here — kept going in the same chat |
| 2 | Held merges for Duff's "merge" each time | Merge as soon as CI tests green (rule 5) |

## 6. Decisions
| Decision | Why |
|---|---|
| HUD theme = Duff's phone (status bar, notification shade, banners) | Duff's pick over kitchen ticket rail |
| Loading screens = phone wallpaper (one per day) + blurred backdrop behind frameless menus | Duff asked; better than HUD backgrounds |
| One UI language: glass menu sheets, Settings app, Gear grid, pill buttons | Duff picked all four UI redesigns |
| Kitchen minigames keep chunky key-cap buttons | big thumb targets mid-rush |
| Visual plan: living town, UI motion, diorama 3D (tilt-shift), fight impact | Duff picked all four |
| No full 3D rebuild | 3D view is already default (PR #109); rebuild would kill painted art + phone perf |

## 7. Changed / rejected
- ❌ Full 3D recreation (already 3D by default; too costly)
- ❌ Kitchen ticket rail HUD theme (Duff chose phone)
- ❌ Loading screens as HUD background (would cover the game) → used as phone wallpaper + menu fallback
- ❌ `ch_cashier` as a town walker (her scanner reads as a gun)
- Mash/hustler painted porch backdrop: offered (needs a Canva generation ~40 min), not requested yet

## 8. Data & facts (exact)
| PR | What | State |
|---|---|---|
| #129 | HUD = Duff's phone | merged |
| #130 | Loading screens as wallpapers | merged |
| #131 | Glass menu sheets, Settings app, Gear grid, hustler + quiz polish | merged |
| #132 | Handoff/plan doc + IGN review v4 (8.4/10) | merged |
| #133 | Visual plan (living town, UI motion, tilt-shift, fight impact) | merged (CI green), merge sha `cd637d8` |
| #135 | Lossy sprite sheets (Continue downloads 8 MB, was 17.6) | merged |
| #136 | Store screens re-shot on the Duffphone UI + kitchen screens talk less (fryer gauge, ticket icon specs) | merged, sha `f67819a` |
- Branch: `ccr-1297da7c-69sgo3`.
- IGN review v4: 8.4/10 (v3 7.9, v2 7.1, v1 6.4). File `docs/reviews/ign_review_2026-11-17_v4.md`.
- World geometry: road centre y 175, x 316; lanes y 167 (dir -1) / 184 (dir +1), x 308 (+1) / 324 (-1); sidewalks y 141 / 211, x 283. Ground world rect P(-5,-16) S(672,384).
- Fork roof vents (2D): (476,268), (581,268); `TownLife.PUFF_BASE_Y = 318`.
- Weather: snow if day ≥ 6 and roll < 22; rain if roll ≥ 70 at 17:00–05:00; else leaves (roll = (day*7919+13) mod 100).
- Walkers: `ch_waitress, ch_sitter, ch_usher, ch_regular, ch_phlebotomist`; 4 by day, 1 at night (23:00–05:30).
- Tilt-shift uniforms: focus_y 0.58, band 0.24, radius 2.2, boost 1.06.
- Itch play alerts: `.github/play_alerts.json` `"armed": false`.

## 9. People, terms & names
- **People:** Duff (owner); Madison (partner, real person, approval rule); Brittany (coworker, `{coworker}`, OK'd her real name); Octavia (baby).
- **Terms:** Duffphone = phone-themed UI; the Spatula = public name of the Fork (`{fork_nick}`); world.pck/street.pck = web packs.
- **Names in use:** `scripts/hud.gd`, `scripts/wallpaper.gd`, `scripts/town_life.gd`, `scripts/minigames/card.gd`, `settings.gd`, `gear_screen.gd`, `mash.gd`, `quiz.gd`, `shaders/tilt_shift.gdshader`, `UiStyle.pill_button`, `UiStyle.glass`, `minigame.pill_buttons`, button flag `"hide": true`, `juice.squash`, `combat_fx.swing/dust`, `hud.wipe_t`, sprites `amb_pigeon`, `amb_puff`.

## 10. Work state
| Item | Status | Version / location | Notes |
|---|---|---|---|
| Phone HUD, wallpapers, menus/Settings/Gear | final, live | main (#129–#131) | not yet phone-tested by Duff |
| Visual plan | final, live | main (#133) | swing smear caught on a render (`docs/renders/swing_smear_2d_3d.jpg`); not phone-tested |
| Kitchen less text | final, live | main (#136) | fryer colour gauge, sandwich/salad spec tiles; not phone-tested |
| Handoff/plan doc | final | `docs/handoffs/2026-11-17_phone_ui_and_visual_plan.md` | |
| Renders | final | `docs/renders/hud_phone_before_after.png`, `wallpapers_phone_menu.png`, `ui_phone_sheets_before_after.png`, `visual_plan_town_motion_3d.png` | |
| Store screenshots | current (Nov 17 late) | `docs/itch/screens/` | re-shoot ids in CLAUDE.md |

## 11. Next steps
1. **Next action:** ask Duff for his phone-test notes on today's build (UI, tilt-shift smoothness on Android, walker density) and fix what he reports.
2. Duff phone-tests the new UI, tilt-shift blur (Android perf) and walker density.
3. Duff pastes the itch page from `docs/itch/PAGE.md`; arm play alerts on debut.
4. Done Nov 17 late: store screens re-shot, kitchen text cut (#136). Consistency audit items 6/8/9 closed.
5. Optional: Canva painted porch backdrop for the door-to-door hustler (offered, not requested).
6. After Duff's notes: balance re-check with two outside players (IGN v4 weakness #3).

## 12. Open questions ⚠️
- Does the tilt-shift run smoothly on Duff's Android? (keep / tone down / Lite only)
- Walkers: right amount, or too busy?

## 13. Re-attach checklist
- Nothing to attach (everything is in the repo; a new cloud session re-clones it).

---
<sub>Audit: 13/13 sections · 9 rules · 2 corrections · 20 data points · secrets removed: none found · generated by active-memory</sub>
