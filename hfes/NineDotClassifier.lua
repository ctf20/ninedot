local NineDotClassifier,parent = torch.class('hfes.NineDotClassifier','hfes.Classifier')

function NineDotClassifier:__init(grid,lines,lastPP)
	parent.__init(self)
	print("creating a classifier")
	self.grid = grid or hfes.GridClassifier()
	self.lines = lines or hfes.LineClassifier()
	self.lastPP = lastPP or hfes.PointClassifier()
end

function NineDotClassifier:buildClassifier(grid,lines,lastPP,specificity)
	local specificity = specificity or 0.5
	self.grid:createCover(grid,specificity)
	self.lines:createCover(lines,specificity)
	self.lastPP:createCover(lastPP,specificity)
end

function NineDotClassifier:match(grid,lines,lastPP)
	local match = true
	local params = {grid,lines,lastPP}
	for i,classifier in ipairs({self.grid,self.lines,self.lastPP}) do
		print("matching:" .. i)
		local matchesClassifier = classifier:match(params[i])
		if matchesClassifier == false then
			print("didnt match:" .. i)
			match = false
			break
		end
	end
	return match
end