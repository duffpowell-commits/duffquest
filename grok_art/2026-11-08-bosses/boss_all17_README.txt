DUFFQUEST — ALL 17 BOSSES / ART HANDOFF

All deliverables are under /workspace/duffquest/art/.
No repository files were modified. 1660 tracked/supplied local files hash-identical to the before snapshot.
39 remaining-boss Sheet rows were marked generated and read back successfully.

FORMATS
ch_<boss>.png — 256x256 RGB PNG, 4 rows x 4 cols, 64px cells.
Rows: down, up, right, left. Columns: stand/passing, contact A, contact B, committed attack.
Origin 32,60. Stand/attack top8, feet last pixel59 (52px); contact head/body top9, last foot pixel59 (51px) for the requested 1px down bob. This intentionally supersedes absolutely identical frame height.
Right/left legs: independently drawn front/rear contacts with counter-swinging arm, left mirrored. Four-frame GIF cycle stand/A/stand/B.
All17 attacks revised: torso shear/weight shift, opposed feet, extended strike/cast with signature prop; Dasher instead has a bent-arm forward charge. One action KEY POSE, not a full windup/recovery sequence.
Inside-silhouette rim/highlight keeps dark outfits readable on #5A5A5A. The ch_<boss>_asphalt_test.png strips show ALL16 frames at3x on that asphalt value.

new_portrait_<boss>.png — 1536x512, 3x1 of512px, smug/shocked/enraged, exact #00FF00, minimum16px margins.
new_boss_intro_<boss>.png — 1920x1080 keyed primary, exact hand-typeset Sheet name, minimum48px margins.
new_boss_intro_<boss>_burst_preview.png — 1920x1080 approved flat-colour burst alternative; not a keyed game sheet.
ch_<boss>_walk.gif — four directional walks side by side, 768x224, 4frames. Asphalt background only for preview.

Sprites and keyed intros: green if pink/magenta exists, otherwise magenta; per-boss keys in checks JSON. Flat borders/cell gutters, opaque RGB PNG (Claude keys to transparency). No text on sprites/portraits. Only exact title on intros.
All humans are original inventions. Boss names are parody labels, not real-person likenesses. Visual comparison against old enemy lineup performed.

VALIDATION
boss_batch2_checks.json: format/border/margins/bob/baseline/pixel differences/mirrors/backups/repo hash tests + explicitly labelled manual reviews.
boss_all17_file_manifest.json: complete102-file inventory, dimensions, absolute paths and SHA256.
boss_batch2_sheet_statuses.json:39 exact IDs/rows/read-back status.
boss_all17_quality_notes.json: per-boss honest limitations.

Important: hashes and differing pixels do not establish good acting; complete sprite pages, asphalt pages and lineups were visually reviewed too. Native attacks/legs are hand-rigged with simpler clusters than generated heads/clothes. Most attacks share a compact extension rig, though faces, bodies, palette and props differ. Front/back strides are compact; side contacts are deliberately much clearer. Motion arcs are sparse hard pixels, not blur.
No Godot runtime validation: Claude still needs to check 1.45x game rendering, timing, collision/hitboxes and projectile attachment offsets. No code/hitbox changes included. Do not pretend the single attack cell is a complete attack animation.

FIRST4 REVISION
Husk, Bozos, Fences and Baron sprite PNGs and GIFs were corrected per reviewer steering. Their previously approved portraits and both intros are byte-for-byte unchanged. Old animations preserved locally as ch_<name>_batch1_v1.png and ch_<name>_walk_batch1_v1.gif, excluded from production ZIP.

PREVIEWS
boss_batch2_lineup.png — first7 new bosses.
boss_batch2_lineup_2.png — last6 new bosses.
boss_batch1_lineup.png — first4 with corrected sprites; approved portraits/intros unchanged.
boss_all17_sprite_lineup.png — all17 front stands on asphalt.
boss_all17_sprite_checks_1..3.png — all17 full4x4 sheets enlarged.
boss_all17_asphalt_checks_1..3.png — all17 D/R pass/A/B/attack on asphalt.

