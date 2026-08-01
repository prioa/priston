#!/usr/bin/env python3
"""Generate PRISTON's original pixel art (GBA-style color, real alpha).

Every pixel here is original work drawn in code -- nothing is derived from
ROM content, matching the mod platform's legal posture.

Outputs (into ../assets/):
  priston_walk.png   16x96 walker sheet: 6 frames of 16x16
                     (stand down/up/left, walk down/up/left; right = flip)
  priston_back.png   32x32 battle back pic (transparent background)
  priston_front.png  56x56 intro / trainer card pic (transparent background)

All three ship real colors with a real alpha channel; the mod marks them
trueColor so the engine's 4-shade palette remap leaves them untouched
(SpriteRenderer.lua / BattleState getImage both skip the quantize then).

Grid legend:
  .  transparent          t  tan fur        c  cream chest/belly
  s  saddle dark brown    b  mid brown      k  near-black outline/mask
  p  pink inner ear       r  collar red     w  collar white
  u  collar blue          g  crown gold     G  crown dark gold
  e  stink green
"""

import os
from PIL import Image, ImageDraw

PAL = {
    "t": (205, 150, 88, 255),
    "c": (240, 214, 166, 255),
    "s": (82, 55, 36, 255),
    "b": (128, 88, 56, 255),
    "k": (34, 26, 22, 255),
    "p": (198, 124, 118, 255),
    "r": (206, 52, 58, 255),
    "l": (112, 70, 34, 255),
    "w": (238, 238, 238, 255),
    "u": (28, 80, 158, 255),
    "g": (233, 186, 62, 255),
    "G": (160, 118, 30, 255),
    "e": (140, 178, 96, 255),
    ".": (0, 0, 0, 0),
}
OUT = os.path.join(os.path.dirname(__file__), "..", "assets")

# ---------------------------------------------------------------- walker

# A chubby German Shepherd with the Slovak-tricolor collar. Down = facing
# the camera: dark forehead and muzzle mask, tan brows and cheeks, cream
# chest; the walk frames swap between a narrow and a splayed stance,
# which reads as a waddle.

DOWN_STAND = [
    "................",
    "..k..........k..",
    ".ksk........ksk.",
    ".kspk......kpsk.",
    "..kssssssssssk..",
    "..ksttttttttsk..",
    "..kttkttttkttk..",
    "..ktssskksssk...",
    "..ksttckcttsk...",
    "..klllglllllk...",
    ".kssssttttssssk.",
    ".kstttcccctttsk.",
    ".ksttccccccttsk.",
    ".kttccccccccttk.",
    "..ktk......ktk..",
    "..kkk......kkk..",
]

DOWN_WALK = DOWN_STAND[:14] + [
    ".ktk........ktk.",
    ".kkk........kkk.",
]

UP_STAND = [
    "................",
    "..k..........k..",
    ".ksk........ksk.",
    ".kssk......kssk.",
    "..kkkkkkkkkkkk..",
    "..kssssssssssk..",
    "..kssssssssssk..",
    "..kssssssssssk..",
    "..kssssssssssk..",
    "..klllglllllk...",
    ".kssssssssssssk.",
    ".kssssssssssssk.",
    ".kttssssssssttk.",
    ".kttk..ss..kttk.",
    "..kkk..ss..kkk..",
    ".......kk.......",
]

UP_WALK = UP_STAND[:13] + [
    ".ktk...ss...ktk.",
    ".kkk...ss...kkk.",
    ".......kk.......",
]

# Left = side view: long muzzle poking left with the dark mask, one upright
# ear, the saddle mantle over the back, a big sagging cream belly, the tail
# hanging low behind. Right-facing frames are engine flips.
LEFT_STAND = [
    "................",
    "....kk..........",
    "...ksk..........",
    "..kssk..........",
    ".ksttsk.........",
    ".ktkttk.........",
    "kksttttk........",
    ".kttttskk....kk.",
    "..klglkssssskssk",
    ".kstttttssssssk.",
    ".ktttttttsssssk.",
    ".kctttttttttsk..",
    ".kccttttttttk...",
    "..ktk.....ktk...",
    "..kkk.....kkk...",
    "................",
]

LEFT_WALK = LEFT_STAND[:13] + [
    ".ktk.......ktk..",
    ".kkk.......kkk..",
    "................",
]

