# Changelog

## 0.13.0

- Der Hofstaat: 31 generische Trainerklassen tragen jetzt Hofaemter
  aus Pristons Koenigreich -- LAUSBUB, KAMMERZOFE, KNAPPE, HOFNARR,
  FALKNER, ZWINGERWART, BADEMEISTER, GLÜCKSRITTER, MINNESÄNGER,
  LEIBGARDIST, ALCHEMIST, TOTENRUFERIN, INTRIGANT (Team Rocket) u.v.m.
  Benannte Figuren (Arenaleiter, Top Vier, Rivale) bleiben unberuehrt.

## 0.12.4

- Hymne klingt jetzt durchgehend: fade=0 fuer beide Stimmen -- vorher
  verklang jede Note nach ~0,3s und der Rest ihres Zeitschlitzes war
  Stille (per WAV-Analyse belegt: 19 Luecken in 20s vs. 0 bei Vanilla;
  nach dem Fix 0). Das war der eigentliche "Musik buggt"-Eindruck.
- Die Euro-Anzeige erscheint erst, nachdem der Frisoer die Aufgabe
  erteilt hat (MOD_PRISTON_QUEST) -- vorher gibt es nichts zu zaehlen.

## 0.12.3

- Hymne sauber neu gesetzt: deklarative Notentabellen in echtem 3/4
  (17 Takte, Couplet-Wiederholung, Fermate), beide Stimmen aus
  denselben Tabellen gebaut. Die Laengengleichheit der Stimmen wird
  beim Laden ERZWUNGEN und im Test geprueft -- der Loop-Drift, der als
  "Musik buggt" hoerbar war (130 vs 104 Einheiten), ist damit
  konstruktiv ausgeschlossen. Neue Option HYMNE (an/aus).
- CESARs Team wird gegen die Basis geprueft und degradiert mit
  Warnung statt die Mod auf exotischen Basen zu reissen.
- Per-Frame-Closures in TATRA/HUD gehoisted (GC-Ruhe).

## 0.12.2

- Stop-and-Go beim Laufen behoben: Der Follower lief bisher ueber die
  Script-Movement-Queue der Engine, die waehrend jeder Hunde-Bewegung
  die Spielereingabe einfriert (Cutscene-Semantik) -- nach jedem
  Schritt stand der Spieler kurz. PRISTON nutzt jetzt die
  Wander-Mechanik der NPCs direkt (blockiert nichts) und holt bei
  Rueckstand im Pikachu-Stil mit halbem Schritt-Takt auf.
  Gemessen: 6 Zellen in 96 Frames Dauerlauf (voll fluessig).

## 0.12.1

- Performance-/Grafikfix im Voxel-Modus: TATRA pausiert automatisch,
  solange eine World-Pipeline (Voxel-Diorama) rendert -- vorher
  halbierte der Vollfenster-Present-Pass die Framerate (gemessen
  18 statt 56 FPS: Stop-and-Go beim Laufen, stotternde Musik) und die
  Playfield-Maske lag als heller Kasten ueber dem 3D-Bild. Im
  klassischen 2D-Modus arbeitet TATRA unveraendert.

## 0.12.0

- PRISTONs Grafiken werden jetzt aus der offiziellen Referenz
  abgeleitet (tools/ref/idle8.gif, 8-Richtungen-Idle vom Mod-Autor):
  Walker (vorn/hinten/seitlich), Kampf-Rueckenansicht und Portraet
  samt GB-Fassung entstehen per Komponentenfilter, Skalierung und
  Palettenquantisierung direkt aus der Vorlage -- schwarzer Mantel,
  sattes Tan, gruenes Halsband, Krone obendrauf.

## 0.11.0

- Euro-Wirtschaft: Trainer-Siege +5 Euro, wilde Siege +1 (Demos zaehlen
  nicht); Stand permanent oben rechts im GB-Font (eigenes Euro-Glyph
  auf der Font-Seite). Der Frisoertermin kostet 100 Euro -- der Frisoer
  prueft und kassiert ueber eigene Script-Verben, neue Dialogzweige
  fuer "zu arm" samt Kontostand-Token.
- Robust gegen den endFrame-Bug des DramaticShape-Mods (verschluckter
  Viewport): die HUD-Geometrie wird notfalls selbst aus dem Renderer
  abgeleitet.

## 0.10.0

- Walker-Seitenansicht komplett neu: gleiche Masse wie Front- und
  Rueckansicht (hoher Ruecken, Haengebauch, Ringelrute, drei Laeufe) --
  der Hund wirkt aus jeder Richtung gleich gross.
- Stinkwolken deutlich sichtbarer: doppelt so breit, kraeftigeres
  Gruen, hoehere Deckkraft.
- Bell-Effekt: PRISTON ansprechen (A) spielt sein WUFF (Cry) und
  zeigt eine Freude-Blase; Event mod.priston.wuff fuer andere Mods.

## 0.9.2

- Follower-Fix: beim Rueckkehren auf eine gecachte Map (Haus rein/raus,
  Warp) blieb der alte Laufzeit-Priston stehen und verdoppelte sich --
  Altbestaende werden jetzt vor dem Respawn entfernt.
