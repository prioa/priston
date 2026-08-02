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

-- ------- der Hund ist der Follower

T.check(Data.field.playerSprites == nil
        or Data.field.playerSprites.walk ~= "SPRITE_PRISTON",
  "player sprites stay vanilla (Priston is a pet now)")

local sprite = Data.sprites and Data.sprites.SPRITE_PRISTON
T.check(sprite ~= nil, "SPRITE_PRISTON registered")
T.eq(sprite.frames, 6, "walker sheet has 6 frames")
T.check(sprite.walker == true, "sprite is a walker")
T.check(sprite.trueColor == true, "walker opts out of the 4-shade remap")

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


T.check(Data.audio and Data.audio.cries and Data.audio.cries.PRISTON ~= nil,
  "PRISTON cry registered")

-- ------- Rad, Wasser, Hymne, Umlaute

T.check(Data.audio and Data.audio.songs
        and Data.audio.songs.Music_PristonHymna ~= nil, "anthem registered")
local hymna = dofile("mods/priston/hymna.lua")
T.eq(hymna.meta.melodie, hymna.meta.bass,
  "anthem voices equal length (no loop drift)")
T.check(hymna.meta.melodie % 12 == 0, "anthem is whole 3/4 bars")
local cesar = Data.trainers.OPP_CESAR
for _, slot in ipairs(cesar.parties[1]) do
  T.check(Data.pokemon[slot.species] ~= nil,
    "CESAR party resolves: " .. tostring(slot.species))
end
T.check(Data.font and Data.font.pages
        and Data.font.pages.priston_umlauts ~= nil, "umlaut font page registered")

-- ------- die TATRA-Pipeline ist registriert

local tatra = Data.render_pipelines and Data.render_pipelines.tatra
T.check(tatra ~= nil, "tatra pipeline registered")
T.eq(tatra.label, "TATRA", "pipeline label")
T.check(type(tatra.present) == "function", "pipeline has a present pass")
T.check(type(tatra.available) == "function", "pipeline gates on availability")

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
T.check(type(byId.priston_reveal.pic) == "table"
        and byId.priston_reveal.pic.type == "image"
        and byId.priston_reveal.pic.path:find("front_gb", 1, true) ~= nil,
  "reveal shows the GB-gray portrait (intro pics get palette-tinted)")
T.check(byId.oak_welcome.text ~= nil, "welcome text replaced (German)")

-- ------- die Euro-Wirtschaft

T.check(Data.commands and Data.commands["priston:check_euro"] ~= nil,
  "check_euro command registered")
T.check(Data.commands and Data.commands["priston:pay_euro"] ~= nil,
  "pay_euro command registered")
T.check(Data.tokens and Data.tokens.PRISTON_EURO ~= nil,
  "euro token registered")
Runtime.emit("battle.ended", { battle = { kind = "trainer" }, result = "win" })
Runtime.emit("battle.ended", { battle = { kind = "wild" }, result = "win" })
Runtime.emit("battle.ended", { battle = { kind = "trainer", demo = true },
                               result = "win" })
T.eq((run.loader.modSave.priston or {}).euros, 6,
  "trainer +5, wild +1, demo zaehlt nicht")

-- ------- die Quest ist verdrahtet

T.check(Data.items.PRISTON_LAVENDELWASSER ~= nil, "Lavendelwasser registered")
T.check(Data.items.PRISTON_KRAEUTERSEIFE ~= nil, "Kraeuterseife registered")
T.check(Data.items.PRISTON_KOENIGSSIEGEL ~= nil, "Koenigssiegel registered")
T.check(Data.trainers.OPP_CESAR ~= nil, "CESAR trainer registered")
T.eq(Data.trainers.OPP_CESAR.parties[1][2].species, "ARCANINE",
  "CESAR runs Growlithe + Arcanine on the imported base")
local MapScripts = require("src.script.MapScripts")
for _, probe in ipairs({
  { "PALLET_TOWN", "TEXT_PALLETTOWN_FISHER" },
  { "LAVENDER_TOWN", "TEXT_LAVENDERTOWN_COOLTRAINER_M" },
  { "VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GIRL" },
  { "VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_BALDING_GUY" },
}) do
  local entry = MapScripts.talkScript(probe[1], probe[2])
  T.check(entry ~= nil, "quest talk handler on " .. probe[1])
end

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
