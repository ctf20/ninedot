local ninedot = torch.class('hfes.ninedot')

function ninedot:__init(N, K, boardSize)
	print("creating an {n,k,c}-problem")

	-- Create an (n,k,c) dot problem 
	self.n = N or 1 --Default = A single dot 
	self.k = K or 1 --Default = Single pen down move 
	self.boardSize = boardSize or 10 --Default is a 10 x 10 board. 
	
	-- Create a board state table which will store the current board state. 
	self.bs = {}
	self.bs.dots = {} --Dot state

	-- Create a board for storing dots. 
	for i = 1, self.boardSize do 
		self.bs.dots[i] = {}
		for j = 1, self.boardSize do 
			self.bs.dots[i][j] = 0 
		end
	end
	--print(self.bs.dots)

	-- Create k random dots 
	local num_dots_made = 0
	while num_dots_made < self.n do
		print('here making dots') 
		local x = math.random(1, boardSize)
		local y = math.random(1, boardSize)
		if self.bs.dots[x][y] == 0 then 
			self.bs.dots[x][y] = 1 
			num_dots_made = num_dots_made + 1
			print("dot in " .. x .. "," .. y)
		end 
	end

	-- Create a data structure for storing an order of lines drawn 
	self.bs.pp = {} -- Line state (sequence of dot positions that the pen has been on.) pp = pen positions 
	-- table.insert(self.bs.pp, {0,1}) bs.pp takes a table of coordinates for the pen position, like this. 
end

-- --- a method
-- function ninedot:print()

--  print("here")

-- end

function ninedot:getMoves()
	local moves = {}	
	-- print('getting moves and scores for current ninebot board state ')
	for i = 1, self.boardSize do 
		for j = 1, self.boardSize do 
			table.insert(moves, {i,j})
		end
	end
	return moves
end

function clone (t) -- deep-copy a table
    if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            target[k] = clone(v)
        else
            target[k] = v
        end
    end
    setmetatable(target, meta)
    return target
end

function ninedot:getScores(moves)
	-- local scores = {}	
	local scores = {}
	local dots_covered, no_dots = self:getScoreCurrentPosition()
	-- print(dots_covered)
	-- print(no_dots)
	local last_move = self.bs.pp[#self.bs.pp]
	for i,move in ipairs(moves) do
		-- print ("**********TESTING NEW MOVE*************")
		temp_dots_covered = clone(dots_covered)
		--print(self:countDotsCovered(temp_dots_covered))
		if last_move ~= nil then 
			temp_dots_covered = self:getDotsCovered(last_move,move,temp_dots_covered)
		else
			temp_dots_covered = self:getDotsCovered(move,nil, temp_dots_covered)
		end
		table.insert(scores,self:countDotsCovered(temp_dots_covered))
	end
	-- print(scores)
	return scores

end


function ninedot:getScoreCurrentPosition()
	local dots_covered = {}
	for i = 1, self.boardSize do 
		dots_covered[i] = {}
		for j = 1, self.boardSize do 
			dots_covered[i][j] = 0
		end
	end
	if #self.bs.pp == 1 then
		dots_covered = self:getDotsCovered(self.bs.pp[1],nil,dots_covered)
	else
		for i=1,#self.bs.pp-1 do
			-- print("moving")
			dots_covered = self:getDotsCovered(self.bs.pp[i],self.bs.pp[i+1],dots_covered)
		end
	end
	-- self:printDotsCovered(dots_covered)
	return dots_covered,self:countDotsCovered(dots_covered)
end

function ninedot:printDotsCovered(dots_covered)
	print(dots_covered)
end

function ninedot:countDotsCovered(dots_covered)
	local count = 0
	for x=1,self.boardSize do
		for y=1,self.boardSize do
			if dots_covered[x][y] == 1 then
				count = count + 1
			end
		end
	end
	return count
end
function ninedot:getDotsCovered(first,second,dots_covered)
	-- print("in getDotsCovered")
	if second == nil then
		-- print("testing: {" .. first[1] .. "," .. first[2] .. "}")
		if self.bs.dots[first[1]][first[2]] == 1 then
			dots_covered[first[1]][first[2]] = 1
			-- print("we did it")
		end
		return dots_covered
	else
		local x_start = first[1]
		local y_start = first[2]
		local gradient = (second[2]-first[2])/(1.0*(second[1]-first[1]))
		local x_range = second[1] - first[1]
		local y_range = second[2] - first[2]

		-- print ("start = " .. x_start .. " " .. y_start)
		-- print ("finish = " .. second[1] .. " " .. second[2])
		
		local inc = 0
		if x_range > 0 then inc = 1 else inc = -1 end
		local x = 0 
		local y = 0 
		if second[1] - first[1] ~= 0  then 
			for i = 0, x_range, inc do 
				x = x_start + i
		--		print('here2')
				y = y_start + gradient*i
				-- print("x [" .. i .. "] = " .. x .. " y [" .. i .. "] = " .. y )

				dots_covered = self:checkDot(x,y,dots_covered)

			end
		else
		if y_range > 0 then inc = 1 else inc = -1 end	
			for i = 0,y_range, inc do 
				x = x_start 
	--			print('here3 ' .. i .. " " .. second[2]-first[2] .. " " .. y )
				y = y_start + i
				-- print("x [" .. i .. "] = " .. x .. " y [" .. i .. "] = " .. y ) 
				
				dots_covered = self:checkDot(x,y,dots_covered)

			end
		end
	end
	return dots_covered
end

function ninedot:checkDot(x,y, dots_covered)

	if math.floor(x)==x and math.floor(y)==y then
		if self.bs.dots[x][y] == 1 then
			dots_covered[x][y] = 1
			-- print("covering:" .. x .. "," .. y)
		end
	end

	return dots_covered

end

function ninedot:updateBoard(chosenMove)
	print("best move:")
	print(chosenMove)
	self.bs.dots[chosenMove[1]][chosenMove[2]] = 1 
	table.insert(self.bs.pp, chosenMove)

end

function ninedot:getFoveationSet()


	return {{1,2},{2,3}}

end


