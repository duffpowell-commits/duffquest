# Nov 17 handoff: Duffphone UI shipped, next = four visual upgrades

## Shipped this session (all merged, CI green)
- #129 HUD = Duff's phone (status bar, notification shade, banners). `hud.gd`.
- #130 Loading screens as wallpapers (phone home one a day, blurred behind frameless menus). `scripts/wallpaper.gd`.
- #131 One UI language: glass menu sheets (`card.gd`), Settings app, gear grid, hustler + quiz polish.
  Helpers: `UiStyle.pill_button`, `UiStyle.glass`, `minigame.pill_buttons`, button flag `"hide": true`.
- Renders: `docs/renders/hud_phone_before_after.png`, `wallpapers_phone_menu.png`, `ui_phone_sheets_before_after.png`.

## Next: Duff picked all four (Nov 17), in this order
Not yet phone-tested by Duff. Re-shoot store screens (`docs/itch/screens/`) after these land.

1. **Living town** (new `scripts/town_life.gd`, a Node2D child of the overworld; 3D needs each item as a card
   like other actors, see `view3d._sign()` / actor cards).
   - Cars along the street lanes using the existing `truck_h` / `truck_v` art (loop off-screen, no collision).
   - 3-6 ambient walkers on sidewalks reusing street `ch_*` sheets (no talk, no fights; avoid Duff's path).
   - Birds that scatter when Duff runs near; steam puffs from the Fork + Waffle Haus vents.
   - Weather by in-game month: fall leaves drifting, winter snow (Omaha), occasional rain at night.
   - Perf: cap counts; `perf_guard.low` halves them. Off in headless/soak.
2. **UI motion**: card sheets slide up (ease-out ~0.18 s; offset drawing AND button rects together, or draw with
   a transform and block input until settled), pill buttons squish on press, HUD cash pill counts up/down,
   a quick iris/wipe on `enter_home()` and other door transitions.
3. **Diorama 3D look** (`view3d.gd _build_env`): glow already on; add tilt-shift via CameraAttributesPractical
   `dof_blur_far/near` (top/bottom of frame), let `lamps` (OmniLight3D) actually pool light on the ground at night.
   Lite mode (`perf_guard`) must turn DOF off. Needs Duff's phone test before merge.
4. **Fight impact**: `juice.gd` already has hit-stop + shake. Add squash/stretch on hit/land (actor scale tween),
   swing smear arcs (`combat_fx.gd`), dust puffs on roll start/end. Same in 3D (render-only).

Check `docs/reviews/ign_review_2026-11-11_v3.md` (the eval) before starting.
