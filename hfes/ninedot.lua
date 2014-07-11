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
	self.bs.dotsCords = {}
	-- Create a board for storing dots. 
	for i = 1, self.boardSize do 
		self.bs.dots[i] = {}
		for j = 1, self.boardSize do 
			self.bs.dots[i][j] = 0 
		end
	end
	--print(self.bs.dots)

	-- create tensor board
	self.tBoard = torch.Tensor(self.boardSize,self.boardSize):fill(0)
	self.boardDiag = math.ceil(math.sqrt(self.boardSize^2+self.boardSize^2))
	if self.boardDiag % 2 == 0 then
		self.boardDiag = self.boardDiag + 1
	end
	self.pseudoTBoard = torch.Tensor(3*self.boardDiag,3*self.boardDiag):fill(0)
	self.pseudoWidth = self.boardDiag*3 / 2
	self.largeBoardWidth = 3*self.boardDiag

	print("boardSize:" .. self.boardSize)
	print("largeBoardWidth:" .. self.largeBoardWidth)
	-- Create k random dots 
	local num_dots_made = 0
	while num_dots_made < self.n do
		print('here making dots') 
		-- local x = math.random(1, self.boardSize)
		-- local y = math.random(1, self.boardSize)
		local x = math.random(1+math.floor(math.sqrt(self.n)/2),self.boardSize-math.floor(math.sqrt(self.n)/2))
		local y = math.random(1+math.floor(math.sqrt(self.n)/2),self.boardSize-math.floor(math.sqrt(self.n)/2))
		if self.bs.dots[x][y] == 0 then 
			self.bs.dots[x][y] = 1
			self.tBoard[x][y] = 1
			table.insert(self.bs.dotsCords,{x,y})
			num_dots_made = num_dots_made + 1
			print("dot in " .. x .. "," .. y)
		end 
	end
	local a = math.floor((self.largeBoardWidth/2)-(self.boardSize/2)+1)
	local b = a + self.boardSize - 1
	print("a:" .. a)
	print("b:" .. b)
	
	self.pseudoTBoard[{{a,
						b},
						{a,
						b}}]=self.tBoard:clone()
	print(self.tBoard)
	-- Create a data structure for storing an order of lines drawn 
	self.bs.pp = {} -- Line state (sequence of dot positions that the pen has been on.) pp = pen positions 
	-- table.insert(self.bs.pp, {0,1}) bs.pp takes a table of coordinates for the pen position, like this.
	--self.foveationWindow = {rows=self.boardDiag,columns=self.boardDiag}
	--self.classifierWindow = {rows=self.boardDiag,columns=self.boardDiag}

	self.fovWindows = {} --Global foveation window to pass for visualization later. 
end

function ninedot:getImage()
	--Returns the ninedot stuff to plot. 
	return {self.bs, self.fovWindows}

end

function ninedot:resetBoardState()
	
	-- Create a board state table which will store the current board state. 
	self.bs = {}
	self.bs.dots = {} --Dot state
	self.bs.dotsCords = {}
	-- Create a board for storing dots. 
	for i = 1, self.boardSize do 
		self.bs.dots[i] = {}
		for j = 1, self.boardSize do 
			self.bs.dots[i][j] = 0 
		end
	end
	--print(self.bs.dots)

	-- create tensor board
	self.tBoard = torch.Tensor(self.boardSize,self.boardSize):fill(0)
	self.boardDiag = math.ceil(math.sqrt(self.boardSize^2+self.boardSize^2))
	if self.boardDiag % 2 == 0 then
		self.boardDiag = self.boardDiag + 1
	end
	self.largeBoardWidth = 3*self.boardDiag
	self.pseudoTBoard = torch.Tensor(self.largeBoardWidth,self.largeBoardWidth):fill(0)
	-- Create k random dots 
	local num_dots_made = 0
	while num_dots_made < self.n do
		print('here making dots') 
		--local x = math.random(1, self.boardSize)
		--local y = math.random(1, self.boardSize)
		local x = math.random(1+math.floor(math.sqrt(self.n)/2),self.boardSize-math.floor(math.sqrt(self.n)/2))
		local y = math.random(1+math.floor(math.sqrt(self.n)/2),self.boardSize-math.floor(math.sqrt(self.n)/2))
		if self.bs.dots[x][y] == 0 then 
			self.bs.dots[x][y] = 1
			self.tBoard[x][y] = 1
			table.insert(self.bs.dotsCords,{x,y})
			num_dots_made = num_dots_made + 1
			print("dot in " .. x .. "," .. y)
		end 
	end
	local a = math.floor((self.largeBoardWidth/2)-(self.boardSize/2)+1)
	local b = a + self.boardSize - 1
	self.pseudoTBoard[{{a,
						b},
						{a,
						b}}]=self.tBoard:clone()
	--print(self.tBoard)
	self.bs.pp = {} -- Line state (sequence of dot positions that the pen has been on.) pp = pen positions 
	self.fovWindows = {} --Global foveation window to pass for visualization later. 

end

