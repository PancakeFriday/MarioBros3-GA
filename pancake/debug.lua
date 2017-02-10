local _ = require "lib.lume"
local Object = require "lib.classic"
local Button = Object:extend()

--------------------------------------------------------------------------------
--Button------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Button:new()
  self.idleColor = {r = 200, g = 200, b = 200, a = 200}
  self.hoverColor = {r = 220, g = 220, b = 220, a = 220}
  self.pushColor = {r = 180, g = 180, b = 180, a = 180}
  self.textColor = {r = 0, g = 0, b = 0, a = 255}
  self.text = ""
  self.action = function() end
  self.doAction = true
  self.rectangle = {mode = "fill", x = 0, y = 0, width = 0, height = 0,
                    rx = 0, ry = 0, segments = 0}
end

function Button:setIdleColor(r,g,b,a)
  self.idleColor = {r = r or 255, g = g or 255, b = b or 255 , a = a or 255}
end

function Button:setHoverColor(r,g,b,a)
  self.hoverColor = {r = r or 255, g = g or 255, b = b or 255 , a = a or 255}
end

function Button:setPushColor(r,g,b,a)
  self.pushColor = {r = r or 255, g = g or 255, b = b or 255 , a = a or 255}
end

function Button:setTextColor(r,g,b,a)
  self.textColor = {r = r or 255, g = g or 255, b = b or 255 , a = a or 255}
end

function Button:setText(s)
  self.text = s
end

function Button:setAction(f)
  self.action = f or self.action
end

function Button:setRectangle(mode, x, y, width, height, rx, ry, segments)
  self.rectangle = {mode = mode or "fill", x = x or 0, y = y or 0, width = width or 0,
                    height = height or 0, rx = rx, ry = ry, segments = segments}
end

function Button:draw()
  local mx, my = love.mouse.getPosition()
  local t = self.rectangle
  local c
  if mx > t.x + 5 and mx < t.x + t.width - 5 and
    my > t.y and my < t.y + t.height then
      if love.mouse.isDown(1) then
        c = self.pushColor
        if self.doAction then
          self.action()
          self.doAction = false
        end
      else
        c = self.hoverColor
        self.doAction = true
      end
  else
    c = self.idleColor
  end

  love.graphics.setColor(c.r, c.g, c.b, c.a)
  love.graphics.rectangle(t.mode, t.x + 5, t.y, t.width - 10, t.height, t.rx, t.ry, t.segments)

  local font = love.graphics.getFont()
  local fw = font:getWidth(self.text)
  local fh = font:getHeight(self.text)

  -- Prints the button text in the center
  c = self.textColor
  love.graphics.setColor(c.r, c.g, c.b, c.a)
  love.graphics.print(self.text, (t.x+t.width)/2 - fw/2, (t.y + fh/2 - 3))
end

--------------------------------------------------------------------------------
--Slider------------------------------------------------------------------------
--------------------------------------------------------------------------------
local Slider = Object:extend()

function Slider:new(min, max, initial)
  self.min = min or 0
  self.max = max or 1
  self.text = "null"

  self:setRect(0,0,1,1)
  self.pos = (initial) or 0
end

function Slider:setRect(x,y,w,h)
  self.x = x
  self.y = y
  self.w = w
  self.h = h
end

function Slider:setText(text)
  self.text = text
end

function Slider:get()
  return (self.pos - self.x)/self.w * (self.max - self.min) + self.min
end

function Slider:update()
  if love.mouse.isDown(1) then
    local x,y = love.mouse.getPosition()
    if x > self.x and x < self.x + self.w then
      if y > self.y + 20 and y < self.y + self.h + 20 then
        self.move = true
      end
    end
  else
    self.move = false
  end

  if self.move and self:get() <= self.max and self:get() >= self.min then
    self.pos = love.mouse.getX()
  end

  if self:get() > self.max then
    self.pos = self.x + self.w
  elseif self:get() < self.min then
    self.pos = self.x
  end
end

function Slider:draw()
  self:update()
  love.graphics.setColor(200,200,200,200)
  love.graphics.rectangle("fill",self.x, self.y + 20, self.w, self.h)
  love.graphics.setColor(200,200,200,255)
  local x = self.pos
  love.graphics.line(x, self.y + 18, x, self.y + self.h + 22)
  love.graphics.setColor(255,255,255,255)

  local font = love.graphics.getFont()
  local fw = font:getWidth(self.text)
  love.graphics.print(self.text, self.x+3, self.y)

  love.graphics.setColor(255,255,255,255)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--The debugger------------------------------------------------------------------
--------------------------------------------------------------------------------
local debug = {}
debug.vars = {}
debug.sliders = {}
debug.buttons = {}

function debug.init()
  debug.initDone = true
  debug.rectangle = {x=10, y=10, width=220, height=220}
end

function debug.update()
  debug.vars = {}
end

function debug.draw()
  if not debug.initDone then
    debug.init()
  end

  local n = _.count(debug.sliders) + _.count(debug.buttons)
  debug.rectangle.height = 30 + _.count(debug.vars)*15 + n*40
  local dr = debug.rectangle

  -- Only draw in this range
  love.graphics.setScissor( dr.x, dr.y, dr.width, dr.height )

  -- The rounded rectangle
  love.graphics.setColor(150, 150, 150, 100)
  love.graphics.rectangle("fill" , dr.x, dr.y, dr.width, dr.height, 5, 5)
  love.graphics.setColor(255,255,255,255)

  -- Here goes the vars that we are going to watch
  love.graphics.line(10, 15 + n*40, 230, 15 + n*40)
  local it=0
  for i,v in pairs(debug.vars) do
    love.graphics.print(i .. "=" .. v, 15, 30 + n*40+it*15)
    it = it + 1
  end

  -- draw the sliders
  for i,v in pairs(debug.sliders) do
    v:draw()
  end
  -- draw the buttons
  for i,v in pairs(debug.buttons) do
    v:draw()
  end

  love.graphics.setScissor()
end

function debug.newSlider(name,min,max,initial)
  local n = _.count(debug.sliders) + _.count(debug.buttons)
  debug.sliders[name] = Slider(min,max,initial)
  debug.sliders[name]:setRect(10, 15 + n*40, 220, 10)
  debug.sliders[name]:setText(name)
end

function debug.getSlider(name)
  if not debug.sliders[name] then return nil end
  return debug.sliders[name]:get()
end

function debug.newButton(name, text, action)
  local n = _.count(debug.sliders) + _.count(debug.buttons)
  debug.buttons[name] = Button()
  debug.buttons[name]:setText(text)
  debug.buttons[name]:setAction(action)
  debug.buttons[name]:setRectangle("fill", 10, 15 + n*40, 220, 20)
end

function debug.watch(name, var)
  debug.vars[name] = tostring(var)
end

return debug
