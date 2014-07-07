local PointClassifier,parent = torch.class('hfes.PointClassifier','hfes.ClassifierModule')

function PointClassifier:__init(point)
	parent.__init(self)
	self.point = point or torch.Tensor({})
end

function PointClassifier:match(input)
	if self.point:storage() == nil then
		return true
	else
		return util.matchTensor(input,self.point)
	end
end

function PointClassifier:createCover(point,specificity)
	local specificity = specificity or 0.5
	if math.random() > specificity then 
		self.point = point
	else
		self.point = torch.Tensor()
	end
	return self.point	
end