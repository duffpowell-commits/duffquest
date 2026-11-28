# PR #234 — branding review evidence (Nov 28, 2026)

Engine: Godot 4.7.2, GL Compatibility, Mesa llvmpipe. Root and porch previous images are the actual engine captures already committed on PR #234 at `83cb8f768fa59cb9b81d308c4253ce8532a8f6aa`. HD previous image was freshly captured from an isolated archive of that exact commit. Comparison images place original screenshots next to new captures without changing their contents.

| Edition | Before → after | Phone request 844×390 | Landscape request 1280×720 |
|---|---|---|---|
| Root | [comparison](root-comparison.png) | [title](root-after-phone.png), [settings](root-phone-settings.png) | [title](root-landscape-title.png) |
| HD | [comparison](hd-comparison.png) ([baseline capture](hd-before-phone-title.png)) | [title](hd-phone-title.png), [settings](hd-phone-settings.png) | [title](hd-landscape-title.png), [settings](hd-landscape-settings.png) |
| Porch | [comparison](porch-comparison.png) | [title](porch-phone-title.png), [settings](porch-phone-settings.png), [controls](porch-phone-controls.png) | [title](porch-landscape-title.png), [settings](porch-landscape-settings.png), [controls](porch-landscape-controls.png) |

Root phone and HD are logical 640×360 engine images under their integer viewport scaling; root landscape and porch captures are full output dimensions. No performance claim from software rendering. Phone capture is a landscape-window simulation, not a phone-device screenshot. Root/HD Continue shown with isolated synthetic Day 7 / $123 save, not an owner's save.

## Verification

- Root `tools/test.sh`: **609 PASS**, `ALL PASS (0 failed)`, `TESTS PASS`, no SCRIPT ERROR. Existing ObjectDB shutdown warning.
- Porch `godot --headless --path spike_full3d --script smoke.gd`: **159 PASS**, 0 FAIL, no SCRIPT ERROR. Existing ObjectDB/resource shutdown warnings.
- `tools/test_brand_legacy.sh`: **3 PASS**, root version 0→8 and HD version 0→7 (Day 7, $123 and honey buns migration), porch best grade A / 42.5 seconds; old/new engine path identical for each edition. Disposable XDG data only.
- Reimport with the two newly tracked brand cache files absent regenerated both from `assets/art/wrr_logo.png` and its import settings. Source textures and `.import` files remain. Other pre-existing tracked cache policy is unchanged. Editor initialization emitted sandbox socket/settings warnings, not a script error.
- Root/HD/porch title and menu render checks visually inspected. The title buttons are 22 logical units high in root/HD (44 rendered px at 640×360) and 64 logical units in porch (~46 px at 844×390); root settings rows (34 px), back (26 px) and some HD volume controls (~40 px) remain smaller than a 44px touch target. Root settings switches retain positional state indicators; porch native buttons now have keyboard focus styling. Full assistive-technology and physical touch audit remains outstanding.
- Root/HD existing approved character artwork unchanged; 3D existing rig and mapped tattoos unchanged. Exact longer ponytail/tattoo recognizability is not independently accepted. No substitute art.

## Risk and release hold

| Gate | Status |
|---|---|
| Exact player-facing application/package/web labels | Local audit done; legacy save-path and internal deployment strings intentionally retain old names |
| Physical Android update with existing signed APK/data | **OUTSTANDING** — no attached Android device or adb available |
| iPhone home-screen PWA upgrade and retained IndexedDB/user:// data | **OUTSTANDING** — no physical iPhone available |
| Actual signing/packaging acceptance and 8.5/10 player review | **OUTSTANDING** — no new APK built locally, no player rating claimed |
| Publication/merge | **HELD** — keep draft PR #234; no kitchen/neighborhood integration. Shared branch preview release uploads are excluded on this branch; review builds may be CI artifacts, not production releases. |

No real save, signing keys, package IDs, build filenames, itch or GitHub Pages URLs were changed. Existing live URLs are not proof of this revision. APK/web artifacts, when CI successfully builds them, are on the branch's [Actions runs](https://github.com/duffpowell-commits/duffquest/actions/workflows/build.yml?query=branch%3Abrand%2Fwash-rinse-regret).