function ninedot:printBoardState()

	print('dot positions')

	print( table.tostring(self.bs.dots))
	
	print('pen positions')

	print( table.tostring( self.bs.pp ) )
end

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
			print("moving")
			dots_covered = self:getDotsCovered(self.bs.pp[i],self.bs.pp[i+1],dots_covered)
		end
	end

	--self:printDotsCovered(dots_covered)
	return dots_covered , self:countDotsCovered(dots_covered)
end

function ninedot:printDotsCovered(dots_covered)
	for i = 1, #dots_covered do 
		print(" ")
		for j = 1, #dots_covered[i] do 
			print(dots_covered[i][j] .. " ")
		end
	end
	
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
		-- for i = 1, #self.bs.dots do 
		-- 		print("")
		-- 	for j = 1, #self.bs.dots[i] do 
		-- 		io.write(self.bs.dots[i][j])
		-- 		if self.bs.dots[i][j] == 1 then 
					
		-- 			--print("dot is actually at : {" .. i .. "," .. j.. "}")
		-- 		end
		-- 	end
		-- end
		--print("testing: {" .. first[1] .. "," .. first[2] .. "}")
		if self.bs.dots[first[1]][first[2]] == 1 then
			dots_covered[first[1]][first[2]] = 1
			--print("we did it")
		else
			dots_covered[first[1]][first[2]] = 0
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
	--print("best move:")
	--print(chosenMove)
	table.insert(self.bs.pp, chosenMove)
end

function ninedot:makePotentialMove(move)
	table.insert(self.bs.pp,move)
end

