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

# ---------------------------------------------------------------- Referenz
# Der Kanon-Charakter kommt aus tools/ref/idle8.gif (8-Richtungen-Idle,
# vom Autor der Mod geliefert). Abgeleitet wird per: groesste zusammen-
# haengende Komponente (entfernt Herzchen/Stinkkringel/Fliegen), Bounding-
# Box, LANCZOS-Skalierung, Quantisierung auf die Referenzpalette.

REF_PAL = [
    (10, 8, 8),      # Outline
    (45, 44, 42),    # schwarzer Mantel
    (58, 47, 37),    # tiefes Braun
    (134, 86, 55),   # Braun-Schatten
    (195, 128, 65),  # Tan
    (206, 154, 93),  # helles Tan
    (118, 140, 82),  # Halsband-Gruen
]
REF_GB = {
    (10, 8, 8): 30, (58, 47, 37): 30,
    (45, 44, 42): 90, (134, 86, 55): 90,
    (195, 128, 65): 170, (118, 140, 82): 170,
    (206, 154, 93): 240,
}

_ref_cache = None


def _ref_frames():
    global _ref_cache
    if _ref_cache is None:
        from PIL import ImageSequence
        gif = Image.open(os.path.join(os.path.dirname(__file__),
                                      "ref", "idle8.gif"))
        _ref_cache = [f.convert("RGBA") for f in ImageSequence.Iterator(gif)]
    return _ref_cache


def _largest_component(img, athr=128):
    w, h = img.size
    px = img.load()
    seen = [[False] * h for _ in range(w)]
    best = []
    for sx in range(w):
        for sy in range(h):
            if seen[sx][sy] or px[sx, sy][3] <= athr:
                continue
            comp, stack = [], [(sx, sy)]
            seen[sx][sy] = True
            while stack:
                x, y = stack.pop()
                comp.append((x, y))
                for nx in (x - 1, x, x + 1):
                    for ny in (y - 1, y, y + 1):
                        if 0 <= nx < w and 0 <= ny < h \
                           and not seen[nx][ny] and px[nx, ny][3] > athr:
                            seen[nx][ny] = True
                            stack.append((nx, ny))
            if len(comp) > len(best):
                best = comp
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    opx = out.load()
    for x, y in best:
        opx[x, y] = px[x, y]
    return out


