--require 'strict' 
require 'hfes'

local n = 2
local k = 2
local b = 5 
local nd = hfes.ninedot(n,k,b)

local d = hfes.hFES(nd)

for i = 1,k do 
	d:makeMove()
end

