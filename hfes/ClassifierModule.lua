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
	
	local p = p or (1/(matrix:storage():size()*1.0))
	--p = 0.1 --A High rate of adding hashes to matrices, i.e. promoting generality is enforced. 
	for i=1,matrix:storage():size() do
		if matrix:storage()[i] ~= 0 and math.random() < p then
			matrix:storage()[i] = 0
			self.numHashes = self.numHashes + 1
		end
				
	end
	
end

function ClassifierModule:mutateMatrixLamarckian(matrix,matchingMatrix,p)
	local p = p or (1/(matrix:storage():size()*1.0))
	-- p = 0.0
	for i=1,matrix:storage():size() do
		if matrix:storage()[i]  == 0 and math.random() < p then
			matrix:storage()[i] = self:getLamarckianElement(matchingMatrix,i)
			self.numHashes = self.numHashes - 1
		end
	end
end

function ClassifierModule:getLamarckianElement(matchingMatrix,i)
	return matchingMatrix:storage()[i]
end

function ClassifierModule:chooseWindow(windows)
	return windows[math.random(1,#windows)]
end