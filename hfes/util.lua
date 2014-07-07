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
  local result, done = {}, {}
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
  k = 1
  for i = 1,#t:size() do
    k = k * t:size()[i]
  end
  return k
end

function util.matchTensor(a,b)
  return torch.sum(torch.eq(a,b)) == torch.prod(getSize(a),1)[1]
end

-- function util.matchTensorWithIgnores(template,pattern)
--   print("template:")
--   print(template)
--   for i=1,#template:storage() do
--     print(template:storage()[i])
--   end
--   print("pattern:")
--   print(pattern)
--   for i=1,#pattern:storage() do
--     print(pattern:storage()[i])
--   end

--   local match = true
--   for i=1,#template:storage() do
--     -- print("utilmt; i=" .. i .. " template:" .. template:storage()[i] .. "; pattern:" .. pattern:storage()[i])
--     if template:storage()[i] ~= -1 then
--       if template:storage()[i] ~= pattern:storage()[i] then
--         print(template:storage()[i])
--         print("not equal to")
--         print(pattern:storage()[i])
--         match = false
--         break
--       end
--     end
--   end
--   print("util.matchTensorWithIgnores:" .. tostring(match))
--   return match
-- end

function util.matchTensorWithIgnores(template,pattern)
  local match = true
  -- print("template")
  -- print(template)
  flatTemplate = torch.reshape(template,1,numElements(template))
  flatPattern = torch.reshape(pattern,1,numElements(pattern))
  for i=1,flatTemplate:size()[2] do
    -- print("utilmt; i=" .. i .. " template:" .. template:storage()[i] .. "; pattern:" .. pattern:storage()[i])
    if flatTemplate[1][i] ~= -1 then
      if flatTemplate[1][i] ~= flatPattern[1][i] then
        -- print(flatPattern[1][i])
        -- print("not equal to")
        -- print(flatTemplate[1][i])
        match = false
        break
      end
    end
  end
  -- print("util.matchTensorWithIgnores:" .. tostring(match))
  return match
end
