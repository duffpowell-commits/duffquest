# DuffQuest tracker

One page: what's built, what's next, what could be better. Updated at every milestone, alongside `CLAUDE.md`
(the handoff) and `QUEUE.md` (the work queue). Newest first.

## Built
- **2026-11-18** **iPhone freeze hardening (Brittany: the game froze on the DJ Vape intro on her iPhone 11, 3D on or off).** Not reproducible in Chrome, desktop WebKit (iPhone profile, real day-6 save, real taps) or native, so every likely cause got a fix: (1) iPhones start in Lite graphics once (`perf_guard`, cfg `ios_lite`; Settings > Lite graphics OFF sticks); (2) the art cache drops one-off 1280x720 backdrops (`bg_*`, `arena_*`, gala) on every room change (`Art.drop_big`, `main._watchdog`), the HD overlay lets go of boss intro cards after their line and guest portraits on room change, the wallpaper caches keep two; (3) a tap anywhere on the screen moves a dialogue line on, not just A (`touch_controls`); (4) watchdog: a loading screen stuck for 10 s, or a menu freed without closing, no longer leaves every tap ignored; (5) Settings > MORE > "Send a bug report": state + memory + the save as text, on the web in a page-level box with a COPY button (iPhone Safari only copies from a real page tap). Render `docs/renders/settings_bug_report_row.png`.
- **2026-11-17** **3D vans stop lying on their side (Duff's phone test: "cars need work but it's a great idea" / "fix the vans").** The vans' art was drawn from above and the 3D view stood it up like a cardboard cutout, so every van read as tipped over. New Canva sheet (`grok_art/2026-11-17-vans`, master on page `vans_v1` of the Canva design "DuffQuest art drop Nov 10"): a white van drawn for the game's camera, cut by `tools/import_vans.py` into `van_side` (mirrored when driving left), `van_front` (coming toward the camera) and `van_back` (driving away), s 4. In 3D they stand as cards like the characters, tinted per van, with real shadows (`view3d.VANS`, `_van`); covers the town vans and the HONK delivery truck. The flat 2D view keeps the top-down vans. Render `docs/renders/vans_3d_before_after.jpg` (left old, right new).
- **2026-11-17** **Kitchen screens talk less (IGN v4 weakness #5).** Fryer: the four text lines ("Set", "Sweet spot 350-375°F", "Cold baskets drop the oil...") are now one colour gauge (blue too cold, green 350-375°F, amber, red smoking), a white pointer for the oil and a gold notch for the HEAT setting; the how-to card says "keep the pointer in the GREEN". Sandwich + salad tickets: the 6 pt "Spec:" text is a row of ingredient tiles in build order with an arrow (two rows of big tiles when the ticket has room), the 86'd item faded with a red slash. Mods and allergies stay as text. Shared `minigame.spec_icons()` / `ticket_spec()`. Render `docs/renders/kitchen_less_text_before_after.png`.
- **2026-11-17** **Store screens re-shot on the Duffphone UI.** 10 of the 15 itch screens showed the old HUD, menu cards and Notes app: 01, 06, 07, 08 (3D, phone status bar), 10-12 (cold open + first bet, glass bet sheet), 13 (Notes on the Duffphone), 14 (side-gig glass sheet), 15 (EVICTED with pill buttons). 02-05 and 09 have no HUD or menus and stay. Public edition, clean language, gore off, 1920x1080. New `arena_shot` ids `ask` ({partner} asks for diapers) and `gala_say:<boss>` (her setup line as an ex walks in) make 06/07 reproducible. Before/after `docs/renders/store_screens_phone_ui_before_after.jpg`.
- **2026-11-17** **Shorter second wait (IGN v4 fix #5).** All 213 character, Duff, kitchen-prop, storefront and street-prop sheets import lossy 0.8 instead of lossless. street.pck 4.8 -> 2.0 MB (New Game), world.pck 12.8 -> 6.0 MB: Continue and the first Fork/arena now download 8 MB instead of 17.6 (about half the old ~23 s on 4G). No visible change in 2D or 3D (`docs/renders/lossy_sprites_before_after.png`). The loading card now names its step ("Unpacking the street (1/2)", "... neighbors (2/2)") so the % restarting doesn't look like it went backwards.
- **2026-11-17** **The visual plan (Duff picked all four).** *Living town* (`scripts/town_life.gd`, cosmetic, own RNG): tinted vans on the four road lanes (brake and queue for Duff; never while a hostile driver is out), 4 off-duty walkers on the sidewalks (1 at night; step around Duff, turn back from fights; not the cashier, her scanner reads as a gun), pigeon flocks that peck and scatter when Duff runs at them (`amb_pigeon`), steam off the Spatula's roof vents (`amb_puff`; 3D lifts it to the roof via `TownLife.PUFF_BASE_Y`), and screen-space weather per in-game day (leaves most days, rain some evenings, snow some days from day 6). Each thing is its own y-sorted node, so it sorts against Duff/trees and becomes a 3D card for free. *UI motion*: buttons squish on press (`minigame.SQUISH_T`), menu sheets slide up (taps ignored mid-slide, never headless), the HUD cash pill counts to the new balance with a green/red flash, a circle wipe opens on every room change (`hud._draw_wipe`). *Diorama 3D*: `shaders/tilt_shift.gdshader` on the 3D container (sharp band round Duff, soft top/bottom, slight toy saturation), off in Lite; the street lamps already pool light at night. *Fight impact*: hit bodies squash and spring back (`juice.squash`, enemies + Duff), a white smear arc follows each swing (gold-edged on finishers), dust puffs when a roll starts and lands (`combat_fx`). Render `docs/renders/visual_plan_town_motion_3d.png`.
- **2026-11-17** **One UI language: the Duffphone.** Every menu card (`card.gd`) is a dark glass sheet rising from the bottom, only as tall as its text + buttons, with a grabber, bold title and pill buttons (same teal / plum / red roles; `UiStyle.pill_button`, `UiStyle.glass`, `minigame.pill_buttons`); the title screen puts its title + tagline on a glass plate up top so Duff's porch stays clear; fail screens get the pills too. Settings is the phone's Settings app: SOUND card (sliders with knobs, Mute switch), GAME card (iOS switches: clean, gore, shake, 3D view, Lite graphics), MORE (Credits, Dev); each row is one hidden button (tap anywhere on it; keys unchanged). Gear is a shop grid: 7 weapon + 6 armour + shades tiles, locked items as black silhouettes with "?", green dot = equipped, gold +N level badge, and a detail card (Duff wearing the armour, stats, EQUIP / UPGRADE / DONE). Door-to-door hustler: a real doorway the door swings shut across, a speech bubble pointing at him, a pill gauge. Lineup quiz: on the kitchen backdrop with a hardboard clipboard and metal clip. Phone + credits use pill buttons. Render `docs/renders/ui_phone_sheets_before_after.png`.
- **2026-11-17** **Loading screens as wallpapers.** Duff's phone home screen shows one of the 14 loading-screen paintings, a new one each in-game day (`scripts/wallpaper.gd for_day`, rebuilt at 640x360). Menus with no world frame to blur (shift menus, cold boot) get a blurred loading screen that rotates each time instead of the old sunburst (consistency audit #8; `main._veil_snapshot`). The phone's status bar uses the HUD's signal bars + battery. Render `docs/renders/wallpapers_phone_menu.png`; `ui_audit_shot` id `menu_wallpaper`.
- **2026-11-17** **HUD reskin: Duff's phone (Duff's pick over a kitchen ticket rail).** The top strip is his lock-screen status bar: bold clock + day on the left; on the right a heart with 4 signal bars ({partner}'s happiness, 25% a bar, the last one fills from the bottom), a battery for Energy (green / amber / red, bolt when over 80), a green cash pill for money (red when rent bites) and the drawer chevron. The drawer is the notification shade: one card per row with its app tile (Notes "!" for the errand, "$" rent, piggy fund, bus pass, her face, "B" bag). Peeks are notification banners with the row's app tile, toasts are banners, buffs are little app icons, the urgent chip is a red notification pill. Same rects as before, so touch hit areas and the phone button don't move; the dialogue box is unchanged. Render `docs/renders/hud_phone_before_after.png`, 3D `hud_phone_3d_home.png`; `tools/hud_shot.tscn` re-shoots it.
- **2026-11-17** **Enemies scaled back halfway.** Duff: "they are tough". Halfway between pre-Nov 13 and the Nov 15 pass 2: hits on Duff x1.1 (was 1.25), early four exes 43/80/98/117 HP (was 54/99/120/144; pre-Nov 13 32/60/75/90), their hits x1.1 (was 1.25), swings every 2.0 s (was 1.7-1.8), lead aim 0.15-0.2 s (was 0.35-0.45), Willnot 220 HP (was 240) with a 230 s timer, night spawn cap back to +2. 3D checked: render-only, same hitboxes and timings as 2D, so it added no difficulty.
- **2026-11-17** **3D Duff's shades sit on his eyes.** The 3D view swaps in the HD Duff sheet, but his round shades were still the 2x overlay fitted to the old faces, so they sat across his mouth. New `assets/art3d/duff_shades_home_hd3d.png` (`tools/duff_hd3d/shades_hd.py`, per-frame eye centres), used only over the HD sheet. Render: `docs/renders/duff_shades_3d_before_after.png`, all frames `duff_shades_hd3d_all_frames.png`.
- **2026-11-17** **3D store screens, smaller web build, low-end fallback.** Store screens 01, 06, 07, 08, 10, 11, 12 re-shot in 3D (render `docs/renders/store_screens_3d_before_after.jpg`). Web: knockout stills recompressed (lossy 0.8 -> 0.62, -1.5 MB in extra.pck), the 3D Duff sheet goes lossy (-1.0 MB), and street.pck no longer carries the 12 outfits a day-one player can't wear (they ride in world.pck; `player.sheet_name()` falls back to the casual tee until it lands). perf_guard's last step on a phone that still drops frames after Lite + 640x360 is the flat 2D view, with a toast. Sandbox-only bug: 144 stale imported textures (pirates drew as four tiny guys in 3D renders); re-imported and committed, see CLAUDE.md "Stale imports".
- **2026-11-17** **Polish pass 3 + review fixes.** Brittany's $ plumb over her head (3D billboard vs perspective), buildings in front of Duff hide outright with their signs, box walls never black, cold open is one line (no control cards on frame one; cards stay in How to play), first bet pitch is one card line, rules four short beats, G (gear) hidden in fights and labelled, level/heat panel hidden until the first special, toasts moved to the top, Jen's daily text no longer lights the phone badge. Render: docs/renders/polish3_review_fixes.png.
- **2026-11-16** **Home-screen app picks up new builds.** Brittany still saw "Mazikeen's bet" after PR #108: the source and every
  shipped build (dev release web + CrazyGames zip) were already clean, but the GitHub Pages copy is a PWA whose Godot
  service worker serves the cached `index.pck` until every window of the app closes. CI now injects
  `tools/web_shell/pwa_autoupdate.html` so a launch swaps in the new build (one reload on the title). test_daily guards
  BRITTANY'S BETS in the public edition.
- **2026-11-16** **3D buildings get depth (cardboard boxes).** Duff picked boxes over flat cutouts. Each storefront/house keeps its painted facade card, with a solid box behind it (`view3d._box`): its top at the art's eave line, its depth min(lot x 0.35, 22 units), walls tinted from the facade's outer columns, and the roof tiled from the least busy patch of the art's own painted roof (skips signs and vents). It replaces the old shadow-only block, so shadows match. When Duff walks behind a building, its facade and box fade to 45% (`_fade_buildings`). 2D untouched. Render `docs/renders/view3d_buildings_boxes.png` (before left, after right; Duff behind the Spatula top right).
- **2026-11-16** **3D polish 2: NOW HIRING and label shadows.** NOW HIRING (you) shrinks back to its normal size when the Spatula sits closer to the camera than Duff (it filled a third of the screen and ran off the edge). 3D labels no longer cast shadows: at dusk the low sun turned the NOW HIRING label into a stray dark line on the sidewalk. Render `docs/renders/view3d_polish2_hiring_before_after.png`.
- **2026-11-16** **HUD drawer icons.** The piggy bank (`ic_piggy`) now sits on the "Octavia's college fund" line and the bus icon (`ic_bus`) on a new "Bus pass: N days left" line, shown while a pass is active (`hud.gd` `ROW_ICONS`). Both sprites existed but were drawn nowhere. Render `docs/renders/hud_drawer_icons.png`.
- **2026-11-16** **3D polish 1: nothing left floating on the flat overlay.** In 3D the Waffle Haus pole sign, the 86 List board and Brittany's "$" still drifted (plain 2D draws mapped onto the camera). The two signs now draw into their own small 4x viewport and stand up as cards (`view3d._sign`, `main.draw_waffle_sign` / `draw_86_board`), the "$" is a 3D label. House names slide below the HUD strip; NOW HIRING hides when the Spatula sits low and close (it filled the screen). Camera y clamp 112..300 and a map-coloured plane past the edge: no more mint strip at the bottom/top. Bus stop signs (`bus_sign`) now stand at all four stops in both views (`data/town_dressing.json`); they were invisible. Bug fix: turning Settings > 3D view off mid-game left every tree and street prop invisible in 2D (they never redraw and had only been recorded for 3D); switching views now redraws the world. `arena_shot -- <id> --2d` forces the flat view. Render `docs/renders/view3d_polish1_before_after.png`.
- **2026-11-16** **3D view, step 7: default on (branch `claude/project-thread-fhx6e4`, draft PR #109, NOT merged).** Duff phone-tested the 3D build and said go. Fixed what he saw: CLOSED signs (and the other building signs, quest markers, house names) slid off their shops as the camera moved, because they were drawn flat and mapped onto the 3D camera; they are now 3D labels pinned to each facade. 3D is the default for new and old settings (Settings > 3D view turns it off), and the web build ships on the 3D engine (+0.8 MB). Renders `docs/renders/view3d_signs.png`, `docs/renders/view3d_editions.png` (public top, family bottom).
- **2026-11-16** **3D view, steps 2-6 (branch `claude/project-thread-fhx6e4`, draft PR #109, NOT merged).** Settings > 3D view puts the town, rooms (home, gala, arenas) and fights on a 3D ground with real sun shadows; actors are the same 2D art captured as cards; FX stay 2D, mapped onto the 3D camera. Renders at native resolution (capped 3x). Lite (same auto switch as 2D lite): 1.5x render, no MSAA/shadows/glow. Ground on the branch is an AI 2x upscale; the real Canva repaint comes from the HD thread. Renders `docs/renders/view3d_*.png`. Step 7 (3D as default) waits on Duff.

- **2026-11-16** **HD audit: everything at 4 px per world unit.** Duff: sprites didn't match the backgrounds' sharpness. Render at 1280x720 (#110); kitchen/props/avatars to s:4, ground 2x, boss magenta fringe (#114); street ground repainted in Canva as 4 tiles joined on min-cost seams (#115, `tools/ground_repaint_tiles.py`); last batch: drone, NFT frame, package, delivery vans, honey bun, cat peek, bus sign, HUD phone and the ic_* icons cut from one Canva 4x4 sheet at s:4 (`tools/import_hud_icons.py`, same world sizes and anchors). Renders `docs/renders/hd_icons_before_after.png`, `hd_icons_home_hud.png`.
- **2026-11-16** **Mini-games: how-to cards, easy first go, two bug fixes.** Duff: the mini-games are cool but too tough, the tutorial needs to stand out. Every action mini-game (19, plus each of prep's 4 steps) opens a HOW TO PLAY card the first time: up to 3 picture steps, each with a little animated hint of the move (tap ripple, drag, hold, beat). The clock waits; tap anywhere or GOT IT to start; the teal `?` in the header (F1 on keyboards) replays it any time. First go runs at 70% speed, second at 85%, then full (`minigame.gd` `PACE_RAMP`; plays per game in `user://coach.json`, not the save). Walk-around scenes (grocery, pharmacy), stealth and Wordle get the card only. Off in headless runs (`coach_on`). Fixes: Stock the make line shows each pan's own food (empty pan art + food pile sized by level, fill gauge with the 40% refill line) and plated name/temp tags (HOT in red); card menus with 7+ choices go 3 columns and body text shrinks to fit above the buttons, so the 86 List's last line shows. Render `docs/renders/minigame_coach_before_after.png`; `ui_audit_shot` ids `prep_stock`, `bounty86`, `coach_*`.
- **2026-11-16** **Brittany's name back + redder hair.** Brittany told Duff she likes the game using her real name (and that "Brittanys Bets" is catchy), so the public edition drops its Mazikeen override: `{coworker}` = Brittany in both builds, the bet cards and HUD read BRITTANY'S BETS (plural, Duff's call). Her hair is copper-red in the sprite sheet, HD portraits and the goose loading screen (`tools/redden_hair.py`, hue shift on a hair-only mask). Render `docs/renders/brittany_red_hair_before_after.png`; store screens 10-14 re-shot with her name.
- **2026-11-16** **Store shots for the new stuff.** Six 1080p listing screens in `docs/itch/screens/` (10-15): cold-open porch pirate, Brittany's bet card and the Mike fight, the side-gig choice card, the EVICTED screen, the phone Notes journal. Public edition, clean language, gore off (`arena_shot` `cold`/`gig`/`evicted`/`notes`). Upload order in `docs/itch/PAGE.md`.
- **2026-11-16** **Fail states: eviction + game over.** Three Mondays in a row short of the week's base (`EVICT_STRIKES`, save field `rent_strikes`, defaults 0) = EVICTED screen, retry rolls back to last Monday. The first story/gala KO each day is a free get-up (old soft landing); the second = KNOCKED OUT / GAME OVER screen, retry rolls back to this morning. Soft fails: rolling snapshots `<save>_morning.json` / `<save>_week.json`, never a wiped save. Bounties, bets and street fights keep their old soft landing. Render `docs/renders/fail_screens.png`; `arena_shot` ids `evicted` / `gameover`.
- **2026-11-15** **Harder story fights + no loading card before the first bet.** Duff: "increase the difficulty of the fights." Early exes per `boss.STORY_TUNE`: HP Ghoster 38->54, Gym Bro 72->99, DJ Vape 90->120, Crypto 108->144 (Willnot stays 240, so the last step is 1.7x, was 2.2x); their hits do x1.25, they attack every 1.7-1.8 s (was 2.2) and aim ahead of a moving Duff. Web: the first bet's alley, Marketplace Mike, {coworker}'s sprite/portrait and the boss music ride in street.pck (+0.7 MB), so the minute-two fight starts without waiting on world.pck.
- **2026-11-15** **Consistency audit, fix 2: listing re-shoot.** CrazyGames preview videos (16:9 + 2:3, 18 s, silent), itch GIFs and 8 of 9 screens re-shot on the 2x cast and the new dialogue box; covers (portal 3 + itch) are the porch title art + logo, which also drops the old mid-throat fox. `arena_shot sandwich` no longer catches the ticket theft. Render `docs/renders/listing_reshoot_before_after.png`.
- **2026-11-15** **Consistency audit, fix 1.** Web/app loading splash is the Duff Quest logo (was Godot's default), app icon is the DQ skillet (was a 16 px placeholder), phone avatars are head crops of the 2x sheets (`tools/make_avatars.py`). Full ranked audit: `docs/reviews/consistency_audit_2026-11-15.md`. Render `docs/renders/avatars_splash_before_after.png`.
- **2026-11-15** **Design review #5-8 (PR #100).** Painted Back Walk bed and the stealth floor replace drawn placeholders; house name tags stay under the HUD; arena HP plate and level panel clear the touch buttons; tiny UI text up a size. Renders in `docs/renders/` (`stealth_floor_before_after.png`, `backwalk_bed_after.png`, `house_tags_after.png`, `arena_hp_plate_after.png`, `tiny_text_after.png`).
- **2026-11-15** **Legal re-audit + brand scrub.** Public pharmacy shelves lose DayQuil/NyQuil/Mucinex/Theraflu/Vicks (now DayQuail, NyteQuail, Snotinex, Sniffaflu, VAPOR) and the red Walgrumps sign; the tower storefront says GLASSHAUS TOWER. AI tool names out of the credits (itch disclosure stays). Render `docs/renders/legal_public_pharmacy_tower.png`; findings in `docs/legal/RISK_AUDIT.md` (Re-audit Nov 15).
- **2026-11-14** **Cast 2x overhaul complete.** Every character sheet in use is redrawn at 2x (Canva, batches 1-21, PRs #58-#92); Duff's gala suit was last. Review stills of every screen and menu: `docs/renders/screens_final_2x.png` (overworld, kitchen, arenas, quests) and `docs/renders/ui_audit_final_2x.png` (every menu + minigame).
- **2026-11-14** **Play stats + play alerts.** `.github/workflows/play_stats.yml` reads itch view/download/purchase
  counts every 3 hours (same `BUTLER_API_KEY`) into the `stats` branch (`stats/history.jsonl`, `latest.json`). Once
  `.github/play_alerts.json` is `"armed": true` (flip it at debut) it opens a closed GitHub issue @mentioning Duff for
  first traffic (10 views since debut), view milestones, 24 h spikes (>= 25 and 2x a normal day) and new purchases.
  Rules + local test: `tools/play_stats.py`. A Monday report reads the stats branch.
- **2026-11-14** **{coworker}'s first bet: a second fight in minute two.** Portal review: after the cold-open pirate the
  game slowed to rules and errands. Now the pirate's KO (or escape) opens {coworker}'s bet card: Marketplace Mike, the
  guy the pirates sell to, is out back of the {fork_nick}. She fronts the stake; win = +$60 and 1-0 on her bet record,
  lose = nothing lost. "Not today" goes straight to the rules. Pitched once (`story.first_bet`); it uses up day one's
  daily bet. New boss `mike` (alley, 70 HP, hustler sprite tinted). Bosses with no HD portrait (mike, grease) no longer
  show an empty portrait frame. 14 test_daily checks; `arena_shot -- cold` now runs through the bet
  (cold_3 card, cold_4 fight, cold_5 payout); render `docs/renders/first_bet.png`.
- **Look At This (Nov 14):** Madison's ADHD. Home talk from day 3, once: Duff starts a story, she cuts in with a reel and a text, phone popup over the dialogue (+3 Happiness). Lines approved by Duff. Render `docs/renders/madison_look_at_this.png`.
- **2026-11-14** **Too Loud (Madison's autism).** Duff approved the lines. First Saturday trip to {grocery} from day 6:
  the store gets loud, she masks ("Totally good."), you dig her headphones out of her bag before the noise meter fills
  (`minigames/noise.gd`; meter full = leave the cart, no fail state), then home for the crash and "Ask me about my day.
  All of it. In order." +5. `scripts/too_loud.gd`, save key `too_loud_seen`, 11 test_daily checks, render
  `docs/renders/madison_too_loud.png` (`arena_shot` `loud` / `loud_bag` / `loud_home`). `main.after_dialog` runs a
  callable when the dialog queue empties (lines, then a game).
- **2026-11-14** **Public build: "the Fork" is now "the Spatula".** 27 strings used a bare "Fork" while the public sign
  says Busted Spatula. New token `{fork_nick}` (family Fork, public Spatula), Club Fork shows as `{club_sandwich}`
  (Club Spatula), and the "Narc of the Fork" achievement migrates on load. test_daily scans every quoted string for a
  bare "Fork". Family edition reads exactly as before.
- **2026-11-14** **Humor audit: repeated jokes cut.** All 2,310 player-facing lines checked for repeats. 63 rewritten
  ("That's the whole X" x7, "The body keeps the receipts" x3, "Hell of a girl" x3, boats now the landlord's alone,
  Earl/Dolores years made consistent, "Respect." x7, barks that copied boss lines). Running gags that escalate stay.
  Madison lines (moods, mornings, her shows) only flagged, not touched. List + flagged pitches:
  `docs/reviews/humor_audit_2026-11-14.md`. Text only, saves unaffected.
- **2026-11-14** **Portal polish (keyboard players).** First 30 s checked at 907x510 in keyboard mode: the cold-open line
  now says how to walk (WASD/arrows) as well as bonk; the level/heat panel moved from mid-screen (where the touch
  buttons sit) to the bottom-right corner when there are no touch buttons; pirate names and enemy Lv tags got ink
  plates (were faint peach text on the sidewalk). Public edition: the sandwich ticket's "Twisted Classic" is now
  "Spatula Classic" (`{house_sandwich}`), and the leak test checks for "Twisted". Renders: `--keys` flag for
  keyboard mode. `docs/renders/portal_polish_keyboard_before_after.jpg`. All menus re-shot at 907x510: fine.
- **2026-11-13** **CrazyGames polish.** The game now fills portal iframes: below 1280x720 (and anywhere integer scaling
  leaves >10% unused) it scales fractionally instead of drawing a 640x360 box in black; 1280x720/1920x1080 stay
  integer. Touch pad no longer pops up on desktop from mouse clicks or touchscreen laptops (CrazyGames rule): web
  shows it up front only on iOS/Android browsers, else on the first real touch. Paste-ready listing
  `docs/portals/LISTING.md`. 6 new test_daily checks. Render `docs/renders/portal_iframe_fit_before_after.jpg`.
- **2026-11-13** **Ad assets.** CrazyGames preview clips (`docs/portals/preview/`: 16:9 1080p 18.3 s, 2:3 1080x1620
  15.2 s, silent, open on the cover, gore off), knockout GIF re-cut to 5.7 s / 630 px, new `boss_intro.gif`, and
  1080p screens (town recapture, Gala landlord ex, sandwich + fryer, fridge calendar day 24, Madison line, street at
  night). New `tools/promo_shot.tscn` drives the takes. Upload order in `docs/itch/PAGE.md`.
- **2026-11-13** **Cold open + street pack.** A new game opens on a porch fight: one line, then a porch pirate
  (Package Pauly) runs at {partner}'s package on the porch and you chase him down; the rules come after
  (`main.gd cold_open()` / `cold_open_rules()`, save flag `story.cold_open`). Web: a 2.9 MB `street.pck` (the
  street, Duff, pirates, home, Duff's portrait) now comes before world.pck, and New Game waits only on it. Throttled
  4G: New Game playable 21.9 s -> 14.3 s; tapping New Game at the title puts you in ~17 s (was ~25 s), with
  someone to hit ~2 s later (was a rules wall and no enemy for 20+ s). The Fork, arenas, gala and minigames wait on
  world.pck behind a loading card (`_world_gate`). `docs/renders/cold_open_before_after.png`;
  `arena_shot -- cold` (with `--fixed-fps 30`).
- **2026-11-13** **The Zebra (Madison's diagnosis story).** Duff approved every line; facts from Madison (hypermobile
  joint syndrome as a kid, Ehlers-Danlos in 2020, Beighton test). Her zebras are in the room for good: a plush on the
  shelf over the bed and a zebra picture in the frame by the shower, both in the room's warm palette. Day 4+, once, at the foot of the bed: 8 lines, +5, happy face throughout.
  `scripts/zebra.gd`, save key `zebra_seen`, 6 test_daily checks, render `docs/renders/madison_zebra.png`.
- **2026-11-13** **Madison's mornings (EDS + migraines).** Duff approved every line. About two hard mornings a week
  she's in bed hurting (hip, or a migraine with the blinds down): bottle for Octavia, two coffees (hers cream and sugar,
  his honey), bring hers for her meds (+8). Skip it and she gets herself up and texts; no penalty. About one good
  morning a week she makes the coffee herself: Sit down (+5) or Take over. `scripts/mornings.gd`, save key `morning`
  (old saves load as no morning), 12 test_daily checks, render `docs/renders/madison_mornings.png`. Next in this arc
  (each pitched to Duff first): her diagnosis story, an autism quest, her ADHD made visible.
- **2026-11-13** **CrazyGames-ready zip.** CI now also ships `duffquest-crazygames.zip` (dev release): no plain
  index.wasm (29 MB total vs the 50 MB no-SDK cap), `window.DQ_PORTAL` makes new players start clean + gore off
  (PEGI 12). Checklist + what's left (covers, preview video, SDK for Full Launch, GameDistribution gameId):
  `docs/portals/SUBMIT.md`.
- **2026-11-13** **Two editions: public vs family.** One codebase. Default export = public (itch, Pages root,
  `duffquest-public.apk`): `data/cast_public.json` renames the Twisted Fork (The Busted Spatula), Wordle (Word Brawl),
  the Hy-Whee slogan, Gucchi (Eau de Fryer), Brittany (Mazikeen, `{coworker}` token) and the real-ex final boss (Rex Tankton, Glasshaus Tower), and `Art.pub()`
  swaps in `*_pub` art (Fork sign, Walgrumps sign in teal block letters, Rex's dark hair + charcoal tank on the walk
  sheet, portraits, intro card and KO stills; made by `tools/make_public_art.py`). Family export (feature tag `family`,
  CI: Pages `/family/` + `duffquest.apk`) keeps everything. `-- --family` shows it in renders. Music credited to Duff.
  test_daily checks both editions. Render: `docs/renders/editions_public_vs_family_2026-11-13.jpg`.
- **2026-11-13** **Legal pass before ads.** Settings > "Credits & legal" (`scripts/minigames/credits.gd`): parody/fiction
  notice, how it was made, privacy, OFL font notices, Godot's MIT license + third-party notices + license texts (from
  `Engine.get_*` at runtime). End credits carry a short notice. `docs/legal/PRIVACY.md` (collects nothing) and
  `docs/legal/RISK_AUDIT.md` (ranked risks: Twisted Fork + Brittany's ranch quest, Wordle name, exes, consent,
  Walgrumps sign, Hy-Vee slogan, music provenance). Renames wait on Duff's yes. UI audit has `credits` shots.
- **2026-11-13** **Label plates + confusion fixes (PRs #48, #49).** New `UiStyle.tag()` (text on a dark ink plate);
  minigames call `tag()`. Overworld labels (house names, CLEARED, NOW HIRING) and every pharmacy label use it.
  Madison's sigh and the cats' food bubbles hide while an interact prompt is up. CLOSED plaques only within 110 px
  of Duff (`CLOSED_NEAR`). Garnish drizzle guide is visible (dashed cream line, ringed dots). Plasma labels the bag,
  stress ball and flow goal. Temp check shows the safe temp from round 2. Station cards explain 86'd / COMP IT /
  GLOVES+SANITIZE; pickles tags DRY/WET hand under each bowl. Renders: `docs/renders/label_plates_before_after.png`,
  `docs/renders/confusion_fixes_before_after.png`. Still open from the audit: pharmacy clone queue, errand drawer
  rebuild, symphony bus backdrop, sandwich toast over the ticket card, beat indicators far from the action
  (backwalk/concert/prep), Show & Tell mosaic unexplained, G button + HUD bars unlabeled (waits on the specials work).
- **2026-11-13** **Searing Spatter cut (Duff: "unnecessary").** No special at Lv 1 now: the S and swap buttons
  stay hidden until Pinwheel unlocks at Lv 2 (the level-up toast says to tap S). Spatula stays at 1.0
  (Duff: combat is too easy). Harder fights: `main.DMG_TAKEN` 1.25 on every hit Duff takes, story exes
  +20% HP (`boss.STORY_HP_MULT`, Willnot's timer 210 -> 250 s to match), night spawn cap +3 (was +2). Saves keep their picked special: `combat.to_dict` stores `selected_id`, and old index-only
  saves are remapped through `LEGACY_ORDER`. test_daily checks the remap. Render: `docs/renders/touch_lv1_no_special.png`.

- **2026-11-13** **Hy-Whee shopping floor redone.** The store is now top-down with the four aisles running
  sideways, painted exactly on the shelf collision rects (`bg_grocery`, built by `tools/grocery_floor_compose.py`
  from the old backdrop's end-cap goods, wall and sign). The repeated icon strips are gone: each list item is one
  big painted item on its shelf with a yellow shelf tag (price), a bobbing arrow while it's needed, a tick once
  it's in the cart. Shelves y-sort with Duff and Karen. People are drawn at 0.75 (was 0.5) with an ink outline.
  Karen's hit is a speech bubble over her head (no more banner across the aisles); "Got it" and "CLANG!" float as
  small text. The title bar hides in the shop so the painted HY-WHEE sign shows, with Budget/Cart chips either
  side. The list is two rows of picture chips with ticks/crosses instead of ASCII `[x]`. Checkout, bagging and
  receipt untouched. Render: `docs/renders/hywhee_floor_before_after.png`.
- **2026-11-13** **Raccoons + Jen repainted.** The raccoon (read as a flat grey cat) is a warm-brown raccoon with a
  black mask and ringed tail, same 192x64 sheet (4 frames x 48x32, origin unchanged), 1 px dark outline so it reads
  on grass. Row 0 now faces right as `raccoon.gd` expects (the old sheet had it walking backwards). Jen's walk sheet
  (`ch_jen`) and phone avatar (`av_jen`) repainted in the Sea of Stars cast style. New `tools/import_critter_strip.py`
  (Canva strip -> small 2-row critter sheet); `tools/import_big_sheet.py --tol` for grey art on a purple key. Masters:
  Drive "97 Gemini art drops" `raccoon_v1.png`, `ch_jen_v1.png`. Render `docs/renders/raccoon_jen_before_after.png`.
- **2026-11-13** **Fix: web build had no sprites.** itch serves the packs gzip-encoded; the browser unzips them and
  Godot's HTTPRequest tried to unzip again, so world.pck failed 3 times and the game started with no art.
  `accept_gzip = false`, world.pck now retries forever behind the loading card instead of giving up, and
  `tools/web_boot_test.py` serves the packs gzip-encoded so this is caught next time.
- **2026-11-13** **Web boot under 10 s.** Title screen on throttled 4G: 19.9 s -> 9.3 s. The first download is now a
  1.8 MB core pack plus a trimmed 2D-only engine (7.2 MB gzipped, was 9.3). Characters, portraits, music, storefronts
  and props moved to `world.pck`, fetched right after boot; Continue/New Game show a "Loading Omaha..." card until
  it lands. Custom web template built in CI (`web_template.yml`). Render `docs/renders/web_boot_2026-11-13.png`.
- **2026-11-12** **Character style pass.** The 20 NPC/enemy walk sheets still on the v1 chibi template (same body,
  hair and shirt swapped) are repainted as distinct Sea of Stars-style characters matching `ch_brittany`: health
  inspector, Pete, Karen + buddy, HOA, butler, drunk, heckler, kid, hustler, scammer, cashier, chef, pharmacist, sushi
  chef, phlebotomist, sitter, usher, waitress and Madison's gala dress. The Grease Trap boss gets its own sprite
  (`ch_grease`) instead of a tinted Grill-Boy. Phone avatars rebuilt from the new sheets. New
  `tools/prep_canva_sheet.py` (grid-line removal, mirrored left row). Renders
  `docs/renders/char_pass_before_after_2026-11-12.png`, `docs/renders/grease_boss_sprite_2026-11-12.png`.
- **2026-11-12** **Fences + the last 5 flat screens painted.** Fences: red brick, privacy wood, chain link and white
  picket repainted at 4x density. Each segment is cut from one master as left post + panel + right post, 39 units post
  to post, so runs tile with no seam and need no end piece (`tools/import_fence_hd.py`; `sd_*_end` removed).
  Screens, from one 16-prop sheet (`k7_sheet`, `kf_*`): phone home app icons (Messages, Stonks, Fund, Gear, Settings,
  Notes); Wordle grid and keyboard on wooden letter tiles tinted by result; grocery shelf goods, list items,
  self-check and coupon kiosks, Karen + buddy + Duff as their sprites, a painted cart; symphony mirror, the #18 bus,
  painted notes and snack icons; show & tell pillows and a cel-shaded patchwork quilt. Every painted piece falls back
  to the old shape if its art is missing. Renders `docs/renders/flat_screens_fences_2026-11-12.png`,
  `docs/renders/ui_audit_2026-11-12_flat_screens.png`.
- **2026-11-12** **Overworld repaint (street props):** the 17 trees and street clutter (oak, maple, pine, ash,
  lilac, hedge, hydrant, mailbox, newspaper box, bench, cone, bike rack, recycling bin, shopping cart, leaves, Huskers
  flag, little free library) repainted as detailed pixel art and imported at 4x density with the same world footprint
  and ground point, so placements, walls and depth sorting are unchanged. `tools/import_dressing_hd.py`;
  `Dressing.art_rect()` now honours density + origin (it assumed s:2). Fences are still the Nov 8 art. Masters in
  Drive "97 Gemini art drops" as `sd_<name>_v1.png`. Renders `docs/renders/props_repaint_before_after.png`,
  `docs/renders/street_dressing_depth.png`.
- **2026-11-12** **Overworld repaint (storefronts):** all 13 exteriors (home, neighbor, Kwik-N-Go, Twisted Fork,
  HOA HQ, Seen Cafe, Iron Temple, Club Cloud 9, Mining Rig, the tower, Walgrumps, Hy-Whee, Plazmart) repainted as
  detailed pixel art and imported at 4x density (one texel per screen pixel), filling their lots instead of half of
  them. Footprints, bottom edges and door x are unchanged, so doors, story triggers and errands still line up.
  `tools/import_storefront_hd.py SRC NAME [--up N]` (keys magenta, area-downscales, writes the manifest; `--up` lets a
  roof rise above the lot, negative shrinks it). `_art_rect()` now honours density + origin. Kwik `SHOP_PT` moved to
  the new centred doors, raccoon spot moved out of the wider Plazmart. Masters (1920 px) live in Drive "97 Gemini art drops" as `sf_<name>_v1.png`; pull them into `grok_art/2026-11-12-storefronts/_work/` (ignored) to re-import.
  Renders `docs/renders/overworld_storefronts_before_after.png`, `..._night.png`.
- **2026-11-12** Side quest 4 live, all four now on: **Lost & Found, Omaha** (`ready: true`, from day 3). A flyer
  from Gail comes with the mail (home mail table, before the bills). Three riddles, any order: a ring in the storm
  drain at the crossroads, Mr. Buttons' collar in the recycling bin by the Kwik-N-Go, a left shoe in the pine tree by
  the bus stop. No '?' while hunting; each unfound thing glints now and then. Return to the green paper box outside
  the Seen Cafe ('?' marker): +$50, +6 happy, "Omaha's Finest". `main.gd` `_alley_talk()` / `alley_payoff()`,
  `LOST_SPOTS` / `LOSTBOX_PT`. Tested end to end. `arena_shot lost`; render `docs/renders/quest_lost_found.png`.
- **2026-11-12** Side quest 3 live: **Brittany's Side Gig** (`ready: true`, from day 5, daytime). She's selling the
  Fork's ranch on Marketplace in hand-lettered mason jars and Chef blames Manny the dishwasher. Pick on a card: cover
  for her (next day +$60, +5 happy, "Ranch Cartel") or tell Chef (next day +$40, no bet that day, "Narc of the
  Fork"). The pick is the quest's saved `choice`. `main.gd` `_gig_talk()` / `gig_choose()` / `gig_payoff()`. Both
  branches tested end to end. `arena_shot gig`; render `docs/renders/quest_brittany_gig.png`.
- **2026-11-12** Side quest 2 live: **The Grease Trap** (`ready: true`, from day 4). An unsigned entry appears on
  the 86 List; after 10 PM the board sends Duff out back, where the floor drain stands up (new boss `grease` in
  `boss.gd`: 180 HP, posting + charge, Grill-Boy sprite tinted amber with an oil slick and drips until it gets its own
  art). Win: +$90, 3 scrap, achievement "Fryer Exorcist". Lose: try another night; it never uses up the day's 86 List
  bounty. `main.gd` `_grease_talk()` / `start_grease_fight()` / `grease_defeated()`. End-to-end check in test_daily.
  `arena_shot` ids `grease86` / `bounty:grease`; render `docs/renders/quest_grease_trap.png`.
- **2026-11-12** Side quest 1 live: **porch mystery** (`ready: true`, offered from day 2). Madison asks Duff to find
  who keeps taking the packages; Brittany saw orange fingers; the porch yields a gas-station receipt; knocking on the
  neighbor's door (daytime only) flushes out Cheeto Chad, a 6 HP pirate who bolts. Catch him: +$60, +12 happy,
  achievement "Neighborhood Watch". Let him over the fence and the quest waits for the next knock. Triggers live in
  `main.gd` `quest_talk()` / `quest_interactables()` / `porch_quest_won()`. End-to-end check in test_daily.
  `arena_shot` ids `porch` / `chad`; render `docs/renders/quest_porch_mystery.png`. Other 3 quests still `ready: false`.
- **2026-11-12** HD-2D polish pass: painted street gets a 1-px unsharp after the fit (`tools/import_street.py`).
  Lighting follows the clock like style board 2: `hd_presentation.gd` grades the world warm morning -> gold dusk ->
  blue night (replaces the flat night overlay), warm light pools fade in at shop doors after sunset, contact
  shadows swing and stretch with the sun, and street props now cast them (`dressing.gd`). Dialogue box hugs its
  text (bottom-anchored, 40 px portrait). `grok_art/**/_work/` + `*_tmp*` are git-ignored; drop rules in
  `grok_art/README.md`. Renders: `docs/renders/lighting_day_dusk_night.png`, `dialog_box_before_after.png`,
  `ground_crisp_before_after.png`. `arena_shot at:X,Y,MIN` sets the clock.
- **2026-11-12** Side-quest backbone (HD-2D plan step 1-2): `scripts/side_quests.gd` holds one save-safe state for
  hand-made side quests (stages, clues, branch choice, NEW flag); save v8 migrate adds an empty `side_quests`, and
  `clean()` drops unknown ids / junk so no save can break the loader. Phone gets a **Notes** app (the journal). Gold
  `!` / teal `?` badges float over quest givers and over whoever the current stage needs. Dialogue now types out
  (70 chars/s, pre-wrapped so words never jump); the first tap finishes the line, the second moves on. Debug builds
  get Settings > "Dev: quests" (jump any quest to any stage or branch; Duff warps to the right NPC), and web builds
  take `#dq=quest:<id>:<stage>`. The 4 quests (porch mystery, Grease Trap bounty, Brittany's side gig, lost & found)
  are defined but `ready: false`, so players see nothing until their content lands. 32 new checks in test_daily.
  `docs/renders/side_quests_backbone.png`.
- **2026-11-11** Last teal slabs painted (IGN v3 audit): props sheet K6 (16 props). Kwik-N-Go is a shelf of picture
  tiles (honey bun, formula can, diapers, cherries...); the temp check grills a real raw cut per protein (chicken,
  turkey, beef, pork chop, ribeye, salmon; wings reuse the Fork wings, paled while raw) that browns as the core climbs;
  baby FEED/CHANGE carry the formula and diaper props. `docs/renders/shop_baby_temp_after.png`. IGN review v3: 7.9/10
  (`docs/reviews/ign_review_2026-11-11_v3.md`). Soak PASS.
- **2026-11-11** Street ground repainted: the flat tile crossroads is now one detailed pixel painting (lane lines,
  cracks, manhole, slab sidewalks, flowers and leaves in the grass) matched to the home interior's style, its roads
  fitted onto the gameplay roads by `tools/import_street.py`. Soak PASS.
- **2026-11-11** Boss taunts: the "I'm not X. I'm Y." reframe was 9 of 68 lines; 12 rewritten (Husk films the
  beatdown "in vertical, for the investors", the Regular has been sitting there "since Truman", the crypto bro's wallet
  password was his ex's birthday). New test caps the formula at 2 and bans shared openers. Last slab screens: Gear
  rows get item icons (16-prop sheet K5), the hustler fight is a door slamming shut, breading has dry/wet hands.
- **2026-11-11 (early)** Fork kitchen painted (Duff: "minigames still behind on style"): 47 house-style C props from
  three Canva 4x4 sheets + a Black Forest cake, cut by `tools/import_kitchen_props.py` (magenta key, rim-only despill
  so purple onions survive, wire-mesh cleanup). Fryer = two real fryers with baskets that brown; sandwich builds real
  layers on a plate; salad fills a real bowl; dessert is a real cake with piped cream and cherries; breading bowls,
  cutting board + tomato that dices down, hotel pans, spray/rag. Every ingredient button is a picture tile. Soak PASS.
- **2026-11-10 (late night)** "Heard." moved into the kitchens only (Duff): stripped from the intro ("That's the whole
  religion. Amen."), the raccoon gag, the gala, a combat toast, the grocery coupon win and the mirror line; the
  Heard-Chef Holler skill is now the Line-Cook Holler ("BEHIND!!"). Added where it belongs: the Fork's between-station
  button reads "Heard.", the 86 warning, and Duff answers about one in three of Dolores's Waffle Haus calls.
  `test_daily` fails if "Heard." / "HEARD!" shows up outside waffle.gd, shift.gd or the sandwich station.
- **2026-11-10 (late night)** 4G first boot 55.5 s -> 17.0 s (IGN v2 "~60 s on 4G"), measured in headless Chrome on
  a throttled 9 Mbit/s link against the real web build. First download 61 MB -> 17.6 MB: the game pack drops to
  8.3 MB (KO stills, boss intro cards, 12 loading screens, 9 scene backdrops stream in after boot as extra.pck,
  landing ~30 s in, during the title/intro) and the engine ships pre-gzipped (9.3 MB) with an in-browser unzip that
  falls back to the plain file on old browsers. HD portrait/arena art re-encoded at lossy 0.8.
- **2026-11-10 (late night)** Bounty signature moves (IGN v2 "six bounties, three original movesets"): Coupon Carol's
  coupon storm (expired coupons flutter down onto growing shadows, three on Duff), the Camper's charger-cord lasso
  (yanks Duff toward him, tangles him half a second; a roll slips it), the Allergy Liar's "IS THERE GLUTEN IN THIS?!"
  shout ring (stuns unless rolled). New `test_daily` checks for all three. Soak fixed: the bot now taps the phone
  control cards away (it had been stuck on them since the onboarding milestone); 30-day soak PASS, all three new
  fights played. `docs/renders/bounty_signature_moves.png`.
- **2026-11-10 (late night)** Arena sprite scale (IGN v2 "32-pixel Duff on a 1280-wide painting"): on painted
  fight floors Duff draws at 1.45x like the bosses, regular enemies at 1.3x, scaled around the feet; Waffle Haus
  shift stays 1x so Dolores matches. Hitboxes unchanged. Render tool got `gala:<boss>` ids and stops teleporting Duff
  off the gala floor. `docs/renders/arena_scale_before_after.png`.
- **2026-11-10 (late night)** UI style pass 2: stealth floor is one night-lit plank floor (warped creaky boards with
  ink cracks, crib, bed, pulsing step tiles for touch) over the nursery painting; Blackhead Patrol is Duff's back
  with both tattoo sleeves and the fox at his nape; Back Walk is Duff face-down on the bed with the real Madison
  sprite walking him; quiz and inspector answers are cream index cards with coloured key badges
  (`UiStyle.card_button`); temp check got a glowing grill and sear marks. Quiz question that only made sense after
  another one now stands alone. UI audit's temp-check shot was catching the shift menu (wrong key), fixed.
  `docs/renders/ui_pass2_before_after.png`, full sheet `ui_audit_pass2.png`.
- **2026-11-10 (night)** UI style pass 1 (Duff: menus + minigames should match the art): every play object in
  15 minigames drawn as a style-lock prop (ink outline, hard shadow, one cel band); art-less screens (gear, Wordle,
  settings, mash, stealth) get the cards' sunburst; phone home has a navy/teal wallpaper; store/pharmacy item grids
  moved right so the paintings show. `docs/renders/ui_audit_before.png` vs `ui_audit_after.png`.
- **2026-11-10 (night)** Phone onboarding: three tap-through control cards (walk / A / B) on a phone's first new
  game, once per install (`user://touch_tut.cfg`), replay from How to play > Show me the buttons; G/S/swap/D touch
  buttons now as big as A; no keyboard chips or "E /" prompts on touch. `docs/renders/touch_onboarding.png`.
- **2026-11-10 (night)** Canva drop live: cat_sacrifice loading screen (14/14 now), painted backdrops for
  Kwik-N-Go, Hy-Whee, Walgrumps, plasma, Holland Center, Akarui, bedroom, nursery, ending living room, and the gala
  floor. Art pipeline is now hands-off (Canva -> Zapier -> Drive -> repo, see CLAUDE.md). `docs/renders/backdrops_nov10.png`.
- **2026-11-10 (late)** Balance softened (Duff): story happiness gates 50/60/65/70/75 -> 45/50/55/60/65;
  the drain while Madison waits on a want went 0.2/s -> 0.08/s (0.04/s in week one) and never drags her below 40.
- **2026-11-10 (late)** IGN fixes: nightly routine gets a BEDTIME card after night one (play, or skip on
  autopilot: +8 Happiness, uses a bottle + diaper, no fail risk; missing supplies still cost). The dead
  "Octavia's fund $0 / 100k" drawer line + bar are gone; the line shows only once there's money in the fund.
- **2026-11-10 (late)** Interact prompt ("E / A: Talk to Madison") readable on any floor: dark pill, gold
  edge, cream text (was pale green on the teal rug). NPC/cat barks now dodge the pill instead of overlapping it
  (`barks.gd hint_rects`). Render id `hint` added (`docs/renders/hint_prompt_pill.png`).
- **2026-11-10 (night)** The six themed boss arenas are real painted art (alley, Seen Cafe, Club Cloud 9, crypto
  garage, tower office, Waffle Haus) at 1280x720 (`tools/arena_import/`), walls fitted to each painting, Waffle Haus
  grills and order rail moved onto the art (`docs/renders/arenas_painted_ingame.png`). CLAUDE.md rewritten as a lean
  handoff; the old log is `docs/handoffs/SESSION_LOG.md`. GitLab dropped for now: GitHub main is the only home.
- **2026-11-10 (evening)** Title screen shows the real Duff: both tattoo sleeves and the fox on his neck, from his
  style-C portrait, in a comic panel over the in-game kitchen (`tools/title_compose.py`,
  `docs/renders/title_tattoos_before_after.png`). GitHub is the main repo again: `build.yml` passed and pushed the
  web build to itch (`BUTLER_API_KEY` works there). GitLab is a backup mirrored by `.github/workflows/mirror_gitlab.yml`.
- **2026-11-10** IGN review fixes: phone-first touch wording and bigger outlined buttons; first Monday's rent
  prorated to half and the Fork open the first weekend; six boss arenas painted in code (alley, Seen Cafe,
  Club Cloud 9, crypto garage, tower office, Waffle Haus); the gala invite arrives the morning after the ending,
  not on day 24. Itch builds deploy from GitLab CI (`BUTLER_API_KEY` set). Tests 112/112, 30-day soak clean.
- **2026-11-10** Gala exes' world sprites (Tyler Pivot, Grant Gratuity, Landlord Lance, Chip Leverage); Mr. Crypto
  walks the right way. IGN-style review: 6.4/10 (`docs/reviews/ign_review_2026-11-10.md`).
- **2026-11-09** Money paths tested (bus pass, minivan, stocks, college fund, symphony date); CI deploy job.
- **2026-11-09** QA fixes: real weekly bill in the intro, knockout x-ray crops per boss.
- **2026-11-09** Build shrink (113 -> 54 MB), knockout gore, HUD declutter, all 17 knockouts live, gala bosses
  became Madison's exes, itch page kit.
- **2026-11-09** Parody bosses with intro cards and knockouts; Falcor's story and Thanksgiving; fridge calendar,
  14 daily events, weekends off; shuffled shifts with autopilot.
- **2026-11-08** Bar-story narration voice and fun facts; restyled menus; Duff's outfits v2; all 17 bosses with
  unique attacks and HD portraits; combat feel (hit-stop, shake, sparks, damage numbers); town dressing.

## Next

1. ~~Itch page CI build switch~~ done by Duff Nov 10. Still to paste: `docs/itch/PAGE.md` + images (Duff).
   dashboard), then paste `docs/itch/PAGE.md` and the images.
2. **Cat loading screen:** Alastor, Lucifer and Freya.
3. **M7 backgrounds** still waiting on real art: the remaining scene backdrops in
   `grok_art/requests/REQUEST_M7_backdrops.md`.
4. **Brittany playtest** of the gentler first week on her iPhone.
5. Balance softened Nov 10; re-check with Brittany's playtest.

## Could improve

From the IGN v2 review (`docs/reviews/ign_review_2026-11-10_v2.md`) and QA, still open (Nov 11):

- **Overworld is still all pixel tiles** (outside street + home): every walk into a painted fight/minigame is a style
  jump. Duff wants the FULL repaint (painted neighborhood, house, Fork/Waffle Haus exteriors, collision refit).
- Nobody has played the gentler week one on a real phone yet (Brittany).
