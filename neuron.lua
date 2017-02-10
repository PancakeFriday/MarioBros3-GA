local Neuron = Object:extend()

local w = 4

function Neuron:new(type, x, y, fact, fireAction)
  self.type = type

  self.x = x
  self.y = y
  -- When the neuron receives an input, this is what the input is multiplied with
  -- 0 means fire (whatever the neuron is programmed to do)
  self.fact = fact
  self.fireAction = fireAction

  self.fireValue = 0

  self.modified = false

  -- Neurons only know about the neurons they are firing into
  self.outNeurons = {}
end

function Neuron:applyMeta()
  for i,v in pairs(self.outNeurons) do
    setmetatable(v, Neuron)
  end
end

function Neuron:copy()
  local newNeuron = Neuron(self.type, self.x, self.y, self.fact, self.fireAction)
  newNeuron.fireValue = self.fireValue
  newNeuron.modified = self.modified
  newNeuron.outNeurons = _.clone(self.outNeurons)
  return newNeuron
end

function Neuron:fire(val)
  local res = 0
  if not val then
    res = self.fact
  else
    res = self.fact * val
  end
  self.fireValue = self.fireValue + res

  for i,v in pairs(self.outNeurons) do
    v:fire(res)
  end
end

function Neuron:action()
  if self.fireAction and self.fireValue > 0 then
    InputHandler:add(self.fireAction)
  end
end

function Neuron:swap(n)
  local t1 = _.clone(n.outNeurons)
  local t2 = _.clone(self.outNeurons)
  _.clear(n.outNeurons)
  _.clear(self.outNeurons)
  n.outNeurons = t2
  self.outNeurons = t1
end

function Neuron:reset()
  self.fireValue = 0
end

function Neuron:connect(n)
  self.modified = true
  table.insert(self.outNeurons, n)
end

function Neuron:draw()
  if not drawgui then
    return
  end
  local ofs = neurondrawoffset
  local color = "white"
  if self.fact == -1 then color = "red" end
  if self.fact ~= 0 then
    gui.box(ofs.x + self.x*w, ofs.y + self.y*w, ofs.x + self.x*w + w, ofs.y + self.y*w + w, color, "black")
  end

  -- Draw the connections
  for i,v in pairs(self.outNeurons) do
    color = "white"
    if self.fireValue > 0 then
      color = "blue"
    elseif self.fireValue < 0 then
      color = "red"
    end
    gui.line(ofs.x + self.x*w+w/2, ofs.y + self.y*w+w/2, ofs.x + v.x*w+w/2, ofs.y + v.y*w+w/2, color)
  end
end

return Neuron
