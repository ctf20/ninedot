--Love test hFES with visualization in real-time 
--Run with /Applications/love.app/Contents/MacOS/love ~/Documents/ninedot/test in the directory /Users/chrisantha/Documents/ninedot/test
require 'hfes'

function love.load()

--Initialize the ninedot problem here. 

	n = 2
	k = 2
	b = 5 
	nd = hfes.ninedot(n,k,b)
	d = hfes.hFES(nd)


	 hero = {} -- new table for the hero
	 hero.x = 300    -- x,y coordinates of the hero
	 hero.y = 450
	 hero.speed = 400
end

function love.update(dt)

	 --Start 

	 --Step 

 	 d:makeMove()
	
	 --End 


	 if love.keyboard.isDown("left") then
	   hero.x = hero.x - hero.speed*dt
	 elseif love.keyboard.isDown("right") then
	   hero.x = hero.x + hero.speed*dt
	 end


end

function love.draw()
 -- let's draw some ground
 love.graphics.setColor(0,255,0,255)
 love.graphics.rectangle("fill", 0, 465, 800, 150)

 -- let's draw our hero
 love.graphics.setColor(255,255,0,255)
 love.graphics.rectangle("fill", hero.x,hero.y, 30, 15)
end
