local NineDotClassifier,parent = torch.class('hfes.NineDotClassifier','hfes.Classifier')
plPretty = require "pl.pretty"
function NineDotClassifier:__init(grid,lines,lastPP)
	parent.__init(self)
	-- print("creating a classifier")
	self.grid = grid or hfes.GridClassifier()
	self.lines = lines or hfes.LineClassifierTwo()
	self.lastPP = lastPP or hfes.PointClassifierTwo()
end

function NineDotClassifier:buildClassifier(grid,lines,lastPP,foveationWindow,specificity)
	local specificity = specificity or 0.5
	self.grid:createCover(grid,specificity)
	-- print(foveationWindow)
	self.lines:createCover(lines,foveationWindow.rows,foveationWindow.cols,specificity)
	self.lastPP:createCover(lastPP,foveationWindow.rows,foveationWindow.cols,specificity)
	-- self.binaryClassifier = self:createBinaryClassifier()
	self.hiddenWeights = self:createHiddenWeights()


end


function NineDotClassifier:getNumHashes()
	local numHashes = 0
	for i,class in ipairs({self.grid,self.lines,self.lastPP}) do
		numHashes = numHashes + class.numHashes
	end
	return numHashes
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


function NineDotClassifier:createHiddenWeights()

	local hiddenWeights = {}
	local bias = 0 
	for _,structure in ipairs({self.grid.grid,self.lines.linesMatrix,self.lastPP.pointMatrix}) do 
		for i = 1, structure:size()[1] do
			for j = 1, structure:size()[2] do
				if structure[i][j] == -1 then 
					table.insert(hiddenWeights,0)
				end
				if structure[i][j] == 1 then 
					table.insert(hiddenWeights,1)
					bias = bias + 1
				end
				if structure[i][j] == 0 then 
					table.insert(hiddenWeights,-1)
					bias = bias + 1

				end		
			end
		end
	end
	table.insert(hiddenWeights, -(bias-0.5))
	
	hiddenWeights = torch.Tensor(hiddenWeights)

	return hiddenWeights 

end

-- function NineDotClassifier:createBinaryClassifier()
-- 	local t = {}
-- 	local longDots = util.flatten(self.grid.grid)
-- 	local longLinesMatrix = util.flatten(self.lines.linesMatrix)
-- 	local longPointMatrix = util.flatten(self.lastPP.pointMatrix)
-- 	for i=1,longDots:storage():size() do
-- 		table.insert(t,longDots:storage()[i])
-- 	end
-- 	for i=1,longLinesMatrix:storage():size() do
-- 		table.insert(t,longLinesMatrix:storage()[i])
-- 	end
-- 	for i=1,longPointMatrix:storage():size() do
-- 		table.insert(t,longPointMatrix:storage()[i])
-- 	end
-- 	return util.getConvertedIntTable(t)
-- end

function NineDotClassifier:mutate(foveationWindows,p)
	for i,mod in ipairs({self.grid,self.lines,self.lastPP}) do
		--print("print i:" .. i)
		mod:mutateOperation(foveationWindows,p)
	end

	--HERE
	
	-- self.binaryClassifier = self:createBinaryClassifier()
	self.hiddenWeights = self:createHiddenWeights()
	-- print("weights")
	-- plPretty.dump(self.hiddenWeights)

end

function NineDotClassifier:duplicate()
	local clone = hfes.NineDotClassifier()
	clone.grid = self.grid:duplicate()
	clone.lines = self.lines:duplicate()
	clone.lastPP = self.lastPP:duplicate()
	clone.hiddenWeights = self.hiddenWeights:clone()
	return clone
end