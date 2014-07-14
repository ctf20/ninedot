local ClassifierModule,parent = torch.class('hfes.ClassifierModule')

function ClassifierModule:__init()
	-- print("creating a classifier")
end

function ClassifierModule:match(input)
end

function ClassifierModule:cover(input,specificity)
end

function ClassifierModule:mutateMatrixRandomly(matrix,p)
	print("matrix:stroage")
	print(matrix:storage():size())
	local p = p or (1/(matrix:storage():size()*1.0))
	for i=1,matrix:storage():size() do
		if math.random() < p then
			matrix:storage()[i] = -1
		end
	end
end