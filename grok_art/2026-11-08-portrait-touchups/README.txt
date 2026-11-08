DUFFQUEST — PORTRAIT TOUCH-UPS
Image generations used: 0. All changes made by hand-directed pixel recolour, reused original eye/nose pixels, deterministic skin-colour interpolation and local drawn curves. No image model used.

ONLY TWO CHANGED REPO FILES
duffquesthd/portraits/madison_portraits_hazbin.png
  Middle irises teal->warm brown matched to the other expressions and two original Madison photos. Pupils/catchlights/lids untouched before common framing.
duffquesthd/portraits/octavia_portraits_hazbin.png
  Giggling retained; curious round blue-grey eyes/raised brows/small O-mouth; distressed inner-raised brows, open toothless wail and tiny tears. Pink wailing irises intentionally retained per Duff approval in CLAUDE.md.

SOURCE / REFERENCES
Both 1280x720 green-key source masters were byte-verified against current-main GitHub blob hashes. Current assets/art/portraits_hd/{madison,octavia}.png also matched main, but are transparent 1536x512 derived outputs, so they are NOT replaced with green-key files or bundled here.
Madison's two original photo references confirm brown irises, as do her other expressions. Octavia's two earlier baby photos were reviewed for round cheeks/button nose/hair/hoodie likeness. Only expressions were redrawn; the existing figure silhouette is unchanged before the required framing cleanup.
History lookup returned no accessible transcript records, so the exact old optional-review prose was NOT recovered. The two requested changes match retained art instructions: brown Madison eyes, baby giggling/curious/wailing, no adult rows of teeth. CLAUDE.md explicitly records Duff's approval of Octavia's pink furious eyes; that intentional accent is retained in the wailing panel.

EDITS
Madison: 232 teal iris pixels in the middle expression recoloured warm brown; pupils, highlights and eyelids unchanged before framing. Other expression artwork unchanged before framing.
Octavia: giggling face retained; middle becomes wide-eyed curious with softly raised brows and a small cooing O-mouth. Third becomes distressed/toothless wailing with inner-raised brows, a rounded dark mouth/tongue and tiny tear glints, rather than an adult angry snarl. Existing face, hair and hoodie pixels reused, including the approved pink eye accent. No teeth added.

CANVAS / GUTTERS
Exact original 1280x720 RGB PNG filenames and #00FF00 key. Three panels in the original one-row layout. 1280 is not divisible by3; the existing importer rounds boundaries to 0, 427, 853, 1280 (widths 427, 426, 427), retained here. The originals already crossed those dividers. Removed neighbouring fragments where separable and very slightly reframed each character strip to create at least 4px clear margins: Madison scale 0.992806; Octavia scale 0.971831. Common scale within each character preserves relative head sizes. This means pixels outside the feature edits also move slightly for framing; not a claim of byte-identical first/third panels in the final framed PNG.
Backups named *_before_touchup.png are preserved beside staged PNGs on the box, but intentionally excluded from this changed-files ZIP. Preview and checks are outside the ZIP too.

INTEGRATION FOR CLAUDE (NOT EXECUTED)
Copy the two files to their repo-relative paths. Then regenerate the runtime transparent sheets with the existing importer:
python3 tools/import_portrait.py duffquesthd/portraits/madison_portraits_hazbin.png madison --cell 512 --margin 16
python3 tools/import_portrait.py duffquesthd/portraits/octavia_portraits_hazbin.png octavia --cell 512 --margin 16
Refresh Godot texture imports afterward. No repo/code/runtime files were modified by this art job.

CHECKS / LIMITATIONS
Dimensions, RGB PNG, exact key borders, safe margins, backups/source hashes, 232-pixel Madison recolour, unchanged unframed giggle/silhouette, no teal left in Madison's iris region and no white adult teeth in the wailing mouth all pass. Both final sheets inspected visually. No in-engine test.
Hand-edited baby face skin/curves are smoother and simpler than the original textured ink; wailing can also read as startled distress. Likeness remains a stylized interpretation, not a photo-identical face. Small framing changes and inherited shoulder cropping are disclosed above. Pink wailing irises remain deliberately non-naturalistic per the prior approval.
