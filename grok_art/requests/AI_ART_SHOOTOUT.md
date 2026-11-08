# AI art shootout: ChatGPT vs Gemini (Nov 8)

Goal: find out which free app can make DuffQuest art, and where both break.
Same tests as the Gemini run (G1–G7) so the scores line up, plus three "stretch" tests
Claude expects BOTH to fail.

## How to run it (phone)
- **ChatGPT:** use the model that makes images (the default in the app). New chat per test.
- **Gemini:** check the model menu first. **Not Flash-Lite.** New chat per test.
- Attach the `ref_` files named in each test (Drive: DuffQuest Art Inbox / 98 Gemini capability test).
- Paste the prompt exactly. Don't add anything. One reroll max (= try 2).
- Save each result to Drive folder **geminiart** as:
  - ChatGPT: `c1_try1.png`, `c1_try2.png` ... `c7_...`
  - Stretch tests: `x1_chatgpt_try1.png`, `x1_gemini_try1.png` ...
- Then tell Claude "shootout's in". Claude pulls, grades, compares.

## Rubric (same as Gemini, 12 points)
Brief (did it draw what was asked, 0–3) · Layout/format (grid, size, camera, 0–3) ·
Style match (Sea of Stars pixels / Hazbin cartoon, 0–3) · Clean (no junk text, keyable background, 0–3).
Pass = 10+. Stretch tests are pass/fail on a measurable check (below).

---

## C1 – Apartment (attach `ref_room_home`, `ref_style_board_2`)
```
Redraw the first image as a finished top-down pixel-art game room in the style of the second image (Sea of Stars: saturated, warm sunlight, soft coloured shadows). Keep EVERY piece of furniture exactly where it is in the first image; only the art changes. Straight-on top-down camera, 16:9, no text, no characters.
```

## C2 – Gym arena (attach `ref_style_board_2`)
```
Top-down pixel-art boss arena, 16:9, Sea of Stars style, warm afternoon light. A small gym: weight racks along the back wall only, open rubber-mat floor filling the middle 70% of the image, nothing in the bottom-left and bottom-right corners. One sign reading exactly IRON TEMPLE, placed low on the back wall with its top edge at least a quarter of the way down the image. No other text anywhere. No characters.
```

## C3 – Duff tuxedo sheet (attach `ref_sheet_duff`)
```
Edit this sprite sheet. Keep the exact grid, size, poses and pixel scale. Change only his clothes: black tuxedo, white shirt, black bow tie. Keep his hair, face and the magenta #FF00FF background exactly the same.
```

## C4 – Porch Pirate sheet (attach `ref_sheet_boss` for format)
```
Make a new sprite sheet in exactly the same format as this one: 4x4 grid, square cells, flat magenta #FF00FF background, no grid lines. Character: "Porch Pirate", a sneaky young guy in a black hoodie and sunglasses carrying a stolen cardboard parcel. Row 1 faces the camera, row 2 faces AWAY (we see his back), row 3 faces right, row 4 faces left. Columns: stand, step, step, throwing the parcel. No text on the box.
```

## C5 – Dolores portraits (attach `ref_portrait_madison`)
```
Three dialogue portraits in exactly this cartoon style (thick tapered ink lines, flat cel shading), side by side on flat green #00FF00: smug, deadpan, furious. Character: Dolores, a 60-year-old Waffle Haus waitress, tall grey beehive hair, cat-eye glasses, mustard-yellow diner uniform, pencil behind her ear. No cigarette, no text.
```

## C6 – Kitchen props
```
A 4x4 grid of pixel-art kitchen props on flat magenta #FF00FF, one per cell, centred, no grid lines, no text. In this order, left to right, top to bottom: fry basket, order ticket, plate of fries, cheeseburger, pickle jar, whisk, chef's knife, cutting board, salad bowl, chicken sandwich, mixing bowl, fire extinguisher, coffee pot, waffle, hot sauce bottle, tip jar.
```

## C7 – Show-off (attach `ref_style_board_2`)
```
Show me the best game art you can make: Duff, a line cook with a dirty-blond undercut and ponytail, fox tattoo on his neck, black t-shirt and stained apron, fighting a giant angry waffle in a 24-hour diner at 3 AM. Sea of Stars pixel-art style, 16:9.
```

---

## Stretch tests (give the SAME prompt to both apps)

### X1 – Change one thing, touch nothing else (attach `ref_done_home`)
```
Edit this image. Add one small potted Christmas tree in the bottom-right corner. Every other pixel must stay exactly the same: same furniture, same colours, same size. Do not redraw the room.
```
Check: Claude diffs it against the original. Pass = everything outside the bottom-right corner is unchanged.
Why it should fail: these apps redraw the whole picture on every edit, so furniture drifts.

### X2 – Seamless floor tile
```
A 512x512 top-down pixel-art texture of old checkered diner floor tiles, scuffed, Sea of Stars style. It must tile seamlessly: the left edge must continue into the right edge and the top into the bottom with no visible seam.
```
Check: Claude tiles it 3x3 and measures the seams. Pass = no visible line.
Why it should fail: they paint pictures, not repeating tiles; seams and a vignette usually show.

### X3 – Exact menu board
```
Pixel-art diner menu board, 16:9, chalk on black. It lists exactly these six lines, spelled exactly, nothing else:
WAFFLE ............ $4.99
HASH BROWNS ....... $2.49
PATTY MELT ........ $6.79
SCATTERED & SMOTHERED $3.19
BOTTOMLESS COFFEE . $1.99
NO REFUNDS. NO REGRETS.
```
Check: every character right, nothing extra. Pass = 0 typos.
Why it might fail: long exact text plus prices. ChatGPT is the better bet here; Gemini usually slips a letter.
