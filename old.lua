local _ = require "lib.lume"
local Object = require "lib.classic"

print("--- Starting bot ---")

function hex(n)
  return tonumber("0x" .. n)
end

function tobyte(n)
  if n > 128 then
    return n-255
  end
  return n
end

function getm(n)
  return tobyte(memory.readbyte(hex(n)))
end

local Timer = {}
Timer.frames = 0

Mario = Object:extend()

local speedmode = "maximum"

local gamestate = "Init"
local maxPopulation = 1000
local mutationValue = 0.9
local idleTime = 100 -- in frames

-- How many make it into the next generation
local numElites = 50
local numCrossovers = 0
local numMutates = 0

local mario = Mario()
local Population = Object:extend()
local generation = 0

state = savestate.create(1)

Input = Object:extend()

function Input:new()
  self.inputs = {}
end

function Input:add(v)
  self.inputs[v] = true
end

function Input:flush()
  joypad.write(1,self.inputs)
  self.inputs = {}
end
input = Input()

function getRandomInput()
  local inputtable = {}

  local ranInputs = {}
  ranInputs[1] = _.weightedchoice({["left"] = 1, ["right"] = 1, ["up"] = 1, ["down"] = 1, ["none"] = 4})
  ranInputs[2] = _.weightedchoice({["A"] = 1, ["none"] = 1})
  ranInputs[3] = _.weightedchoice({["B"] = 1, ["none"] = 1})
  for i,v in pairs(ranInputs) do
    if v ~= "none" then
      inputtable[v] = true
    end
  end

  return inputtable
end

function Population:new()
  self.members = {}
end

function Population:add(m)
  table.insert(self.members, m)
end

function Population:getMaxFitness()
  local maxFitness = -1
  for i,v in pairs(self.members) do
    if v.vars.fitness > maxFitness then
      maxFitness = v.vars.maxFitness
    end
  end
  return maxFitness
end

function Population:getAvgFitness()
  local sum = 0
  for i,v in pairs(self.members) do
    sum = sum + v.vars.maxFitness
  end
  return sum / _.count(self.members)
end

function Population:getCrossover(mutated)
  local child = Mario()
  if _.count(self.members) > 2 then
    local weights = {}
    for i,v in pairs(self.members) do
      weights[i] = math.max(v.vars.fitness,1)
    end
    local mother = self.members[_.weightedchoice(weights)]
    weights[mother] = 0
    local father = self.members[_.weightedchoice(weights)]

    if _.count(father.brain.connectionmap) > _.count(mother.brain.connectionmap) then
      local t = mother
      mother = father
      father = t
    end

    -- Loop through the larger one
    for i,x in pairs(mother.brain.connectionmap) do
      local rand = _.random(0,1)
      local parent
      if i > _.count(father.brain.connectionmap) then
        parent = mother
      else
        if rand < 0.5 then parent = mother else parent = father end
      end
      local connection = parent.brain.connectionmap[i]
      -- Only consider connections going to an out node
      if connection then
        local outNeuron = parent.brain:getNeuron(connection.x1, connection.y1)
        local inNeuron = parent.brain:getNeuron(connection.x2, connection.y2)
        if inNeuron and inNeuron.mode == "in" then
          if outNeuron.mode == "inout" then
            -- I need to create the connection and the neuron
            child.brain:newNeuron(outNeuron.mode, outNeuron.type, outNeuron.x, outNeuron.y)
            child.brain:newConnection(outNeuron, connection.x2, connection.y2)
            -- Get at least one connection to the intermediate node
            for j,k in pairs(father.brain.connectionmap) do
              if k.x2 == connection.x1 and k.y2 == connection.y1 then
                local originNeuron = parent.brain:getNeuron(k.x1, k.y1)
                child.brain:newConnection(originNeuron, k.x2, k.y2)
              end
            end
          else
            child.brain:newConnection(outNeuron, connection.x2, connection.y2)
          end
        else
          --child.brain:newConnection(outNeuron, connection.x2, connection.y2)
        end
      end
    end
  end

  if mutated then
    -- chance to either create an intermediate neuron and connect to it
    -- or just connect to an existing neuron
    local choice = _.weightedchoice({["connection"] = 50, ["intermediate"] = 20, ["remove"] = 1, ["move"] = 40})
    if choice == "intermediate" then
      -- create intermediate neuron
      -- 18 -- 48
      local cranx, crany = math.random(18,35), math.random(11,26)
      child.brain:newNeuron("inout", "intermediate", cranx, crany)
      local ranx = math.random(0,16)
      local rany = math.random(17,26)
      child.brain:newConnection(child.brain:getNeuron(cranx, crany), ranx, rany)
      local outNeurons = {}
      for i,v in pairs(child.brain.neuronmap) do
        if v.mode == "out" then
          table.insert(outNeurons,v)
        end
      end
      local outN = _.randomchoice(outNeurons)
      child.brain:newConnection(outN, cranx, crany)
    elseif choice == "connection" then
      -- just connect to an existing neuron
      local outNeurons = {}
      for i,v in pairs(child.brain.neuronmap) do
        if v.mode == "out" or v.mode == "inout" then
          table.insert(outNeurons,v)
        end
      end
      local outN = _.randomchoice(outNeurons)
      local ranx = math.random(0,16)
      local rany = math.random(17,26)
      child.brain:newConnection(outN, ranx, rany)
    elseif choice == "remove" then
      if _.count(child.brain.connectionmap) > 1 then
        local rand = math.random(1,_.count(child.brain.connectionmap))
        child.brain.connectionmap[rand] = nil
      end
    elseif choice == "move" then
      local inConnections = {}
      for i,v in pairs(child.brain.connectionmap) do
        local n = child.brain:getNeuron(v.x2, v.y2)
        if n == nil or n.type == "in" then
          table.insert(inConnections,v)
        end
      end
      if _.count(inConnections) > 0 then
        local inC = _.randomchoice(inConnections)
        local ranx = _.randomchoice({-1,0,1})
        local rany = _.randomchoice({-1,0,1})
        inC.x2 = inC.x2 + ranx
        inC.y2 = inC.y2 + rany
      end
    end
  end
  return child
