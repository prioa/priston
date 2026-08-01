-- priston: Du spielst PRISTON -- einen uebergewichtigen Schaeferhund, der
-- aus dem Koenigshaus der Slowakei verbannt wurde, weil er zu sehr stinkt.
-- Overworld-Walker, Battle-Backpic und Trainer-Portrait werden ersetzt,
-- und Prof. Eichs Intro erzaehlt die Verbannungs-Geschichte auf Deutsch.
--
-- Alle Pixel sind Originalarbeit aus tools/make_assets.py; es werden keine
-- ROM-Daten ausgeliefert.
return function(mod)
  local walk = mod.path .. "/assets/priston_walk.png"
  local back = mod.path .. "/assets/priston_back.png"
  local front = mod.path .. "/assets/priston_front.png"

  -- ------- der Hund selbst: Walker-Sheet + Battle-Pics
  -- trueColor: die PNGs bringen echte GBA-Farben und echtes Alpha mit;
  -- das Flag nimmt sie vom 4-Graustufen-Remap der Engine aus

  mod.content.sprites:register("SPRITE_PRISTON", {
    id = "SPRITE_PRISTON",
    image = walk,
    frames = 6,
    walker = true,
    trueColor = true,
  })

  mod.content.sprites:register("SPRITE_PRISTON_BIKE", {
    id = "SPRITE_PRISTON_BIKE",
    image = mod.path .. "/assets/priston_bike.png",
    frames = 6, walker = true, trueColor = true,
  })
  mod.content.sprites:register("SPRITE_PRISTON_SURF", {
    id = "SPRITE_PRISTON_SURF",
    image = mod.path .. "/assets/priston_surf.png",
    frames = 6, walker = true, trueColor = true,
  })

  -- patch, nicht override: fly bleibt Vanilla (der Vogel traegt ihn)
  mod.content.field:patch("playerSprites", {
    walk = "SPRITE_PRISTON",
    bike = "SPRITE_PRISTON_BIKE",
    surf = "SPRITE_PRISTON_SURF",
  })
  mod.content.field:patch("playerPics", { back = back, front = front })

  -- playerPics kennt kein trueColor-Feld; der Hook ist der sanktionierte
  -- Weg: ctx.trueColor = true nimmt unsere farbigen Pics aus der
  -- Paletten-Quantisierung (BattleState getImage / OakSpeech resolvePic)
  mod.hooks:wrap("player.sprite", function(next, path, ctx)
    local out = next(path, ctx)
    local effective = type(out) == "string" and out or path
    if type(effective) == "string"
       and effective:find("priston_", 1, true) then
      ctx.trueColor = true
    end
    return out
  end)

  -- ------- echte Umlaute: eigene Font-Seite oberhalb der Vanilla-Codes
  -- (Basis 0x120; die Kana-Beispielseite der Doku liegt bei 0x100)
  mod.content.font:register("priston_umlauts", {
    image = mod.path .. "/assets/priston_font.png",
    base = 0x120,
    glyphsPerRow = 7,
    charmap = {
      { seq = "\195\164", code = 0x120 },  -- ae
      { seq = "\195\182", code = 0x121 },  -- oe
      { seq = "\195\188", code = 0x122 },  -- ue
      { seq = "\195\132", code = 0x123 },  -- AE
      { seq = "\195\150", code = 0x124 },  -- OE
      { seq = "\195\156", code = 0x125 },  -- UE
      { seq = "\195\159", code = 0x126 },  -- sz
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
    if okSong and song then
      mod.content.music:register("Music_PristonHymna", song)
      mod.hooks:wrap("music.select", function(next, chosen, ctx)
        if ctx and ctx.reason == "map" and ctx.mapId == "PALLET_TOWN" then
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

  mod.hooks:wrap("battle.overlay", function(next, battle)
    local out = next(battle)
    if battle and battle.showPlayerBack then
      local img, quads = stinkImage()
      if img then
        pcall(function()
          local f = stinkFrame()
          love.graphics.setColor(1, 1, 1, 0.85)
          love.graphics.draw(img, quads[f], 14, 34, 0, 2, 2)
          love.graphics.draw(img, quads[(f + 2) % 4], 36, 42, 0, 2, 2)
          love.graphics.setColor(1, 1, 1, 1)
        end)
      end
    end
    return out
  end)

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

  -- __prepend statt Listen-Ersatz: die Vanilla-Namen bleiben waehlbar,
  -- PRISTON steht nur zuerst
  mod.content.field:patch("boot", {
    namePresets = {
      player = { __prepend = { "PRISTON", "SMRAD", "BOBIK" } },
      rival = { __prepend = { "CESAR", "REX", "LORD" } },
    },
  })

  -- ------- Slowakei-Color-Grading
  -- Jede Map-Palette bekommt beim Laden eine kuehle Tatra-Variante
  -- (warme Kanaele runter, Blau hoch); der map.palette-Hook schaltet per
  -- Option um. Vanilla-Paletten bleiben unangetastet im Registry.

  mod.options:define({
    { key = "slovak_look", label = "SLOWAKEI-LOOK", type = "toggle",
      default = true },
    { key = "stink_aura", label = "STINK-AURA", type = "toggle",
      default = true },
  })

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

  mod.content.trainers:register("OPP_CESAR", {
    id = "OPP_CESAR",
    name = "CESAR",
    pic = mod.path .. "/assets/priston_cesar.png",
    baseMoney = 99,
    parties = {
      {
        { level = 14, species = "GROWLITHE" },
        { level = 18, species = "ARCANINE" },
      },
    },
  })

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
        { "show_text", "PRISTON! Da bist\ndu ja!\f"
          .. "Ein Brief vom\nKÖNIGSHOF -- an\vmeinen SALON:\f"
          .. "\"Wir hören, der\nVerbannte sammelt\vORDEN. Schön.\"\f"
          .. "\"Aber ZUERST hat\ner einen TERMIN\vbeim FRISÖR.\"\f"
          .. "\"Danach öffnet den\nUMSCHLAG, der\vbeiliegt.\"" },
        { "show_text", "Ein Frisörbesuch\nalso! Waschen,\vBürsten, Krallen --\vdas Vollprogramm\vhalt.\f"
          .. "Nur fehlt mir was\nfürs KÖNIGLICHE\vProtokoll:\f"
          .. "LAVENDELWASSER von\nRENE, WR. NEUDORF.\f"
          .. "KRÄUTERSEIFE von\nNICI, GAADEN." },
        { "set_flag", Q_START },
        { "jump", "end" },

        { "label", "laufend" },
        { "check_item", WASSER }, { "jump_if_false", "erinnern" },
        { "check_item", SEIFE }, { "jump_if_false", "erinnern" },
        { "take_item", WASSER },
        { "take_item", SEIFE },
        { "show_text", "Alles da! Dann ab\nauf den Tisch.\f"
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
        { "show_text", "Da steht noch was:\f\"Der Hof erwartet\ndich zurück.\"\f"
          .. "Und? Kehrst du\nheim?" },
        { "choice", { "ZUM HOF", "BLEIBEN" } },
        { "jump_if_false", "kanto" },
        { "set_field", "mod:entscheidung", "hof" },
        { "set_flag", Q_DONE },
        { "show_text", "Dann lauf, du\nsauberer Hund!\f"
          .. "Und besuch uns --\nWENN die Samt-\vkissen langweilig\vwerden." },
        { "jump", "end" },

        { "label", "kanto" },
        { "set_field", "mod:entscheidung", "kanto" },
        { "set_flag", Q_DONE },
        { "show_text", "Ha! Wusste ich es.\f"
          .. "LECKERLIS schlagen\nSAMTKISSEN.\f"
          .. "Und irgendwer muss\nCESAR ja was zum\vBellen geben.\f"
          .. "Willkommen daheim,\nPRISTON." },
        { "jump", "end" },

        { "label", "verloren" },
        { "show_text", "CESAR bellt\ntriumphierend.\f"
          .. "Heil dein Team --\ndann NOCHMAL!" },
        { "jump", "end" },

        { "label", "erinnern" },
        { "show_text", "Der TERMIN steht!\nEs fehlt noch:\f"
          .. "LAVENDELWASSER:\nRENE, WR. NEUDORF.\f"
          .. "KRÄUTERSEIFE:\nNICI, GAADEN." },
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
        { "show_text", "NICI: Ah. Der\n\"KÖNIGSHUND\".\vSoso.\f"
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
  mod.hooks:wrap("render.hud", function(next, game, viewport)
    if type(viewport) == "table" and viewport.width then
      TATRA.viewport = viewport
    end
    return next(game, viewport)
  end)

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
    available = function()
      return love ~= nil and love.graphics ~= nil
        and love.graphics.newShader ~= nil
    end,
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
      .. "Jedes Jahr schicke\nich neue Trainer\vauf die Reise.\f"
      .. "Doch dieses Jahr\nist einer dabei,\vder... anders ist."

    byId.world_spiel.text = "Dies ist der\nBEZIRK MÖDLING.\f"
      .. "Die Einheimischen\nnennen ihn KANTO.\vFrag nicht.\f"
      .. "Hier zieht jeder\nTrainer mit\vPOKéMON los.\f"
      .. "Dieses Jahr auch:\nein HUND."

    mod.ui.insertStepAfter(steps, "world_spiel", {
      id = "priston_reveal",
      kind = "say",
      pic = "player",  -- "player" traegt playerTrueColor; type="image" nicht
      reveal = "fade",
      cry = "PRISTON",
      text = "Dies ist PRISTON.\f"
        .. "Ein SCHÄFERHUND --\nund zwar aus dem\vKÖNIGSHAUS der\vSLOWAKEI.\f"
        .. "Ein stattlicher\nHund. Sehr...\vstattlich.",
    })
    mod.ui.insertStepAfter(steps, "priston_reveal", {
      id = "priston_story",
      kind = "say",
      pic = "player",  -- "player" traegt playerTrueColor; type="image" nicht
      text = "Er hatte alles:\nSamtkissen!\vEinen BUTLER!\vLECKERLI auf\vSilber!\f"
        .. "Doch dann kam der\nschwarze Tag...",
    })
    mod.ui.insertStepAfter(steps, "priston_story", {
      id = "priston_banished",
      kind = "say",
      pic = "player",  -- "player" traegt playerTrueColor; type="image" nicht
      text = "VERBANNT!\nWegen GESTANKS.\f"
        .. "Kein Bad half.\nKein Parfüm.\vNichts half.\f"
        .. "So wanderte er\nüber die Berge --\f"
        .. "und fand hier im\nBEZIRK ein neues\vDAHEIM.",
    })
    mod.ui.insertStepAfter(steps, "priston_banished", {
      id = "priston_oath",
      kind = "yesno",
      pic = "player",  -- "player" traegt playerTrueColor; type="image" nicht
      saveKey = "ehre_schwur",
      text = "Nur: kaum jemand\nGLAUBT ihm das.\f"
        .. "PRISTON! Wirst du\nihnen ALLEN\vbeweisen, wer du\vwirklich bist?",
    })

    byId.ask_player_name.text = "Doch zuerst...\f"
      .. "Wie nennt man dich\nam Hofe?"
    byId.name_player.title = "DEIN NAME?"
    byId.name_player.presets = { "PRISTON", "SMRAD", "BOBIK" }

    byId.ask_rival_name.text = "EINER glaubt ihm\nkein Wort:\f"
      .. "CESAR. Der große\nweiße HÜTEHUND\vvon nebenan.\f"
      .. "\"Königshaus? Dass\nich nicht BELLE!\"\f"
      .. "Und jetzt zieht er\nSELBST als Trainer\vlos --\f"
      .. "nur um dabei zu-\nzusehen, wie du\vSCHEITERST!"
    byId.name_rival.title = "SEIN NAME?"
    byId.name_rival.presets = { "CESAR", "REX", "LORD" }

    byId.legend.text = "{PLAYER}!\nDeine Reise\vbeginnt jetzt!\f"
      .. "Sammle ORDEN.\nFang POKéMON.\vBeweise dich.\f"
      .. "Ach ja -- und geh\nirgendwann zum\vFRISÖR.\f"
      .. "Du weißt schon,\nwarum."

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
