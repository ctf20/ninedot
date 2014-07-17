require 'hfes'
local plPretty = require 'pl.pretty'
require "socket"
ProFi = require "ProFi"
--math.randomseed( os.time() )

local historyScore = {}
local historyFitness = {}
local historyHashes = {}
local historyVHL = {} --Value history length 
local historyMSS = {} --Actual Match set size 

local historyGameScore = {}
local historyGameScoreSlide = {}
local numGames = 0 


local n = 2
local k = 2
local b = 3 
--First start 
nd = hfes.ninedot(n,k,b)
d = hfes.hFES(nd)
step = 1 

local rolloutTimeStart
local rolloutTimeStop
function update(dt)
	-- Start
	if step == 1 then
		rolloutTimeStart = socket.gettime()
		ProFi:start()

	end

	-- Step
	--print("move number = " .. step)
		 
	if step <= nd.k then 
	 	--print("doing move:" .. step)
	 	--d:makeMove()
	 	d:makeMoveTD()
 		--d:printBoardState()
	step = step + 1 
	elseif step > nd.k then 
		--Called after game over. 
		d:updateValues()

		d:evolveClassifiers() --Evolve the classifiers!! :) 
		
		local gameScore = 0 
		for h = 1, #d.rollouts do 
			gameScore = gameScore + d.rollouts[h].reward
		end

		d:clearRollouts()
		-- d:deleteClassifiers(5000)

		d:resetBoardState()
		--Start of game 
		numGames = numGames + 1
		step = 1
		rolloutTimeStop = socket.gettime()
		print("time p/r = " .. (rolloutTimeStop - rolloutTimeStart))
		print("numClassifiers:" .. d.numClassifiers)
		-- ProFi:stop()
		-- ProFi:writeReport( 'MyProfilingReport' .. d.numClassifiers ..".txt" )
	end
end

local updates = 1
for i=1,5000 do
	if updates == 1 then
		ProFi:start()
	end
	update()
	updates = updates + 1
	if updates > k + 1 then
		ProFi:stop()
		ProFi:writeReport( 'MyProfilingReport' .. d.numClassifiers ..".txt" )
		updates = 1
	end
end