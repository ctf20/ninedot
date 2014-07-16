local ClassifierModule,parent = torch.class('hfes.ClassifierModule')

function ClassifierModule:__init()
	-- print("creating a classifier")
end

function ClassifierModule:match(input)
end

function ClassifierModule:cover(input,specificity)
end

function ClassifierModule:mutateMatrixRandomly(matrix,p)
--	print("matrix:stroage")
--	print(matrix:storage():size())
	local numHashes = 0 
	local p = p or (1/(matrix:storage():size()*1.0))
	p = 1.0
	for i=1,matrix:storage():size() do
		if math.random() < p then
			matrix:storage()[i] = -1
			numHashes = numHashes + 1
		end
		--I THINK WE NEED TO ADD INCREASING SPECIFICITY NOW TOO. 
				
	end
	return numHashes 
end

function ClassifierModule:mutateMatrixLamarckian(matrix,matchingMatrix,p)
	local p = p or (1/(matrix:storage():size()*1.0))
	p = 0.0
	for i=1,matrix:storage():size() do
		if math.random() < p then
			matrix:storage()[i] = self:getLamarckianElement(matchingMatrix,i)
			self.numHashes = self.numHashes - 1
		end
	end
	return self.numHashes 
end

function ClassifierModule:getLamarckianElement(matchingMatrix,i)
	return matchingMatrix:storage()[i]
end

function ClassifierModule:chooseWindow(windows)
	return windows[math.random(1,#windows)]
end