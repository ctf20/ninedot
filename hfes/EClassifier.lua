local EClassifier = torch.class('hfes.EClassifier')

function EClassifier:__init()
	-- print("creating a classifier")
	self.weight = 0.0
	self.fitness = 0.0
	self.classifier = nil
	self.valueHistory = torch.Tensor({})  --Length of this is the number of times this classifer has been active 

	--Keep an estimate of the size of the match set (sliding average)
	self.matchSetEstimate = 0 
	--Relative accurary as in XCS 
	self.relativeAccuracy = 0 
	self.accuracy = 0 --This is to be set in updateValue. 
	self.error = 0 
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
	--self:calcFitness()

	
end

function EClassifier:calcFitness()
	local fit 
	if self.valueHistory:storage():size() == 1 then 
		fit = 0
	else
--		fit = -torch.var(self.valueHistory)/(torch.mean(self.valueHistory)*(self.valueHistory:storage():size()))
		fit = -torch.var(self.valueHistory)
	end
	--print("fitness = " .. fit .. " variance = " .. torch.var(self.valueHistory) )

	self.fitness = fit 
	--fit = math.abs(self.weight)

	return fit 

end


function EClassifier:calcFitnessXCS()
	local fit 
	local BETA = 0.25 
	--MAM update as in XCS (check this is being done right)
	if self.valueHistory:storage():size() < 1/BETA then 
		fit = (self.fitness + self.relativeAccuracy)/(self.valueHistory:storage():size())
	else
		fit = self.fitness + BETA*(self.relativeAccuracy - self.fitness)
	end
--	print("acc = " .. self.relativeAccuracy )
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
	clone.matchSetEstimate = 0.0 
	clone.relativeAccuracy = 0.0
	clone.accuracy = 0.0
	clone.error = 0.0 

	return clone 
end

function EClassifier:duplicate()
	--print("IN CLONE")
	local clone = hfes.EClassifier()
	clone.weight = self.weight
	clone.classifier = self.classifier:duplicate()
	clone.fitness = self.fitness
	clone.valueHistory = self.valueHistory:clone()	
	clone.matchSetEstimate = self.matchSetEstimate
	clone.relativeAccuracy = self.relativeAccuracy 
	clone.accuracy = self.accuracy --This is to be set in updateValue. 
	clone.error = self.error 

	--print(clone.valueHistory:storage():size())
	--print("KKK")
	return clone 
end

function EClassifier:mutate(p)
	self.classifier:mutate(p)
end
