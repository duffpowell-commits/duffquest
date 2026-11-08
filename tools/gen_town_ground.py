"""Write the first data/town_ground.txt: the outdoor ground as a grid of materials, laid out to
match the old painted map (same roads, same footpaths to the same doors).

    python3 tools/gen_town_ground.py

After this the text file is the source of truth: edit it by hand (even on a phone).
Letters: g grass, s sidewalk, a asphalt, d dirt, b brick, v gravel.
Each letter is a grid CORNER; the game fills the square between four corners with the matching
transition tile ("dual grid"). Two materials may meet only if Grok drew that pair:
sidewalk/asphalt, grass/sidewalk, grass/asphalt, dirt/grass. Never put two of the same material
diagonally across a corner from each other with the other two different (no diagonal tile exists).
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TILE = 64            # px per tile (32 world units)
OX, OY = -10, -32    # px position of corner (0,0): puts corner lines on the old road centres
COLS, ROWS = 22, 13  # corners: covers x -10..1334, y -32..736 (map is 1280x720 px)

ROAD_Y = 352         # old horizontal road centre, px
ROAD_X = 630         # old vertical road centre, px
# footpaths from the road sidewalks to building doors (old map path centres, snapped to corners)
PATHS_UP = [182, 1078, 438, 758]       # paths above the road (to the top row of buildings)
PATHS_DOWN = [182, 438, 758, 1078]     # paths below the road
PATH_LEN = 2                           # corners beyond the sidewalk


def main():
    def cx(i):
        return OX + i * TILE

    def cy(j):
        return OY + j * TILE

    rj = min(range(ROWS), key=lambda j: abs(cy(j) - ROAD_Y))
    ri = min(range(COLS), key=lambda i: abs(cx(i) - ROAD_X))
    g = [["g"] * COLS for _ in range(ROWS)]
    for i in range(COLS):
        g[rj - 1][i] = g[rj + 1][i] = "s"
    for j in range(ROWS):
        g[j][ri - 1] = g[j][ri + 1] = "s"
    for i in range(COLS):
        g[rj][i] = "a"
    for j in range(ROWS):
        g[j][ri] = "a"
    for x in PATHS_UP:
        i = min(range(COLS), key=lambda k: abs(cx(k) - x))
        for k in range(1, PATH_LEN + 1):
            g[rj - 1 - k][i] = "s"
    for x in PATHS_DOWN:
        i = min(range(COLS), key=lambda k: abs(cx(k) - x))
        for k in range(1, PATH_LEN + 1):
            g[rj + 1 + k][i] = "s"
    lines = [f"# town ground. tile {TILE} origin {OX} {OY}. g grass s sidewalk a asphalt d dirt b brick v gravel",
             f"tile {TILE}", f"origin {OX} {OY}"] + ["".join(r) for r in g]
    out = ROOT / "data" / "town_ground.txt"
    out.write_text("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
