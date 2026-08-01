-- "Nad Tatrou sa blyska" -- die slowakische Hymne (Volksweise "Kopala
-- studienku", gemeinfrei) als eigenes ChipAsm-Arrangement fuer PRISTONs
-- Heimweh. Zwei Pulskanaele: Melodie + einfacher Begleitbass, 3/4-Gefuehl.
local ChipAsm = require("src.audio.ChipAsm")

return ChipAsm.song{
  tempo = 0x150,
  channels = {
    { hw = 1, program = {
      { duty = 2 },
      { notetype = { speed = 12, volume = 10, fade = 2 } },
      { label = "melodie" },
      -- Nad Tatrou sa blyska
      { octave = 5 },
      { note = "E", len = 4 }, { note = "E", len = 4 },
      { note = "D", len = 2 }, { note = "C", len = 2 },
      { octave = 4 }, { note = "B", len = 6 }, { rest = 2 },
      -- hromy divo biju
      { octave = 5 },
      { note = "C", len = 4 }, { note = "D", len = 4 },
      { octave = 4 },
      { note = "B", len = 2 }, { note = "A", len = 2 },
      { note = "G", len = 6 }, { rest = 2 },
      -- Zastavme ich, bratia
      { note = "G", len = 2 }, { note = "A", len = 2 },
      { note = "B", len = 4 },
      { octave = 5 }, { note = "C", len = 2 },
      { octave = 4 }, { note = "B", len = 2 },
      { note = "A", len = 6 }, { rest = 2 },
      -- ved sa ony stratia
      { note = "B", len = 2 },
      { octave = 5 }, { note = "C", len = 2 },
      { octave = 4 },
      { note = "A", len = 2 }, { note = "G", len = 2 },
      { note = "F#", len = 4 }, { note = "E", len = 6 }, { rest = 2 },
      -- Slovaci oziju
      { note = "E", len = 2 }, { note = "G", len = 2 },
      { note = "B", len = 4 },
      { octave = 5 }, { note = "E", len = 4 },
      { note = "D", len = 2 }, { note = "C", len = 2 },
      { octave = 4 }, { note = "B", len = 8 },
      { note = "A", len = 2 }, { note = "G", len = 2 },
      { note = "F#", len = 4 }, { note = "E", len = 10 },
      { rest = 8 },
      { loop = { count = 0, to = "melodie" } },
    } },
    { hw = 2, program = {
      { duty = 1 },
      { notetype = { speed = 12, volume = 6, fade = 1 } },
      { octave = 3 },
      { label = "bass" },
      { note = "E", len = 8 }, { note = "G", len = 8 },
      { note = "A", len = 8 }, { note = "E", len = 8 },
      { note = "C", len = 8 }, { note = "D", len = 8 },
      { note = "B", len = 8 }, { note = "E", len = 8 },
      { note = "E", len = 8 }, { note = "A", len = 8 },
      { note = "B", len = 8 }, { note = "E", len = 12 },
      { rest = 4 },
      { loop = { count = 0, to = "bass" } },
    } },
  },
}
