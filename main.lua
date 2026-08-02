-- priston: Dein Haustier PRISTON -- ein uebergewichtiger Schaeferhund,
-- verbannt aus dem Koenigshaus der Slowakei, weil er zu sehr stinkt --
-- laeuft als Follower neben dem Spieler her. Prof. Eichs Intro erzaehlt
-- seine Geschichte, eine Quest fuehrt zum Hundefrisoer nach Moedling.
--
-- Alle Pixel sind Originalarbeit aus tools/make_assets.py; es werden keine
-- ROM-Daten ausgeliefert.
return function(mod)
  local walk = mod.path .. "/assets/priston_walk.png"
  local frontGb = mod.path .. "/assets/priston_front_gb.png"

  -- ------- der Hund selbst: Walker-Sheet fuer den Follower
  -- trueColor: das PNG bringt echte GBA-Farben und echtes Alpha mit;
  -- das Flag nimmt es vom 4-Graustufen-Remap der Engine aus

  mod.content.sprites:register("SPRITE_PRISTON", {
    id = "SPRITE_PRISTON",
    image = walk,
    frames = 6,
    walker = true,
    trueColor = true,
  })

  -- ------- echte Umlaute: eigene Font-Seite oberhalb der Vanilla-Codes
  -- (Basis 0x120; die Kana-Beispielseite der Doku liegt bei 0x100)
  mod.content.font:register("priston_umlauts", {
    image = mod.path .. "/assets/priston_font.png",
    base = 0x120,
    glyphsPerRow = 8,
    charmap = {
      { seq = "\195\164", code = 0x120 },  -- ae
      { seq = "\195\182", code = 0x121 },  -- oe
      { seq = "\195\188", code = 0x122 },  -- ue
      { seq = "\195\132", code = 0x123 },  -- AE
      { seq = "\195\150", code = 0x124 },  -- OE
      { seq = "\195\156", code = 0x125 },  -- UE
      { seq = "\195\159", code = 0x126 },  -- sz
      { seq = "\226\130\172", code = 0x127 },  -- Euro
    },
  })

  -- ------- die Hymne: "Nad Tatrou sa blyska" fuer Pallet Town
  -- Volksweise (gemeinfrei), eigenes Arrangement in hymna.lua; mod:read +
  -- load haelt sie durch das Loader-Dateisystem addressierbar (Jukebox-
  -- Muster), damit die installierte Mod identisch laeuft wie im Repo.
  local hymnaSource = mod:read("hymna.lua")
  if hymnaSource then
    local chunk, hymnaErr = load(hymnaSource, "@" .. mod.path .. "/hymna.lua")
    local okSong, song = false, nil
    if chunk then okSong, song = pcall(chunk) end
    if okSong and type(song) == "table" and song.meta
       and song.meta.melodie ~= song.meta.bass then
      mod.log:error("Hymne: Stimmen ungleich lang (%d vs %d) -- "
        .. "Registrierung verweigert, Pallet Town behaelt sein "
        .. "Vanilla-Thema", song.meta.melodie, song.meta.bass)
      okSong = false
    end
    if okSong and type(song) == "table" and song.song then
      mod.content.music:register("Music_PristonHymna", song.song)
      mod.hooks:wrap("music.select", function(next, chosen, ctx)
        if ctx and ctx.reason == "map" and ctx.mapId == "PALLET_TOWN"
           and mod.options:get("hymne") then
          return next("Music_PristonHymna", ctx)
        end
        return next(chosen, ctx)
      end)
    else
      mod.log:warn("hymna.lua baut nicht (%s) -- Pallet Town behaelt sein "
        .. "Vanilla-Thema", tostring(song or hymnaErr))
    end
  else
    mod.log:warn("hymna.lua fehlt im Mod-Ordner -- Pallet Town behaelt "
      .. "sein Vanilla-Thema")
  end

  -- ------- animierte Stinkwolken
  -- 4-Frame-Sheet (assets/priston_stink.png); Overworld zeichnet sie ueber
  -- den Post-Zonen-Replay (echte Farben), der Kampf ueber battle.overlay.

  local STINK = { image = nil, quads = nil }

  local function stinkFrame()
    local t = 0
    pcall(function() t = love.timer.getTime() end)
    return math.floor(t * 5) % 4
  end

  local function stinkImage()
    if STINK.image == nil then
      local ok, img = pcall(function()
        return require("src.render.Assets").image(
          mod.path .. "/assets/priston_stink.png")
      end)
      if ok and img and love.graphics and love.graphics.newQuad then
        STINK.image = img
        STINK.quads = {}
        for f = 0, 3 do
          STINK.quads[f] = love.graphics.newQuad(0, f * 16, 16, 16,
                                                 img:getDimensions())
        end
      else
        STINK.image = false
      end
    end
    if STINK.image then return STINK.image, STINK.quads end
    return nil, nil
  end

  -- Overworld-Fix fuer trueColor-Walker (engine_internals): markTrueColor
  -- nimmt das ganze 16x16-Feld vom SGB-Zonen-Shader aus, wodurch unter den
  -- transparenten Pixeln die UNgefaerbte Welt (DMG-Weiss) durchscheint --
  -- der beruechtigte weisse Kasten. Stattdessen zeichnen wir wie vanilla,
  -- lassen den Zonen-Shader normal laufen und replayen die Farbversion
  -- danach obendrauf (PaletteFX.markSpriteRedraw) -- derselbe Mechanismus,
  -- den der OG-RED-Modus fuer seine Objekt-Farben nutzt.
  mod.events:on("game.ready", function()
    local okPatch, patchErr = pcall(function()
      local SpriteRenderer = require("src.render.SpriteRenderer")
      local PaletteFX = require("src.render.PaletteFX")
      if SpriteRenderer.__priston_truecolor_fix then return end
      SpriteRenderer.__priston_truecolor_fix = true
      local vanillaDraw = SpriteRenderer.draw
      -- Frame-Layout des 6-Frame-Walkers (SpriteRenderer.lua Kopfkommentar):
      -- 0-2 stehen unten/oben/links, 3-5 gehen; rechts = gespiegelt links
      local STAND = { down = 0, up = 1, left = 2, right = 2 }
      local WALK = { down = 3, up = 4, left = 5, right = 5 }
      local noop = function() end
      SpriteRenderer.draw = function(self, px, py, camX, camY, facing,
                                     walkPhase, stepFlip, topHalf)
        local def = self.def
        if not (def and def.trueColor and def.walker and def.frames
                and def.frames > 1 and PaletteFX.spriteRedrawPassActive()) then
          return vanillaDraw(self, px, py, camX, camY, facing,
                             walkPhase, stepFlip, topHalf)
        end
        local mark = PaletteFX.markTrueColor
        PaletteFX.markTrueColor = noop
        local okDraw, drawErr = pcall(vanillaDraw, self, px, py, camX, camY,
                                      facing, walkPhase, stepFlip, topHalf)
        PaletteFX.markTrueColor = mark
        if not okDraw then error(drawErr, 0) end
        local x = math.floor(px - camX)
        local y = math.floor(py - camY) - 4
        local frame = (walkPhase == 1) and WALK[facing] or STAND[facing]
        local flip = facing == "right"
          or ((facing == "down" or facing == "up") and walkPhase == 1
              and stepFlip)
        local quad = self.frames and (self.frames[frame] or self.frames[0])
        if topHalf and self.halfFrames then
          quad = self.halfFrames[frame] or quad
        end
        if not quad then return end
        if flip then
          PaletteFX.markSpriteRedraw(self.image, quad, x + 16, y, -1)
        else
          PaletteFX.markSpriteRedraw(self.image, quad, x, y, 1)
        end
        -- die koeniglichen Schwaden steigen ueber dem Hund auf, im selben
        -- Post-Zonen-Replay, damit das Gruen die Zonenfaerbung ueberlebt
        if type(def.id) == "string"
           and def.id:sub(1, 14) == "SPRITE_PRISTON" then
          local img, quads = stinkImage()
          if img then
            PaletteFX.markSpriteRedraw(img, quads[stinkFrame()], x, y - 12, 1)
          end
        end
      end
    end)
    if not okPatch then
      mod.log:warn("trueColor-Walker-Fix nicht installierbar (%s) -- der "
        .. "Sprite bekommt in SGB-Farbmodi einen weissen Kasten",
        tostring(patchErr))
    end
  end)

  -- ------- Slowakei-Color-Grading
  -- Jede Map-Palette bekommt beim Laden eine kuehle Tatra-Variante
  -- (warme Kanaele runter, Blau hoch); der map.palette-Hook schaltet per
  -- Option um. Vanilla-Paletten bleiben unangetastet im Registry.

  mod.options:define({
    { key = "slovak_look", label = "SLOWAKEI-LOOK", type = "toggle",
      default = true },
    { key = "stink_aura", label = "STINK-AURA", type = "toggle",
      default = true },
    { key = "hymne", label = "HYMNE", type = "toggle",
      default = true },
  })

  -- ------- Euro-Wallet: der Frisoer nimmt kein Pokedollar
  -- Trainer-Siege +5, wilde Siege +1; Stand in mod.save.euros, Anzeige
  -- oben rechts (render.hud), Abrechnung ueber eigene Script-Verben.

  mod.events:on("battle.ended", function(ev)
    if not ev or ev.result ~= "win" or ev.skipped then return end
    local battle = ev.battle
    if not battle or battle.demo or battle.ghost then return end
    local reward = (battle.kind == "trainer") and 5 or 1
    mod.save:set("euros", math.min(999, (mod.save:get("euros", 0)) + reward))
  end)

  mod.content.tokens:register("PRISTON_EURO", function()
    return tostring(mod.save:get("euros", 0))
  end)

  mod.commands:register("priston:check_euro", function(ctx, amount)
    ctx.lastCheck = (mod.save:get("euros", 0)) >= (tonumber(amount) or 0)
  end)

  mod.commands:register("priston:pay_euro", function(ctx, amount)
    local euros = mod.save:get("euros", 0)
    mod.save:set("euros", math.max(0, euros - (tonumber(amount) or 0)))
  end)

  -- ------- Quest: "Die Ehre zurück"
  -- Der Hof gewährt das VOLLPROGRAMM beim Hundefrisör zu MÖDLING (Pallet
  -- Town spielt Mödling; die Schilder unten benennen auch WR. NEUDORF
  -- (Lavender) und GAADEN (Viridian)). Zutaten bei RENE und NICI holen,
  -- Finale gegen CESAR. Alles über Vanilla-NPCs, kein Map-Edit; Zweige
  -- ohne Quest-Bezug spielen den Original-Text (show_text löst die
  -- TEXT_-Konstante über die Text-Pointer der Map auf).

  local Q_START = "MOD_PRISTON_QUEST"
  local Q_DONE = "MOD_PRISTON_DONE"
  local Q_RENE = "MOD_PRISTON_RENE"
  local Q_NICI = "MOD_PRISTON_NICI"
  local WASSER = "PRISTON_LAVENDELWASSER"
  local SEIFE = "PRISTON_KRAEUTERSEIFE"
  local SIEGEL = "PRISTON_KOENIGSSIEGEL"

  mod.content.items:register(WASSER, {
    id = WASSER, name = "LAVENDELWASSR", price = 0,
    keyItem = true, tossable = false,
  })
  mod.content.items:register(SEIFE, {
    id = SEIFE, name = "KRÄUTERSEIFE", price = 0,
    keyItem = true, tossable = false,
  })
  mod.content.items:register(SIEGEL, {
    id = SIEGEL, name = "KÖNIGSSIEGEL", price = 0,
    keyItem = true, tossable = false,
  })

  local cesarParty = { { level = 14, species = "GROWLITHE" },
                       { level = 18, species = "ARCANINE" } }
  for _, slot in ipairs(cesarParty) do
    if not mod.content.pokemon:get(slot.species) then
      -- degrade statt Load-Fehler: auf exotischen Basen (andere Mods,
      -- Fixtures) fehlt die Spezies -- dann kaempft CESAR mit dem, was da
      -- ist, statt die ganze Mod zu reissen
      mod.log:warn("%s fehlt in der Basis -- CESAR nutzt Ersatz",
        slot.species)
      for id in mod.content.pokemon:each() do slot.species = id break end
    end
  end
  mod.content.trainers:register("OPP_CESAR", {
    id = "OPP_CESAR",
    name = "CESAR",
    pic = mod.path .. "/assets/priston_cesar.png",
    baseMoney = 99,
    parties = { cesarParty },
  })

  -- ------- der Hofstaat: Trainerklassen im Setting des Koenigreichs
  -- Nur die generischen KLASSEN werden zu Hofaemtern; benannte Figuren
  -- (Arenaleiter, Top Vier, Rivale) behalten ihre Namen. patch nach dem
  -- Deutsch-Mod (priority 50 < 100), damit die Hoftitel den Merge
  -- gewinnen; fehlt eine Klasse in der Basis, wird sie uebersprungen.
  local HOFSTAAT = {
    OPP_YOUNGSTER = "LAUSBUB",
    OPP_BUG_CATCHER = "MOTTENFÄNGER",
    OPP_LASS = "KAMMERZOFE",
    OPP_SAILOR = "BOOTSMANN",
    OPP_JR_TRAINER_M = "KNAPPE",
    OPP_JR_TRAINER_F = "HOFFRÄULEIN",
    OPP_POKEMANIAC = "POKéNARR",
    OPP_SUPER_NERD = "HOFGELEHRTER",
    OPP_HIKER = "BERGVOGT",
    OPP_BIKER = "KUTSCHER",
    OPP_BURGLAR = "SCHATZDIEB",
    OPP_ENGINEER = "HUFSCHMIED",
    OPP_FISHER = "FISCHVOGT",
    OPP_SWIMMER = "BADEMEISTER",
    OPP_CUE_BALL = "SÖLDNER",
    OPP_GAMBLER = "GLÜCKSRITTER",
    OPP_BEAUTY = "HOFDAME",
    OPP_PSYCHIC_TR = "HOFSEHER",
    OPP_ROCKER = "MINNESÄNGER",
    OPP_JUGGLER = "HOFNARR",
    OPP_UNUSED_JUGGLER = "GAUKLER",
    OPP_TAMER = "ZWINGERWART",
    OPP_BIRD_KEEPER = "FALKNER",
    OPP_BLACKBELT = "LEIBGARDIST",
    OPP_SCIENTIST = "ALCHEMIST",
    OPP_ROCKET = "INTRIGANT",
    OPP_GENTLEMAN = "EDELMANN",
    OPP_COOLTRAINER_M = "RITTER",
    OPP_COOLTRAINER_F = "EDELDAME",
    OPP_CHANNELER = "TOTENRUFERIN",
    OPP_CHIEF = "TRUCHSESS",
  }
  for id, titel in pairs(HOFSTAAT) do
    if mod.content.trainers:get(id) then
      mod.content.trainers:patch(id, { name = titel })
    end
  end

  mod.content.map_scripts:register("PALLET_TOWN", {
    talk = {
      TEXT_PALLETTOWN_SIGN = {
        { "show_text", "MÖDLING\f(Die Einheimischen\nsagen KANTO.)\f"
          .. "Heimat des besten\nHUNDEFRISÖRS weit\vund breit." },
      },
      TEXT_PALLETTOWN_FISHER = {
        { "check_flag", Q_DONE }, { "jump_if_true", "fertig" },
        { "check_flag", Q_START }, { "jump_if_true", "laufend" },
        { "face_player" },
        { "show_text", "Da seid ihr ja --\ndu und PRISTON!\f"
          .. "Ein Brief vom\nKÖNIGSHOF -- an\vmeinen SALON:\f"
          .. "\"An den HALTER des\nVerbannten:\"\f"
          .. "\"PRISTON hat einen\nTERMIN beim\vFRISÖR.\"\f"
          .. "\"Danach öffnet den\nUMSCHLAG, der\vbeiliegt.\"" },
        { "show_text", "Ein Frisörbesuch\nalso! Waschen,\vBürsten, Krallen --\vdas Vollprogramm\vhalt.\f"
          .. "Macht 100€. Und\nfürs KÖNIGLICHE\vProtokoll brauche\vich noch:\f"
          .. "LAVENDELWASSER von\nRENE, WR. NEUDORF.\f"
          .. "KRÄUTERSEIFE von\nNICI, GAADEN.\f"
          .. "Trainer zahlen dir\ndoch PREISGELD --\vdas wird schon!" },
        { "set_flag", Q_START },
        { "jump", "end" },

        { "label", "laufend" },
        { "check_item", WASSER }, { "jump_if_false", "erinnern" },
        { "check_item", SEIFE }, { "jump_if_false", "erinnern" },
        { "priston:check_euro", 100 }, { "jump_if_false", "zu_arm" },
        { "priston:pay_euro", 100 },
        { "take_item", WASSER },
        { "take_item", SEIFE },
        { "show_text", "Alles da! Rauf mit\nPRISTON auf den\vTisch.\f"
          .. "Waschen! Bürsten!\nKrallen! FÖHN!" },
        { "emote", "player", "happy", 45 },
        { "wait", 20 },
        { "show_text", "Fertig ist der\nFRISÖRBESUCH!\f"
          .. "PRISTON glänzt wie\nein KRONJUWEL!" },
        { "show_text", "?!\fCESAR: WUFF!\nWUFF! WUFF!\f"
          .. "CESAR: Wehe ihr\nöffnet diesen\vUMSCHLAG!\f"
          .. "CESAR: Wenn der\nSchwindler ECHT\vist...\f"
          .. "CESAR: ...dann hab\nICH jahrelang\veinen KÖNIG\vangebellt!\f"
          .. "CESAR: NIEMALS!" },
        { "start_battle", "trainer", "OPP_CESAR", 1 },
        { "jump_if_false", "verloren" },
        { "give_item", SIEGEL, 1, false },
        { "show_text", "CESAR zieht\nwinselnd ab!\f"
          .. "Der UMSCHLAG...\fDas KÖNIGSSIEGEL.\nECHT!\f"
          .. "{PLAYER} erhält das\nKÖNIGSSIEGEL!" },
        { "show_text", "Da steht noch was:\f\"Der Hof erwartet\nPRISTON zurück.\"\f"
          .. "Und? Gebt ihr\nihn her?" },
        { "choice", { "ZUM HOF", "BLEIBEN" } },
        { "jump_if_false", "kanto" },
        { "set_field", "mod:entscheidung", "hof" },
        { "set_flag", Q_DONE },
        { "show_text", "Der Hof also...\f"
          .. "PRISTON schaut\ndich lange an...\f"
          .. "...und setzt sich\nauf deinen Fuß.\f"
          .. "Er bleibt. Manche\nDinge schlagen\vSAMTKISSEN." },
        { "jump", "end" },

        { "label", "kanto" },
        { "set_field", "mod:entscheidung", "kanto" },
        { "set_flag", Q_DONE },
        { "show_text", "Gute Wahl!\f"
          .. "LECKERLIS schlagen\nSAMTKISSEN.\f"
          .. "Und irgendwer muss\nCESAR ja was zum\vBellen geben.\f"
          .. "Der bleibt bei\ndir, das sieht\vdoch jeder." },
        { "jump", "end" },

        { "label", "verloren" },
        { "show_text", "CESAR bellt\ntriumphierend.\f"
          .. "Heil dein Team --\ndann NOCHMAL!" },
        { "jump", "end" },

        { "label", "erinnern" },
        { "show_text", "Der TERMIN steht!\nEs fehlt noch:\f"
          .. "LAVENDELWASSER:\nRENE, WR. NEUDORF.\f"
          .. "KRÄUTERSEIFE:\nNICI, GAADEN.\f"
          .. "Und 100€ -- du\nhast {PRISTON_EURO}€." },
        { "jump", "end" },

        { "label", "zu_arm" },
        { "show_text", "Die Zutaten sind\nda -- aber das\vVOLLPROGRAMM\vkostet 100€.\f"
          .. "Du hast erst\n{PRISTON_EURO}€.\f"
          .. "Besieg ein paar\nTRAINER, dann\vsehen wir uns!" },
        { "jump", "end" },

        { "label", "fertig" },
        { "show_text", "Der bestfrisierte\nHund des Bezirks!\f"
          .. "...riecht halt\nnoch. Bisserl." },
      },
    },
  })

  mod.content.map_scripts:register("LAVENDER_TOWN", {
    talk = {
      TEXT_LAVENDERTOWN_SIGN = {
        { "show_text", "WR. NEUDORF\f(Bei Hunger: RENE\nfragen. PRISTON\vtut es täglich.)" },
      },
      TEXT_LAVENDERTOWN_COOLTRAINER_M = {
        { "check_flag", Q_START }, { "jump_if_false", "vanilla" },
        { "check_flag", Q_RENE }, { "jump_if_true", "danach" },
        { "face_player" },
        { "show_text", "RENE: PRISTON!\nAlter Stinker!\f"
          .. "Und du bist also\nder HALTER.\vRespekt.\f"
          .. "LAVENDELWASSER für\nden FRISÖRTERMIN?\f"
          .. "Klar. Für dich\ndoch immer." },
        { "give_item", WASSER, 1, false },
        { "show_text", "{PLAYER} erhält\nLAVENDELWASSER!" },
        { "show_text", "RENE: Und hier --\nLECKERLIS!\f"
          .. "Für unterwegs. Und\nfür danach. Und\vdazwischen." },
        { "heal_party" },
        { "show_text", "PRISTON hat ALLES\nsofort verdrückt!\f"
          .. "(Vielleicht hilft\ndeshalb kein BAD\vder Welt...)\f"
          .. "(Er schwitzt\nlängst LECKERLI.)" },
        { "set_flag", Q_RENE },
        { "jump", "end" },
        { "label", "danach" },
        { "show_text", "RENE: Nachschlag?\nAlles aufgegessen.\fVon dir." },
        { "jump", "end" },
        { "label", "vanilla" },
        { "show_text", "TEXT_LAVENDERTOWN_COOLTRAINER_M" },
      },
    },
  })

  mod.content.map_scripts:register("VIRIDIAN_CITY", {
    talk = {
      TEXT_VIRIDIANCITY_SIGN = {
        { "show_text", "GAADEN\f(Bitte leise --\nFLORIAN spielt\vRANGLISTE.)" },
      },
      TEXT_VIRIDIANCITY_GIRL = {
        { "check_flag", Q_START }, { "jump_if_false", "vanilla" },
        { "check_flag", Q_NICI }, { "jump_if_true", "danach" },
        { "face_player" },
        { "show_text", "NICI: Ah. Der Bub\nmit dem \"KÖNIGS-\vHUND\". Soso.\f"
          .. "Na, Hauptsache\nsauber.\f"
          .. "Die KRÄUTERSEIFE\nist frisch\vgekocht. Hier!" },
        { "give_item", SEIFE, 1, false },
        { "show_text", "{PLAYER} erhält die\nKRÄUTERSEIFE!" },
        { "show_text", "NICI: FLORIAN?\nOben im KINDER-\vZIMMER. Seit 26\vJahren.\f"
          .. "Sag ihm, das Essen\nist fertig. Mich\vhört er nie." },
        { "set_flag", Q_NICI },
        { "jump", "end" },
        { "label", "danach" },
        { "show_text", "NICI: Und? Hat\nFLORIAN reagiert?\f...dachte ich mir." },
        { "jump", "end" },
        { "label", "vanilla" },
        { "show_text", "TEXT_VIRIDIANCITY_GIRL" },
      },
    },
  })

  mod.content.map_scripts:register("VIRIDIAN_NICKNAME_HOUSE", {
    talk = {
      TEXT_VIRIDIANNICKNAMEHOUSE_BALDING_GUY = {
        { "check_flag", Q_START }, { "jump_if_false", "vanilla" },
        { "face_player" },
        { "show_text", "FLORIAN: Nicht\njetzt. RANGLISTE.\f"
          .. "(Er zockt seit\nStunden und dreht\vnebenbei ein\vBUTTERFLY-MESSER.)\f"
          .. "FLORIAN: AU!\nSchon wieder der\vFinger..." },
        { "check_flag", Q_NICI }, { "jump_if_false", "end" },
        { "show_text", "PRISTON bellt:\nESSEN IST FERTIG!\f"
          .. "FLORIAN: ...gleich.\nNoch EIN Match." },
        { "jump", "end" },
        { "label", "vanilla" },
        { "show_text", "TEXT_VIRIDIANNICKNAMEHOUSE_BALDING_GUY" },
      },
    },
  })

  -- Quest-Abschluss anderen Mods mitteilen
  mod.events:on("flag.changed", function(ev)
    if ev.name == Q_DONE and ev.value then
      mod.events:emit("mod.priston.ehre_wiederhergestellt",
        { entscheidung = mod.save:get("entscheidung") })
    end
  end)

  -- ------- die Stink-Aura
  -- Der Gestank ist spielmechanisch: ein Teil der wilden Pokemon nimmt
  -- Reissaus, bevor der Kampf beginnt, und NPCs, an denen PRISTON vorbei-
  -- laeuft, reagieren mit einer Schreckblase. Option aus = exakt Vanilla.

  mod.hooks:wrap("encounter.roll", function(next, encDef, ctx)
    local enc = next(encDef, ctx)
    if enc and mod.options:get("stink_aura") then
      local rng = (ctx and ctx.rng) or love.math.random
      -- ~3 von 8 Begegnungen verweht der Gestank
      if rng(0, 255) < 96 then return nil end
    end
    return enc
  end)

  -- Schreckblasen: pro NPC einmal je Map-Besuch, mit globalem Cooldown,
  -- kurz und per Knopfdruck abbrechbar -- exakt der Trainer-"!"-Mechanik
  -- der Engine nachempfunden (ow.emote, engine_internals)
  local stinkCooldown, stinkSeen = 0, {}
  mod.events:on("map.entered", function() stinkSeen = {} end)
  mod.events:on("world.stepped", function(ev)
    if not mod.options:get("stink_aura") then return end
    if stinkCooldown > 0 then stinkCooldown = stinkCooldown - 1; return end
    local world = mod.world
    local ow = world and world.overworld and world:overworld()
    if not ow or ow.emote or ow.engaging or (ow.runner and ow.runner:isRunning()) then
      return
    end
    if type(ow.npcs) ~= "table" then return end
    for _, npc in ipairs(ow.npcs) do
      local nx, ny = npc.cellX, npc.cellY
      if nx and ny
         and not (npc.def and npc.def.name == FOLLOWER)
         and math.abs(nx - ev.x) + math.abs(ny - ev.y) == 1
         and not stinkSeen[npc.id or (nx .. "," .. ny)]
         and love.math.random(3) == 1 then
        stinkSeen[npc.id or (nx .. "," .. ny)] = true
        stinkCooldown = 20
        ow.emote = { npc = npc, frames = 26, bubble = 1, skippable = true }
        mod.events:emit("mod.priston.smelled",
          { mapId = ev.mapId, npc = npc.id })
        return
      end
    end
  end)

  -- Ausgabe in der ROHFORM (vier {r,g,b}-Triple-Arrays): der Map-Paletten-
  -- Pfad (PaletteFX.sendColors) indiziert numerisch und normalisiert die
  -- v2-{colors=...}-Form nicht -- sie wuerde beim ersten Frame crashen
  local function gradeColor(r, g, b)
    return {
      math.max(0, math.floor(r * 0.82)),
      math.max(0, math.floor(g * 0.96)),
      math.min(255, math.floor(b * 1.15 + 10)),
    }
  end

  local function gradePalette(value)
    local out = {}
    for i = 1, 4 do
      local c = value[i] or (value.colors and value.colors[i])
      if type(c) ~= "table" then return nil end
      local r = c.r or c[1]
      local g = c.g or c[2]
      local b = c.b or c[3]
      if type(r) ~= "number" or type(g) ~= "number"
         or type(b) ~= "number" then
        return nil
      end
      out[i] = gradeColor(r, g, b)
    end
    return out
  end

  -- erst sammeln, dann registrieren: nie das Registry mutieren, waehrend
  -- each() darueber laeuft
  local pending, graded = {}, {}
  for name, value in mod.content.palettes:each() do
    local slovak = type(value) == "table" and gradePalette(value)
    if slovak then pending[#pending + 1] = { name = name, value = slovak } end
  end
  for _, entry in ipairs(pending) do
    mod.content.palettes:register("SLOVAK_" .. entry.name, entry.value)
    graded[entry.name] = "SLOVAK_" .. entry.name
  end
  if #pending == 0 then
    mod.log:warn("keine Map-Paletten im Registry gefunden -- das "
      .. "SLOWAKEI-LOOK-Grading bleibt wirkungslos (Headless-Lauf?)")
  end

  mod.hooks:wrap("map.palette", function(next, name, map, ctx)
    local out = next(name, map, ctx)
    if not mod.options:get("slovak_look") then return out end
    return graded[out] or out
  end)

  -- ------- TATRA: echte Shader-Pipeline (Ganzbild-Color-Grading)
  -- present-Pass, nicht worldPresent: worldPresent feuert nur, wenn eine
  -- Pipeline die Welt gezeichnet hat (Pipelines.lua:324); present laeuft
  -- auch ueber der flachen 2D-Welt, in Menues und Kaempfen. Options-Zeile,
  -- OFF/1/2/3-Ladder, Hotkey und Persistenz liefert die Engine aus dem
  -- Record. Hotkey 0 kollidiert weder mit den Engine-Keys (2-5) noch mit
  -- dem Voxel-Mod (3/5/6/7/8/9).

  -- unter einer aktiven World-Pipeline (Voxel) pausiert TATRA ganz: der
  -- Vollfenster-Present-Pfad kostet dort massiv FPS (gemessen 18 statt
  -- 56) und das Diorama bringt seine eigene Optik mit. Einmal definiert,
  -- keine Allokation pro Frame.
  local function worldPipelineProbe()
    return require("src.render.Pipelines").worldPipeline() ~= nil
  end
  local function tatraAvailable()
    if not (love and love.graphics and love.graphics.newShader) then
      return false
    end
    local ok, active = pcall(worldPipelineProbe)
    return not (ok and active)
  end

  local TATRA = {
    presets = {
      [1] = { strength = 0.45, vig = 0.30, grain = 0.015 },
      [2] = { strength = 0.70, vig = 0.45, grain = 0.030 },
      [3] = { strength = 1.00, vig = 0.60, grain = 0.045 },
    },
    level = 0, time = 0,
    shader = nil,   -- nil = unversucht, false = nicht verfuegbar
    canvas = nil, cw = 0, ch = 0,
  }

  -- rect = Spielfeld in tc-Koordinaten (x, y, w, h); w <= 0 heisst
  -- "unbekannt, ganze Flaeche". Alles ausserhalb bleibt unangetastet,
  -- damit die Letterbox pechschwarz bleibt und die Vignette sich auf das
  -- Spielfeld zentriert statt auf das Fenster.
  local TATRA_SHADER = [[
    uniform float strength;
    uniform float time;
    uniform float vig;
    uniform float grain;
    uniform vec4 rect;
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
      vec4 px = Texel(tex, tc);
      vec2 q = rect.z > 0.0 ? (tc - rect.xy) / rect.zw : tc;
      float inside = rect.z > 0.0
        ? step(0.0, q.x) * step(q.x, 1.0) * step(0.0, q.y) * step(q.y, 1.0)
        : 1.0;
      vec3 c = px.rgb;
      // kuehle Weissbalance: Tatra-Morgenlicht
      c *= mix(vec3(1.0), vec3(0.90, 0.97, 1.10), strength);
      // sanfte S-Kurve fuer Kontrast
      vec3 s = c * c * (3.0 - 2.0 * c);
      c = mix(c, s, 0.55 * strength);
      // Split-Toning: Schatten kippen ins Blau, Lichter minimal warm
      float luma = dot(c, vec3(0.299, 0.587, 0.114));
      c += (1.0 - luma) * strength * vec3(-0.030, 0.005, 0.060);
      c += luma * strength * vec3(0.035, 0.012, -0.020);
      // Vignette, zentriert auf das Spielfeld
      vec2 d = q - vec2(0.5);
      c *= 1.0 - vig * strength * dot(d, d) * 1.2;
      // Filmkorn
      float n = fract(sin(dot(sc + vec2(time * 61.7, time * 12.9),
                              vec2(12.9898, 78.233))) * 43758.5453);
      c += (n - 0.5) * grain * strength;
      return vec4(mix(px.rgb, clamp(c, 0.0, 1.0), inside), px.a) * color;
    }
  ]]

  -- render.hud liefert jedes Frame das Spielfeld-Rechteck in denselben
  -- Fenster-Pixeln, in denen der present-Pass arbeitet (Renderer:endFrame
  -- gibt dieselbe Tabelle an den Hook weiter)
  -- DRAMATIC_SHAPE patcht Renderer:endFrame und verschluckt dessen
  -- Rueckgabe -- render.hud bekommt dann viewport=nil. Fallback: die
  -- Playfield-Geometrie selbst aus dem Renderer ableiten.
  local function hudViewport(viewport)
    if type(viewport) == "table" and viewport.scale then return viewport end
    local ok, vp = pcall(function()
      local Renderer = require("src.render.Renderer")
      local ww, wh = love.graphics.getDimensions()
      local pw, ph = love.graphics.getPixelDimensions()
      local dpiX, dpiY = pw / ww, ph / wh
      local Sp = Renderer:fitScale()
      local uiw, uih = Renderer:uiSize()
      return {
        width = ww, height = wh,
        gameX = math.floor((pw - uiw * Sp) / 2) / dpiX,
        gameY = math.floor((ph - uih * Sp) / 2) / dpiY,
        gameWidth = uiw * Sp / dpiX,
        gameHeight = uih * Sp / dpiY,
        scale = Sp / dpiX,
      }
    end)
    if ok then return vp end
    return nil
  end

  mod.hooks:wrap("render.hud", function(next, game, viewport)
    viewport = hudViewport(viewport)
    if type(viewport) == "table" and viewport.width then
      TATRA.viewport = viewport
    end
    local out = next(game, viewport)
    -- Euro-Stand oben rechts, GB-Font, nur waehrend eines Spielstands
    local okHud, hudErr = pcall(function()
      if not (game and game.overworld and viewport and viewport.scale) then
        return
      end
      -- Anzeige erst, wenn der Frisoer die Aufgabe erteilt hat -- vorher
      -- hat der Spieler mit Euros nichts zu schaffen
      local flags = game.save and game.save.flags
      if not (flags and flags.MOD_PRISTON_QUEST) then return end
      local Font = mod.ui.Font
      local label = tostring(mod.save:get("euros", 0)) .. "€"
      local w = Font.width(label)
      love.graphics.push("all")
      love.graphics.translate(viewport.gameX or 0, viewport.gameY or 0)
      love.graphics.scale(viewport.scale, viewport.scale)
      love.graphics.setColor(1, 1, 1, 0.88)
      love.graphics.rectangle("fill", 160 - w - 6, 1, w + 5, 10)
      love.graphics.setColor(0, 0, 0, 1)
      love.graphics.rectangle("line", 160 - w - 6, 1, w + 5, 10)
      Font.draw(label, 160 - w - 3, 2)
      love.graphics.pop()
    end)
    if not okHud and not TATRA.hudWarned then
      TATRA.hudWarned = true
      mod.log:warn("Euro-HUD zeichnet nicht: %s", tostring(hudErr))
    end
    return out
  end, -100) -- niedrige Prioritaet: aeusserster Wrap, damit ein anderer Mod,
             -- der den Viewport nicht weiterreicht (DRAMATIC_SHAPE), uns
             -- die Engine-Argumente nicht wegnimmt

  local function tatraShader()
    if TATRA.shader == nil then
      local ok, sh = pcall(function()
        return love.graphics.newShader(TATRA_SHADER)
      end)
      TATRA.shader = (ok and sh) or false
    end
    return TATRA.shader or nil
  end

  mod.content.render_pipelines:register("tatra", {
    label = "TATRA",
    levels = { "OFF", "1", "2", "3" },
    hotkey = "0",
    priority = 10,
    available = tatraAvailable,
    update = function(dt, level)
      TATRA.level = math.min(3, math.max(0, math.floor(tonumber(level) or 0)))
      TATRA.time = (TATRA.time + (dt or 0)) % 64
    end,
    present = function(canvas)
      local preset = TATRA.presets[TATRA.level]
      if not (preset and canvas) then return canvas end

      local sh = tatraShader()
      if not sh then return canvas end
      local w, h = canvas:getDimensions()
      if not TATRA.canvas or TATRA.cw ~= w or TATRA.ch ~= h then
        local okCanvas, fresh = pcall(love.graphics.newCanvas, w, h)
        if not okCanvas then return canvas end
        TATRA.canvas, TATRA.cw, TATRA.ch = fresh, w, h
      end
      local prevBlend, prevAlpha = love.graphics.getBlendMode()
      love.graphics.setShader(sh)
      love.graphics.setColor(1, 1, 1, 1)
      -- replace, nicht alpha: das ist eine Bildverarbeitungs-Kopie
      love.graphics.setBlendMode("replace", "premultiplied")
      pcall(sh.send, sh, "strength", preset.strength)
      pcall(sh.send, sh, "vig", preset.vig)
      pcall(sh.send, sh, "grain", preset.grain)
      pcall(sh.send, sh, "time", TATRA.time)
      local vp = TATRA.viewport
      if vp and vp.width == w and vp.gameWidth and vp.gameWidth > 0 then
        pcall(sh.send, sh, "rect", { vp.gameX / w, vp.gameY / h,
                                     vp.gameWidth / w, vp.gameHeight / h })
      else
        pcall(sh.send, sh, "rect", { 0, 0, -1, -1 })
      end
      local ok = pcall(function()
        love.graphics.setCanvas(TATRA.canvas)
        love.graphics.draw(canvas)
      end)
      love.graphics.setCanvas()
      love.graphics.setShader()
      love.graphics.setBlendMode(prevBlend or "alpha", prevAlpha)
      return ok and TATRA.canvas or canvas
    end,
    invalidate = function()
      TATRA.canvas, TATRA.cw, TATRA.ch = nil, 0, 0
    end,
  })

  -- ------- ein standesgemaesses "WUFF" als Cry (ChipAsm steht auf der
  -- Whitelist, braucht kein engine_internals)

  mod.content.cries:register("PRISTON", {
    chip = require("src.audio.ChipAsm").sfx{
      channels = {
        { hw = 1, program = {
          { pitchSweep = { pace = 2, subtract = true, shift = 2 } },
          { squareNote = { len = 4, volume = 15, fade = 1, frequency = 0x380 } },
          { squareNote = { len = 6, volume = 12, fade = 3, frequency = 0x2C0 } },
        } },
      },
    }.chip,
    pitch = 128,
    length = 160,
  })

  -- ------- PRISTON laeuft mit: der Follower
  -- Ein Laufzeit-NPC folgt dem Spieler eine Zelle versetzt: bei jedem
  -- Schritt geht er auf die soeben verlassene Zelle. Faellt er weiter
  -- als 3 Zellen zurueck (Bike, Warp innerhalb der Map), wird er direkt
  -- hinter den Spieler gesetzt. Auf jeder Map spawnt er neu -- Laufzeit-
  -- Objekte werden von der Engine bewusst nicht serialisiert.

  local FOLLOWER = "PRISTON_FOLLOWER"
  local follower = { active = false, moving = false, prevX = nil, prevY = nil }

  local function behindCell(px, py, facing)
    if facing == "up" then return px, py + 1 end
    if facing == "down" then return px, py - 1 end
    if facing == "left" then return px + 1, py end
    return px - 1, py
  end

  mod.events:on("map.entered", function(ev)
    follower.active, follower.moving = false, false
    local world = mod.world
    local ow = world and world.overworld and world:overworld()
    local player = ow and ow.player
    if not player or not player.cellX then return end
    -- gecachte Map-Instanzen bringen den alten Laufzeit-Priston wieder
    -- mit (Haus rein/raus) -- erst alle Altbestaende entfernen, sonst
    -- verdoppelt sich der Hund
    for _, npc in ipairs(ow.npcs or {}) do
      if npc.def and npc.def.name == FOLLOWER and npc.id then
        pcall(function() world:removeNpc(npc.id) end)
      end
    end
    local bx, by = behindCell(player.cellX, player.cellY,
                              player.facing or "down")
    local ok = world:spawnNpc(ev.mapId, {
      name = FOLLOWER,
      sprite = "SPRITE_PRISTON",
      movement = "STAY",
      x = bx, y = by,
    })
    if ok then
      follower.active = true
      follower.prevX, follower.prevY = player.cellX, player.cellY
    end
  end)

  mod.events:on("world.stepped", function(ev)
    if not follower.active then return end
    local world = mod.world
    local ow = world and world.overworld and world:overworld()
    if not ow then follower.active = false; return end
    local dog
    for _, npc in ipairs(ow.npcs or {}) do
      if npc.def and npc.def.name == FOLLOWER then dog = npc; break end
    end
    if not dog then follower.active = false; return end
    local tx, ty = follower.prevX, follower.prevY
    follower.prevX, follower.prevY = ev.x, ev.y
    if not (dog.cellX and tx) then return end
    local dx, dy = tx - dog.cellX, ty - dog.cellY
    local dist = math.abs(dx) + math.abs(dy)
    if dist == 0 then return end
    if dist > 3 then
      -- Anschluss verloren (Bike, Warp in derselben Map): aufsetzen
      dog.cellX, dog.cellY = tx, ty
      dog.targetX, dog.targetY = nil, nil
      dog.moving, dog.progress = false, 0
      dog.px, dog.py = tx * 16, ty * 16
      return
    end
    if dog.moving then return end
    -- WICHTIG: kein scriptMove! Die Script-Queue friert waehrenddessen
    -- die Spielereingabe ein (OverworldController: `#self.scriptMoves > 0`
    -- gilt als Cutscene) -- das war das Stop-and-Go nach jedem Schritt.
    -- Stattdessen den Wander-Mechanismus des NPC direkt ansteuern; der
    -- blockiert nichts.
    local dir
    if math.abs(dx) >= math.abs(dy) then
      dir = dx > 0 and "right" or "left"
    else
      dir = dy > 0 and "down" or "up"
    end
    local okStep = pcall(function()
      local Collision = require("src.world.Collision")
      local d = Collision.DELTA[dir]
      dog.facing = dir
      dog.targetX, dog.targetY = dog.cellX + d[1], dog.cellY + d[2]
      dog.moving, dog.progress = true, 0
      -- Aufholen im Pikachu-Stil: halber Schritt-Takt bei Rueckstand
      dog.stepFrames = (dist > 1) and 8 or nil
    end)
    if not okStep then follower.active = false end
  end)

  -- ------- Bellen: PRISTON ansprechen (A) -> WUFF + Freude-Blase
  mod.events:on("world.interacted", function(ev)
    if not follower.active or ev.kind ~= "npc" then return end
    local target = ev.target
    if not (type(target) == "table" and target.def
            and target.def.name == FOLLOWER) then
      return
    end
    local world = mod.world
    local ow = world and world.overworld and world:overworld()
    if not ow or ow.emote then return end
    pcall(function()
      local Game = require("src.core.Game")
      require("src.core.Sound").playCry(Game.data, "PRISTON")
    end)
    ow.emote = { npc = target, frames = 32, bubble = 3, skippable = true }
    mod.events:emit("mod.priston.wuff", { mapId = ev.mapId })
  end)

  -- Der Spieler darf durch seinen Hund hindurchtreten (der weicht beim
  -- naechsten Schritt ohnehin auf die verlassene Zelle aus)
  mod.hooks:wrap("movement.collision", function(next, allowed, ctx)
    local out = next(allowed, ctx)
    if out or not follower.active or not ctx then return out end
    local world = mod.world
    local ow = world and world.overworld and world:overworld()
    if not (ow and ctx.mover == ow.player) then return out end
    for _, npc in ipairs(ow.npcs or {}) do
      if npc.def and npc.def.name == FOLLOWER
         and npc.cellX == ctx.toX and npc.cellY == ctx.toY then
        return true
      end
    end
    return out
  end)

  -- ------- das Intro: Prof. Eich erzaehlt die Verbannung

  mod.hooks:wrap("intro.oak_speech.build", function(next, steps, speech)
    steps = next(steps, speech)
    if type(steps) ~= "table" then return steps end

    local byId = {}
    for _, step in ipairs(steps) do byId[step.id] = step end
    -- ein anderes Mod koennte Anker entfernt haben; dann lieber sauber
    -- aussteigen als das Intro zerlegen
    if not (byId.oak_welcome and byId.world_spiel and byId.ask_player_name
            and byId.name_player and byId.ask_rival_name and byId.name_rival
            and byId.legend) then
      mod.log:warn("Oak-Intro-Anker fehlen -- laeuft ein anderes Intro-Mod? "
        .. "PRISTONs Vorgeschichte wird uebersprungen")
      return steps
    end

    byId.oak_welcome.text = "Willkommen in der\nWelt der POKéMON!\f"
      .. "Ich bin PROF.\nEICH.\f"
      .. "Du bekommst heute\ndeinen ersten\vPartner!\f"
      .. "Und wie ich sehe,\nkommt dein HUND...\veinfach MIT."

    byId.world_spiel.text = "Dies ist der\nBEZIRK MÖDLING.\f"
      .. "Die Einheimischen\nnennen ihn KANTO.\vFrag nicht.\f"
      .. "Hier zieht jeder\nTrainer mit\vPOKéMON los.\f"
      .. "Du eben mit\nPOKéMON und HUND."

    mod.ui.insertStepAfter(steps, "world_spiel", {
      id = "priston_reveal",
      kind = "say",
      pic = { type = "image", path = frontGb },
      reveal = "fade",
      cry = "PRISTON",
      text = "Das ist PRISTON.\nDEIN Hund.\f"
        .. "Ein SCHÄFERHUND --\naus dem KÖNIGSHAUS\vder SLOWAKEI.\f"
        .. "Ja. WIRKLICH.",
    })
    mod.ui.insertStepAfter(steps, "priston_reveal", {
      id = "priston_story",
      kind = "say",
      pic = { type = "image", path = frontGb },
      text = "Er hatte alles:\nSamtkissen!\vEinen BUTLER!\vLECKERLI auf\vSilber!\f"
        .. "Doch dann kam der\nschwarze Tag...",
    })
    mod.ui.insertStepAfter(steps, "priston_story", {
      id = "priston_banished",
      kind = "say",
      pic = { type = "image", path = frontGb },
      text = "VERBANNT!\nWegen GESTANKS.\f"
        .. "Kein Bad half.\nKein Parfüm.\vNichts half.\f"
        .. "So wanderte er\nüber die Berge --\f"
        .. "und landete vor\nEURER Tür.",
    })
    mod.ui.insertStepAfter(steps, "priston_banished", {
      id = "priston_oath",
      kind = "yesno",
      pic = { type = "image", path = frontGb },
      saveKey = "ehre_schwur",
      text = "Seither weicht er\ndir nicht von der\vSeite.\f"
        .. "Wirst du ihm\nhelfen zu beweisen,\vwer er WIRKLICH\vist?",
    })

    byId.ask_player_name.text = "Doch zuerst:\nWie heißt DU?"
    byId.name_player.title = "DEIN NAME?"

    byId.ask_rival_name.text = "Das ist dein\nRivale von nebenan.\f"
      .. "Und SEIN Hund:\nCESAR.\f"
      .. "Der große weiße\nHÜTEHUND, der\vPRISTON jeden Tag\vanbellt.\f"
      .. "\"Königshaus? Dass\nich nicht BELLE!\""
    byId.name_rival.title = "SEIN NAME?"

    byId.legend.text = "{PLAYER}!\nEure Reise beginnt!\f"
      .. "Sammle ORDEN.\nFang POKéMON.\f"
      .. "Und geh mit\nPRISTON irgendwann\vzum FRISÖR.\f"
      .. "Du riechst schon,\nwarum."

    return steps
  end)

  -- Antworten (der Ehrenschwur) landen im Mod-Save
  mod.events:on("intro.oak_speech.answered", function(ev)
    if ev.saveKey then mod.save:set(ev.saveKey, ev.value) end
  end)

  mod.events:on("intro.oak_speech.finished", function()
    mod.save:set("intro_gesehen", true)
    mod.log:info("PRISTONs Verbannungs-Intro abgeschlossen")
  end)
end
