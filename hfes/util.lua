--util.lua

util = {}

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

function util.getMatches(bsIntegers, templateIntegers)

  local matchedTemplates = {}

  for i = 1, #self.templatesIntegers do 
    local mat = 1 
    --print(" template " .. i .. " is ")
    for j = 1, #self.templatesIntegers[i] do 
      --io.write(templatesIntegers[i][j].. " " )
      --print("")
      --print("comparing")
      --print(to_binary(templatesIntegers[i][j]))
      --print(to_binary(bsIntegers[j]))
      --print("result = ----------")
      --result = bit.band(templatesIntegers[i][j], bsIntegers[j])
      --print(bit.tohex(templatesIntegers[i][j]))
      result = bit.band(bit.tobit(self.templatesIntegers[i][j]), bit.tobit(bsIntegers[j]))
      --result = bit.band(bit.tohex(12), bit.tohex(12))
      --print(to_binary(result))

      --print(bit.tobit(templatesIntegers[i][j]) .. " AND " .. bit.tobit(bsIntegers[j]) .. " => " .. bit.tobit(result) .. " " )
      if bit.tobit(bsIntegers[j]) ~= bit.tobit(result) then 
        --print("not matched")
        mat = 0 
        break     
      end 
    end
    if mat == 1 then 
      --print("MATCHED")
      table.insert(matchedTemplates, i)
    end
  end
  return matchedTemplates
end
