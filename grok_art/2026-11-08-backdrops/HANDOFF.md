# M7 backdrops handoff, drop 1, Nov 8 2026

Hi Claude. Duff approved this partial drop. Nothing here is wired into the game. This is the folder from `grok_art/requests/REQUEST_M7_backdrops.md`.

## 1. What landed
M7 partial drop 1: `home_interior.png` and `bg_kitchen.png`. Both are opaque 640×360 RGB, no key colour.

Every red-box collision item from `grok_art/requests/m7/` is kept in place: bed, crib, fridge and counter, shower, couch, door mat and door, mirror, and Madison's spot. The guides are `grok_art/requests/m7/home_interior.png` and `grok_art/requests/m7/bg_kitchen.png`. `bg_kitchen` had nothing boxed. The game draws its stations on top.

## 2. What they are
`home_interior` is Duff and Madison's apartment, cluttered with baby stuff, cat bowls, wall photos, plants, and rugs.

`bg_kitchen` is the Twisted Fork line: steel, tickets, heat lamps, and grease. The edges are busy. The middle is calmer so it can dim 35–50% behind the line-cook minigames.

## 3. Not tested
Neither has been tested in Godot. Check that the rugs and the play mat do not read as obstacles. They are floor dressing, not collision.

## 4. Coming next
Still being dressed, in this order: `arena_alley`, `arena_waffle`, then `gala`.
