--require 'strict' --Doesnt seem to work for some reason...!? 
require 'hfes'
--print("sss")

local n = 2
local k = 2
local b = 5 
local nd = hfes.ninedot(n,k,b)

local d = hfes.hFES(nd)

for i = 1,k do 
	d:makeMove()
end


--d:print()

-- print('two')
-- d2:print()


