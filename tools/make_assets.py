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
    """56x56 Portraet im Gen-1-Stil: PRISTON sitzt in 3/4-Pose -- echte
    Schnauze, Brustwolle mit Fellkante, Pfoten mit Zehen, Sattel mit
    gezackter Grenze, Cel-Shading (Basis/Schatten/Licht), Krone."""
    KO = (30, 22, 16, 255)
    T = (201, 144, 80, 255)
    TS = (156, 101, 53, 255)
    C = (238, 214, 171, 255)
    CS = (204, 172, 124, 255)
    S = (94, 64, 40, 255)
    SD = (62, 42, 28, 255)
    PK = (208, 136, 128, 255)
    GO = (236, 190, 64, 255)
    GD2 = (170, 126, 34, 255)
    WH = (250, 250, 250, 255)

    img = Image.new("RGBA", (56, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Hinterlaeufe/Haunch rechts (er sitzt leicht nach rechts gedreht)
    d.ellipse([30, 33, 54, 55], fill=T, outline=KO)
    d.arc([30, 33, 54, 55], 100, 200, fill=TS)
    d.line([(38, 44), (35, 52)], fill=TS)
    d.ellipse([42, 49, 53, 55], fill=T, outline=KO)
    d.line([(46, 51), (46, 54)], fill=TS)
    d.line([(49, 51), (49, 54)], fill=TS)

    # Rute: kringelt links hinter dem Koerper hervor
    d.ellipse([1, 42, 14, 52], fill=S, outline=KO)
    d.ellipse([2, 44, 9, 50], fill=T)
    # Bauch/Rumpf
    d.ellipse([6, 29, 45, 55], fill=T, outline=KO)
    # Brust-/Halswolle: Creme mit gezackter Fellkante
    d.polygon([(14, 30), (20, 26), (28, 25), (34, 28), (36, 34),
               (35, 42), (30, 50), (24, 53), (18, 50), (13, 42)],
              fill=C, outline=KO)
    for zx, zy in ((14, 36), (16, 44), (33, 38), (31, 46)):
        d.polygon([(zx, zy), (zx + 2, zy + 3), (zx - 1, zy + 3)], fill=C)
    d.arc([13, 32, 35, 52], 40, 140, fill=CS)

    # Vorderlaeufe mit Zehen
    d.rectangle([16, 40, 22, 54], fill=C, outline=KO)
    d.rectangle([26, 41, 32, 55], fill=C, outline=KO)
    d.line([(18, 51), (18, 54)], fill=CS)
    d.line([(20, 51), (20, 54)], fill=CS)
    d.line([(28, 52), (28, 55)], fill=CS)
    d.line([(30, 52), (30, 55)], fill=CS)
    d.arc([16, 40, 22, 54], 90, 200, fill=CS)

    # Ohren
    d.polygon([(15, 16), (10, 1), (24, 9)], fill=S, outline=KO)
    d.polygon([(16, 13), (13, 5), (21, 10)], fill=PK)
    d.polygon([(38, 16), (44, 1), (30, 9)], fill=S, outline=KO)
    d.polygon([(37, 13), (41, 5), (33, 10)], fill=PK)
    d.line([(17, 15), (15, 18)], fill=KO)
    d.line([(36, 15), (38, 18)], fill=KO)

    # Kopf
    d.ellipse([13, 8, 41, 32], fill=T, outline=KO)
    # Sattel-/Maskenzone oben mit gezackter Grenze
    d.polygon([(14, 20), (14, 13), (20, 8), (34, 8), (40, 13), (40, 20),
               (36, 18), (32, 21), (27, 18), (22, 21), (18, 18)],
              fill=S)
    d.line([(15, 12), (20, 9)], fill=SD)
    # Augenbrauen-Punkte
    d.rectangle([19, 15, 22, 16], fill=T)
    d.rectangle([32, 15, 35, 16], fill=T)
    # Augen mit Glanzlicht
    d.rectangle([20, 18, 23, 22], fill=KO)
    d.rectangle([31, 18, 34, 22], fill=KO)
    d.point([(21, 19), (32, 19)], fill=WH)
    d.point([(22, 20), (33, 20)], fill=(120, 90, 60, 255))

    # Schnauze mit Nasenruecken und Lefzen
    d.ellipse([20, 22, 34, 34], fill=T, outline=KO)
    d.polygon([(24, 23), (30, 23), (29, 28), (25, 28)], fill=TS)
    d.ellipse([22, 27, 32, 34], fill=C, outline=KO)
    d.rectangle([25, 24, 29, 27], fill=KO)
    d.point([(26, 25)], fill=(90, 70, 60, 255))
    d.line([(27, 27), (27, 30)], fill=KO)
    d.arc([23, 27, 31, 33], 20, 160, fill=KO)
    d.point([(21, 30), (33, 30)], fill=TS)

    # Krone
    d.polygon([(23, 7), (23, 2), (25, 0), (27, 3), (29, 0), (31, 3),
               (33, 1), (33, 7)], fill=GO, outline=KO)
    d.line([(23, 7), (33, 7)], fill=KO)
    d.point([(25, 4), (28, 3), (31, 4)], fill=GD2)

    # Schattenkante + Kopf-Highlight
    d.arc([6, 29, 45, 55], 110, 200, fill=TS)
    d.arc([13, 8, 41, 32], 300, 340, fill=(224, 174, 112, 255))

    stink_wisps(d, [(3, 26), (50, 28)])

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
    """56x56 Trainer-Pic im Gen-1-Stil: CESAR breitbeinig in
    3/4-Drohhaltung -- EIN solider Koerperumriss, Nackenkamm auf der
    Rueckenlinie, gesenkter Kopf mit gebleckten Zaehnen, tiefe Rute."""
    BG = (255, 255, 255, 255)
    W = (240, 240, 240, 255)
    LS = (170, 170, 170, 255)
    MD = (90, 90, 90, 255)
    KO = (30, 30, 30, 255)

    img = Image.new("RGBA", (56, 56), BG)
    d = ImageDraw.Draw(img)

    # Rute: tief und buschig hinter der Hinterhand
    d.polygon([(6, 36), (0, 40), (1, 47), (8, 45)], fill=W, outline=KO)
    d.line([(4, 41), (6, 43)], fill=LS)

    # EIN solider Koerper (Hinterhand bis Brust)
    d.ellipse([3, 22, 49, 53], fill=W, outline=KO)
    # Nackenkamm: Zacken direkt auf der oberen Koerperkante
    for x0, ytop in ((8, 27), (14, 24), (20, 22), (26, 21)):
        d.polygon([(x0, ytop + 6), (x0 + 3, ytop - 2), (x0 + 6, ytop + 5)],
                  fill=W, outline=KO)
    # Kammbasis wieder schliessen (Fell verdeckt die Ellipsenlinie)
    d.line([(9, 28), (32, 24)], fill=W)
    # Schattierung
    d.arc([3, 22, 49, 53], 100, 210, fill=LS)
    d.line([(14, 36), (11, 46)], fill=LS)          # Haunch-Falte

    # Beine: breitbeinig, mit Zehen
    d.rectangle([8, 46, 15, 55], fill=W, outline=KO)
    d.rectangle([21, 44, 28, 55], fill=W, outline=KO)
    d.rectangle([35, 45, 42, 55], fill=W, outline=KO)
    for lx in (10, 12): d.line([(lx, 52), (lx, 55)], fill=LS)
    for lx in (23, 25): d.line([(lx, 51), (lx, 55)], fill=LS)
    for lx in (37, 39): d.line([(lx, 52), (lx, 55)], fill=LS)

    # Ohren flach angelegt
    d.polygon([(29, 14), (21, 5), (33, 9)], fill=W, outline=KO)
    d.polygon([(29, 13), (25, 8), (31, 10)], fill=MD)
    d.polygon([(48, 15), (55, 7), (44, 10)], fill=W, outline=KO)
    d.polygon([(47, 14), (51, 9), (45, 11)], fill=MD)

    # Kopf: gesenkt, vorn rechts, klar VOR dem Koerper
    d.ellipse([25, 9, 51, 33], fill=W, outline=KO)
    d.arc([25, 9, 51, 33], 130, 220, fill=LS)
    # Brauen + Augen
    d.line([(30, 16), (36, 19)], fill=KO)
    d.line([(46, 15), (40, 18)], fill=KO)
    d.rectangle([32, 19, 35, 21], fill=KO)
    d.rectangle([41, 18, 44, 20], fill=KO)
    d.point([(33, 20), (42, 19)], fill=W)

    # Schnauze mit offenem Maul + Zahnreihe
    d.ellipse([35, 21, 54, 34], fill=W, outline=KO)
    d.polygon([(51, 23), (54, 25), (54, 29), (50, 28)], fill=KO)
    d.line([(39, 26), (50, 27)], fill=LS)
    d.polygon([(37, 29), (52, 30), (50, 35), (38, 33)], fill=MD, outline=KO)
    for tx in range(39, 49, 3):
        d.polygon([(tx, 30), (tx + 1, 33), (tx + 2, 30)], fill=W)
    d.line([(36, 24), (40, 25)], fill=LS)

    img.save(os.path.join(OUT, "priston_cesar.png"))


def make_front_gb():
    """Graustufen-Variante des Portraets fuer Eichs Intro: die Engine
    toent Intro-Pics ueber die SGB-Palette (wie Oaks eigenes Bild), also
    liefern wir 4 Remap-sichere Stufen (240/170/90/30) statt Farbe."""
    src = Image.open(os.path.join(OUT, "priston_front.png")).convert("RGBA")
    img = Image.new("RGBA", (56, 56), (0, 0, 0, 0))
    spx, px = src.load(), img.load()
    for y in range(56):
        for x in range(56):
            r, g, b, a = spx[x, y]
            if a == 0:
                continue
            luma = 0.299 * r + 0.587 * g + 0.114 * b
            if luma > 200: v = 240
            elif luma > 130: v = 170
            elif luma > 60: v = 90
            else: v = 30
            px[x, y] = (v, v, v, 255)
    img.save(os.path.join(OUT, "priston_front_gb.png"))


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
    make_front_gb()
    print("wrote priston_walk.png, priston_back.png, priston_front.png")
