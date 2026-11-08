DuffQuest: Duff outfit batch

11 PNG sheets, each256x256 with4x4 64px cells. Rows down/up/right/left; columns stand/stepA/stepB/frying-pan attack. Key#00FF00, same as the approved reference.

These are hand-edited clothing pixels on the approved reference, not independent image generations. All176 per-frame silhouettes and all heads are pixel-identical to the base; all protected neck/hand/weapon pixels are unchanged. New fabric/footwear ramps are confined to explicit clothing masks. duff_home.png is a byte-for-byte base copy.

Coordinates: declared origin32,60. Reference actual opaque height52, y6..57; source PNGs preserve that alignment exactly. No3px importer shift applied here. Claude should use the same import alignment as the approved base, not introduce a new outfit-specific offset.

Walk previews: one GIF per outfit, all four facings simultaneously, frame order1,0,2,0 at140ms/frame. GIF256-colour palette is preview-only; PNGs are RGB masters.

Costume choices where Sheet leaves details unspecified: canvas apron with rear crossed straps/ties, black tee underneath; short-sleeve cream double-breasted chef coat; olive utility dad shirt; steel-teal open workshirt with rolled cuffs; clog gear differs only in footwear/toe vents. Black/red suffix changes only shoe pixels. Compact coat and clog details retain the exact approved silhouette.

Not generated: duff_dress (6x3 changing poses), duff_roll_black/red (4x1 dodge animations), duff_shades (overlay), ch_duff_suit (separate prefix). Their statuses were not changed.

Mechanics context freshly read via GitHub read-only: CLAUDE.md, scripts/player.gd. No root README.md exists. Duff is the only playable character. ARMORS lists apron/clogs/sleeves/coat/dad, with red/black shoes:10 equipped variants plus home override (the handoff's count12 appears stale). WALK=[1,0,2,0], attack column3 (zero-based). Player has a buffered3-hit combo and invulnerable dodge roll. No gameplay or engine playtest was performed.

No repository changes. Full verification: duff_outfits_checks.json.
