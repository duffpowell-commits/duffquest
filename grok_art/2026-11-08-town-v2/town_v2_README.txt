DUFFQUEST — TOWN V2 / LOW-USAGE ART HANDOFF

IMAGE GENERATIONS USED:0. Native pixel drawing, bitmap lettering, and edits/crops of already approved dressing assets only. No new model variants. All files under /workspace/duffquest/art/.

SYNC LIMITATION
Attempted git pull --ff-only origin main, but /workspace/duffquest_repo is an exported snapshot with no .git directory, so pull failed before any change. Did NOT clone, collect credentials, or pretend the snapshot was refreshed. Read current main cat.gd, assets/art/manifest.json,CLAUDE.md,QUEUE.md,tasks/todo.md using the sanctioned GitHub connector. Latest-main manifest and Sheet columnC agree on cat/bus dimensions. All1660local-export file hashes unchanged. No repo art/code/placement edits.

DELIVERED ART
waffle_sign.png — 48x64, grid1x1, cells48x64, key#FF00FF, origin[24, 60]. New48x64 single prop: legible native5x7 hand-lettering; compact double-line roadside pole sign, sized near the old procedural world footprint. No I-80 or extra text.
bus_sign.png — 32x40, grid1x1, cells32x40, key#FF00FF, origin[16, 38]. Exact existing32x40; enamel teal bus pictogram and short native3x5 BUS lettering, silver rim/pole.
lawn_mailbox.png — 32x40, grid1x1, cells32x40, key#FF00FF, origin[16, 38]. Single32x40 residential curb mailbox; teal weathered enamel, vermilion flag, warm wood stake; no letters.
lawn_flamingo.png — 32x40, grid1x1, cells32x40, key#00FF00, origin[16, 38]. 32x40 pink plastic flamingo, bent leg and curved neck; green key required by pink.
lawn_sprinkler.png — 32x32, grid1x1, cells32x32, key#FF00FF, origin[16, 30]. 32x32 oscillating sprinkler; crisp water droplets, metal highlights; no soft airbrush.
lawn_bush.png — 32x32, grid1x1, cells32x32, key#FF00FF, origin[16, 30]. 32x32 dense garden shrub reused from approved tree foliage, preserving clustered golden-green detail; no ground scenery.
lawn_gnome.png — 32x32, grid1x1, cells32x32, key#FF00FF, origin[16, 30]. 32x32 chunky painted garden gnome statue: red cap, blue jacket, cream beard, lit stone base; original design.
lawn_kiddie_pool.png — 64x40, grid1x1, cells64x40, key#FF00FF, origin[32, 38]. Single64x40 (existing truck_h size convention): teal inflatable pool with structured water ripples and tiny yellow duck; own footprint only.
lawn_trash_can.png — 32x40, grid1x1, cells32x40, key#FF00FF, origin[16, 38]. 32x40 bin reused from approved detailed clutter sheet; brighter metal rim so dark green reads on asphalt/grass. Recycle pictogram, no lettering.
cat_alastor.png — 192x64, grid4x2, cells48x32, key#00FF00, origin[24, 28]. Exact legacy grid and row direction: top LEFT, bottom RIGHT. Cols walkA/walkB/hungry-alert/fed-settled, matching cat.gd frame indices. Native coat: ginger tabby / silver-grey / black. Pink ears/nose require green key. cat.gd velocity lookup is opposite the legacy row directions; see README.
cat_freya.png — 192x64, grid4x2, cells48x32, key#00FF00, origin[24, 28]. Exact legacy grid and row direction: top LEFT, bottom RIGHT. Cols walkA/walkB/hungry-alert/fed-settled, matching cat.gd frame indices. Native coat: ginger tabby / silver-grey / black. Pink ears/nose require green key. cat.gd velocity lookup is opposite the legacy row directions; see README.
cat_lucifer.png — 192x64, grid4x2, cells48x32, key#00FF00, origin[24, 28]. Exact legacy grid and row direction: top LEFT, bottom RIGHT. Cols walkA/walkB/hungry-alert/fed-settled, matching cat.gd frame indices. Native coat: ginger tabby / silver-grey / black. Pink ears/nose require green key. cat.gd velocity lookup is opposite the legacy row directions; see README.
town_tree_trunks.png — 384x384, grid3x3, cells128x128, key#FF00FF, origin[64, 120]. Optional cheap mechanical split of unchanged approved3x3 tree atlas: exposed lower woody pixels / complementary canopy. Empty slots remain empty. Composite reconstructs approved source exactly. Import key first; fade only canopy dynamically. No hidden trunk invented.
town_tree_canopies.png — 384x384, grid3x3, cells128x128, key#00FF00, origin[64, 120]. Optional cheap mechanical split of unchanged approved3x3 tree atlas: exposed lower woody pixels / complementary canopy. Empty slots remain empty. Composite reconstructs approved source exactly. Import key first; fade only canopy dynamically. No hidden trunk invented.

