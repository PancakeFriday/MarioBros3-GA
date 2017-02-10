function hex(n)
  return tonumber("0x" .. n)
end

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

function memory.readlbyte(low,high)
  return memory.readbyte(low) + memory.readbyte(high)*2^8
end

function eachGrandChild(root)
  for _,child in pairs(root) do
    for index,grandChild in pairs(child) do
      coroutine.yield(index, grandChild)
    end
  end
end

function grandChildren(t)
    return coroutine.wrap(function() eachGrandChild(t) end)
end

function tosignedbyte(n)
  if n > 128 then
    return n-255
  end
  return n
end

function getRanPow(minscore, maxscore, pow)
  return math.floor(minscore+(maxscore-minscore)*math.random()^pow)
end

function resOutput()
  file = io.open("output", "w")
  io.output(file)
  io.write("")
  io.close(file)
end

function log(...)
  local t = {...}
  local s = ""
  for i,v in pairs(t) do
    s = s .. v .. "\t"
  end
  print(s.."")
  file = io.open("output", "a")
  io.output(file)
  io.write(s.."\n")
  io.close(file)
end
