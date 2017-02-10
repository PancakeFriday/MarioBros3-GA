local Mario = Object:extend()

function Mario:new(first)
  self.alive = true

  self.network = Network()

  self.prev = {}

  self.pos = vec2()
  self.prev.pos = vec2()

  self.speed = vec2()
  self.prev.speed = vec2()

  self.jumping = 0
  self.floor = 0
  self.prev.floor = 0

  self.waitmode = 0

  self.fitness = 0
  self.fitnessCont = {}
  self.prev.fitness = 0
  self.maxFitness = -1

  self.idleTime = 0

  if _.random(0,1) < neuronChance then
    local n = self.network:ranNeuron()
    self.network:ranConnection(n)
  end
  if _.random(0,1) < connectionChance then
    self.network:ranConnection()
  end
  --
  -- -- walking
  -- if first then
  --   self.network:getNeuron(10,17):connect(self.network:getNeuron(50,19))
  -- end
  -- -- jumping
  -- self.network:newNeuron("inter", 30, 18, 1)
  -- self.network:getNeuron(6,17):connect(self.network:getNeuron(30, 18))
  -- self.network:getNeuron(30,18):connect(self.network:getNeuron(50, 22))
end

function Mario:applyMeta()
  setmetatable(self.network, Network)
  self.network:applyMeta()
  setmetatable(self.pos, vec2)
  setmetatable(self.prev.pos, vec2)
  setmetatable(self.speed, vec2)
  setmetatable(self.prev.speed, vec2)
end

function Mario:copy()
  local t = Mario()
  t.network = self.network:copy()
  return t
end

function Mario:calcFitness()
  if self.waitmode ~=1 then
    if self.fitnessCont[self.pos.x] then
      self.fitness = self.fitnessCont[self.pos.x]
    else
      self.fitness = self.fitness
      + ((self.pos.x - self.prev.pos.x) * math.abs(self.speed.x))/10
      * (self.floor)*highGroundFactor
      self.fitnessCont[self.pos.x] = self.fitness
    end
  end

  for i,v in pairs(self.fitnessCont) do
    if i > self.pos.x then
      table.remove(self.fitnessCont, i)
    end
  end

  if self.fitness < 0 then self.fitness = 0 end

  if self.fitness > self.maxFitness then
    self.maxFitnessTime = 0
    self.maxFitness = self.fitness
  else
    self.maxFitnessTime = self.maxFitnessTime + 1
  end
end

function Mario:kill()
  self.alive = false
end

function Mario:update()
  -- gui.text(100,100,self.floor)
  -- gui.text(100,110,self.jumping)
  self.prev.fitness = self.fitness
  self.prev.pos = vec2(self.pos.x, self.pos.y) -- I want a copy not a reference
  self.prev.speed = vec2(self.speed.x, self.speed.y)

  self.pos.x = memory.readlbyte(hex("90"), hex("75"))
  self.pos.y = memory.readlbyte(hex("A2"), hex("87"))

  self.speed.x = tosignedbyte(memory.readbyte(hex("BD")))
  self.speed.y = tosignedbyte(memory.readbyte(hex("CF")))

  self.jumping = memory.readbyte(hex("D8"))

  if self.jumping == 1 then
    InputHandler:add("A")
    InputHandler:noground()
  else
    InputHandler:ground()
  end

  if self.jumping == 0 then
    self.prev.floor = self.floor
    self.floor = math.ceil((400 - self.pos.y)/16)*16
  end

  self.waitmode = memory.readbyte(hex("58C"))

  self:calcFitness()
  -- Update the network before the rest, or else the neurons will have fireValue 0
  self.network:update()

  -- Kill him if he's just idling
  if not self.network:anyInput() and self.speed.x == 0 and self.speed.y == 0 then
    self.idleTime = self.idleTime + 1
  else
    self.idleTime = 0
  end
  if self.idleTime > idleTimeout then
    self:kill()
  end

  -- Kill him if the fitness didn't update for some time
  if self.maxFitnessTime > fitnessTimeout then
    self:kill()
  end

  -- below the floor
  if self.pos.y > 410 then
    self:kill()
  end
end

function Mario:draw()
  self.network:draw()
end

return Mario