STYLE / FORMAT
Straight-on, slightly-above3/4 camera, no diagonal streets/scene. Bright source sun and warm enamel/wood/teal material language; cool inside-edge light on dark cat/bin/metal. Deliberate fur/material clusters and native pixel shapes, no blur, soft gradients or textured keys. All game files opaque RGB PNG on exact flat keys; import key to transparency, never nearest-scale the key with interpolation. Minimum2px cell margins. Pink noses/ears/flamingo and flowering canopy use#00FF00; remaining assets#FF00FF.
WAFFLE HAUS is hand-lettered in native5x7glyphs, two lines; BUS uses3x5glyphs plus a bus pictogram. Each letter manually read and glyph masks verified. No other lettering; bin has a recycle pictogram only.
New waffle sign has no dedicated Sheet C row:48x64chosen to fit readable letters and approximate the existing procedural pole-sign world footprint at s2. Pool64x40uses an existing wide-prop size convention; new lawn props32x32or32x40. New prop origins are ground anchors, not vehicle center anchors.

CAT LAYOUT — IMPORTANT EXISTING CONFLICT
Exact192x64,4columns x2rows,48x32cells,origin24,28; paws baseline28. Ginger/tabby Alastor, silver-grey Freya and dark slate-black Lucifer match legacy coat identities; fur detail is a stylized interpretation, not checked against pet photos.
Actual legacy PNGs have top row facing LEFT and bottom row RIGHT. Preserved those row directions exactly as requested, rather than silently swapping the old file layout. Their body/eyes are naturally cat-shaped, no fantasy features.
Latest cat.gd instead selects row0 when velocity.x>=0. Sheet F also assumes row0RIGHT (columnC only specifies exact dimensions). Therefore the old art/runtime direction mapping is inconsistent. Claude should choose an import-time row swap OR correct the lookup; no extra art variant is supplied.
Frame semantics follow actual code, not the Sheet F's loose '4walkframes' wording: col0walkA,col1walkB; col2hungry/alert idle; col3fed/settled idle. Only0and1are the walking loop in cat.gd. Opposite contacts differ; the fed pose has closed eyes and a lower relaxed head. Row2 is a per-cell mirror of row1, not a reversal of the whole atlas.

INTEGRATION NOTES (PROPOSED, NOT APPLIED)
- waffle_sign is a NEWasset. main.gd::_draw_waffle_sign_and_board currently draws the sign procedurally. Replace only its pole/sign subsection; preserve bounty-board/story interactions. New PNG carries only WAFFLE HAUS, no arrow or extra lettering.
- bus_sign replaces the legacy32x40asset, but current town notes say the visible old bus sign remains baked into map_objects.png. Merely replacing bus_sign.png might not remove that baked version; Claude should clear/cover that old cutout and place the new sprite once.
- New lawn_* props need registration/placement in town_dressing.json or the appropriate dressing importer. Use the right-side empty lawns, NOT extra grass pasted over the existing sidewalks. Keep doors, paths and collision clearance intact. No placement/collision changes made here.
- town_v2_import_manifest.json is an integration proposal, not a repo manifest patch.

TREE OCCLUSION — CODE ISSUE, NOT FIXED BY THESE PNGS
Current main notes say M4 already applies45% see-through to enemies/bosses/raccoons/cats/Brittany/inspector, not just Duff. But front-layer selection is still based on DUFF'Sfeet, so another actor in front of that tree can be drawn under it. Proper per-actor y-sort/shared depth ordering remains Claude's code work. Do not claim the artwork fixes draw order, and do not blindly double-apply the existing fade.
Optional town_tree_trunks.png and town_tree_canopies.png cheaply split the EXISTING384x384,3x3treeatlas into exposed lower woody pixels and the complementary canopy. Same128pxcells and64,120anchor. Cell map: maple,oak,scraggly_ash / pine,lilac,hedge / unused,unused,unused. Trunk layer contains no hidden newly invented wood; hedge has no trunk. Composite after keying reconstructs the approved sheet pixel-for-pixel. Keep trunks opaque and depth-sort by the shared ground anchor; fade only canopy when appropriate. Both layers together replace ONEtree, not two independently placed trees.
The contact sheet's opaque-versus45%canopy panel is an ARTILLUSTRATION only, not a Godot screenshot. No separate alpha variant was generated.

CHECKS / HONEST LIMITATIONS
All12primary assets inspected individually/in the grass+asphalt contact sheet. PNG formats, exact grids, key borders, cell margins, cat mirrored rows, walk differences,28pxbaseline, exact letter masks, tree roundtrip and unchanged snapshot hashes pass. See town_v2_checks.json.
Native cats/gnome/signs are intentionally hand-pixelled and cleaner/simpler than Board2's large architectural painting; the tiny formats cannot hold its full texture density. Sparse trim/feather/fur/wear clusters replace smooth detail. Tiny BUS lettering should be viewed at native or nearest-integer scale. Dark cat depends on cool rim highlights for contrast. Runtime cat facing needs the integration decision above. No engine placement, collision, font-scale, import-cache or y-sort runtime test. After importing, Claude should refresh Godot's texture import cache per its own notes.

DELIVERABLES
town_v2_preview.png — grass/asphalt contact sheet plus occlusion illustration.
town_v2_manifest.json — absolute file paths, dimensions/grid/origin/key/SHA256.
town_v2_checks.json — automated checks and explicitly labelled visual judgments.
town_v2_import_manifest.json — proposed registration data; optional tree layers separate.
