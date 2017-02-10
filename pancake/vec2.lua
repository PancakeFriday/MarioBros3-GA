local Object = require "lib.classic"
local vec2 = Object:extend()

function vec2:new(x,y)
  self.x = x or 0
  self.y = y or 0
end

function vec2:get()
  return self.x, self.y
end

function vec2:set(x,y)
  self.x = x
  self.y = y
end

function vec2:__add(v)
  if type(v) == "number" then
    return vec2(self.x + v, self.y + v)
  else
    assert(v:is(vec2), "invalid type")
    return vec2(self.x + v.x, self.y + v.y)
  end
end

function vec2:__sub(v)
  if type(v) == "number" then
    return vec2(self.x - v, self.y - v)
  else
    assert(v:is(vec2), "invalid type")
    return vec2(self.x - v.x, self.y - v.y)
  end
end

function vec2:__mul(v)
  if type(v) == "number" then
    return vec2(self.x * v, self.y * v)
  else
    assert(v:is(vec2), "invalid type")
    return self.x * v.x + self.y * v.y
  end
end

function vec2:__div(v)
  assert(type(v) == "number")
  return vec2(self.x / v, self.y / v)
end

function vec2:len()
  return math.sqrt(self.x^2 + self.y^2)
end

function vec2:normalized()
  return self/self:len()
end

function vec2:distTo(v)
  assert(v:is(vec2), "invalid type")
  local t = self - v
  return t:len()
end

return vec2
