local Input = {}
local loaded = false
-- The jump button is not meant to stay pressed. Since I have no way of teaching that,
-- that means I have to reset it manually
local groundFrames = -1
local wait = 0
local counter = 0

function Input:load()
  self.inputs = {}
end

function Input:add(v)
  if not loaded then self:load(); loaded = true end
  self.inputs[v] = true
end

function Input:noground()
  groundFrames = -1
end

function Input:ground()
  groundFrames = groundFrames + 1
end

function Input:flush()
  if input.get()["click"] == 1 and wait > 100 then
    print("<yy")
    wait = 0
    counter = counter + 1
    if counter%2 == 0 then
      speedmode = "normal"
    elseif counter%2 == 1 then
      speedmode = "maximum"
    end

    if math.floor(counter/2)%2 == 1 then
      drawgui = true
    else
      drawgui = false
    end
    print("Set speedmode to " .. speedmode)
    print("Set drawgui to " .. tostring(drawgui))

    emu.speedmode(speedmode)
  end
  wait = wait + 1

  if not loaded then self:load(); loaded = true end
  if groundFrames == 0 then
    self.inputs["A"] = false
  end
  joypad.write(1,self.inputs)
  self.inputs = {}
end

return Input
