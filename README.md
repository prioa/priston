# Priston

Dein Haustier PRISTON — ein übergewichtiger Schäferhund, der wegen
seines Gestanks aus dem Königshaus der Slowakei verbannt wurde — läuft
als Follower neben dir her. Prof. Eichs Intro erzählt seine Geschichte
auf Deutsch, eine Quest führt zum Hundefrisör nach Mödling, und CESAR,
der Hund deines Rivalen, bellt ihn dabei unermüdlich an.

## Ausprobieren

```sh
# im gen1recomp-Checkout, mit diesem Repo als mods/priston:
python3 tools/modkit.py validate mods/priston
POKEPORT_DEV=1 love .        # F10: Mod-Manager, priston aktivieren, NEW GAME
```

## Was drin ist

- **Follower:** PRISTON (eigenes trueColor-Walker-Sheet mit echtem
  Alpha) folgt dem Spieler Zelle für Zelle, mit animierten
  Stinkschwaden; man kann durch ihn hindurchtreten
- **Deutsches Intro** mit echten Umlauten (eigene Font-Seite) und
  GB-getöntem Porträt: Herkunft, Verbannung, Ankunft — und CESAR
- **Quest "Die Ehre zurück":** Frisörtermin in MÖDLING (Pallet Town),
  Lavendelwasser bei RENE in WR. NEUDORF, Kräuterseife bei NICI in
  GAADEN, FLORIAN-Cameo, Finale gegen CESAR (eigenes Trainer-Porträt),
  KÖNIGSSIEGEL und die Wahl ZUM HOF / BLEIBEN — der Kanon steht in
  STORY.md
- **STINK-AURA** (Option): wilde Pokemon fliehen teils vor dem Geruch,
  NPCs bekommen Schreckblasen
- **SLOWAKEI-LOOK** (Option): kühles Tatra-Grading aller Map-Paletten
- **TATRA** (Shader-Pipeline, Hotkey 0): Grading, Vignette, Filmkorn
- **"Nad Tatrou sa blýska"** (Volksweise, eigenes ChipAsm-Arrangement)
  als Thema von Pallet Town

## Assets

Alle Grafiken sind Originalarbeit und werden von `tools/make_assets.py`
generiert (Python 3 + Pillow). Es sind keine ROM-Daten enthalten.
