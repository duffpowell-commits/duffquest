# active-memory handoff: DuffQuest art pipeline (Gemini vs ChatGPT vs Grok, M7 backgrounds)

**Handoff #2** · 2026-11-08 · Lineage: #1 (2026-11-08): M4–M9 merged, M7 backdrops started, Grok ran out, Gemini app became the art department; #2 (2026-11-08): Gemini G1–G7 graded, ChatGPT C1–C7 + X1–X2 won and most went into the game, ChatGPT-vs-Grok rematch started (R1, R2 done), GitHub account suspended (6 commits unpushed)

## 0. Instructions for Claude (read first)

You are continuing work from a previous chat. That chat is gone; this file is the complete context and the source of truth.

1. Read this whole file before replying.
2. Follow sections 3 (Style), 4 (Hard rules) and 5 (Corrections) in every reply, for the rest of this chat. They override your defaults.
3. Use the values in section 8 exactly. Never round, re-estimate, or "correct" them.
4. Do not suggest anything listed in section 7 (Changed / rejected) again unless the user brings it up.
5. Code word: None active. If the user types /amcodeword, start every reply with the phrase they choose (default "Yes Boss!").
6. Your first reply: at most 5 lines covering the goal, the current state, and the next step (section 11). Mention any files from section 13 that were not attached. Ask the questions in section 12 if there are any. End with "Ready to continue with <next step>?" Then wait for the user's go.

## 1. Mission
- **Goal:** Upgrade DuffQuest's art to the Sea of Stars look using the free AI image apps (ChatGPT, Gemini; Grok out for the week), find out which app is best, and wire the winners into the game. Main backlog: the 19 M7 full-screen backgrounds (`grok_art/requests/REQUEST_M7_backdrops.md`).
- **Done looks like:** each asset graded, the best version in the game, collision checked, smoke test clean, merged to `main`, `dev` build updated.
- **Context:** DuffQuest = comedy RPG about Duff's real life in Omaha (Godot 4.5, GDScript, 640×360). Repo `duffpowell-commits/duffquest`. Its `CLAUDE.md` is the full project handoff; read it first in any repo session.

## 2. About the user
- Duff Powell, Omaha. Line cook. Partner Madison, baby daughter Octavia (both in the game).
- Phone only (Godot Android editor). No desktop tools, ever.
- Busy; wants maximum automation, but broke: will not pay for image APIs.
- Runs ChatGPT app, Gemini app, Grok (out for the week), Cursor agent "Place", Google Drive, Gmail.

## 3. Style & communication
- **Language:** English.
- **Tone:** informal, direct, blunt, sharp humour; light profanity OK. Push back when a better way exists. Game narration follows `docs/voice.md` (Duff at the bar, present tense, Palahniuk layer).
- **Reply length:** short; lead with the answer; phone screen.
- **Formatting:** short bullets; score tables for grading; prompts for AI apps in copyable code blocks; long prompt sets go in a Google Doc in Drive `geminiart` (easier to copy on phone).
- **Working style:** do the work, don't hand him manual steps unless unavoidable; send renders as files (SendUserFile), not many inline images; grade every AI image with the 12-point rubric and say what's wrong.
- **Avoid:** corporate fluff, recapping steps, nagging about the hour.

## 4. Hard rules (word for word)
1. "Push after every chunk of work; merge to `main` at the end of every milestone."
2. "Up to three milestones per session; update this handoff and merge after each." (repo `CLAUDE.md`)
3. "Save renders to `docs/renders/`, don't paste lots of images into chat."
4. "Smoke test (before every push)": `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn --fixed-fps 30 --write-movie /tmp/smoke/f.png --quit-after 600`
5. "Duff is phone-only (Godot Android editor). GDScript only, no desktop-only tools."
6. `gh` GraphQL is blocked: use `gh api repos/...` REST and `gh run ...`.
7. After replacing PNGs run `godot --headless --path . --import` before any render.
8. If Duff interrupts a command, stop and wait; don't merge until he says so.
9. PR #2 (`cursor/add-duffquesthd-7d71`): don't merge without asking.
10. Signs in new background art sit LOW: "top edge at least a quarter of the way down the image; nothing important in the top fifth" (Duff: "let's have gemini drop those signs down").
11. Storefronts must be "STRAIGHT-ON from the front like a 2D JRPG town ... Building only: no parking lot, no car, no trees, no fences, no dumpster" (map decision Nov 7: straight-on camera, never isometric).