WALKER_FRAMES = [DOWN_STAND, UP_STAND, LEFT_STAND, DOWN_WALK, UP_WALK, LEFT_WALK]


def grid_to_image(grid):
    h, w = len(grid), len(grid[0])
    img = Image.new("RGBA", (w, h))
    px = img.load()
    for y, row in enumerate(grid):
        assert len(row) == w, "row %d has %d cols, want %d" % (y, len(row), w)
        for x, ch in enumerate(row):
            px[x, y] = PAL[ch]
    return img


def make_walker():
    sheet = Image.new("RGBA", (16, 96), (0, 0, 0, 0))
    for i, frame in enumerate(WALKER_FRAMES):
        assert len(frame) == 16, "frame %d has %d rows" % (i, len(frame))
        sheet.paste(grid_to_image(frame), (0, i * 16))
    sheet.save(os.path.join(OUT, "priston_walk.png"))


# ---------------------------------------------------------------- shapes

T, C, S, B, K = PAL["t"], PAL["c"], PAL["s"], PAL["b"], PAL["k"]
P, R, W, U, G, GD, E = (PAL[ch] for ch in "prwugGe")


def dither_edge(px, box, a, b):
    """A 1px checker seam between two fur colors -- cheap fur texture."""
    x0, y0, x1, y1 = box
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < 56 and 0 <= y < 56 and px[x, y][:3] == a[:3]:
                if (x + y) % 2 == 0:
                    px[x, y] = b


def stink_wisps(d, spots):
    """The famous royal stench, rising as sickly green waves."""
    for x0, y0 in spots:
        d.line([(x0, y0), (x0 + 2, y0 - 4), (x0, y0 - 8), (x0 + 2, y0 - 12)],
               fill=E)
        d.point([(x0 + 1, y0 - 13)], fill=E)


# ------------------------------------------------------------- battle back

