--require 'strict' 
require 'hfes'

local n = 9
local k = 4
local b = 5 
local nd = hfes.ninedot(n,k,b)

local d = hfes.hFES(nd)

for i = #nd.bs.pp,k-1 do 
	d:makeMove()
end
