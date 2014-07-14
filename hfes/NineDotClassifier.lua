local NineDotClassifier,parent = torch.class('hfes.NineDotClassifier','hfes.Classifier')

function NineDotClassifier:__init(grid,lines,lastPP)
	parent.__init(self)
	-- print("creating a classifier")
	self.grid = grid or hfes.GridClassifier()
	self.lines = lines or hfes.LineClassifierTwo()
	self.lastPP = lastPP or hfes.PointClassifierTwo()
	self.binaryClassifier = {}
end

function NineDotClassifier:buildClassifier(grid,lines,lastPP,foveationWindow,specificity)
	local specificity = specificity or 0.5
	self.grid:createCover(grid,specificity)
	-- print(foveationWindow)
	self.lines:createCover(lines,foveationWindow.rows,foveationWindow.cols,specificity)
	self.lastPP:createCover(lastPP,foveationWindow.rows,foveationWindow.cols,specificity)
	self.binaryClassifier = self:createBinaryClassifier()
end

-- function NineDotClassifier:match(grid,linesMatrix,pointMatrix)
-- 	local match = true
-- 	local params = {grid,linesMatrix,pointMatrix}
-- 	for i,classifier in ipairs({self.grid,self.lines,self.lastPP}) do
-- 		-- print(classifier)
-- 		local matchesClassifier = classifier:match(params[i])
-- 		if matchesClassifier == false then
-- 			match = false
-- 			break
-- 		end
-- 	end
-- 	return match
-- end

function NineDotClassifier:match(input)
	return util.matchClassifierIntegerTable(input,self.binaryClassifier)
end

function NineDotClassifier:createBinaryClassifier()
	local t = {}
	local longDots = util.flatten(self.grid.grid)
	local longLinesMatrix = util.flatten(self.lines.linesMatrix)
	local longPointMatrix = util.flatten(self.lastPP.pointMatrix)
	for i=1,longDots:storage():size() do
		table.insert(t,longDots:storage()[i])
	end
	for i=1,longLinesMatrix:storage():size() do
		table.insert(t,longLinesMatrix:storage()[i])
	end
	for i=1,longPointMatrix:storage():size() do
		table.insert(t,longPointMatrix:storage()[i])
	end
	return util.getConvertedIntTable(t)
end

function NineDotClassifier:mutate(p)
	for i,mod in ipairs({self.grid,self.lines,self.lastPP}) do
		--print("print i:" .. i)
		mod:mutateSpecificMatrixRandomly(p)
	end
end

function NineDotClassifier:duplicate()
	local clone = hfes.NineDotClassifier()
	clone.grid = self.grid:duplicate()
	clone.lines = self.lines:duplicate()
	clone.lastPP = self.lastPP:duplicate()
	clone.binaryClassifier = {}
	for i,b in ipairs(self.binaryClassifier) do
		table.insert(clone.binaryClassifier,b)
	end
	return clone
end