function ninedot:undoLastMove()
	self.bs.pp[#self.bs.pp] = nil
end
-- function ninedot:getFoveationSet()
-- 	local allFoveationWindows = {}
-- 	-- the center will be determined by the foveation window
-- 	for i,center in ipairs(self.bs.dotsCords) do
-- 		-- we may have to loop over different classifier sizes
-- 		centerRelativeToLargeBoard = {center[1]+self.boardDiag+math.floor(self.boardSize/2),center[2]+self.boardDiag+math.floor(self.boardSize/2)}
-- 		print("c rel:")
-- 		print(centerRelativeToLargeBoard)
-- 		local foveationWindow = {dots={},lines={},lastP={}}
-- 		local row_min = centerRelativeToLargeBoard[1] - math.floor(self.foveationWindow.rows/2)
-- 		local row_max = centerRelativeToLargeBoard[1] + math.floor(self.foveationWindow.rows/2)
-- 		local col_min = centerRelativeToLargeBoard[2] - math.floor(self.foveationWindow.columns/2)
-- 		local col_max = centerRelativeToLargeBoard[2] + math.floor(self.foveationWindow.columns/2)

-- 		-- print(self.bs.dotsCords)
-- 		print(self.tBoard)
-- 		print("center:")
-- 		print(center)
-- 		print "sub:"
-- 		print ("" .. row_min .. "," .. row_max .. "," .. col_min .. "," .. col_max)
-- 		print(self.pseudoTBoard)
-- 		foveationWindow.dots = self.pseudoTBoard:sub(row_min,
-- 												 	 row_max,
-- 												 	 col_min,
-- 												 	 col_max):clone()
-- 		if #self.bs.pp > 1 then
-- 			for j=1,#self.bs.pp-1 do
-- 				if (self.bs.pp[j][1] >= row_min and self.bs.pp[j][1] <= row_max) and
-- 				   (self.bs.pp[j][2] >= col_min and self.bs.pp[j][2] <= col_max) and
-- 				   (self.bs.pp[j+1][1] >= row_min and self.bs.pp[j+1][1] <= row_max) and
-- 				   (self.bs.pp[j+1][2] >= col_min and self.bs.pp[j+1][2] <= col_max) then
-- 					table.insert(foveationWindow.lines,{{self.bs.pp[j][1]-row_min+1,self.bs.pp[j][2]-col_min+1},
-- 														{self.bs.pp[j+1][1]-row_min+1,self.bs.pp[j+1][2]-col_min+1}})
-- 					if j+1 == #self.bs.pp then
-- 						foveationWindow.lastP = {self.bs.pp[j+1][1]-row_min+1,self.bs.pp[j+1][2]-col_min+1}
-- 					end
-- 				end
-- 			end
-- 		end


-- 		foveationWindow.lines = torch.Tensor(foveationWindow.lines)
-- 		print("foveationWindow:")
-- 		print(foveationWindow.dots)
-- 		print("pps:")
-- 		print(foveationWindow.lines)
-- 		print("lastP:")
-- 		print(foveationWindow.lastP)
-- 		foveationWindow.lastP = torch.Tensor(foveationWindow.lastP)
-- 		table.insert(allFoveationWindows,foveationWindow)
-- 	end
-- 	-- for i,w in ipairs(windows) do
-- 	-- 	print(w)
-- 	-- 	print("match:") 
-- 	-- 	print(hfes.utils.matchTensorWithIgnores(torch.Tensor({{1,0},{1,0}}),torch.Tensor({{1,0},{1,1}})))
-- 	-- end
-- 	-- print(self.tBoard)
-- 	-- for i=1,windows[1]:storage():size() do
-- 	-- 	print(windows[1]:storage()[i])
-- 	-- end

-- 	return allFoveationWindows
-- end

function ninedot:getFoveationSet()
	local foveationPositions = {}
	local lPPS = self:createLargeBoardPPS(self.bs.pp)
	for i,center in ipairs(self.bs.dotsCords) do
		local relCenter = self:getLargeBoardCoordinates(center)
		local foveationPosition = {center=center,relCenter=relCenter,foveationWindows={}}
		for j,size in ipairs({{5,5}}) do
			-- print("center:")
			-- print(center)
			-- print("relCenter")
			-- print(relCenter)
			local x = self.tBoard:clone()
			x[center[1]][center[2]] = 9
			-- print(x)
			-- local k = self.pseudoTBoard:clone()
			-- k[relCenter[1]][relCenter[2]] = 9
			-- print(k)
			local foveationWindow = self:extractLargeWindow(relCenter,size[1],size[2])
			-- print(foveationWindow.dots)
			foveationWindow.lines,foveationWindow.linesMatrix = self:extractLinesInLargeWindow(foveationWindow,lPPS,size[1],size[2])
			-- print("lines")
			-- print(foveationWindow.lines)
			foveationWindow.lastPP,foveationWindow.pointMatrix = self:extractLastPPInLargeWindow(foveationWindow,lPPS,size[1],size[2])
			-- print("lastPP")
			-- print(foveationWindow.lastPP)
			table.insert(foveationPosition.foveationWindows,foveationWindow)
		end
		foveationPosition.dotCord = self.bs.dotsCords[i]
		table.insert(foveationPositions,foveationPosition)
	end
	self.fovWindows = foveationPositions
	return foveationPositions
end

function ninedot:createLargeBoardPPS(pps)
	local lPPS = {}
	for i,pp in ipairs(pps) do
		table.insert(lPPS,self:getLargeBoardCoordinates(pp))
	end
	return lPPS
end

function ninedot:getLargeBoardCoordinates(center)
	local fromTop = math.floor(self.largeBoardWidth/2 - self.boardSize/2 + center[1])
	-- print("fl")
	-- print fromLeft
	local fromLeft = math.floor(self.largeBoardWidth/2 - self.boardSize/2 + center[2])
	return {fromTop,fromLeft}
end

function ninedot:extractLargeWindow(centerRelativeToLargeBoard,rows,columns)
	-- print("centerRelativeToLargeBoard")
	-- print(centerRelativeToLargeBoard)
	local row_min = centerRelativeToLargeBoard[1] - math.floor(rows/2)
	local row_max = centerRelativeToLargeBoard[1] + math.floor(rows/2)
	local col_min = centerRelativeToLargeBoard[2] - math.floor(columns/2)
	local col_max = centerRelativeToLargeBoard[2] + math.floor(columns/2)
	local dots = self.pseudoTBoard:sub(row_min,
							 	 row_max,
							 	 col_min,
							 	 col_max):clone()
	return {dots=dots,
			row_min=row_min,
			row_max=row_max,
			col_min=col_min,
			col_max=col_max,
			rows=rows,
			cols=columns}
end

function ninedot:extractLinesInLargeWindow(window,lPPS,rows,columns)
	-- print("ninedot:extractLinesInLargeWindow")
	-- print(window)
	-- print(lPPS)
	local lines = {}
	if #lPPS > 1 then
		for j=1,#lPPS-1 do
			if (lPPS[j][1] >= window.row_min and lPPS[j][1] <= window.row_max) and
			   (lPPS[j][2] >= window.col_min and lPPS[j][2] <= window.col_max) and
			   (lPPS[j+1][1] >= window.row_min and lPPS[j+1][1] <= window.row_max) and
			   (lPPS[j+1][2] >= window.col_min and lPPS[j+1][2] <= window.col_max) then
				table.insert(lines,{{lPPS[j][1]-window.row_min+1,lPPS[j][2]-window.col_min+1},
													{lPPS[j+1][1]-window.row_min+1,lPPS[j+1][2]-window.col_min+1}})
			end
		end
	end
	lines = torch.Tensor(lines)
	local linesMatrix = util.convertPPVecToMatrix(lines,rows,columns)
	return lines,linesMatrix
end

function ninedot:extractLastPPInLargeWindow(window,lPPS,rows,columns)
	local lastPP = {}
	if #lPPS >= 1 and 
	(lPPS[#lPPS][1] >= window.row_min and lPPS[#lPPS][1] <= window.row_max) and
    (lPPS[#lPPS][2] >= window.col_min and lPPS[#lPPS][2] <= window.col_max) then
		lastPP = {lPPS[#lPPS][1]-window.row_min+1,lPPS[#lPPS][2]-window.col_min+1}
	end
	lastPP = torch.Tensor(lastPP)
	local pointMatrix = util.convertPointToMatrix(lastPP,rows,columns)

	return lastPP,pointMatrix
end