end

function Population:getMutated()
  return self:getCrossover(true)
end

function Population:getElite(num)
  local maxit = -1
  local maxFitness = 0
  local maxFitnessChild = nil
  local biggestFitness = 100000000000
  for i=1,num do
    maxit = -1
    maxFitness = 0
    maxFitnessChild = nil
    for j,k in pairs(self.members) do
      if k.vars.fitness > maxFitness and k.vars.fitness < biggestFitness then
        maxFitness = k.vars.fitness
        maxit = j
        maxFitnessChild = k
      end
    end
    biggestFitness = maxFitness
  end
  return maxFitnessChild
end

function Population:createChild()
  -- Create crossover or mutation
  local rand = _.random(0,1)
  if rand < mutationValue then
    return self:getMutated()
  else
    return self:getCrossover()
  end
end

function Population:getSize()
  return _.count(self.members)
end

function Population:getNextGeneration()
  local t = {}
  for i=1,numElites do
    table.insert(t,self:getElite(i))
  end
  for i=1,numCrossovers do
    table.insert(t,self:getCrossover())
  end
  for i=1,numMutates do
    table.insert(t,self:getMutated())
  end
  print("NumElites: " .. _.count(t))
  for i,v in pairs(t) do
    print("Fitness: " .. v.vars.fitness)
  end
  return t
end

local population = Population()

function Mario:new()
  self.prev = {}
  self.vars = {}
  self.vars.fitness = 0
  self.vars.posx = getm("00090")
  self.vars.posy = getm("000A2")
  self.vars.speedx = getm("000BD")
  self.vars.speedy = getm("000CF")
  self.vars.form = getm("000ED")
  self.vars.lives = getm("0736")
  self.brain = NNetwork()

  self.vars.maxFitness = -1
  self.vars.maxFitnessTime = Timer.frames
  self.vars.startTime = Timer.frames

  self.inputs = {}
end

function Mario:input(t)
  self:addInput(t)
  joypad.write(1, t)
end

function Mario:getLastInput()
  return self.inputs[_.count(self.inputs)]
end

function Mario:addInput(t)
  table.insert(self.inputs, t)
end

function Mario:calcFitness()
  self.vars.fitness = self.vars.fitness
  + ((self.vars.posx - self.prev.posx) * math.abs(self.vars.speedx))/10

  if self.vars.fitness < 0 then self.vars.fitness = 0 end

  if self.vars.fitness > self.vars.maxFitness then
    self.vars.maxFitnessTime = Timer.frames
    self.vars.maxFitness = self.vars.fitness
  end
end

function Mario:getResponse()
  return self.vars.fitness - self.prev.fitness
end

function Mario:update()
  self.prev.posx = self.vars.posx
  self.prev.posy = self.vars.posy
  self.prev.speedx = self.vars.speedx
  self.prev.speedy = self.vars.speedy
  self.prev.form = self.vars.form
  self.prev.lives = self.vars.lives
  self.prev.fitness = self.vars.fitness

  self.vars.posx = memory.readbyte(hex("90")) + memory.readbyte(hex("75"))*2^8
  self.vars.posy = memory.readbyte(hex("A2")) + memory.readbyte(hex("87"))*2^8
  self.vars.speedx = getm("000BD")
  self.vars.speedy = getm("000CF")
  self.vars.form = getm("000ED")
  self.vars.lives = getm("0736")

  if self.vars.lives < 4 then
    mario:kill()
  elseif Timer.frames - self.vars.maxFitnessTime >= idleTime then
    self:kill()
  end
