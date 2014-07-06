require "hfes"
local PointClassifier,parent = torch.class('hfes.PointClassifier','hfes.Classifier')

function PointClassifier:__init(point)
	parent.__init(self)
	self.point = point or torch.Tensor({})
end

function PointClassifier:match(input)
	if self.point:storage() == nil then
		return true
	else
		return hfes.utils.matchTensor(input,self.point)
end

function PointClassifier:createCover(point,specificity)
	local specifity = specifity or 0.5
	if math.random() > specifity:
		self.point = point
	else
		self.point = torch.Tensor()
	end
	return self.point	
end