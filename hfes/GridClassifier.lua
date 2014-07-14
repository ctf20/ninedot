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
	return util.matchTensorWithIgnores(self.grid,input)
end

function GridClassifier:createCover(dots,specificity)
	local specificity = specificity or 0.5
	local dotsTemplate = dots:clone()
	for i=1,#dotsTemplate:storage() do
		if math.random() > specificity then
			dotsTemplate:storage()[i] = -1
		end
	end
	self.grid = dotsTemplate
	return self.grid	
end

function GridClassifier:mutateSpecificMatrixRandomly(p)
	print("grid:stroage")
	print(self.grid)
	print(self.grid:storage():size())
	self:mutateMatrixRandomly(self.grid,p)
end

function GridClassifier:duplicate()
	local clone = hfes.GridClassifier()
	clone.grid = self.grid:clone()
	clone.rows = self.rows
	clone.columns = self.columns
	return clone
end