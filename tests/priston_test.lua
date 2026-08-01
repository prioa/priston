-- Standalone: luajit mods/priston/tests/priston_test.lua
-- Laedt den Mod durch den echten Loader und prueft die erklaerten Effekte:
-- Sprite-Registrierung, field-Patches, Intro-Steps, Save-Verdrahtung.
--
-- Braucht einen importierten ROM-Datensatz (data/generated/); ohne den
-- wird sauber uebersprungen -- modkit validate deckt den Load headless ab.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function hasGenerated()
  local handle = io.open("data/generated/constants.lua", "r")
  if handle then handle:close() return true end
  return false
end
if not hasGenerated() then
  print("priston_test skipped (needs data/generated/)")
  os.exit(0)
end

local T = require("tests.modkit")
local Runtime = require("src.mods.Runtime")
local OakSpeech = require("src.ui.OakSpeech")
local Data = require("src.core.Data")
Data:load()

local run = T.sdk.loadMod("mods/priston", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")
local mod = run.mod
T.check(mod ~= nil and mod.state == "loaded", "mod reached the loaded state")

-- ------- der Hund ist der Spieler

local sprite = Data.sprites and Data.sprites.SPRITE_PRISTON
T.check(sprite ~= nil, "SPRITE_PRISTON registered")
T.eq(sprite.frames, 6, "walker sheet has 6 frames")
T.check(sprite.walker == true, "sprite is a walker")
T.check(sprite.trueColor == true, "walker opts out of the 4-shade remap")

-- der player.sprite-Hook markiert unsere farbigen Pics als trueColor
local Sprites = require("src.pokemon.Sprites")
local _, backTrue = Sprites.playerPath(Data, "back", { kind = "battle" })
T.check(backTrue == true, "battle back pic resolves trueColor")
local _, frontTrue = Sprites.playerPath(Data, "front", { kind = "intro" })
T.check(frontTrue == true, "intro front pic resolves trueColor")

-- Slowakei-Grading: jede Map-Palette hat eine SLOVAK_-Variante
if Data.palettes and Data.palettes.palettes then
  local pals = Data.palettes.palettes
  local sampled, gradedOk = 0, 0
  for name in pairs(pals) do
    if not name:find("^SLOVAK_") and pals["SLOVAK_" .. name] then
      sampled = sampled + 1
      local v = pals["SLOVAK_" .. name]
      if type(v) == "table" and (v.colors or v[1]) then gradedOk = gradedOk + 1 end
    end
  end
  T.check(sampled > 0, "graded palette variants registered")
  T.eq(sampled, gradedOk, "graded variants carry 4-color tables")
end

T.eq(Data.field.playerSprites.walk, "SPRITE_PRISTON",
  "player walks as PRISTON")
T.check(Data.field.playerSprites.bike ~= "SPRITE_PRISTON",
  "bike sprite stays vanilla (patch, not override)")
T.check(Data.field.playerPics.back:find("priston_back", 1, true) ~= nil,
  "battle back pic replaced")
T.check(Data.field.playerPics.front:find("priston_front", 1, true) ~= nil,
  "front pic replaced")

local presets = Data.field.boot.namePresets
T.eq(presets.player[1], "PRISTON", "PRISTON leads the player presets")
T.eq(presets.rival[1], "GASTON", "GASTON leads the rival presets")
T.check(#presets.player > 3, "vanilla player presets survive the prepend")

T.check(Data.audio and Data.audio.cries and Data.audio.cries.PRISTON ~= nil,
  "PRISTON cry registered")

-- ------- das Intro erzaehlt die Verbannung

local speech = OakSpeech.new({
  data = Data,
  save = { player = { name = "PRISTON", rival = "GASTON" } },
  stack = { push = function() end, pop = function() end },
}, nil)
local steps = speech:buildSteps()

local byId, order = {}, {}
for i, step in ipairs(steps) do byId[step.id] = step; order[step.id] = i end

T.check(byId.oak_welcome and byId.name_player and byId.shrink,
  "vanilla anchors still present")
T.check(byId.priston_reveal and byId.priston_story and byId.priston_banished
        and byId.priston_oath, "all four story beats injected")
T.check(order.world_spiel < order.priston_reveal
        and order.priston_reveal < order.priston_story
        and order.priston_story < order.priston_banished
        and order.priston_banished < order.priston_oath
        and order.priston_oath < order.ask_player_name,
  "story sits between world spiel and the naming")

T.eq(byId.priston_oath.kind, "yesno", "the oath is a yes/no")
T.eq(byId.priston_oath.saveKey, "ehre_schwur", "oath writes ehre_schwur")
T.eq(byId.priston_reveal.cry, "PRISTON", "reveal plays the dog's cry")
T.check(byId.priston_reveal.pic and byId.priston_reveal.pic.type == "image",
  "reveal shows the portrait")
T.check(byId.oak_welcome.text ~= nil, "welcome text replaced (German)")
T.eq(byId.name_player.presets[1], "PRISTON", "naming screen leads with PRISTON")
T.eq(byId.name_rival.presets[1], "GASTON", "rival naming leads with GASTON")

-- ------- Antworten landen im Mod-Save

Runtime.emit("intro.oak_speech.answered", {
  saveKey = "ehre_schwur", value = true, label = "JA", index = 1,
  step = byId.priston_oath, speech = speech,
})
Runtime.emit("intro.oak_speech.finished", { speech = speech, answers = {} })

local bucket = run.loader.modSave.priston or {}
T.eq(bucket.ehre_schwur, true, "oath answer saved")
T.eq(bucket.intro_gesehen, true, "intro completion stamped")

run.release()
T.finish("priston")
