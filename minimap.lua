local Minimap = {}

function Minimap:load()
  -- Let's get this straight:
  -- 1: collision
  -- 2: Enemy

  -- Which blocks have collision type
  local collision = _.concat({4}, range(37,53), range(68,70), range(80,117), {121}, range(160,191), range(219,255))

  self.map = {}
  self.enemies = {}

  local w,h = 16, 27
  for i=0,hex("794f")-hex("6000") do
    local x = ((i%w) + math.floor(i/(w*h))*(w))
    local y = (math.floor(i/w)%h)

    if not self.map[x] then self.map[x] = {} end
    local byte = memory.readbyte(hex("6000") + i)
    if intable(byte, collision) then
      self.map[x][y] = 1
    end
  end
end

function Minimap:update()
  -- This is the code to read the enemies (which have a 16Bit position)
  -- Wipe the enemies table, because it needs to be rewritten every frame
  self.enemies = {}
  xlow = hex("91")
  xhigh = hex("76")
  ylow = hex("A3")
  yhigh = hex("88")
  for i=0,4 do
    local x = math.floor((memory.readlbyte(xlow+i, xhigh+i))/16)
    local y = math.floor((memory.readlbyte(ylow+i, yhigh+i))/16)
    if not self.enemies[x] then self.enemies[x] = {} end
    self.enemies[x][y] = 1
  end
end

function Minimap:get(x,y)
  if self.map[x] and self.map[x][y] then
    return self.map[x][y], "map"
  elseif self.enemies[x] and self.enemies[x][y] then
    return self.enemies[x][y], "enemy"
  end

  return nil
end

return Minimap
