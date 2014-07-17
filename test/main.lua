--Love test hFES with visualization in real-time 
--Run with /Applications/love.app/Contents/MacOS/love ~/Documents/ninedot/test in the directory /Users/chrisantha/Documents/ninedot/test
--require 'strict'
require 'hfes'
local plPretty = require 'pl.pretty'
--math.randomseed( os.time() )

local historyScore = {}
local historyFitness = {}
local historyHashes = {}
local historyVHL = {} --Value history length 
local historyMSS = {} --Actual Match set size 

local historyGameScore = {}
local historyGameScoreSlide = {}
local numGames = 0 

function delay_s(delay)
  delay = delay or 1
  local time_to = os.time() + delay
  while os.time() < time_to do end
end

function love.load()

--Initialize the ninedot problem here. 
	local n = 2
	local k = 2
	local b = 3 
	--First start 
	nd = hfes.ninedot(n,k,b)
	d = hfes.hFES(nd)
	step = 1 
	--local blabla = 0
	 -- hero = {} -- new table for the hero
	 -- hero.x = 300    -- x,y coordinates of the hero
	 -- hero.y = 450
	 -- hero.speed = 400

end



function love.update(dt)

	-- Start


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
		--print("Game score = " .. gameScore)
		table.insert(historyGameScore, gameScore)
		if #historyGameScoreSlide == 0 then 
			table.insert(historyGameScoreSlide, 1)
		else
			table.insert(historyGameScoreSlide, 0.9*historyGameScoreSlide[#historyGameScoreSlide] + 0.1*gameScore)
		end

		--print(rol)
		d:clearRollouts()

		--Need to reset the problem and do another one. 
		-- local ttt ={}
		-- local cCount = 0
		-- for k,v in pairs(d.classifiers) do
		-- 	cCount = cCount + 1
		-- 	table.insert(ttt,"," .. v.fitness)
		-- end
		-- print("fitness classifiers")
		-- print(table.concat(ttt))
		-- print("n class:" .. cCount)
		-- -- if cCount < 100 then
		-- 	plPretty.dump(d.classifiers)
		-- end

		-- d:deleteClassifiers(4000)

		d:resetBoardState()
		--Start of game 
		numGames = numGames + 1
		step = 1 
	end

	-- if love.keyboard.isDown("left") then
	--    hero.x = hero.x - hero.speed*dt
	-- elseif love.keyboard.isDown("right") then
	--    hero.x = hero.x + hero.speed*dt
	-- end

end

function love.draw()
--delay_s(1)
if numGames%1 == 0 then 

--Get the data to draw from the problem specificiation 
local stuffToDrawBig = d:getImage() --Gets a set of current classiifers for this board state. 
stuffToDrawBigX = stuffToDrawBig[1] 
local classifiers = stuffToDrawBig[2] --Contains ALL the classifiers so far!!!

local stuffToDraw = stuffToDrawBigX[1]
local foveationsBig = stuffToDrawBigX[2] 

--print("checking foveation data structure")
--print(#foveationsBig) -- Prints 9 foveations 

if #foveationsBig > 0 then
	foveations = foveationsBig[1].foveationWindows
	fovCoords = foveationsBig[1].center 
	--print(fovCoords[1])
	--print(fovCoords[2])
else
	foveations = {}
end

--os.exit()
--print(stuffToDraw)


	--------------------------------------------------------------------------------
	--Draw the empty board + dots in the problem 
	--------------------------------------------------------------------------------

	local x = 100 
	local y = 100 
	love.graphics.setColor(255,255,0,255)
	-- Draw the board
	for i = 1, nd.boardSize do 
		for j = 1, nd.boardSize do 
			if stuffToDraw.dots[i][j] == 0 then 
				 love.graphics.circle( "fill", x + 50 * i, y + 50*j , 1, 10 )
			else
				 love.graphics.circle( "fill", x + 50 * i, y + 50*j , 5, 100 )
			end
		end
	end

	--------------------------------------------------------------------------------
	--Draw the lines 
	--------------------------------------------------------------------------------

	love.graphics.setLineWidth( 10 )
	if #stuffToDraw.pp > 1 then 
		for i = 1, #stuffToDraw.pp-1 do 
			  
			  love.graphics.line(x + 50*stuffToDraw.pp[i][1],y + 50*stuffToDraw.pp[i][2], x + 50*stuffToDraw.pp[i+1][1], y + 50*stuffToDraw.pp[i+1][2])

		end	
	
	elseif #stuffToDraw.pp == 1 then  
		--Draw the start pen position 
		--print("drawing first point(((((((((((((((((((((")
		love.graphics.setColor(100,100,100,255)
		love.graphics.circle( "fill", x + 50 * stuffToDraw.pp[1][1], y + 50*stuffToDraw.pp[1][2] , 20, 200 )
		
	end
	--Draw final pen position 
	if #stuffToDraw.pp > 0 then 
		love.graphics.setColor(0,0,255,255)
		love.graphics.circle( "fill", x + 50 * stuffToDraw.pp[#stuffToDraw.pp][1], y + 50*stuffToDraw.pp[#stuffToDraw.pp][2] , 10, 200 )
	end

	-----------------------------------------------------------------------------
	--Draw the foveation windows. 
	-----------------------------------------------------------------------------

	-- if #foveationsBig > 0 then 

	-- 	print("foveations")
	-- 	-- for i = 1, #foveations do 
	-- 	-- 	print(foveations[i].dotCord[1] .." " ..   foveations[i].dotCord[2])
	-- 	-- end
	-- 	--print(foveations[1])

	-- 	--Draw the foveation dot window in the right position. 
	-- 	love.graphics.setColor(255,0,255,255)
	-- 	-- Draw the board
	-- 	local fx = fovCoords[1]
	-- 	local fy = fovCoords[2]
	-- 	print ("fx = " .. fx .. " fy = ".. fy)
	-- 	for i = 1, nd.boardSize do 
	-- 		for j = 1, nd.boardSize do 
	-- 			if foveations[1].dots[i][j] == 0 then 
	-- 				 love.graphics.circle( "fill", x + 50 * (i + fx-math.ceil(5/2)) , y + 50*(j + fy-math.ceil(5/2)) , 2, 100 )
	-- 			else
	-- 				 love.graphics.circle( "fill", x + 50 * (i + fx-math.ceil(5/2)), y + 50*(j + fy-math.ceil(5/2)) , 10, 255 )
	-- 			end
	-- 		end
	-- 	end
	-- end

--Analysis parts of the visualization 
   if love.keyboard.isDown("up") then
      delay_s(2)
      print("Key pressed")

   end
-----------------------------------------------------------------------------
-- Print all the foveation windows on the right of the screen. 
-----------------------------------------------------------------------------

x = 450 
y = -20
if #foveationsBig > 0 then

	for f = 1, #foveationsBig do 

		--Draw the foveation dot window in the right position. 
		love.graphics.setColor(255,0,255,255)
		-- Draw the board
		local fx = 0 --foveationsBig[f].center[1]
		local fy = 0 --foveationsBig[f].center[2]

		--print ("fx = " .. fx .. " fy = ".. fy)
		for i = 1, 5 do 
			for j = 1, 5 do 
				if foveationsBig[f].foveationWindows[1].dots[i][j] == 0 then 
					 love.graphics.circle( "fill", x  + 7 * (i + fx-math.ceil(5/2)) , y + f*60 + 7*(j + fy-math.ceil(5/2)) , 1, 100 )
				else
					 love.graphics.circle( "fill", x + 7 * (i + fx-math.ceil(5/2)), y + f*60 + 7*(j + fy-math.ceil(5/2)) , 3, 255 )
				end
			end
		end
	end


end


----------------------------------------------------------------------------
-- Print all the classifiers for each foveation position. 
----------------------------------------------------------------------------
x = 500 
y = -20

--print("drawing classifiers")
--print("number of classifiers in total = " .. #classifiers)
love.graphics.setColor(0,255,255,255)
love.graphics.print("No Classifiers: " .. d.numClassifiers, 500, 10)

if #foveationsBig > 0 then
	local histSc = {}
	local fitness = {}
	local hashes = {}
	local VHL = {}
	local MSS = {}


	for f = 1, #foveationsBig do --Go through each foveation position 
		local displace = 0
		love.graphics.setColor(0,255,255,255)
		-- Draw the board
		local fx = 0 --foveationsBig[f].center[1]
		local fy = 0 --foveationsBig[f].center[2]

		-- Go through each matching classifier for this foveationWindow. 
		--print("number of classifiers matching in foveationPosition " .. f .. " = " .. #foveationsBig[f].foveationWindows[1].matchings)

		--Sort classifiers by WEIGHT 
		table.sort(foveationsBig[f].foveationWindows[1].matchings, function (a,b) return (classifiers[a].fitness > classifiers[b].fitness) end )
		table.insert(MSS, #foveationsBig[f].foveationWindows[1].matchings )
		for q = 1, #foveationsBig[f].foveationWindows[1].matchings do 

			if q%10 == 0 then 
				displace = displace + 1
			end

			love.graphics.setColor(0,255,255,255)

			--print("classifier " .. q .. " = " .. foveationsBig[f].foveationWindows[1].matchings[q])

			local classif = classifiers[foveationsBig[f].foveationWindows[1].matchings[q]]
			--print(classif.classifier.grid)
			love.graphics.print(string.format("%.4f", classif.weight), x  + q* 50 , y + f*70 + 40)
			table.insert(histSc, classif.weight)
			table.insert(fitness, classif.fitness)
			table.insert(hashes, classif.totalHashes)
			table.insert(VHL, classif.valueHistory:storage():size())
			
			--Draw this classifier's dot matchings 
			for i = 1, 5 do 
				for j = 1, 5 do 
					if classif.classifier.grid.grid[i][j] == 0 then 
						 love.graphics.circle( "fill", x  + q* 50  + 7 * (i + fx-math.ceil(5/2)) , y + f*70 + 7*(j + fy-math.ceil(5/2)) , 1, 100 )
					elseif classif.classifier.grid.grid[i][j] == 1 then 
						 love.graphics.circle( "fill", x +  q* 50  + 7 * (i + fx-math.ceil(5/2)), y + f*70 + 7*(j + fy-math.ceil(5/2)) , 3, 255 )
					else
 						 love.graphics.setColor(0,100,100,100)
						 love.graphics.circle( "fill", x +  q* 50  + 7 * (i + fx-math.ceil(5/2)), y + f*70 + 7*(j + fy-math.ceil(5/2)) , 3, 255 )
	 					 love.graphics.setColor(0,255,255,255)
					end
				end
			end


			--Draw the classifier's line positions 
			--if classif.classifier.lines.lines:storage() ~= nil then 
			-- 	--print("NUM LINES88")
			-- 	local num_lines = classif.classifier.lines.lines:size()[1]

			-- 	love.graphics.setLineWidth( 2 )
			-- 	love.graphics.setColor(255,100,50,255)
			-- 	if num_lines > 0 then 
			-- 		--print("DRAWING CLASSIFIER LINE ************** > 1")

			-- 		for i = 1, num_lines-1 do 
			-- 			local startX = classif.classifier.lines.lines[i][1][1]
			-- 			local startY = classif.classifier.lines.lines[i][1][2]
			-- 			local endX = classif.classifier.lines.lines[i][2][1]
			-- 			local endY = classif.classifier.lines.lines[i][2][2]
			-- 			love.graphics.line(x +  q* 50 + 7 * (startX + fx-math.ceil(5/2)) ,y +  f* 60 + 7 * (startY+ fy-math.ceil(5/2)) , x +  q* 50 + 7 * (endX + fx-math.ceil(5/2)) , y +  f* 60 + 7 * (endY + fy-math.ceil(5/2)) )

			-- 		end	
				
			-- 	-- elseif num_lines == 1 then  
			-- 	-- 		startX = classif.classifier.lines.lines[1][1][1]
			-- 	-- 		startY = classif.classifier.lines.lines[1][1][2]

			-- 	-- 	--Draw the start pen position 
			-- 	-- 	print("DRAWING CLASSIFIER LINE **************  1")
			-- 	-- 	love.graphics.setColor(255,0,50,255)
			-- 	-- 	love.graphics.circle( "fill", x + q* 50 + 7 * (startX + fx-math.ceil(5/2)),y + f* 60 + 7 * (startY + fy-math.ceil(5/2)), 2, 200 )
					
			-- 	end

			-- end

			love.graphics.setLineWidth( 2 )
			love.graphics.setColor(255,255,255,255)
			--love.graphics.setColor(255,0,50,255)
			local fovCols = math.ceil(math.sqrt(classif.classifier.lines.linesMatrix:size()[1]))
			--print("length = " .. fovCols)
			for i = 1, classif.classifier.lines.linesMatrix:size()[1] do 
				for j = 1, classif.classifier.lines.linesMatrix:size()[2] do 
					
					if classif.classifier.lines.linesMatrix[i][j] == 1 then
						local startX, startY = util.unconvertCoords(i,fovCols)
						local endX, endY = util.unconvertCoords(j,fovCols)

						-- print("line position = " .. i .. " " .. j )
						-- print("start x = " .. startX)
						-- print("start y = " .. startY)
						-- print("end x = " .. endX)						
						-- print("end y = " .. endY)

						love.graphics.line(x +  q* 50 + 7 * (startX + fx-math.ceil(5/2)) ,y +  f* 70 + 7 * (startY+ fy-math.ceil(5/2)) , x +  q* 50 + 7 * (endX + fx-math.ceil(5/2)) , y +  f* 70 + 7 * (endY + fy-math.ceil(5/2)) )

					end
				end
			end

			-- --Draw the classifier's POINT positions 
			-- if classif.classifier.lastPP.point:storage() ~= nil then 

			-- 	local startX = classif.classifier.lastPP.point[1]
			-- 	local startY = classif.classifier.lastPP.point[2]
			-- 	love.graphics.setColor(0,0,255,255)
			-- 	love.graphics.circle( "fill", x + q* 50 + 7*(startX+ fx-math.ceil(5/2)),  y + f * 60 + 7*(startY + fy-math.ceil(5/2)), 3, 200 )
			
			-- end

			for i = 1, classif.classifier.lastPP.pointMatrix:size()[1] do 
				for j = 1, classif.classifier.lastPP.pointMatrix:size()[2] do 
				
					if classif.classifier.lastPP.pointMatrix[i][j] == 1 then 
						love.graphics.setColor(0,0,255,255)
						love.graphics.circle( "fill", x + q* 50 + 7*(i+ fx-math.ceil(5/2)),  y + f * 70 + 7*(j + fy-math.ceil(5/2)), 5, 200 )
					end
					if classif.classifier.lastPP.pointMatrix[i][j] == 0 then
						love.graphics.setColor(100,20,0,255) 
						love.graphics.circle( "fill", x + q* 50 + 7*(i+ fx-math.ceil(5/2)),  y + f * 70 + 7*(j + fy-math.ceil(5/2)), 2, 20)
					end

				end

			end


		end

	end
table.insert(historyScore, histSc)
table.insert(historyFitness, fitness)
table.insert(historyHashes, hashes)
table.insert(historyVHL, VHL)
table.insert(historyMSS, MSS)

end

--ORANGE - weights of classifiers 
love.graphics.setColor(255,100,50,255)
-----DRAW HISTORY OF SCORES
for i = 1,#historyScore do 
	for j = 1, #historyScore[i] do 
		love.graphics.circle( "fill", i, 10 + 500-100*historyScore[i][j] , 1, 255 )
	end
end
if #historyScore > 100 then 
	historyScore = {}
end

--GREEN = fitness of classifiers 
love.graphics.setColor(0,255,100,255)
-----DRAW HISTORY OF FITNESS
for i = 1,#historyFitness do 
	for j = 1, #historyFitness[i] do 
		--print(historyFitness[i][j])
		love.graphics.circle( "fill", i, 10 + 500-100*historyFitness[i][j] , 1, 255 )
	end
end
if #historyFitness > 100 then 
	historyFitness = {}
end

--BLUE = number of hashes 
love.graphics.setColor(00,00,255,255)
-----DRAW HISTORY OF HASHES
for i = 1,#historyHashes do 
	for j = 1, #historyHashes[i] do 
		--print(historyHashes[i][j])
		love.graphics.circle( "fill", i, 10 + 200-2*historyHashes[i][j] , 1, 255 )
	end
end
if #historyHashes > 100 then 
	historyHashes = {}
end

--YELLOW = value history length 
love.graphics.setColor(255,255,00,255)
-----DRAW HISTORY OF VALUE HISTORY LENGTH 
for i = 1,#historyVHL do 
	for j = 1, #historyVHL[i] do 
		--print(historyVHL[i][j])
		love.graphics.circle( "fill", i, 10 + 100-0.5*historyVHL[i][j] , 1, 255 )
	end
end
if #historyVHL > 100 then 
	historyVHL = {}
end

--PINK  = REAL MATCH SET SIZE 
love.graphics.setColor(255,10,255,255)
-----DRAW HISTORY OF REAL MATCH SET SIZE 
for i = 1,#historyMSS do 
	for j = 1, #historyMSS[i] do 
		--print(historyMSS[i][j])
		love.graphics.circle( "fill", i, 10 + 270-0.5*historyMSS[i][j] , 1, 255)
		if historyMSS[i][j] == 1 then 
			love.graphics.setColor(255,255,255,255)
			love.graphics.circle( "fill", i, 10 + 270-0.5*historyMSS[i][j] , 2, 255)
			love.graphics.setColor(255,10,255,255)

		end
	end
end
if #historyMSS > 100 then 
	historyMSS = {}
end

----DRAW HISTORY OF GAME SCORE 

-----DRAW HISTORY OF SCORES
for i = 1,#historyGameScore do 
		love.graphics.circle( "fill", i*(nd.k+1), 10 + 400-50*historyGameScore[i] , 1, 255 )
		love.graphics.setColor(100,255,250,255)
		love.graphics.circle( "fill", i*(nd.k+1), 10 + 400-50*historyGameScoreSlide[i] , 1, 255 )
		love.graphics.setColor(100/2,255/2,250/2,255)

end
if #historyGameScore > math.floor(100/(nd.k+1)) then 
	historyGameScore = {}
	historyGameScoreSlide = {}
end

----VISUALIZE THE PROPERTIES OF THE ROLLOUT 
for i = 1 ,#d.rollouts do 

	--Visualize properties of the active classifiers in the rollout 
	for a = 1, #d.rollouts[i].activeClassifiers do 
		love.graphics.setColor(255,10,255,255)

		--PINK = estimated Match Set Size (also you can see this fromthe number of dots per rollout on the horizontal axis! )
		love.graphics.circle( "fill", 500 + (i-1)*300 + a*3, 10 + 500-1*d.classifiers[d.rollouts[i].activeClassifiers[a]].matchSetEstimate , 2, 255 )
		
		--GREEN = FITNESS (the fitness tends to become very massively negative and explode eventually!!!)
		love.graphics.setColor(0,255,100,255)
		love.graphics.circle( "fill", 500 + (i-1)*300 + a*3, 10 + 500-1000*d.classifiers[d.rollouts[i].activeClassifiers[a]].fitness , 2, 255 )

		--YELLOW = length of value history i.e. number of times matched in total. 
		love.graphics.setColor(255,255,00,255)
		love.graphics.circle( "fill", 500 + (i-1)*300 + a*3, 10 + 500-1*d.classifiers[d.rollouts[i].activeClassifiers[a]].valueHistory:storage():size()  , 2, 255 )
		
		--BLUE = number of hashes in this classifier, i.e. its generality 
		love.graphics.setColor(00,00,255,255)
		local hash = d.classifiers[d.rollouts[i].activeClassifiers[a]].classifier.grid.numHashes + 
					 d.classifiers[d.rollouts[i].activeClassifiers[a]].classifier.lines.numHashes + 
					 d.classifiers[d.rollouts[i].activeClassifiers[a]].classifier.lastPP.numHashes
		
		--print(hash ..  " == > " .. d.classifiers[d.rollouts[i].activeClassifiers[a]].totalHashes)

		love.graphics.circle( "fill", 500 + (i-1)*300 + a*3, 10 + 300-hash  , 2, 255 )
		
		--print(d.classifiers[d.rollouts[i].activeClassifiers[a]].matchSetEstimate)

	end

end

-- table.insert(self.rollouts, {	reward = instantScore, activeClassifiers = activeClassifiers,
-- 									foveationWindows=foveationWindowsMoves, classifiersToWindows=classifersToWindowsMoves})



 -- -- let's draw some ground
 -- love.graphics.setColor(0,255,0,255)
 -- love.graphics.rectangle("fill", 0, 465, 800, 150)

 -- -- let's draw our hero
 -- love.graphics.setColor(255,255,0,255)
 -- love.graphics.rectangle("fill", hero.x,hero.y, 30, 15)
end
end