FILE LIST AND INDIVIDUAL NOTES

HUSK — Phone/rocket-cue gesture reads at sprite scale; phone is only a few pixels. Corrected contacts, bob, strike and dark-jacket rim.
  ch_husk.png [256, 256]
  new_portrait_husk.png [1536, 512]
  new_boss_intro_husk.png [1920, 1080]
  new_boss_intro_husk_burst_preview.png [1920, 1080]
  ch_husk_walk.gif [768, 224]
  ch_husk_asphalt_test.png [3072, 220]

BOZOS — Round silhouette and moustache remain distinct; strike stretches the otherwise round body. Corrected contacts, bob and violet-outfit rim.
  ch_bozos.png [256, 256]
  new_portrait_bozos.png [1536, 512]
  new_boss_intro_bozos.png [1920, 1080]
  new_boss_intro_bozos_burst_preview.png [1920, 1080]
  ch_bozos_walk.gif [768, 224]
  ch_bozos_asphalt_test.png [3072, 220]

FENCES — Blue glasses/ochre sweater read well; tablet is small at native scale. Corrected contacts, bob, strike and rim.
  ch_fences.png [256, 256]
  new_portrait_fences.png [1536, 512]
  new_boss_intro_fences.png [1920, 1080]
  new_boss_intro_fences_burst_preview.png [1920, 1080]
  ch_fences_walk.gif [768, 224]
  ch_fences_asphalt_test.png [3072, 220]

BARON — White wing-hair and mulberry coat stand out; long coat partially masks the front/back stride. Side contacts separated and bob/strike/rim fixed.
  ch_baron.png [256, 256]
  new_portrait_baron.png [1536, 512]
  new_boss_intro_baron.png [1920, 1080]
  new_boss_intro_baron_burst_preview.png [1920, 1080]
  ch_baron_walk.gif [768, 224]
  ch_baron_asphalt_test.png [3072, 220]

DONALD — Ivory suit and dark rhomboid face differ from all other bosses; native face is darker and less detailed than the large portrait.
  ch_donald.png [256, 256]
  new_portrait_donald.png [1536, 512]
  new_boss_intro_donald.png [1920, 1080]
  new_boss_intro_donald_burst_preview.png [1920, 1080]
  ch_donald_walk.gif [768, 224]
  ch_donald_asphalt_test.png [3072, 220]

GHOSTER — Fringe/seafoam jacket/phone clear; skin reads warmer than the original ash-pale concept at sprite scale.
  ch_ghoster.png [256, 256]
  new_portrait_ghoster.png [1536, 512]
  new_boss_intro_ghoster.png [1920, 1080]
  new_boss_intro_ghoster_burst_preview.png [1920, 1080]
  ch_ghoster_walk.gif [768, 224]
  ch_ghoster_asphalt_test.png [3072, 220]

GYMBRO — Broadest muscular silhouette, lime tank/fuchsia band. Still 52px high to fit the cells, and the head is smaller relative to the shoulders than Duff.
  ch_gymbro.png [256, 256]
  new_portrait_gymbro.png [1536, 512]
  new_boss_intro_gymbro.png [1920, 1080]
  new_boss_intro_gymbro_burst_preview.png [1920, 1080]
  ch_gymbro_walk.gif [768, 224]
  ch_gymbro_asphalt_test.png [3072, 220]

DJVAPE — Only violet double-bun/coral-headphone silhouette; compact sprite outfit is simplified compared with the larger portrait.
  ch_djvape.png [256, 256]
  new_portrait_djvape.png [1536, 512]
  new_boss_intro_djvape.png [1920, 1080]
  new_boss_intro_djvape_burst_preview.png [1920, 1080]
  ch_djvape_walk.gif [768, 224]
  ch_djvape_asphalt_test.png [3072, 220]

