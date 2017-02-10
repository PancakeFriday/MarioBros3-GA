local Population = Object:extend()

Population.Generation = 0

function Population:new()
  self.members = {}
  self.current = nil
  self:newMember()
end

function Population:applyMeta()
  for i,v in pairs(self.members) do
    setmetatable(v, Mario)
    v:applyMeta()
  end
  setmetatable(self.current, Mario)
  self.current:applyMeta()
end

function Population:newMember()
  if _.count(self.members) > minParents then
    -- Get a new member from a mother and a father
    local choice = {}
    for i,v in pairs(self.members) do
      choice[i] = v.maxFitness
      if choice[i] < 1 then choice[i] = 1 end
    end

    local mi, fi = _.weightedchoice(choice), _.weightedchoice(choice)
    local mother = self.members[mi]:copy()
    local father = self.members[fi]:copy()
    local child = Mario()

    mother.network:mutate()
    father.network:mutate()

    local motherModN = mother.network:getOutboundNeurons()
    local fatherModN = father.network:getOutboundNeurons()
    if _.count(motherModN) < _.count(fatherModN) then
      local t = motherModN
      motherModN = fatherModN
      fatherModN = t
    end
    for i,v in pairs(motherModN) do
      if _.random(0,1) < inheritChance then
        local whichN
        if i%2 == 0 or i > _.count(fatherModN) then
          whichN = motherModN[i]
        else
          whichN = fatherModN[i]
        end
        child.network:insert(v)
        child.network:fixMissing()
        child.network:reconnect()
      end
    end

    self.current = child
  else
    self.current = Mario(true)
  end

  table.insert(self.members, self.current)
end

function Population:update()
  self.current:update()

  if not self.current.alive then
    if _.count(self.members) >= maxPopulation then
      Population.Generation = Population.Generation + 1
      function compare(a,b)
        return a.fitness < b.fitness
      end

      table.sort(self.members, compare)
      for i,v in pairs(self.members) do
      end
      local elites = {}
      for i=0,numElites-1 do
        table.insert(elites, self.members[_.count(self.members) - i])
      end
      log("--- ELITES ---")
      for i,v in pairs(elites) do
        log(i.."", v.fitness .. "")
      end

      log("--- Max Fitness ---")
      log(self:getMaxFitness())
      log("--- Avg Fitness ---")
      log(self:getAvgFitness())
      self.members = elites
    else
      -- Just get a new one
      self:newMember()
    end

    savestate.load(mainSave)
  end
end

function Population:getMaxFitness()
  local maxf = -1
  for i,v in pairs(self.members) do
    if v.fitness > maxf then maxf = v.fitness end
  end
  return maxf
end

function Population:getAvgFitness()
  local s = 0
  for i,v in pairs(self.members) do
    s = s + v.fitness
  end
  return s / _.count(self.members)
end

function Population:draw()
  self.current:draw()
  if drawgui then
    gui.text(0,0,"Members: " .. _.count(self.members))
    gui.text(80,0,"Gen: " .. Population.Generation)
    gui.text(130,0,"Max Fitn: " .. string.format("%6.2f", self:getMaxFitness()))
    gui.text(0,10,"Avg Fitn: " .. string.format("%6.2f", self:getAvgFitness()))
    gui.text(100,10,"Cur Fitn: " .. string.format("%6.2f", self.current.fitness))
  end
end

return Population