## 5. Corrections log
| # | Claude did | The user wanted |
|---|---|---|
| 1 | Said M5 was blocked on art while the drop was in the repo | Check the repo for drops before calling anything blocked |
| 2 | Rendered old art after a PNG swap | Re-import first (`--import`) |
| 3 | Gave Gemini prompts needing manual file carrying | Automated loop wanted; then he chose the manual app route ("im too broke to worry about automation") |
| 4 | Called the Gemini G1 image a portrait | It was the apartment room |
| 5 | Kept going after he interrupted | Stop and wait for his go |
| 6 | Merged PR #32 while its CI run showed failure (the failure was likely the GitHub suspension itself) | Check CI result before merging |
| 7 | Was mid-way through swapping the Kwik-N-Go storefront when Duff interrupted (18:18) | Stop; he ran /amhandoff. The swap was NOT finished (see section 10) |

## 6. Decisions
| Decision | Why |
|---|---|
| ChatGPT app is the main art source now | Beat Gemini on every test (section 8) |
| ChatGPT apartment (C1) in game, replaced Gemini's | Duff: "Yes please"; same layout, no code change |
| ChatGPT gym (C2 try 2), tux (C3), Porch Pirate (C4), Dolores portrait (C5) in game | Scored 11–12; Claude wired after Duff's go on the shootout |
| Gemini G7 = title screen; Gemini G6 props drive fryer/sandwich | Duff: "Carry on in the order you presented" |
| ChatGPT vs Grok rematch: same Grok prompts, keep the winner per asset | Duff: "work backwards and have chatgpt test against grok" |
| R1 Kwik try 1: Grok kept (ChatGPT drew isometric + lot/car) | Map is straight-on |
| R2 trees: ChatGPT's maple/oak/ash/pine/lilac in; Grok's hedge kept | ChatGPT brighter; its hedge was boxy, town uses a long hedge wall |
| Move collision boxes in code instead of asking for redraws | Cheaper, keeps better art |
| GitHub suspended: keep working and committing locally, push when reinstated | Duff filed an appeal |

