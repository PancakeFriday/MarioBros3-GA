local Options = {}


function Options:update()
  file = io.open("optionsfile", "r")
  local t = file:read("*all")
  local vars = _.split(t, "\n")
  for i,v in pairs(vars) do
    vars[i] = _.split(v," ")
  end

  -- Evaluate options
  for i,v in pairs(vars) do
    if v[1] == "speedmode" then
      emu.speedmode(v[2])
    elseif v[1] == "save" then
      local savefile = io.open("savefile", "w")
      savefile:write(binser.s(Population))
      io.close(savefile)
    elseif v[1] == "load" then
      local savefile = io.open("savefile", "r")
      Population = binser.d(savefile:read("*all"))[1]
      for i,v in pairs(Population) do
        print(i.."")
      end
      io.close(savefile)
      setmetatable(Population, PopulationFactory)
      Population:applyMeta()
    elseif v[1] == "gui" then
      if v[2] == "true" then
        drawgui = true
      elseif v[2] == "false" then
        drawgui = false
      end
    end
  end

  io.close(file)

  file = io.open("optionsfile", "w")
  file:write("")
  io.close(file)
end

return Options