- Kompatibilitaet verifiziert: Follower + Wisps unter SGB, RED++ und
  OG RED; im Voxel-Overworld rendert der Follower als Billboard in
  korrekten Farben (Wisps zeichnet der 3D-Weltpass nicht -- bekannt).

## 0.9.1

- Portraet-Rework v3: Token-Master-Architektur -- Farb- und GB-Fassung
  entstehen aus demselben semantischen Raster, die Silhouetten-Outline
  wird automatisch nachgezogen. Keine Quantisierungs-Flecken mehr im
  Intro; Schattierung als saubere Cel-Flaechen mit Dither-Grenzen.

## 0.9.0

- Grosser Umbau: Man spielt wieder den normalen Trainer -- PRISTON ist
  jetzt das HAUSTIER und laeuft als Follower neben dem Spieler her
  (Laufzeit-NPC, folgt Zelle fuer Zelle, Durchtreten erlaubt, spawnt
  pro Map neu). Player-Sprites/-Pics sind wieder Vanilla.
- Grafik-Rework im Gen-1-Stil: neues Priston-Portraet (3/4-Sitzpose,
  echte Schnauze, Zehen, Cel-Shading) samt GB-Graustufen-Variante
  fuers Intro (wird wie Vanilla-Pics palettengetoent), neues
  CESAR-Portraet (Drohhaltung, Nackenkamm, gebleckte Zaehne).
- Story auf Haustier-Perspektive umgeschrieben (STORY.md-Kanon v3):
  CESAR ist der Hund des Rivalen; der Brief adressiert den Spieler
  als Halter; PRISTON bleibt in beiden Enden beim Spieler.
- Stink-Aura erschreckt den eigenen Hund nicht mehr.

## 0.8.0

- Komplette Story-Ueberarbeitung aus einem Guss (Kanon in STORY.md):
  Eich stellt weiter die Pokemon-Welt vor -- sein neuer Trainer ist
  dieses Jahr ein Hund. Der Bezirk Moedling heisst bei den
  Einheimischen "Kanto". CESAR ist jetzt DER Rivale des
  Originalspiels: er zieht selbst als Trainer los, um Priston
  scheitern zu sehen (erklaert alle Vanilla-Rivalenkaempfe), und
  sein Finale-Motiv ist die Blamage, jahrelang einen echten KOENIG
  angebellt zu haben.
- Der Frisoerbesuch ist das Zentrum der Quest (das Vollprogramm nur
  eine Randnotiz); der versiegelte Umschlag mit dem KOENIGSSIEGEL
  liegt dem Brief des Hofes bei.
- Der Gestank hat jetzt eine Kanon-Ursache: ganz Kanto maestet
  Priston -- er schwitzt laengst Leckerli (RENE spricht es aus).
- Schlusswahl umbenannt: ZUM HOF / BLEIBEN.

## 0.7.1

- mod.card: Rivalen-Eintrag auf CESAR aktualisiert, Quest-Maps gelistet.

## 0.7.0

- Story-Quest "Die Ehre zurück": Der Hof gewährt das VOLLPROGRAMM beim
  Hundefrisör zu MÖDLING (Pallet Town). Lavendelwasser bei RENE in
  WR. NEUDORF (Lavender) holen -- samt Leckerli-Mast --, Kräuterseife
  bei NICI in GAADEN (Viridian), FLORIAN zockt derweil oben im
  Kinderzimmer. Finale: Trainerkampf gegen CESAR (Growlithe/Arcanine)
  mit eigenem Porträt, Belohnung KÖNIGSSIEGEL und der Wahl: zurück an
  den Hof oder bleiben in Kanto (landet in mod.save.entscheidung).
- Intro umgestellt: der Rivale ist jetzt CESAR, der große weiße
  Hütehund aus dem Nachbarhaus.
- Ortsschilder benennen MÖDLING, WR. NEUDORF und GAADEN.

## 0.6.0

- STINK-AURA (Option, standardmaessig an): ~3 von 8 wilden Begegnungen
  verweht der Gestank (encounter.roll), und NPCs, an denen PRISTON
  vorbeilaeuft, reagieren mit einer abbrechbaren Schreckblase -- einmal
  pro NPC und Map-Besuch, mit Cooldown. Option aus = exakt Vanilla.

## 0.5.0

- Echte Umlaute: eigene Font-Seite (ä ö ü Ä Ö Ü ß, Basis 0x120) plus
  Intro-Texte mit richtiger Schreibung (SCHÄFERHUND, KÖNIGSHOF, ...).
- PRISTON faehrt Rad und schwimmt: eigene 6-Frame-Walker fuer
  playerSprites.bike und .surf (fly bleibt der Vanilla-Vogel).
- "Nad Tatrou sa blyska" (Volksweise, gemeinfrei) als eigenes
  ChipAsm-Arrangement -- Pallet Town spielt jetzt PRISTONs Heimweh.
- Stinkwolken steigen auch beim Radfahren und Schwimmen auf.

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
