--util.lua

util = {}

local function strToTable(input)
  local t = {}
  input:gsub(".",function(c) table.insert(t,c) end)
  return t
end

function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result = {}
  local done = {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

local function getSize(a)
  local sizeTable = {}
  for i = 1,#a:size() do
    table.insert(sizeTable,a:size()[i])
  end
  return torch.Tensor(sizeTable)
end

local function numElements(t)
  local k = 1
  for i = 1,#t:size() do
    k = k * t:size()[i]
  end
  return k
end

function util.flatten(t)
  return torch.reshape(t,1,numElements(t))
end

function util.matchTensor(a,b)
  return torch.sum(torch.eq(a,b)) == torch.prod(getSize(a),1)[1]
end

function util.matchTensorWithIgnores(template,pattern)
  local match = true
  local flatTemplate = torch.reshape(template,1,numElements(template))
  local flatPattern = torch.reshape(pattern,1,numElements(pattern))
  for i=1,flatTemplate:size()[2] do
    if flatTemplate[1][i] ~= -1 then
      if flatTemplate[1][i] ~= flatPattern[1][i] then
        match = false
        break
      end
    end
  end
  return match
end

function util.addToSet(v,set)
  set[v] = 1
  return set
end

function util.getKeywords(set)
  kws = {}
  for k,v in pairs(set) do
    table.insert(kws,k)
  end
  table.sort(kws)
  return kws
end

function util.convertPPVecToMatrix(ppVec,rows,columns)
  -- print("r/c:")
  -- print(rows)
  -- print(columns)
  local matrix = torch.Tensor(rows*columns,rows*columns):fill(0)
  if ppVec:storage() ~= nil then
    for i=1,ppVec:size()[1] do
      local line = ppVec[i]
      local index = i + 1
      local startX = line[1][1]
      local startY = line[1][2]
      local from = util.convertCoords(startX,startY,columns)
      local endX = line[2][1]
      local endY = line[2][2]
      local to = util.convertCoords(endX,endY,columns)
      matrix[from][to] = 1
    end
  end
  return matrix
end

function util.convertCoords(x,y,cols)
  return ((x-1) * cols) + y
end

function util.unconvertCoords(i,cols)
  local x = math.ceil(i/cols)
  local y = (i-1)%(cols) +1
  return x,y
end


function util.convertPointToMatrix(point,rows,columns)
  -- print("r/c:")
  -- print(rows)
  -- print(columns)
  local matrix = torch.Tensor(rows,columns):fill(0)
  if point:storage() ~= nil then
      matrix[point[1]][point[2]] = 1
  end
  return matrix
end

------------------------------------------
-- matching
------------------------------------------

local function bits(num)
    local t={}
    local rest
    while num>0 do
        rest=num%2
        table.insert(t,1,rest)
        num=(num-rest)/2
    end
    return table.concat(t)
end

local function convertTableToClassifierFormat(input)
  local t = {}
  for i,b in ipairs(input) do
    table.insert(t,convertBitToClassifierBit(b))
  end
  return table.concat(t)
end

local function convertBitToClassifierBit(b)
  local output = ""
  if b == "0" or b == 0 then
    output = "01"
  elseif b == "1" or b == 1 then
    output = "10"
  else
    output = "11"
  end
  return output
end

local function splitInto32(input)
  local noSplits = math.ceil(#input/15)
  -- print(noSplits)
  local t = {}
  for i=1,noSplits do
    table.insert(t,{})
  end
  local split = 0
  for i,b in ipairs(input) do
    -- print("i:" .. i)
    if (i-1)%15 == 0 then
      split = split + 1
      -- print("split:" .. split)
    end
    table.insert(t[split],convertBitToClassifierBit(b))
  end
  return t
end

local function concat32TablesToStrings(t)
  local strTable = {}
  for i,split in ipairs(t) do
    table.insert(strTable,table.concat(split))
  end
  return strTable
end

local function convertStrTableToIntTable(t)
  local intTable = {}
  for i,split in ipairs(t) do
    table.insert(intTable,tonumber(split,2))
  end
  return intTable
end

function util.getConvertedIntTable(input)
  local splits32 = splitInto32(input)
  local strTable = concat32TablesToStrings(splits32)
  local intTable = convertStrTableToIntTable(strTable)
  return intTable
end

function util.matchClassifierBinary(input,pattern)
  return bit.band(tonumber(input,2),tonumber(pattern),2) == input
end

function util.matchClassifierInteger(input,pattern)
  return bit.band(input,pattern) == input
end

function util.matchClassifierIntegerTable(inputT,patternT)
  local match = true
  for i=1,#inputT do
    if util.matchClassifierInteger(inputT[i],patternT[i]) == false then
      return false
    end
  end
  return match
end

