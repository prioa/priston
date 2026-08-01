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

  mod.content.sprites:register("SPRITE_PRISTON", {
    id = "SPRITE_PRISTON",
    image = walk,
    frames = 6,
    walker = true,
  })

  -- patch, nicht override: surf/bike/fly bleiben Vanilla, nur das Laufen
  -- gehoert PRISTON
  mod.content.field:patch("playerSprites", { walk = "SPRITE_PRISTON" })
  mod.content.field:patch("playerPics", { back = back, front = front })

  -- __prepend statt Listen-Ersatz: die Vanilla-Namen bleiben waehlbar,
  -- PRISTON steht nur zuerst
  mod.content.field:patch("boot", {
    namePresets = {
      player = { __prepend = { "PRISTON", "SMRAD", "BOBIK" } },
      rival = { __prepend = { "GASTON", "FIFI", "LORD" } },
    },
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

    byId.oak_welcome.text = "Hallo!\nMein Name ist\vEICH.\f"
      .. "Man nennt mich den\nPOKéMON-PROF!\f"
      .. "Doch heute geht es\nnicht um POKéMON."

    byId.world_spiel.text = "Dies ist KANTO.\f"
      .. "Hier fragt niemand\nwoher du kommst.\f"
      .. "Und niemand...\nwie du riechst."

    mod.ui.insertStepAfter(steps, "world_spiel", {
      id = "priston_reveal",
      kind = "say",
      pic = { type = "image", path = front },
      reveal = "fade",
      cry = "PRISTON",
      text = "Dies ist PRISTON.\f"
        .. "Ein SCHAEFERHUND\naus der SLOWAKEI.\f"
        .. "Ein stattlicher\nHund. Sehr...\vstattlich.",
    })
    mod.ui.insertStepAfter(steps, "priston_reveal", {
      id = "priston_story",
      kind = "say",
      pic = { type = "image", path = front },
      text = "PRISTON lebte am\nKOENIGSHOF der\vSLOWAKEI.\f"
        .. "Samtkissen!\nLeckerli!\vEin Butler nur\vfuer ihn!\f"
        .. "Doch dann kam der\nschwarze Tag...",
    })
    mod.ui.insertStepAfter(steps, "priston_story", {
      id = "priston_banished",
      kind = "say",
      pic = { type = "image", path = front },
      text = "Der Hof hat ihn\nVERBANNT!\f"
        .. "Der Grund...\fEr STINKT.\f"
        .. "Kein Bad half.\nKein Parfuem.\vNichts half.",
    })
    mod.ui.insertStepAfter(steps, "priston_banished", {
      id = "priston_oath",
      kind = "yesno",
      pic = { type = "image", path = front },
      saveKey = "ehre_schwur",
      text = "PRISTON!\nWirst du deine\vEHRE zurueck-\verobern?",
    })

    byId.ask_player_name.text = "Doch zuerst...\f"
      .. "Wie nennt man dich\nam Hofe?"
    byId.name_player.title = "DEIN NAME?"
    byId.name_player.presets = { "PRISTON", "SMRAD", "BOBIK" }

    byId.ask_rival_name.text = "Das ist GASTON.\nDer neue LIEBLING\vdes Hofes.\f"
      .. "SEIN Ruecken wird\ngekrault.\f"
      .. "Und ER hat deine\nVerbannung\veingefaedelt!"
    byId.name_rival.title = "SEIN NAME?"
    byId.name_rival.presets = { "GASTON", "FIFI", "LORD" }

    byId.legend.text = "{PLAYER}!\nDeine Reise\vbeginnt jetzt!\f"
      .. "Hol dir die EHRE\ndes Koenigshauses\vzurueck!\f"
      .. "Und vielleicht...\nein Bad."

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
