# Wash, Rinse, Regret branding

Owner approved the gold tattoo-lettered logo and cream order-ticket art on 2026-11-27. Source: `approved-brand-art.png` SHA-256 `96f06ca19dd9c72c9af2ecac7d9ff4f9bf774dea65a41f7bb268df1a161c9152`. The game assets are exact cropped and resampled versions of the approved artwork, keeping the intentional cream backing. Main and HD title screens use `assets/art/wrr_logo.png`; the porch chapter uses `art/wrr_chapter_ticket.png`. Existing studio logo, game HUD, controls, and title paths are unchanged.

The previous itch cover is retained as historical art; do not upload it under the new name. No live listing changes are authorized by this branding branch.

## Verification (Godot 4.7.2)

- Root test gate: 609 PASS, ALL PASS (0 failed), TESTS PASS. Porch smoke: 159 PASS, no FAIL or SCRIPT ERROR; existing shutdown resource warnings.
- [Root title capture](../renders/wash-rinse-regret/root-title.png) (640×360 logical canvas at requested 844×390 window): existing Continue button reads a synthetic Day 7, $123 save placed under the pre-rename path. The logo plate leaves the portrait and buttons visible.
- [Porch title capture](../renders/wash-rinse-regret/porch-title.png) (844×390 actual render): existing chapter title, scroll-free buttons and untouched controls. HD title also rendered successfully at 640×360 logical canvas.
- Linux `user://` was probed under the old and new project configurations: both resolve to the same legacy `godot/app_userdata` directory, and the renamed project reads the original sentinel. The root real SaveGame reader also found the seeded legacy fixture. APK package IDs, signing files, build filenames, save keys and web/itch URLs are unchanged. Physical Android upgrade and iPhone PWA upgrade remain unverified; this is not release authorization.
- #228 remains open; the local software-rendered titles are visual checks, not a 60 FPS device acceptance test. The isolated kitchen/neighborhood branches are not integrated.
