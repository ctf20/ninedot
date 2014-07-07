local GridClassifier,parent = torch.class('hfes.GridClassifier','hfes.ClassifierModule')

function GridClassifier:__init(grid)
	parent.__init(self)
	if grid then
		self.grid = grid
		self.rows = grid:size()[1]
		self.columns = grid:size()[2]
	else
		self.grid = torch.Tensor({})
		self.rows = 0
		self.columns = 0
	end
end

function GridClassifier:match(input)
	return utils.matchTensor(input,self.grid)
end

function GridClassifier:createCover(dots,specificity)
	local specifity = specifity or 0.5
	local dotsTemplate = dots:clone()
	for i=1,#dotsTemplate:storage() do
		if math.random() > specifity then
			dotsTemplate:storage()[i] = -1
		end
	end
	self.grid = dotsTemplate
	return self.grid	
end