CRYPTO — Orange buzz/cobalt-yellow tracksuit read distinctly; tablet and rug shorthand become tiny pixel symbols.
  ch_crypto.png [256, 256]
  new_portrait_crypto.png [1536, 512]
  new_boss_intro_crypto.png [1920, 1080]
  new_boss_intro_crypto_burst_preview.png [1920, 1080]
  ch_crypto_walk.gif [768, 224]
  ch_crypto_asphalt_test.png [3072, 220]

WILLNOT — Original olive face, widow peak and barefoot action hero; gun is miniature, and toes only resolve enlarged. No actor likeness.
  ch_willnot.png [256, 256]
  new_portrait_willnot.png [1536, 512]
  new_boss_intro_willnot.png [1920, 1080]
  new_boss_intro_willnot_burst_preview.png [1920, 1080]
  ch_willnot_walk.gif [768, 224]
  ch_willnot_asphalt_test.png [3072, 220]

REGULAR — Heavy rust-plaid silhouette/mug/grey moustache readable; front/back strides are compact under the stocky body.
  ch_regular.png [256, 256]
  new_portrait_regular.png [1536, 512]
  new_boss_intro_regular.png [1920, 1080]
  new_boss_intro_regular_burst_preview.png [1920, 1080]
  ch_regular_walk.gif [768, 224]
  ch_regular_asphalt_test.png [3072, 220]

SENDBACK — Emerald jacket/napkin bib/red side-part distinguish him; the plate is only a narrow pixel ellipse in profile.
  ch_sendback.png [256, 256]
  new_portrait_sendback.png [1536, 512]
  new_boss_intro_sendback.png [1920, 1080]
  new_boss_intro_sendback_burst_preview.png [1920, 1080]
  ch_sendback_walk.gif [768, 224]
  ch_sendback_asphalt_test.png [3072, 220]

COUPON — Braid crown/turquoise coat/coral bag distinct; long coat partly hides front/back leg depth; coupon fan simplified.
  ch_coupon.png [256, 256]
  new_portrait_coupon.png [1536, 512]
  new_boss_intro_coupon.png [1920, 1080]
  new_boss_intro_coupon_burst_preview.png [1920, 1080]
  ch_coupon_walk.gif [768, 224]
  ch_coupon_asphalt_test.png [3072, 220]

ALLERGY — Frizz halo/burgundy glasses/maroon trousers distinct; onion prop is tiny at native scale.
  ch_allergy.png [256, 256]
  new_portrait_allergy.png [1536, 512]
  new_boss_intro_allergy.png [1920, 1080]
  new_boss_intro_allergy_burst_preview.png [1920, 1080]
  ch_allergy_walk.gif [768, 224]
  ch_allergy_asphalt_test.png [3072, 220]

CAMPER — Lavender curls/moss cardigan/headphones and laptop distinguish this boss; laptop details are abstract pixels.
  ch_camper.png [256, 256]
  new_portrait_camper.png [1536, 512]
  new_boss_intro_camper.png [1920, 1080]
  new_boss_intro_camper_burst_preview.png [1920, 1080]
  ch_camper_walk.gif [768, 224]
  ch_camper_asphalt_test.png [3072, 220]

BDAYDAD — Paper crown/teal polo/shorts/cake-box silhouette distinct; cake box is reduced to a cream block at native scale.
  ch_bdaydad.png [256, 256]
  new_portrait_bdaydad.png [1536, 512]
  new_boss_intro_bdaydad.png [1920, 1080]
  new_boss_intro_bdaydad_burst_preview.png [1920, 1080]
  ch_bdaydad_walk.gif [768, 224]
  ch_bdaydad_asphalt_test.png [3072, 220]

DASHER — Yellow jacket/maroon twists/red shoes clear; committed shoulder-charge uses bent arms, box, forward head shift and speed ticks rather than a punch.
  ch_dasher.png [256, 256]
  new_portrait_dasher.png [1536, 512]
  new_boss_intro_dasher.png [1920, 1080]
  new_boss_intro_dasher_burst_preview.png [1920, 1080]
  ch_dasher_walk.gif [768, 224]
  ch_dasher_asphalt_test.png [3072, 220]