end

function Mario:kill()
  population:add(self)
  gamestate = "Init"

  if population:getSize() > maxPopulation then
    gamestate = "NewGeneration"
  end
end

function getInput()
    if joypad.read(1)["select"] then
      if speedmode == "normal" then
        speedmode = "maximum"
      else
        speedmode = "normal"
      end
      emu.speedmode(speedmode)
    end
end

emu.speedmode(speedmode)

function range(a,b)
  local t = {}
  for i=a,b do
    table.insert(t,i)
  end
  return t
end

function intable(a,t)
  for i,v in pairs(t) do
    if a == v then return true end
  end
  return false
end

Neuron = Object:extend()

function Neuron:new(mode,type,x,y,value)
  self.mode = mode
  self.x = x
  self.xoff = 0
  self.y = y
  self.yoff = 0
  self.value = value
  self.type = type
end

function Neuron:draw(xoff,yoff,width)
  local x = (self.x - self.xoff)*width + xoff
  local y = (self.y - self.yoff)*width + xoff
  local w = (self.x - self.xoff)*width + xoff + width
  local h = (self.y - self.yoff)*width + yoff + width

  local fill = "white"
  local border = "black"
  if self.type == "enemy" then
    fill = "red"
  end
  gui.box(x,y,w,h, fill, border)
end

function Neuron:doAction()
  input:add(self.type)
end

Connection = Object:extend()

function Connection:new(x1,y1,x2,y2)
  self.x1 = x1
  self.y1 = y1
  self.x2 = x2
  self.y2 = y2
  self.active = false
end

function Connection:draw(xoff,yoff,width)
  local color = "white"
  if self.active then color = "blue" end
  gui.line(self.x1*width + xoff+2, self.y1*width + yoff+2, self.x2*width + xoff+2, self.y2*width + yoff+2,color)
end

NNetwork = Object:extend()

function NNetwork:new()
  self.startbyte = hex("6000")
  self.width, self.height = 16,27
  self.map = {}
  self.neuronmap = {}
  self.connectionmap = {}
  self.enemiesx = {}
  self.enemiesy = {}

  for i=0,hex("794f")-hex("6000") do
    local x = ((i%self.width) + math.floor(i/(self.width*self.height))*(self.width))
    local y = (math.floor(i/self.width)%self.height)

    if not self.map[x] then self.map[x] = {} end
    self.map[x][y] = memory.readbyte(self.startbyte + i)
  end

  -- All the blocks which have a collision
  local collision = _.concat({4}, range(37,53), range(68,70), range(80,117), {121},range(160,191), range(219,255))
  -- Generate neuronmap
  local playerx = memory.readbyte(hex("90")) + memory.readbyte(hex("75"))*2^8
  for x,v in pairs(self.map) do
    for y,k in pairs(v) do
      if intable(self.map[x][y], collision) then
          self:newNeuron("in","collision",x,y,1)
      end
    end
  end

  -- Let's try an intermediate neuron
  -- self:newNeuron("inout", "intermediate",35,10)

  -- Get some neurons for our controls
  self:newNeuron("out","left",40,0,1)
  self:newNeuron("out","right",40,3,1)
  self:newNeuron("out","up",40,6,1)
  self:newNeuron("out","down",40,9,1)
  self:newNeuron("out","A",40,12,1)
  self:newNeuron("out","B",40,15,1)
end

function NNetwork:newNeuron(mode,type,x,y,val)
  table.insert(self.neuronmap, Neuron(mode,type,x,y,val))
end

function NNetwork:getNeuron(x,y)
  for i,v in pairs(self.neuronmap) do
    if x < 16 then
      if v.x - v.xoff == x and v.y - v.yoff == y then
        return v
      end
    else
      if v.x == x and v.y == y and v.type ~= "collision" then
        return v
      end
    end
  end
  return nil
end

-- The connection will always start from a neuron!
function NNetwork:newConnection(n1,x2,y2)
  table.insert(self.connectionmap, Connection(n1.x, n1.y, x2, y2))
end

