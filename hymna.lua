-- "Nad Tatrou sa blyska" -- die slowakische Hymne (Volksweise "Kopala
-- studienku", gemeinfrei) als eigenes ChipAsm-Arrangement.
--
-- Deklarativ: beide Stimmen stehen als Notentabellen in sauberem
-- 3/4-Takt (12 Einheiten pro Takt, 2 = Achtel, 4 = Viertel,
-- 6 = punktierte Viertel, 12 = punktierte Halbe). Die Programme werden
-- aus den Tabellen GEBAUT, und die Gesamtlaengen beider Stimmen werden
-- mitgeliefert -- main.lua verweigert die Registrierung, wenn sie nicht
-- exakt gleich sind. Loop-Drift (der alte "Musik buggt"-Fehler) ist
-- damit konstruktiv ausgeschlossen. fade = 0: getragene Stimmen halten
-- ihren ganzen Zeitschlitz -- mit Decay (fade > 0) verklingt jede Note
-- nach ~0,3s und der Rest des Slots ist STILLE (der "Musik buggt"-
-- Hoereindruck; per WAV-Analyse belegt: 19 Luecken vs. 0 bei Vanilla).
local ChipAsm = require("src.audio.ChipAsm")

-- { Oktave, Ton, Laenge }; Ton "-" = Pause
local MELODIE = {
  -- Nad Tatrou sa blyska
  { 5, "E", 6 }, { 5, "E", 2 }, { 5, "D", 4 },
  { 5, "C", 6 }, { 5, "C", 2 }, { 4, "B", 4 },
  -- hromy divo biju
  { 5, "C", 6 }, { 5, "D", 2 }, { 4, "B", 4 },
  { 4, "A", 6 }, { 4, "A", 2 }, { 4, "G", 4 },
  -- (Wiederholung des Couplets, wie gesungen)
  { 5, "E", 6 }, { 5, "E", 2 }, { 5, "D", 4 },
  { 5, "C", 6 }, { 5, "C", 2 }, { 4, "B", 4 },
  { 5, "C", 6 }, { 5, "D", 2 }, { 4, "B", 4 },
  { 4, "A", 6 }, { 4, "A", 2 }, { 4, "G", 4 },
  -- Zastavme ich, bratia
  { 4, "G", 6 }, { 4, "A", 2 }, { 4, "B", 4 },
  { 5, "C", 6 }, { 5, "C", 2 }, { 4, "B", 4 },
  -- ved sa ony stratia
  { 4, "B", 6 }, { 5, "C", 2 }, { 4, "A", 4 },
  { 4, "G", 6 }, { 4, "G", 2 }, { 4, "F#", 4 },
  -- Slovaci oziju
  { 4, "E", 6 }, { 4, "G", 2 }, { 4, "B", 4 },
  { 5, "E", 6 }, { 5, "D", 2 }, { 5, "C", 4 },
  { 4, "B", 12 },
  -- ...oziju (Schluss)
  { 4, "A", 6 }, { 4, "G", 2 }, { 4, "F#", 4 },
  { 4, "E", 12 },
}

-- ein Grundton pro Takt, punktierte Halbe -- 16 Takte wie die Melodie
local BASS = {
  { 3, "E", 12 }, { 3, "G", 12 }, { 3, "A", 12 }, { 3, "E", 12 },
  { 3, "E", 12 }, { 3, "G", 12 }, { 3, "A", 12 }, { 3, "E", 12 },
  { 3, "G", 12 }, { 3, "A", 12 }, { 3, "B", 12 }, { 3, "E", 12 },
  -- Finale hat FUENF Takte (B-Fermate + Schlusstakt)
  { 3, "E", 12 }, { 3, "C", 12 }, { 3, "B", 12 }, { 3, "B", 12 },
  { 3, "E", 12 },
}

local function laenge(stimme)
  local total = 0
  for _, n in ipairs(stimme) do total = total + n[3] end
  return total
end

local function programm(stimme, notetype, label)
  local prog = { { duty = notetype.duty },
                 { notetype = { speed = notetype.speed,
                                volume = notetype.volume,
                                fade = notetype.fade } },
                 { label = label } }
  local oktave = nil
  for _, n in ipairs(stimme) do
    local okt, ton, len = n[1], n[2], n[3]
    if ton == "-" then
      prog[#prog + 1] = { rest = len }
    else
      if okt ~= oktave then
        prog[#prog + 1] = { octave = okt }
        oktave = okt
      end
      prog[#prog + 1] = { note = ton, len = len }
    end
  end
  prog[#prog + 1] = { loop = { count = 0, to = label } }
  return prog
end

return {
  meta = { melodie = laenge(MELODIE), bass = laenge(BASS) },
  song = ChipAsm.song{
    tempo = 0x150,
    channels = {
      { hw = 1, program = programm(MELODIE,
          { duty = 2, speed = 12, volume = 10, fade = 0 }, "melodie") },
      { hw = 2, program = programm(BASS,
          { duty = 1, speed = 12, volume = 6, fade = 0 }, "bass") },
    },
  },
}
