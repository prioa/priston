# Priston

Du spielst PRISTON — einen uebergewichtigen Schaeferhund, der aus dem
Koenigshaus der Slowakei verbannt wurde, weil er zu sehr stinkt. Der Mod
ersetzt Laufsprite, Battle-Backpic und Trainer-Portrait des Spielers und
erzaehlt die Verbannungs-Geschichte in Prof. Eichs Intro auf Deutsch.

## Ausprobieren

```sh
# im gen1recomp-Checkout, mit diesem Repo als mods/priston eingehaengt:
python3 tools/modkit.py validate mods/priston
python3 tools/modkit.py lint mods/priston
POKEPORT_DEV=1 love .        # F10: Mod-Manager, priston aktivieren, NEW GAME
```

## Was drin ist

- `SPRITE_PRISTON`: eigenes 6-Frame-Walker-Sheet (watschelnder Gang) in
  GBA-Farben mit echtem Alpha (`trueColor`, kein Graustufen-Remap)
- `field.playerPics`: Rueckenansicht im Kampf + Portrait (Intro, Trainer
  Card, Ruhmeshalle) -- Schaeferhund-Farben, Trikolore-Halsband, schiefe
  Goldkrone, gruene Stinkschwaden
- Option **SLOWAKEI-LOOK** (standardmaessig an): kuehles Tatra-Color-
  Grading aller Map-Paletten ueber den `map.palette`-Hook; Vanilla-
  Paletten bleiben unangetastet
- Deutsches Intro: vier neue Story-Steps (Hof, Verbannung, Ehrenschwur als
  Ja/Nein-Frage, Antwort landet in `mod.save`), Rivale = GASTON, der neue
  Liebling des Hofes
- Cry `PRISTON`: ein tiefes Chip-Wuff (ChipAsm, original)

## Assets

Alle Grafiken sind Originalarbeit und werden von `tools/make_assets.py`
generiert (Python 3 + Pillow). Es sind keine ROM-Daten enthalten.

```sh
python3 tools/make_assets.py
```
