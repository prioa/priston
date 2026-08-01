#!/usr/bin/env python3
"""Generate PRISTON's original pixel art.

Every pixel here is original work drawn in code -- nothing is derived from
ROM content, matching the mod platform's legal posture.

Outputs (into ../assets/):
  priston_walk.png   16x96 walker sheet: 6 frames of 16x16
                     (stand down/up/left, walk down/up/left; right = flip)
  priston_back.png   32x32 battle back pic (grayscale on white, opaque)
  priston_front.png  56x56 intro / trainer card pic (white -> transparent)

Shade legend in the grids below:
  .  white  (overworld: OBJ color 0 = transparent; front pic: matted alpha)
  1  light  (tan fur)
  2  dark   (saddle marking / shading)
  3  black  (outline, nose, eyes)

The engine remaps overworld shades at draw time with thresholds
r>0.83 white, r>0.5 light, r>0.17 dark, else black (SpriteRenderer.lua),
so the four gray values below sit safely inside those buckets.
"""

import os
from PIL import Image, ImageDraw

SHADE = {".": 255, "1": 176, "2": 96, "3": 0}
OUT = os.path.join(os.path.dirname(__file__), "..", "assets")

# ---------------------------------------------------------------- walker

# A chubby German Shepherd. Down = facing the camera: pointy ears, muzzle,
# dark chest patch, a visibly round body; the walk frames swap between a
# narrow and a splayed stance, which reads as a waddle.

DOWN_STAND = [
    "................",
    "..3..........3..",
    ".323........323.",
    ".3223......3223.",
    "..333333333333..",
    "..311111111113..",
    "..313111111313..",
    "..311113311113..",
    "..321111111123..",
    ".32222222222223.",
    ".31111222211113.",
    ".31111222211113.",
    ".31111111111113.",
    "..313......313..",
    "..333......333..",
    "................",
]

DOWN_WALK = DOWN_STAND[:13] + [
    ".313........313.",
    ".333........333.",
    "................",
]

UP_STAND = [
    "................",
    "..3..........3..",
    ".323........323.",
    ".3223......3223.",
    "..333333333333..",
    "..311111111113..",
    "..311111111113..",
    "..311111111113..",
    "..321111111123..",
    ".32222222222223.",
    ".31122222222113.",
    ".31122222222113.",
    ".31111111111113.",
    "..313..33..313..",
    "..333..33..333..",
    "................",
]

UP_WALK = UP_STAND[:13] + [
    ".313...33...313.",
    ".333...33...333.",
    "................",
]

# Left = side view: snout poking left, one ear, a big sagging belly, the
# tail curled up at the rear. Right-facing frames are engine flips.
LEFT_STAND = [
    "................",
    "....33..........",
    "...323..........",
    "..33333.........",
    ".3111113........",
    ".3131113........",
    "33111113........",
    ".31111233.....33",
    "..3222222222233.",
    ".31112222222223.",
    ".31111222222223.",
    ".31111111112223.",
    ".31111111111113.",
    "..311......311..",
    "..333......333..",
    "................",
]

LEFT_WALK = LEFT_STAND[:13] + [
    ".311........311.",
    ".333........333.",
    "................",
]

WALKER_FRAMES = [DOWN_STAND, UP_STAND, LEFT_STAND, DOWN_WALK, UP_WALK, LEFT_WALK]


def grid_to_image(grid, transparent_white=False):
    h, w = len(grid), len(grid[0])
    img = Image.new("RGBA", (w, h))
    px = img.load()
    for y, row in enumerate(grid):
        assert len(row) == w, "row %d has %d cols, want %d" % (y, len(row), w)
        for x, ch in enumerate(row):
            v = SHADE[ch]
            a = 0 if (transparent_white and ch == ".") else 255
            px[x, y] = (v, v, v, a)
    return img


def make_walker():
    sheet = Image.new("RGBA", (16, 96), (255, 255, 255, 255))
    for i, frame in enumerate(WALKER_FRAMES):
        assert len(frame) == 16, "frame %d has %d rows" % (i, len(frame))
        sheet.paste(grid_to_image(frame), (0, i * 16))
    sheet.save(os.path.join(OUT, "priston_walk.png"))


# ---------------------------------------------------------------- shapes

L = (176, 176, 176, 255)
D = (96, 96, 96, 255)
B = (0, 0, 0, 255)