## 7. Changed / rejected
- Grok/Place as art source → Gemini app → now ChatGPT app (Grok out for the week; ChatGPT scored higher)
- Gemini apartment G1 → ChatGPT C1 (PR #32, merged)
- Gemini gym G2 → ChatGPT C2 try 2 (local commit, unpushed)
- Gym extra walls (5 boxes) → one racks band `Rect2(0,0,320,56)`
- Gemini "Dolores" G5 (curlers, robe, cigarette: wrong character) → ChatGPT C5
- Old porch pirate art → ChatGPT C4 (`ch_pirate0/2` = try 1, `ch_pirate1/3` = try 2)
- Grok trees (maple, oak, scraggly_ash, pine, lilac) → ChatGPT R2
- Controls text on the title screen → "How to play" button (it covered Duff's face)
- ❌ Automated Gemini API loop (free image quota 0; no billing)
- ❌ ChatGPT/OpenAI API (no free tier for images)
- ❌ Creative Claw generation (cost)
- ❌ Making the HUD see-through for arena signs (Duff chose: signs drop low instead)
- ❌ Gemini Flash-Lite for images (it claimed files were saved that weren't; G3 never arrived)
- ❌ ChatGPT's "results" email (`gptimagetest.md`): it only copied the prompts, no images

## 8. Data & facts (exact)
**Scores (12-point rubric, pass = 10+):**
| Test | ChatGPT | Gemini |
|---|---|---|
| 1 apartment | C1 11 | G1 ~9 |
| 2 gym | C2 11 | G2 try 2 10 |
| 3 tux sheet | C3 11 | G3 never came |
| 4 Porch Pirate | C4 12 | G4 9 |
| 5 Dolores | C5 11 | G5 8 (wrong character) |
| 6 kitchen props | C6 12 (16/16 in order) | G6 9 (5/16) |
| 7 show-off | C7 12 (Duff vs giant waffle) | G7 11 |
- X1 (add one tree, change nothing): ChatGPT FAIL strictly: 5.76% of pixels outside the corner changed >60, mean diff 21.0; no furniture moved. Fix for edits: paste only the edited region onto the original.
- X2 seamless tile: ChatGPT PASS by eye (3×3 tiling continues; edge-diff numbers high only because the edge is a grout line).
- X3 menu board: not received yet.
- Rematch: R1 Kwik try 1: Grok ~11 vs ChatGPT ~8 (isometric). R2 trees: ChatGPT ~11 vs Grok ~9.
- Backgrounds: PNG 640×360, opaque, filename = id. 1 world unit = 2 px. Sheets 256×256, 4×4 cells of 64, origin (32,60), rows down/up/right/left, cols stand/step/step/attack.
- ChatGPT outputs: 1672×941 (16:9), 1254×1254 (sheets). Gemini: ~2576×1438 JPG.
- Gym walls now `ARENA_EXTRA_WALLS = {"gymbro": [Rect2(0, 0, 320, 56)]}`; wall check: Duff stops at y 52 (gym) vs 26 (ghoster).
- Kwik footprint `Rect2(470, 40, 130, 70)`; `sf_kwik.png` canvas 260×140; ChatGPT try 2 would fit at 260×94.
- Tree sizes after swap: sd_maple 108×112, sd_oak 112×108, sd_scraggly_ash 101×112, sd_pine 88×112, sd_lilac 65×76; sd_hedge kept 112×47.
- Arena HUD covers the top ~35 world units (~20%) of a fight screen.
- API price notes (not used): Nano Banana $0.039/image; GPT Image 2 $0.006/$0.053/$0.211 low/medium/high square.

## 9. People, terms & names
- **People:** Duff (owner); Madison (partner); Octavia (daughter); Brittany (best friend, tester, iPhone); Dolores (Waffle Haus waitress NPC, 31 years in); Earl = The Regular (boss); "Place" = Duff's Cursor/Grok art agent.
- **Terms:** M7 = backgrounds milestone; G1–G7 = Gemini tests; C1–C7 = ChatGPT tests (same jobs); X1–X3 = trick tests for both; R1–R7 = ChatGPT vs Grok rematch; "drop" = batch of new art.
- **Drive folders:** "geminiart" `1VdN9JO8VeAx2_8DKFLDMwRJKclWln6F1` (all new results go here); "DuffQuest Art Inbox" `1axKztjLwkqYBuO89YvjQ2M-LVioGqoYA`; "97 Gemini art drops" `1kwe88L_hV7qM_-It2I8n6ZRTMchYoFT4`; "98 Gemini capability test" `1S95GvY8VOkFFdjVe3iHTUKp6BsZXKlMS`.
- **Drive Docs:** "Gemini tests - shootout + redos (Nov 8)" `16qJDEFFn1KMEpq5DrFn45h0FjBFdbLvEiBK21zX3ONk`; "ChatGPT vs Grok rematch (Nov 8)" `1mszZJe55HuUkX0NwdlLwOeB_VSqmqcPH_OM7MMjSHIs`; Gemini test doc `13q2fog54B7WVbSIWjhQQzf9AOtz1NRHlV7Q8EThOh0s`. `g2_try2.jpg` uploaded to geminiart.
- **Result file names:** `c#_try#.png`, `x#_chatgpt_try1.png`, `x#_gemini_try1.png`, `g#_try#.png`, `r#_chatgpt.png`, `r1_chatgpt_try2.png`.
- **Repo folders:** `grok_art/2026-11-08-gemini-test/`, `grok_art/2026-11-08-chatgpt-test/`; briefs `grok_art/requests/AI_ART_SHOOTOUT.md`, `grok_art/requests/CHATGPT_VS_GROK.txt`.
- **New tools:** `tools/import_big_sheet.py SRC TARGET_ID` (any-size 4×4 sheet → 256 format); `tools/import_props.py` (G6 → `kp_*`); `tools/import_chatgpt_trees.py` (R2 → `sd_*`); `tools/swap_storefront.py SRC NAME` (uncommitted); `tools/arena_shot.tscn -- <id>` (ids: boss arena, `title`, `home`, `fryer`, `sandwich`, `dolores`, `at:X,Y` (uncommitted)); `tools/arena_wall_check.tscn`.
- **Code names:** `ARENA_EXTRA_WALLS`, `_sync_arena_walls`, `TITLE_HELP`, `Art.portrait_for` (Dolores lines start with "Dolores"; "Madison texts" now maps to Madison).

## 10. Work state
| Item | Status | Version / location | Notes |
|---|---|---|---|
| GitHub account `duffpowell-commits` | SUSPENDED (~4:35 PM Nov 8) | appeal filed by Duff | every push/fetch/API returns 403 "Your account was suspended" |
| PR #32 ChatGPT apartment | merged | main | CI result unknown (lockout) |
| Local unpushed commits (6) | committed, not pushed | branch `chatgpt-home` in the Claude sandbox repo `/home/claude/duffquest` | gym C2, tux C3, Dolores C5, C5–C7+X1 files, pirates C4, X2, rematch brief, R1 render, R2 trees + Madison-texts fix. LOST if the sandbox ends before reinstatement. |
| Kwik storefront swap (R1 try 2) | INTERRUPTED, not done | `assets/art/sf_kwik.png` = still Grok's | uncommitted: `tools/swap_storefront.py`, `arena_shot.gd` `at:X,Y` id, `r1_chatgpt_try2.png`. ChatGPT try 2 is straight-on, building only, sign right: looks like a winner, needs Duff's go |
| ChatGPT C6 props | graded 12, not wired | `grok_art/2026-11-08-chatgpt-test/c6_try1.png` | waffle, coffee pot, tip jar, ticket ready for a Waffle Haus screen |
| ChatGPT C7 | graded 12, unused | `c7_try1.png` | spare loading screen / boss card |
| ChatGPT X3, rematch R3–R7 | waiting | Doc "ChatGPT vs Grok rematch" | R3 clutter, R4 Gym Bro card, R5 Brittany (redo), R6 Earl sheet, R7 Duff apron |
| Gemini redo doc (X1–X3, G3, G4 back row, G2 floor sign, G5 take 2) | waiting | Doc "Gemini tests - shootout + redos" | nothing back yet |
| M7 backgrounds | 3/19 in (home, kitchen, gym) | | 16 left (list in repo `QUEUE.md`) |

## 11. Next steps
1. **Next action:** ask Duff whether to put ChatGPT's straight-on Kwik-N-Go (`r1_chatgpt_try2.png`) in the game; if yes: `python3 tools/swap_storefront.py grok_art/2026-11-08-chatgpt-test/r1_chatgpt_try2.png kwik`, `--import`, shot `arena_shot.tscn -- at:535,128`, before/after render, smoke, commit.
2. Grade incoming rematch R3–R7 and ChatGPT X3 (Drive `geminiart` or attached in chat); keep the winner, wire it, render, smoke, commit.
3. When GitHub is back: `git fetch`, rebase, push the local commits, open PR(s), check CI, merge.
4. Then back to M7: ChatGPT prompts for the 16 remaining backgrounds (signs low, straight-on).

## 12. Open questions ⚠️
- Kwik-N-Go: swap in ChatGPT's try 2? (Claude's lean: yes.)
- If the sandbox may close before GitHub returns: save the 6 unpushed commits as a git bundle to Drive? (yes / skip)

## 13. Re-attach checklist
- [ ] `handoff-duffquest.md` (this file).
- [ ] Any new ChatGPT/Gemini images not saved to Drive `geminiart`.
- [ ] If the old sandbox is gone and GitHub is still locked: the git bundle from Drive (if one was made), else the unpushed work must be redone from `grok_art` images in Drive/chat.

---
<sub>Audit: 13/13 sections · 11 rules · 7 corrections · 41 data points · secrets removed: yes (none in file) · generated by active-memory</sub>
