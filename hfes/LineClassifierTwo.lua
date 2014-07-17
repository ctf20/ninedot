local LineClassifierTwo,parent = torch.class('hfes.LineClassifierTwo','hfes.ClassifierModule')

function LineClassifierTwo:__init(lines,linesMatrix)
	parent.__init(self)
	self.lines = lines or torch.Tensor({})
	self.linesMatrix = lines or torch.Tensor({})
	self.numHashes = 0 
end

function LineClassifierTwo:match(input)
	  -- print(self.linesMatrix)
	  -- print(input)
	return util.matchTensorWithIgnores(self.linesMatrix,input)
end

function LineClassifierTwo:createCover(lines,windowRows,windowCols,specificity)
	local specificity = specificity or 0.5
	--specificity = 0.0
	local linesMatrix = util.convertPPVecToMatrix(lines,windowRows,windowCols)
	self.lines = {}
	if lines:storage() ~= nil then --go through each line. 
		for i=1,lines:size()[1] do 
			startX = lines[i][1][1]
			startY = lines[i][1][2]
			endX = lines[i][2][1]
			endY = lines[i][2][2]
			if math.random() > specificity then
				local from = util.convertCoords(startX,startY,windowCols)
      			local to = util.convertCoords(endX,endY,windowCols)
      			linesMatrix[from][to] = 0 -- -1
      			self.numHashes = self.numHashes + 1
			else
				-- print("insert")
				-- local a={{startX,startY},{endX,endY}}
				-- print(a[1])
				-- print(a[2])
				table.insert(self.lines,{{startX,startY},{endX,endY}})
			end
		end
	end

	--Set elements in linesMatrix to -1 randomly..
	for i=1,linesMatrix:storage():size() do 
		if math.random() > specificity then
			if linesMatrix:storage()[i] == -1 then -- 0 then 
				linesMatrix:storage()[i] = 0 -- -1
				self.numHashes = self.numHashes + 1
			end
		end
	end
	self.linesMatrix = linesMatrix
	-- print("self.lines")
	-- print(self.lines)
	self.lines = torch.Tensor(self.lines)
	return self.lines,self.linesMatrix
end

function LineClassifierTwo:duplicate()
	local clone = hfes.LineClassifierTwo()
	clone.lines = self.lines:clone()
	clone.linesMatrix = self.linesMatrix:clone()
	clone.numHashes = self.numHashes
	return clone
end

function LineClassifierTwo:mutateSpecificMatrixRandomly(p)
	self:mutateMatrixRandomly(self.linesMatrix,p)
end

function LineClassifierTwo:mutateOperation(foveationWindows,p)
	self:mutateSpecificMatrixRandomly(p)
	local window = self:chooseWindow(foveationWindows)
	self:mutateMatrixLamarckian(self.linesMatrix,window.linesMatrix,p)
end