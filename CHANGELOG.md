# Changelog

## 0.2.1

- Crashfix: SLOWAKEI-LOOK-Paletten in der Rohform ({{r,g,b}x4}) statt der
  v2-colors-Form registrieren -- PaletteFX.sendColors indiziert numerisch
  und stuerzte sonst beim ersten Frame ab.

## 0.2.0

- Komplett ueberarbeitete Grafiken: GBA-Farben (Schaeferhund-Tan,
  Sattel-Braun, schwarze Schnauzen-Maske) mit echtem Alpha statt
  Weiss-Keying; trueColor nimmt sie vom 4-Graustufen-Remap aus.
- Slowakisches Trikolore-Halsband, goldene Krone, gruene Stinkschwaden.
- Neu: SLOWAKEI-LOOK (Option, standardmaessig an) -- alle Map-Paletten
  bekommen ein kuehles Tatra-Color-Grading ueber den map.palette-Hook.

## 0.1.0

- Erstversion: PRISTON als spielbarer Charakter (Walker-Sheet,
  Battle-Backpic, Portrait), deutsches Verbannungs-Intro mit
  Ehrenschwur, eigener Cry, Namensvorschlaege PRISTON/GASTON.
