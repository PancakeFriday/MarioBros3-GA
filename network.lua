local Network = Object:extend()

function Network:new()
  self.neurons = {}

  -- Let's create the map
  for x=0,18 do
    for y=0,27 do
      self:newNeuron("map", x, y, 0) -- They are all not gonna fire (for now)
    end
  end

  -- Let's create the inputs
  self:newNeuron("input", 50, 10, 1, "up")
  self:newNeuron("input", 50, 13, 1, "down")
  self:newNeuron("input", 50, 16, 1, "left")
  self:newNeuron("input", 50, 19, 1, "right")
  self:newNeuron("input", 50, 22, 1, "A")
  self:newNeuron("input", 50, 25, 1, "B")
end

function Network:applyMeta()
  for i,col in pairs(self.neurons) do
    for j,v in pairs(col) do
      setmetatable(v, Neuron)
      v:applyMeta()
    end
  end
end

function Network:copy()
  local t = Network()
  t.neurons = {}
  for x, col in pairs(self.neurons) do
    for y, n in pairs(col) do
      if not t.neurons[x] then t.neurons[x] = {} end
      t.neurons[x][y] = n:copy()
    end
  end
  return t
end

function Network:newNeuron(tp, x,y, fact, fireAction)
  if not self.neurons[x] then self.neurons[x] = {} end
  self.neurons[x][y] = Neuron(tp, x,y, fact, fireAction)
end

function Network:insert(n)
  if not self.neurons[n.x] then self.neurons[n.x] = {} end
  self.neurons[n.x][n.y] = n:copy()
end

function Network:reconnect()
  for i,v in pairs(self:getOutboundNeurons()) do
    for j,k in pairs(v.outNeurons) do
      v.outNeurons[j] = self:getNeuron(k.x,k.y)
    end
  end
end

function Network:fixMissing()
  for i, n in grandChildren(self.neurons) do
    for j, k in pairs(n.outNeurons) do
      self:insert(k)
    end
  end
end

function Network:mutate()
-- Mutation
-- I will implement mutation, by randomly swapping neurons with their neighbors
-- Do this a random number of times
  local outBoundNeurons = self:getOutboundNeurons()
  for i,v in pairs(outBoundNeurons) do
    -- Swap this neurons outneurons with its neighbors outneurons
    if _.random(0,1) <= mutationChance then
      local neighbor
      while(not neighbor) do
        local ranx = _.randomchoice({-1,0,1})
        local rany = _.randomchoice({-1,0,1})

        neighbor = self:getNeuron(v.x + ranx, v.y + rany)
      end
      v:swap(neighbor)
    end
  end
end

function Network:getNeuron(x,y)
  if self.neurons[x] and self.neurons[x][y] then
    return self.neurons[x][y]
  end
  return nil
end

function Network:getOutboundNeurons()
  local t = {}
  for i, n in grandChildren(self.neurons) do
    if _.count(n.outNeurons) > 0 and n.type == "map" then
      table.insert(t,n)
    end
  end
  return t
end

function Network:updateNeuron(x,y,fact)
  self.neurons[x][y].fact = fact
end

function Network:ranConnection(n)
  local choice = {}
  for i, n in grandChildren(self.neurons) do
    -- start connecting from a map neuron
    if n.type == "map" then
      table.insert(choice, n)
    end
  end

  local startN = _.randomchoice(choice)
  local endN = nil
  if n then endN = self.neurons[n.x][n.y] end
  -- If we connect to an intermediate neuron, connect the start neuron to it
  -- then go on
  while(startN.type ~= "input") do
    if not endN then
      choice = {}
      for i,n in grandChildren(self.neurons) do
        if n.type ~= "map" and n.x > startN.x then
          table.insert(choice, n)
        end
      end

      endN = _.randomchoice(choice)
    end
    startN:connect(endN)
    startN = endN
    endN = nil
  end
end

function Network:ranNeuron()
  local ranx = _.randomchoice(range(20,48))
  local rany = _.randomchoice(range(2,30))
  while self:getNeuron(ranx, rany) ~= nil do
      ranx = _.randomchoice(range(20,48))
      rany = _.randomchoice(range(2,30))
  end
  local ranfact = _.randomchoice({-1,1})
  self:newNeuron("inter", ranx, rany, ranfact)
  return self:getNeuron(ranx,rany)
end

function Network:anyInput()
  for i, n in grandChildren(self.neurons) do
    if n.type == "input" then
      if n.fireValue > 0 then
        return true
      end
    end
  end
  return false
end

function Network:update()
  self.neurons["map"] = {}
  local playerx = math.floor(memory.readlbyte(hex("90"), hex("75"))/16) - 4
  local playery = math.floor((memory.readlbyte(hex("A2"), hex("87")))/16) - 15
  for x=0,18 do
    for y=0,27 do
      local col, type = Minimap:get(x + playerx,y + playery)
      if col and type == "map" then
        self:updateNeuron(x,y,1)
      elseif col and type == "enemy" then
        self:updateNeuron(x,y,-1)
      else
        self:updateNeuron(x,y,0)
      end
    end
  end

  for i, n in grandChildren(self.neurons) do
    -- We only fire the map neurons, which will fire anything connected to them
    if n.type == "map" then
      n:fire()
    end
  end

  -- Now do the inputs
  for i, n in grandChildren(self.neurons) do
    n:action()
  end
end

function Network:draw()
  for i, n in grandChildren(self.neurons) do
    if drawgui then
      n:draw()
    end
    n:reset()
  end
end

return Network
