--Love test hFES with visualization in real-time 
--Run with /Applications/love.app/Contents/MacOS/love ~/Documents/ninedot/test in the directory /Users/chrisantha/Documents/ninedot/test
require 'strict'
require 'hfes'

function love.load()

--Initialize the ninedot problem here. 
	n = 3
	k = 3
	b = 5 
	nd = hfes.ninedot(n,k,b)
	d = hfes.hFES(nd)
	step = 1 

	 -- hero = {} -- new table for the hero
	 -- hero.x = 300    -- x,y coordinates of the hero
	 -- hero.y = 450
	 -- hero.speed = 400

end

function love.update(dt)

	-- Start 

	-- Step 
	if step <= k then 
	 	print("doing move:" .. step)
	 	d:makeMove()
 		--d:printBoardState()
	step = step + 1 
	elseif step > k then 
		--Need to reset the problem and do another one. 
		d:resetBoardState()
		step = 1 
	end


	-- if love.keyboard.isDown("left") then
	--    hero.x = hero.x - hero.speed*dt
	-- elseif love.keyboard.isDown("right") then
	--    hero.x = hero.x + hero.speed*dt
	-- end

end

function love.draw()

--Get the data to draw form the problem specificiation 
local stuffToDraw = d:getImage()
--print(stuffToDraw)

	----------------
	--Draw the empty board + dots in the problem 
	----------------
	local x = 100 
	local y = 100 
	-- Draw the board
	for i = 1, b do 
		for j = 1, b do 
			if stuffToDraw.dots[i][j] == 0 then 
				 love.graphics.circle( "fill", x + 50 * i, y + 50*j , 1, 10 )
			else
				 love.graphics.circle( "fill", x + 50 * i, y + 50*j , 5, 100 )
			end
		end
	end


	----------------
	--Draw the lines 
	----------------
	love.graphics.setLineWidth( 10 )
	if #stuffToDraw.pp > 1 then 
		for i = 1, #stuffToDraw.pp-1 do 
			  print("DRAWING LINE")
			  love.graphics.line(x + 50*stuffToDraw.pp[i][1],y + 50*stuffToDraw.pp[i][2], x + 50*stuffToDraw.pp[i+1][1], y + 50*stuffToDraw.pp[i+1][2])

		end	
	end



 -- -- let's draw some ground
 -- love.graphics.setColor(0,255,0,255)
 -- love.graphics.rectangle("fill", 0, 465, 800, 150)

 -- -- let's draw our hero
 -- love.graphics.setColor(255,255,0,255)
 -- love.graphics.rectangle("fill", hero.x,hero.y, 30, 15)

end