function NNetwork:update()
  local camxinblocks = memory.readbyte(hex("90")+89)
  local playerx = math.floor((memory.readbyte(hex("90")) + memory.readbyte(hex("75"))*2^8)/16) - 1
  local playery = math.floor((memory.readbyte(hex("A2")) + memory.readbyte(hex("87"))*2^8)/16) - 24
  for i,v in pairs(self.neuronmap) do
    if v.type == "enemy" then
      self.neuronmap[i] = nil
    end

    -- if x == math.floor(playerx/16) and y == math.floor(playery/16)+1 then
    --   self:newNeuron("in",x,y,2)
    -- end
    --
    for p,_ in pairs(self.enemiesx) do
      if x == self.enemiesx[p] and y == self.enemiesy[p] then
        self:newNeuron("in",x,y,0)
      end
    end
    if v.type == "collision" then
      v.xoff = playerx
      v.yoff = playery
    end
  end

  -- enemies
  xlow = hex("91")
  xhigh = hex("76")
  ylow = hex("A3")
  yhigh = hex("88")
  for i=0,4 do
    local x = math.floor((memory.readbyte(xlow+i) + memory.readbyte(xhigh+i)*2^8)/16)
    local y = math.floor((memory.readbyte(ylow+i) + memory.readbyte(yhigh+i)*2^8)/16)
    self:newNeuron("in", "enemy",x,y,0)
    self.neuronmap[_.count(self.neuronmap)].xoff = playerx
    self.neuronmap[_.count(self.neuronmap)].yoff = playery
  end

  -- Intersection
  for i,v in pairs(self.connectionmap) do
    v.active = false
  end
  for i,v in pairs(self.connectionmap) do
    -- Get intersection
    local outNeuron = self:getNeuron(v.x1, v.y1)
    local inNeuron = self:getNeuron(v.x2, v.y2)

    -- Only consider connections going to in neurons
    if inNeuron and inNeuron.mode == "in" then
      if outNeuron then
        if outNeuron.mode == "out" then
          v.active = true
        else
          -- Loop through all connections going to this node
          for j,k in pairs(self.connectionmap) do
            if k.x2 == v.x1 and k.y2 == v.y1 then
              k.active = true
              v.active = true
            end
          end
        end
      end
    end
  end

  for i,v in pairs(self.connectionmap) do
    -- Now activate the neurons
    local outNeuron = self:getNeuron(v.x1, v.y1)
    if v.active and outNeuron.mode == "out" then
      outNeuron:doAction()
    end
  end
end

function NNetwork:draw()
  camxinblocks = memory.readbyte(hex("00090")+89)

  -- yes, I found those through trial and error
  -- collisions: 4, 37-53,68-70,80-117,160-191,219-255 (starting at 0)

  -- local camxinblocks = memory.readbyte(hex("90")+89)
  -- local camxincoords = memory.readbyte(hex("90")+109)
  -- local playerxinblocks = memory.readbyte(hex("90")+84)
  -- local playerx = memory.readbyte(hex("90")) + memory.readbyte(hex("75"))*2^8
  -- local playery = memory.readbyte(hex("A2")) + memory.readbyte(hex("87"))*2^8

  -- Controls
  gui.text(185,8,"Left")
  gui.text(185,20,"Right")
  gui.text(185,32,"Up")
  gui.text(185,44,"Down")
  gui.text(185,56,"A")
  gui.text(185,68,"B")

  local w = 4
  local xoff
  local xoff = 10
  local yoff = 10
  for i,v in pairs(self.neuronmap) do
    if v.x - v.xoff < 16 or v.type ~= "collision" then
      v:draw(xoff,yoff,w)
    end
  end

  for i,v in pairs(self.connectionmap) do
    v:draw(xoff,yoff,w)
  end
end

while (true) do
  math.randomseed(os.time() + Timer.frames)
  Timer.frames = Timer.frames + 1
  -- Cheat
  -- memory.writebyte(hex("000ED"), 5)
  if gamestate == "Init" then
    savestate.load(state)
    gamestate = "Init2"
  end

  if gamestate == "Init2" then
    if memory.readbyte(hex("321")) == 240 then -- Level fully loaded (weird, right?)
      mario = population:createChild()
      gamestate = "Update"
    else
      emu.frameadvance()
    end
  end

  if gamestate == "NewGeneration" then
    print("Generation: " .. generation)
    print("Avg Fitness: " .. population:getAvgFitness())
    print("Max Fitness: " .. population:getMaxFitness())
    generation = generation + 1
    local children = population:getNextGeneration()
    population = Population()

    for i,v in pairs(children) do
      population:add(v)
    end
    print("--- NEW GENERATION ---")
    print("Generation: " .. generation)
    print("Avg Fitness: " .. population:getAvgFitness())
    print("Max Fitness: " .. population:getMaxFitness())

    gamestate = "Init"
  end

  if gamestate == "Update" then
    gui.text(10,10,mario.vars.fitness)
    gui.text(10,20,"Generation: " .. generation)
    gui.text(10,30,"Population: " .. population:getSize())
    gui.text(10,40,"Avg Fitness: " .. string.sub(population:getAvgFitness(), 0, 5))
    gui.text(10,50,"Max Fitness: " .. population:getMaxFitness())
    getInput()

    mario:update()
    mario.brain:update()
    mario.brain:draw()
    mario:calcFitness()
    input:flush()

    emu.frameadvance()
  end
end