def snap_shades(img, transparent_white):
    """Clamp every pixel to the 4 legal grays; optionally keep white clear."""
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                px[x, y] = (255, 255, 255, 0 if transparent_white else 255)
                continue
            v = min((255, 176, 96, 0), key=lambda s: abs(s - r))
            if v == 255 and transparent_white:
                px[x, y] = (255, 255, 255, 0)
            else:
                px[x, y] = (v, v, v, 255)
    return img


def stink_wisps(d, spots):
    """The famous royal stench, rising as wavy lines."""
    for x0, y0 in spots:
        d.line([(x0, y0), (x0 + 2, y0 - 4), (x0, y0 - 8), (x0 + 2, y0 - 12)],
               fill=D)


# ------------------------------------------------------------- battle back

def make_back():
    """32x32, from behind: round rear, saddle across the back, ears poking
    over the head, stink wisps. Drawn opaque on white like extracted pics."""
    img = Image.new("RGBA", (32, 32), (255, 255, 255, 255))
    d = ImageDraw.Draw(img)

    # the enormous rear/body
    d.ellipse([3, 14, 28, 31], fill=L, outline=B)
    # saddle marking across the back
    d.ellipse([7, 15, 24, 25], fill=D)
    # head from behind, overlapping the body top
    d.ellipse([9, 5, 22, 18], fill=L, outline=B)
    d.chord([9, 5, 22, 18], 180, 360, fill=D, outline=B)  # dark head top
    # ears
    d.polygon([(10, 8), (8, 1), (15, 5)], fill=D, outline=B)
    d.polygon([(21, 8), (23, 1), (16, 5)], fill=D, outline=B)
    # tail curled at the right hip
    d.arc([24, 16, 31, 25], 270, 90, fill=B)
    d.arc([25, 17, 30, 24], 270, 90, fill=D)
    # hind paws peeking out at the bottom
    d.rectangle([7, 29, 11, 31], fill=L, outline=B)
    d.rectangle([20, 29, 24, 31], fill=L, outline=B)

    stink_wisps(d, [(2, 13), (28, 12)])
    snap_shades(img, transparent_white=False)
    img.save(os.path.join(OUT, "priston_back.png"))


# ------------------------------------------------------------- front pic

def make_front():
    """56x56 portrait for Oak's intro, the trainer card and the Hall of
    Fame: PRISTON sitting proudly, slightly too wide for the frame, wearing
    the small crooked crown he refused to give back."""
    img = Image.new("RGBA", (56, 56), (255, 255, 255, 0))
    d = ImageDraw.Draw(img)

    # body: a big rounded mass, wider than tall
    d.ellipse([6, 26, 49, 54], fill=L, outline=B)
    # chest
    d.ellipse([20, 34, 35, 52], fill=D)
    d.ellipse([22, 38, 33, 52], fill=L)
    # front legs
    d.rectangle([15, 44, 20, 54], fill=L, outline=B)
    d.rectangle([35, 44, 40, 54], fill=L, outline=B)

    # ears first, so the head outline sits cleanly on top of their bases
    d.polygon([(16, 18), (11, 3), (24, 12)], fill=L, outline=B)
    d.polygon([(16, 15), (14, 7), (21, 12)], fill=D)
    d.polygon([(39, 18), (44, 3), (31, 12)], fill=L, outline=B)
    d.polygon([(39, 15), (41, 7), (34, 12)], fill=D)
    # head
    d.ellipse([15, 12, 40, 34], fill=L, outline=B)
    # eyes
    d.rectangle([21, 19, 23, 22], fill=B)
    d.rectangle([32, 19, 34, 22], fill=B)
    # muzzle
    d.ellipse([22, 23, 33, 33], fill=L, outline=B)
    d.rectangle([26, 24, 29, 27], fill=B)  # nose
    d.line([(27, 27), (27, 30)], fill=B)
    d.line([(24, 31), (31, 31)], fill=B)  # mouth

    # the small crooked crown, centered between the ears, one spike bent
    d.polygon([(22, 11), (22, 6), (24, 1), (26, 6), (28, 0), (30, 6),
               (33, 2), (33, 11)], fill=D, outline=B)
    d.line([(22, 11), (33, 11)], fill=B)

    stink_wisps(d, [(2, 24), (49, 24), (6, 32), (46, 34)])
    snap_shades(img, transparent_white=True)
    img.save(os.path.join(OUT, "priston_front.png"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    make_walker()
    make_back()
    make_front()
    print("wrote priston_walk.png, priston_back.png, priston_front.png")
