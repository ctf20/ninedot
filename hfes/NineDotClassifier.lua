local NineDotClassifier,parent = torch.class('hfes.NineDotClassifier','hfes.Classifier')

function NineDotClassifier:__init(grid,lines,lastPP)
	parent.__init(self)
	-- print("creating a classifier")
	self.grid = grid or hfes.GridClassifier()
	self.lines = lines or hfes.LineClassifierTwo()
	self.lastPP = lastPP or hfes.PointClassifier()
end

function NineDotClassifier:buildClassifier(grid,lines,lastPP,foveationWindow,specificity)
	local specificity = specificity or 0.5
	self.grid:createCover(grid,specificity)
	-- print(foveationWindow)
	self.lines:createCover(lines,foveationWindow.rows,foveationWindow.cols,specificity)
	self.lastPP:createCover(lastPP,specificity)
end

function NineDotClassifier:match(grid,linesMatrix,lastPP)
	local match = true
	local params = {grid,linesMatrix,lastPP}
	for i,classifier in ipairs({self.grid,self.lines,self.lastPP}) do
		-- print(classifier)
		local matchesClassifier = classifier:match(params[i])
		if matchesClassifier == false then
			match = false
			break
		end
	end
	return match
end