def make_back():
    """32x32, from behind: round rear, the dark mantle across the back,
    ears over the head, the Slovak collar peeking out, stink wisps."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # the enormous rear
    d.ellipse([3, 14, 28, 31], fill=T, outline=K)
    # dark mantle across back and shoulders
    d.ellipse([6, 14, 25, 26], fill=S)
    # head from behind
    d.ellipse([9, 5, 22, 18], fill=S, outline=K)
    # leather collar between head and shoulders, one gold tag
    d.line([(10, 16), (21, 16)], fill=PAL["l"])
    d.line([(10, 17), (21, 17)], fill=PAL["l"])
    d.line([(11, 18), (20, 18)], fill=PAL["l"])
    d.point([(15, 17), (16, 17)], fill=G)
    # ears
    d.polygon([(10, 8), (8, 1), (15, 5)], fill=S, outline=K)
    d.polygon([(21, 8), (23, 1), (16, 5)], fill=S, outline=K)
    d.polygon([(11, 6), (10, 3), (14, 5)], fill=P)
    d.polygon([(20, 6), (21, 3), (17, 5)], fill=P)
    # tail hanging at the right hip, tan tip
    d.line([(26, 20), (28, 24), (27, 29)], fill=S, width=2)
    d.point([(27, 30), (28, 30)], fill=T)
    # tan haunches
    d.ellipse([4, 24, 10, 30], fill=T)
    d.ellipse([21, 24, 27, 30], fill=T)
    # hind paws
    d.rectangle([7, 29, 11, 31], fill=T, outline=K)
    d.rectangle([20, 29, 24, 31], fill=T, outline=K)

    img.save(os.path.join(OUT, "priston_back.png"))


# ------------------------------------------------------------- front pic

def make_front():
    """56x56 portrait: PRISTON sitting, slightly too wide for the frame --
    dark saddle mantle, tan brows on the dark forehead, black muzzle mask,
    cream chest, the tricolor collar, and the small crooked gold crown."""
    img = Image.new("RGBA", (56, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # body: a big rounded mass, wider than tall
    d.ellipse([6, 27, 49, 54], fill=T, outline=K)
    # dark mantle over the shoulders
    d.chord([6, 27, 49, 54], 180, 360, fill=S, outline=K)
    # cream chest, sagging over the belly
    d.ellipse([19, 32, 36, 54], fill=C, outline=K)
    # front legs over the chest
    d.rectangle([15, 44, 20, 54], fill=T, outline=K)
    d.rectangle([35, 44, 40, 54], fill=T, outline=K)

    # ears first, so the head outline sits cleanly on their bases
    d.polygon([(16, 18), (11, 3), (24, 12)], fill=S, outline=K)
    d.polygon([(16, 15), (14, 7), (21, 12)], fill=P)
    d.polygon([(39, 18), (44, 3), (31, 12)], fill=S, outline=K)
    d.polygon([(39, 15), (41, 7), (34, 12)], fill=P)
    # head
    d.ellipse([15, 12, 40, 34], fill=T, outline=K)
    # dark forehead cap
    d.chord([15, 12, 40, 30], 180, 360, fill=S)
    # tan brows on the dark cap
    d.rectangle([20, 17, 24, 18], fill=T)
    d.rectangle([31, 17, 35, 18], fill=T)
    # eyes
    d.rectangle([21, 19, 23, 22], fill=K)
    d.rectangle([32, 19, 34, 22], fill=K)
    d.point([(22, 20), (33, 20)], fill=W)  # catchlight
    # muzzle: dark mask with a cream lower jaw
    d.ellipse([22, 23, 33, 33], fill=B, outline=K)
    d.ellipse([24, 28, 31, 33], fill=C)
    d.rectangle([26, 24, 29, 27], fill=K)  # nose
    d.line([(27, 27), (27, 30)], fill=K)
    d.line([(24, 31), (31, 31)], fill=K)  # mouth

    # leather collar between head and chest, one gold tag
    d.line([(19, 34), (36, 34)], fill=PAL["l"])
    d.line([(18, 35), (37, 35)], fill=PAL["l"])
    d.line([(19, 36), (36, 36)], fill=PAL["l"])
    d.point([(27, 35), (28, 35)], fill=G)

    # the small crooked gold crown, one spike bent
    d.polygon([(22, 11), (22, 6), (24, 1), (26, 6), (28, 0), (30, 6),
               (33, 2), (33, 11)], fill=G, outline=K)
    d.line([(22, 11), (33, 11)], fill=K)
    d.point([(24, 8), (28, 7), (32, 8)], fill=GD)

    # fur texture: dither the saddle/tan seams
    px = img.load()
    dither_edge(px, (7, 38, 48, 41), T, S)
    dither_edge(px, (16, 28, 39, 30), T, S)

    stink_wisps(d, [(2, 26), (50, 26), (6, 36), (48, 38)])
    img.save(os.path.join(OUT, "priston_front.png"))


UMLAUTS = {
    # 8x8-Zellen, Gen-1-artige 7-breite Glyphen, Tinte schwarz auf
    # transparent (wie die extrahierten Font-Seiten der Engine)
    "ae": [
        ".x...x..",
        "........",
        ".xxxx...",
        ".....x..",
        ".xxxxx..",
        "x....x..",
        ".xxxxx..",
        "........",
    ],
    "oe": [
        ".x...x..",
        "........",
        ".xxxx...",
        "x....x..",
        "x....x..",
        "x....x..",
        ".xxxx...",
        "........",
    ],
    "ue": [
        ".x...x..",
        "........",
        "x....x..",
        "x....x..",
        "x....x..",
        "x...xx..",
        ".xxx.x..",
        "........",
    ],
    "AE": [
        ".x...x..",
        ".xxxx...",
        "x....x..",
        "x....x..",
        "xxxxxx..",
        "x....x..",
        "x....x..",
        "........",
    ],
    "OE": [
        ".x...x..",
        ".xxxx...",
        "x....x..",
        "x....x..",
        "x....x..",
        "x....x..",
        ".xxxx...",
        "........",
    ],
    "UE": [
        ".x...x..",
        "........",
        "x....x..",
        "x....x..",
        "x....x..",
        "x....x..",
        ".xxxx...",
        "........",
    ],
    "sz": [
        ".xxx....",
        "x...x...",
        "x..x....",
        "x...x...",
        "x....x..",
        "x.x.x...",
        "x..x....",
        "x.......",
    ],
}
UMLAUT_ORDER = ["ae", "oe", "ue", "AE", "OE", "UE", "sz"]


def make_font():
    """56x8: sieben 8x8-Glyphen (ä ö ü Ä Ö Ü ß) als eigene Font-Seite."""
    sheet = Image.new("RGBA", (8 * len(UMLAUT_ORDER), 8), (0, 0, 0, 0))
    px = sheet.load()
    for i, key in enumerate(UMLAUT_ORDER):
        grid = UMLAUTS[key]
        for y, row in enumerate(grid):
            assert len(row) == 8, (key, y)
            for x, ch in enumerate(row):
                if ch == "x":
                    px[i * 8 + x, y] = (0, 0, 0, 255)
    sheet.save(os.path.join(OUT, "priston_font.png"))


def _walker_frame(name):
    idx = {"down": 0, "up": 1, "left": 2}[name]
    return grid_to_image(WALKER_FRAMES[idx])


def make_bike():
    """16x96-Walker: PRISTON auf einem viel zu kleinen Fahrrad.
    Oberkoerper aus dem Lauf-Sheet, Rahmen und Raeder gezeichnet;
    Walk-Frames drehen die Pedale."""
    sheet = Image.new("RGBA", (16, 96), (0, 0, 0, 0))
    for f, (view, pedal) in enumerate([("down", 0), ("up", 0), ("left", 0),
                                       ("down", 1), ("up", 1), ("left", 1)]):
        frame = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(frame)
        src = _walker_frame(view)
        if view in ("down", "up"):
            # nur der Kopf (Reihen 0-8), damit kein Schulter-Kasten entsteht
            frame.paste(src.crop((0, 0, 16, 9)), (0, 0), src.crop((0, 0, 16, 9)))
            # Lenker mit Griffen, Pfoten liegen auf
            d.line([(2, 10), (13, 10)], fill=K)
            d.point([(2, 9), (13, 9)], fill=K)
            d.point([(5, 10), (10, 10)], fill=T)
            # Vorderrad frontal: schmal und hoch, mit Schutzblech-Punkt
            d.ellipse([6, 11, 9, 15], outline=K)
            d.point([(7, 11), (8, 11)], fill=(112, 70, 34, 255))
        else:
            # Seitenansicht: Kopf/Ruecken (Reihen 1-9, Spalten 0-11)
            frame.paste(src.crop((0, 1, 12, 10)), (1, 0), src.crop((0, 1, 12, 10)))
            # Raeder
            d.ellipse([1, 10, 6, 15], outline=K)
            d.ellipse([9, 10, 14, 15], outline=K)
            # Rahmen + Sattelstange
            d.line([(4, 12), (8, 9)], fill=K)
            d.line([(8, 9), (11, 12)], fill=K)
            # Pedale: zwei Stellungen
            if pedal == 0:
                d.point([(7, 12), (8, 13)], fill=K)
            else:
                d.point([(8, 12), (7, 13)], fill=K)
        sheet.paste(frame, (0, f * 16))
    sheet.save(os.path.join(OUT, "priston_bike.png"))


def make_surf():
    """16x96-Walker: PRISTON schwimmt -- Kopf und Ruecken ueber Wasser,
    kleine Gischt; Walk-Frames wechseln die Paddel-Gischt."""
    W1 = (200, 228, 255, 255)
    W2 = (150, 196, 240, 255)
    sheet = Image.new("RGBA", (16, 96), (0, 0, 0, 0))
    for f, (view, phase) in enumerate([("down", 0), ("up", 0), ("left", 0),
                                       ("down", 1), ("up", 1), ("left", 1)]):
        frame = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(frame)
        src = _walker_frame(view)
        if view in ("down", "up"):
            frame.paste(src.crop((0, 0, 16, 9)), (0, 2), src.crop((0, 0, 16, 9)))
            # Ruecken/Rumpf als flache Insel ueber Wasser
            d.ellipse([2, 10, 13, 14], fill=(82, 55, 36, 255), outline=K)
        else:
            frame.paste(src.crop((0, 1, 10, 9)), (2, 1), src.crop((0, 1, 10, 9)))
            d.ellipse([3, 9, 14, 13], fill=(82, 55, 36, 255), outline=K)
        # Wasserlinie + Gischt, zwei Phasen
        y = 14
        for x in range(0, 16, 2):
            off = (x // 2 + phase) % 2
            d.point([(x, y + off), (x + 1, y + off)], fill=W1)
        d.point([(1, 12 + phase), (14, 13 - phase)], fill=W2)
        sheet.paste(frame, (0, f * 16))
    sheet.save(os.path.join(OUT, "priston_surf.png"))


def make_stink():
    """16x64: vier 16x16-Frames aufsteigender gruener Stinkschwaden.
    Zwei Wellenlinien mit Phasenversatz pro Frame; Alpha nimmt nach oben
    ab, damit die Schwaden verwehen."""
    import math
    E1 = (140, 178, 96)
    E2 = (176, 205, 130)
    sheet = Image.new("RGBA", (16, 64), (0, 0, 0, 0))
    px = sheet.load()
    for f in range(4):
        oy = f * 16
        for cx, col, speed in ((4, E1, 1.0), (11, E2, 1.3)):
            for y in range(2, 14):
                x = cx + round(1.6 * math.sin(y / 2.6 + f * math.pi / 2 * speed))
                if 0 <= x < 16:
                    alpha = max(70, 255 - (13 - y) * 16)
                    px[x, oy + y] = (col[0], col[1], col[2], alpha)
    sheet.save(os.path.join(OUT, "priston_stink.png"))


def make_cesar():
    """56x56 Trainer-Pic: CESAR, der grosse weisse Huetehund von nebenan --
    aufgeplustert, Ohren zurueck, Zaehne gebleckt. 4 Graustufen auf
    opakem Weiss wie die extrahierten Trainer-Pics; das SGB-Zonen-Remap
    faerbt ihn dann wie jeden Vanilla-Trainer."""
    L2 = (216, 216, 216, 255)   # helles Fell
    img = Image.new("RGBA", (56, 56), (255, 255, 255, 255))
    d = ImageDraw.Draw(img)

    # maechtiger Fellkoerper
    d.ellipse([4, 24, 51, 55], fill=L2, outline=K)
    # Fell-Zacken am Ruecken (aufgeplustert)
    for x0 in range(6, 48, 6):
        d.polygon([(x0, 28), (x0 + 3, 21), (x0 + 6, 28)], fill=L2, outline=K)
    # Brustwolke
    d.ellipse([18, 34, 37, 55], fill=(240, 240, 240, 255))
    # Kopf, leicht gesenkt (Drohhaltung)
    d.ellipse([14, 8, 41, 32], fill=L2, outline=K)
    # Ohren flach nach hinten
    d.polygon([(15, 14), (6, 10), (16, 22)], fill=L2, outline=K)
    d.polygon([(40, 14), (49, 10), (39, 22)], fill=L2, outline=K)
    # zornige Brauen + enge Augen
    d.line([(20, 15), (26, 18)], fill=K)
    d.line([(35, 15), (29, 18)], fill=K)
    d.rectangle([22, 18, 25, 20], fill=K)
    d.rectangle([30, 18, 33, 20], fill=K)
    # Schnauze mit gebleckten Zaehnen
    d.ellipse([21, 21, 34, 31], fill=(240, 240, 240, 255), outline=K)
    d.rectangle([25, 22, 30, 24], fill=K)          # Nase
    d.line([(22, 27), (33, 27)], fill=K)           # Lefze
    for tx in (23, 26, 29, 32):                    # Zaehne
        d.polygon([(tx, 27), (tx + 1, 29), (tx + 2, 27)], fill=(96, 96, 96, 255))
    # Knurr-Linien
    d.line([(10, 6), (14, 9)], fill=(96, 96, 96, 255))
    d.line([(45, 6), (41, 9)], fill=(96, 96, 96, 255))

    # auf die 4 Graustufen klemmen, Weiss bleibt opak
    px = img.load()
    for y in range(56):
        for x in range(56):
            r = px[x, y][0]
            v = min((255, 216, 96, 0), key=lambda s: abs(s - r))
            if v == 216: v = 176
            px[x, y] = (v, v, v, 255)
    img.save(os.path.join(OUT, "priston_cesar.png"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    make_walker()
    make_back()
    make_front()
    make_stink()
    make_font()
    make_bike()
    make_surf()
    make_cesar()
    print("wrote priston_walk.png, priston_back.png, priston_front.png")
