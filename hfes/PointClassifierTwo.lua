local PointClassifierTwo,parent = torch.class('hfes.PointClassifierTwo','hfes.ClassifierModule')

function PointClassifierTwo:__init(point,pointMatrix)
	parent.__init(self)
	self.point = point or torch.Tensor({})
	self.pointMatrix = pointMatrix or torch.Tensor({})
end

function PointClassifierTwo:match(input)
	return util.matchTensorWithIgnores(self.pointMatrix,input)
end

function PointClassifierTwo:createCover(point,windowRows,windowCols,specificity)
	local specificity = specificity or 0.5
	local pointMatrix = util.convertPointToMatrix(point,windowRows,windowCols)
	self.point = torch.Tensor({})
	if point:storage() ~= nil then --go through each line. 
		if math.random() > specificity then
  			pointMatrix[point[1]][point[2]] = -1
		else
			-- print("insert")
			-- local a={{startX,startY},{endX,endY}}
			-- print(a[1])
			-- print(a[2])
			self.point = point:clone()
		end
	end
	--Set elements in pointMatrix to -1 randomly..
	for i=1,pointMatrix:storage():size() do 
		if math.random() > specificity then
			if pointMatrix:storage()[i] == 0 then 
				pointMatrix:storage()[i] = -1
			end
		end
	end
	self.pointMatrix = pointMatrix
	return self.point,self.pointMatrix
end

function PointClassifierTwo:duplicate()
	local clone = hfes.PointClassifierTwo()
	clone.point = self.point:clone()
	clone.pointMatrix = self.pointMatrix:clone()
	return clone
end

function PointClassifierTwo:mutateSpecificMatrixRandomly(p)
	self:mutateMatrixRandomly(self.pointMatrix,p)
end