def _derive(frame_idx, box_w, box_h):
    src = _largest_component(_ref_frames()[frame_idx])
    # angedockte Stinkkringel-Reste: Gruen oberhalb der Koerpermitte weg
    # (das gruene HALSBAND sitzt unten und bleibt unberuehrt)
    bb = src.getbbox()
    spx = src.load()
    for y in range(bb[1], bb[1] + (bb[3] - bb[1]) // 2):
        for x in range(bb[0], bb[2]):
            r, g, b, a = spx[x, y]
            if a > 0 and g > r + 12 and g > b + 20:
                spx[x, y] = (0, 0, 0, 0)
    src = src.crop(src.getbbox())
    scale = min(box_w / src.width, box_h / src.height)
    nw = max(1, round(src.width * scale))
    nh = max(1, round(src.height * scale))
    img = src.resize((nw, nh), Image.LANCZOS)
    out = Image.new("RGBA", (box_w, box_h), (0, 0, 0, 0))
    out.paste(img, ((box_w - nw) // 2, box_h - nh), img)
    px = out.load()
    for y in range(box_h):
        for x in range(box_w):
            r, g, b, a = px[x, y]
            if a < 110:
                px[x, y] = (0, 0, 0, 0)
                continue
            c = min(REF_PAL,
                    key=lambda p: (p[0] - r) ** 2 + (p[1] - g) ** 2
                                  + (p[2] - b) ** 2)
            px[x, y] = c + (255,)
    return out


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

# Left = Seitenansicht mit derselben Masse wie die Front-/Rueckansicht:
# hoher Ruecken, dicker Haengebauch, Schnauze vorn, Ringelrute hinten.
LEFT_STAND = [
    "................",
    "...kk......k....",
    "..ksk.....ksk...",
    ".kstsk....ksk...",
    ".ksttskkkkssk...",
    "kktkttssssssk...",
    "kksttttsssssck..",
    ".ksttttsssssssk.",
    ".kcttttttttsssk.",
    ".kcctttttttttsk.",
    ".kccttttttttttk.",
    "..kcttttttttttk.",
    "..kttttttttttk..",
    "..ktk..ktk.ktk..",
    "..kkk..kkk.kkk..",
    "................",
]

LEFT_WALK = LEFT_STAND[:13] + [
    ".ktk...ktk..ktk.",
    ".kkk...kkk..kkk.",
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
    """16x96-Walker aus der Referenz: Frames 0/4/6 (vorn/hinten/links),
    Walk-Phase = 1px-Bob (Beine tucken), rechts spiegelt die Engine."""
    sheet = Image.new("RGBA", (16, 96), (0, 0, 0, 0))
    stands = {
        0: _derive(0, 16, 15),   # down
        1: _derive(4, 16, 15),   # up
        2: _derive(6, 16, 15),   # left
    }
    for slot, frame in stands.items():
        cell = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        cell.paste(frame, (0, 1), frame)
        sheet.paste(cell, (0, slot * 16))
        walk = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        walk.paste(frame, (0, 0), frame)          # 1px hoeher = Schritt
        sheet.paste(walk, (0, (slot + 3) * 16))
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
    """32x32-Kampf-Rueckenansicht aus der Referenz (Frame 4)."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    dog = _derive(4, 30, 30)
    img.paste(dog, (1, 2), dog)
    img.save(os.path.join(OUT, "priston_back.png"))


# ------------------------------------------------------------- front pic

# Token-Raster: das Portraet wird EINMAL mit semantischen Tonwerten
# gezeichnet; Farb- und GB-Version entstehen aus demselben Master, die
# Silhouetten-Outline wird automatisch nachgezogen. So gibt es keine
# Quantisierungs-Flecken und beide Fassungen bleiben deckungsgleich.
_T_EMPTY, _T_OUT, _T_TAN, _T_TAND, _T_CREAM, _T_CREAMD = 0, 1, 2, 3, 4, 5
_T_SAD, _T_SADD, _T_PINK, _T_GOLD, _T_GOLDD, _T_EYEW, _T_TANL = 6, 7, 8, 9, 10, 11, 12

_FRONT_COLORS = {
    _T_OUT: (30, 22, 16, 255),
    _T_TAN: (201, 144, 80, 255),
    _T_TAND: (156, 101, 53, 255),
    _T_CREAM: (238, 214, 171, 255),
    _T_CREAMD: (204, 172, 124, 255),
    _T_SAD: (94, 64, 40, 255),
    _T_SADD: (62, 42, 28, 255),
    _T_PINK: (208, 136, 128, 255),
    _T_GOLD: (236, 190, 64, 255),
    _T_GOLDD: (170, 126, 34, 255),
    _T_EYEW: (250, 250, 250, 255),
    _T_TANL: (224, 174, 112, 255),
}
_FRONT_GB = {
    _T_OUT: 30, _T_SADD: 30,
    _T_SAD: 90, _T_TAND: 90, _T_GOLDD: 90, _T_CREAMD: 90,
    _T_TAN: 170, _T_GOLD: 170, _T_PINK: 170,
    _T_CREAM: 240, _T_EYEW: 240, _T_TANL: 240,
}


def _add_crown(img, gold=(236, 190, 64, 255), dark=(170, 126, 34, 255),
               outline=(10, 8, 8, 255)):
    """Kleine schiefe Krone auf den hoechsten Kopfpunkt setzen."""
    d = ImageDraw.Draw(img)
    px = img.load()
    w, h = img.size
    top, cx = None, w // 2
    for y in range(h):
        for x in range(w // 2 - w // 6, w // 2 + w // 6):
            if px[x, y][3] > 0:
                top, cx = y, x
                break
        if top is not None:
            break
    if top is None:
        return img
    base = max(6, top + 1)
    x0 = cx - 1
    d.polygon([(x0, base), (x0, base - 4), (x0 + 2, base - 6), (x0 + 4, base - 3),
               (x0 + 6, base - 7), (x0 + 8, base - 3), (x0 + 10, base - 5),
               (x0 + 10, base)], fill=gold, outline=outline)
    d.line([(x0, base), (x0 + 10, base)], fill=outline)
    d.point([(x0 + 3, base - 3), (x0 + 7, base - 4)], fill=dark)
    return img


def make_front():
    """56x56-Portraet direkt aus der Referenz (Frame 0), plus Krone."""
    img = Image.new("RGBA", (56, 56), (0, 0, 0, 0))
    dog = _derive(0, 52, 48)
    img.paste(dog, (2, 8), dog)
    _add_crown(img)
    img.save(os.path.join(OUT, "priston_front.png"))


def make_front_gb():
    """GB-Fassung: expliziter LUT von Referenzpalette auf 4 Stufen."""
    src = Image.open(os.path.join(OUT, "priston_front.png")).convert("RGBA")
    img = Image.new("RGBA", (56, 56), (0, 0, 0, 0))
    spx, px = src.load(), img.load()
    extra = { (236, 190, 64): 170, (170, 126, 34): 90 }
    for y in range(56):
        for x in range(56):
            r, g, b, a = spx[x, y]
            if a == 0:
                continue
            v = REF_GB.get((r, g, b)) or extra.get((r, g, b))
            if v is None:
                luma = 0.299 * r + 0.587 * g + 0.114 * b
                v = 240 if luma > 200 else 170 if luma > 120 \
                    else 90 if luma > 55 else 30
            px[x, y] = (v, v, v, 255)
    img.save(os.path.join(OUT, "priston_front_gb.png"))


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
    "euro": [
        "..xxxx..",
        ".x......",
        "xxxx....",
        ".x......",
        "xxxx....",
        ".x......",
        "..xxxx..",
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
UMLAUT_ORDER = ["ae", "oe", "ue", "AE", "OE", "UE", "sz", "euro"]


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
    E1 = (110, 200, 70)
    E2 = (160, 230, 110)
    sheet = Image.new("RGBA", (16, 64), (0, 0, 0, 0))
    px = sheet.load()
    for f in range(4):
        oy = f * 16
        for cx, col, speed in ((4, E1, 1.0), (11, E2, 1.3)):
            for y in range(1, 14):
                x = cx + round(1.6 * math.sin(y / 2.6 + f * math.pi / 2 * speed))
                alpha = max(140, 255 - (13 - y) * 12)
                for xx in (x, x + 1):
                    if 0 <= xx < 16:
                        px[xx, oy + y] = (col[0], col[1], col[2], alpha)
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
