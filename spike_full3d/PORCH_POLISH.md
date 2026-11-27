# Fork Around and Find Out: porch polish pass

Approved direction: Nov 26, 2026. Finish the first 3D encounter before expanding into the kitchen. Current work stays in spike_full3d; do not change the live 2D edition. Read HANDOFF.md and BUILDING.md.

## Baseline
The last blind review scored 5/10 on pass 1. Pass 1b, the skillet, and the rename are merged, but the score has not been re-established. Do not treat the 2D game's historical 8.9 as evidence for the remake. Reviews are paused; use human phone feedback first.

## Playtest checklist (exact current APK or web build)
- New player completes tutorial actions without external instruction; can tell when a hit, dodge, guard, or special worked.
- Three encounters progress without unreasonable spikes. Retry begins at the right checkpoint; no out-of-bounds state. Clear hit feedback and comic payoff.
- Camera and speech never cover combat or thumb controls. Test portrait web orientation, landscape APK, interruption/resume, back and touch cancellation.
- Target 60 FPS on the actual phone, including under effects. Record build, FPS, Lite mode, failures and screenshots. Don't expand until phone performance is measured.
- Existing approved character model and reference master art remain canonical. Compare rendered hands, tattoo placement and attached piercings against approved references; no private photos in the public repo. Report discrepancies before editing.
- Walk home verifies zone transition, player control and consistent visual identity.

## Next pass
Fix the top observed issues in one focused PR; no new moves, models, paid assets or larger zones before evidence. Use existing code and art, visual polish and input fixes where needed. Run 3D smoke and root tools/test.sh; capture actual engine renders; comply with required review and CI gates. No new blind score while paused. Keep the live 2D itch listing intact.

Only after the porch slice satisfies its agreed quality gate: plan the short Waffle Haus shift, reuse existing four kitchen models, verify credit budget before paid work, seek approval for new art and moves, and preserve original dark comedy. Do not copy personal/family content into this public document.
