local EClassifier = torch.class('hfes.EClassifier')

function EClassifier:__init()
	-- print("creating a classifier")
	self.weight = 0.0
	self.fitness = 0.0
	self.classifier = nil
	self.valueHistory = torch.Tensor({})  --Length of this is the number of times this classifer has been active 
end

function EClassifier:setValue(value)
	--print("setting value with " .. value)
	self.weight = value
	if self.valueHistory:storage() ~= nil then 
		self.valueHistory = torch.cat(self.valueHistory,torch.Tensor({value}))
		--print("concat*****************************************")
	else
		--print("fresh")
		self.valueHistory = torch.Tensor({value})  
	end
	--Fitness is always chanegd by a new value so we should recalculate it here. 
	self:calcFitness()
end

function EClassifier:calcFitness()

	local fit = -torch.var(self.valueHistory)/torch.mean(self.valueHistory)
	
	self.fitness = fit 
	
	return fit 

end


function EClassifier:replicate()
--	print("REPLICATING ******************************")
	local clone = self:duplicate()
	clone.fitness = 0.0
	clone.weight = 0.0
	clone.valueHistory = torch.Tensor({})
	--print("printing selfvh")
	--print(self.valueHistory)
	clone:setValue(self.valueHistory[-1])
	return clone 
end

function EClassifier:duplicate()
	--print("IN CLONE")
	local clone = hfes.EClassifier()
	clone.weight = self.weight
	clone.classifier = self.classifier:duplicate()
	clone.fitness = self.fitness
	clone.valueHistory = self.valueHistory:clone()	
	--print(clone.valueHistory:storage():size())
	--print("KKK")
	return clone 
end

function EClassifier:mutate(p)
	self.classifier:mutate(p)
end
