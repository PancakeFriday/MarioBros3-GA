_ = require "lib.lume"
Object = require "lib.classic"
vec2 = require "pancake.vec2"

require "util"
require "vars"
binser = require "binser"

Timer = require "timer"
Minimap = require "minimap"
InputHandler = require "inputhandler"
Neuron = require "neuron"
Network = require "network"
Mario = require "mario"
PopulationFactory = require "population"
Population = PopulationFactory()
Options = require "options"

print("--- Starting bot ---")

emu.speedmode(speedmode)

function init()
  resOutput()
  mainSave = savestate.create(2)
  savestate.load(mainSave)
  Minimap:load()
end

function update()
  Options:update()
  Timer:update()
  InputHandler:flush()

  Minimap:update()
  Population:update()
end

function draw()
  Population:draw()
end

-- DO NOT EDIT BEYOND THIS LINE --
----------------------------------
init()

while true do
  update()

  draw()

  -- for i=0,100 do
  --   local s = 15
  --   gui.text(math.floor(i/s)*s*2, (i%s)*s, memory.readbyte(hex("0") + i))
  -- end

  emu.frameadvance()
end
