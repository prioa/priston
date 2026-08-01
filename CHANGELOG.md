# Changelog

## 0.4.0

- Animierte Stinkwolken: 4-Frame-Sheet, im Overworld ueber den
  Post-Zonen-Replay (Gruen ueberlebt die Zonenfaerbung), im Kampf ueber
  battle.overlay -- laeuft auch im 3D-Voxel-Battle.
- Halsband jetzt Leder-Braun mit goldener Marke (statt Trikolore),
  in allen drei Ansichten.
- Gebackene Wisps aus dem Battle-Backpic entfernt (ersetzt durch die
  animierten).

## 0.3.1

- Overworld: weisser Kasten um den trueColor-Walker behoben -- der Sprite
  wird jetzt nach dem SGB-Zonen-Pass in Echtfarbe replayt
  (markSpriteRedraw statt Ganzzellen-Ausnahme; engine_internals).
- TATRA: Vignette und Filmkorn beziehen sich jetzt auf das Spielfeld
  statt auf das Fenster; die Letterbox bleibt schwarz.
- Intro: die Story-Steps zeigen das Portraet ueber den player-Shorthand,
  damit es in Echtfarbe rendert (type=image traegt kein trueColor).

## 0.3.0

- Neu: TATRA -- eine echte Shader-Pipeline (render_pipelines, present-
  Pass): kuehle Weissbalance, S-Kurven-Kontrast, Split-Toning, Vignette
  und Filmkorn als OFF/1/2/3-Ladder. Hotkey 0, Zeile im Options-Menue,
  Persistenz durch die Engine. Kollisionsfrei mit dem DramaticShape-
  Voxel-Mod (Hotkeys 3/5/6/7/8/9).

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
