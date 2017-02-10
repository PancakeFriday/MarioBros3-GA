local Timer = {}
Timer.time = 0

function Timer:update()
  self.time = self.time + 1
end

function Timer:get()
  return self.time
end

return Timer
