--require 'strict' 
require 'hfes'
math.randomseed(os.time())
local n = 9
local k = 4
local b = 5 
local nd = hfes.ninedot(n,k,b)

local d = hfes.hFES(nd)
print(#nd.bs.pp)
for j = 1, #nd.bs.pp do 
	print(nd.bs.pp[j][1] .. " " .. nd.bs.pp[j][2])
end
for i = #nd.bs.pp,k-1 do 
	--print("IN MAKE MOVE")
	d:makeMove()
end

nd.bs.pp = {}

for i = #nd.bs.pp,k-1 do 
	d:makeMove()
end
