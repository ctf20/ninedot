--Love test hFES with visualization in real-time 

-- function love.draw()
--     love.graphics.print('Hello World!', 400, 300)
-- end

require 'hfes'

--Initialize the ninedot problem here. 
	local n = 2
	local k = 2
	local b = 3 
	--First start 
	nd = hfes.ninedot(n,k,b)
	d = hfes.hFES(nd)
	d:makeMoveTD()
	d:makeMoveTD()
	d:makeMoveTD()

	local active = d:getActiveClassifiersForMove()
	print(#d.classifiers)
	print(active)

	child = d.classifiers[20]:replicate()
	print("child")
	print(child)
	child:mutate(1.0)
