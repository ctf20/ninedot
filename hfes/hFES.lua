--- creates a class "hierarchical Feature Evolution System"
local hFES = torch.class('hfes.hFES')
local plPretty = require 'pl.pretty'

--- the initializer
function hFES:__init(problem)
	print('hFES init')
	print("setting problem")
	self.problem = problem
	print("setting classifiers")
	self.classifiers = {}
	print("self.classifiers")
	print(self.classifiers)
	-- print("#self.classifiers:" .. #self.classifiers)
	self.numClassifiers = 0
	self.rollouts = {} --Stores the set of active classifiers
	self.pop_max = 400
	self.hiddenWeightMatrix = self:createFixedMatrix()
	self.indexesToClassifierIndexes = {}
	self.classifierFitnesses = {}
	self.averageFitness = 0

	self.allBoardStatesDict = {}
	self.allBoardStatesMatrix = nil
	self.allBoardStatesToClassifiers = {}
	self.allBoardStatesAndClassifiersMatrix = nil
	self.allBoardStatesScores = {}

	self.coveringsPerRollout = {0}
	self.deletionsPerRollout = {0}
	self.deletionFitnessPerRollout = {{}}
	self.deletionAgePerRollout = {{}}
	self.deletionWeightPerRollout = {{}}
	self.deletionGeneralityPerRollout = {{}}
	self.deletionAvgBSScorePerRollout = {{}}
	self.performancePerRollout = {}
	self.numClassifiersPerRollout = {}

	self.timeCount = 0
	self.classifierOrderings = {}
	self.currentMove = 0
	self.epsilon = 0.05
end

function hFES:createFixedMatrix() 

	local length = 676
	self.hiddenWeightMatrix  = torch.Tensor(self.pop_max,length):fill(0)
	return self.hiddenWeightMatrix

end

--- a method
function hFES:print()

 print(self.contents)

end

function hFES:boardStateUnique(bs,hash)
	local hash = hash or bs.inputVectorHash
	if self.allBoardStatesDict[hash] == nil then
		return true
	else
		return false
	end
end

function hFES:addUniqueBS(bs,score,hash)
	local hash = hash or bs.inputVectorHash
	local score = score or 0
	if self:boardStateUnique(bs,hash) then
		if self.allBoardStatesMatrix == nil then
			self.allBoardStatesMatrix = bs.inputVector:reshape(bs.inputVector:size()[1],1)
			self.allBoardStatesAndClassifiersMatrix = torch.Tensor(1,self.pop_max)
		else
			self.allBoardStatesMatrix = torch.cat(self.allBoardStatesMatrix,bs.inputVector:reshape(bs.inputVector:size()[1],1))
			self.allBoardStatesAndClassifiersMatrix = torch.cat(
						self.allBoardStatesAndClassifiersMatrix:t(),torch.Tensor(1,self.pop_max
							):fill(0):t()):t()
		end
		local id = self.allBoardStatesMatrix:size()[2]
		self.allBoardStatesDict[hash] = id
		self.allBoardStatesToClassifiers[id] = {}
		-- print("score:",score)
		table.insert(self.allBoardStatesScores,score)
		return id
	else
		return nil
	end
end

function hFES:createClassifierOrderingTable()
	local ids = {}
	for i=1,self.numClassifiers do
		table.insert(ids,i)
	end
	table.sort(ids,function(a,b) return self.classifiers[a].age < self.classifiers[b].age end)
	self.classifierOrderings = ids
	return self.classifierOrderings
end

function shuffled(tab)
local n, order, res = #tab, {}, {}
 
for i=1,n do order[i] = { rnd = math.random(), idx = i } end
table.sort(order, function(a,b) return a.rnd < b.rnd end)
for i=1,n do res[i] = tab[order[i].idx] end
return res
end


function hFES:updateRollout(activeClassifiers, instantScore, foveationWindowsMoves, classifersToWindowsMoves, newlyCreatedClassifiers)

	table.insert(self.rollouts, {	reward = instantScore, activeClassifiers = activeClassifiers,
									foveationWindows=foveationWindowsMoves, classifiersToWindows=classifersToWindowsMoves,
									newlyCreatedClassifiers=newlyCreatedClassifiers
									})

end

function hFES:evolveClassifiers(_niched) --Evolve the classifiers!! :)
	local niched
	if _niched == false then
		niched = false
	else
		niched = true
	end
--Choose two classifiers from each of the moves in the rollout 
	local MAX_TOURNAMENTS = 1 
	local POP_MAX = 100
	if niched then
		for r = 1, #self.rollouts do --For each rollout, get the population 
			local pop = self.rollouts[r].activeClassifiers
			if pop ~= nil and #pop > 0 then
				for num_tournaments = 1, MAX_TOURNAMENTS do
					local median
					local winner,loser,winner_id,loser_id = self:binaryTournament(pop)
					if winner ~= nil then
						-- median = util.median(self:getClassifierFitnesses(pop))
						-- median = util.mean(self:getClassifierFitnesses(pop))
						median = self.averageFitness
						print("median based on matched:" .. median)
						--Winner will be replicated
						local child = winner:replicate(median)
						--And mutated
						-- get specific foveation windows for winner
						local fIds = self.rollouts[r].classifiersToWindows[winner_id]
						-- plPretty.dump(self.rollouts[r].classifiersToWindows)
						-- for k,v in pairs(self.rollouts[r].classifiersToWindows) do
						-- 	print(k)
						-- end
						-- print("fIds:**********************************************************************8")
						-- plPretty.dump(fIds)
						-- print("winner:",winner)
						local windows = {}
						for i,id in ipairs(fIds) do
							table.insert(windows,self.rollouts[r].foveationWindows[id])
						end
						child:mutate(windows)
						self:insertNewClassifier(child,true)
					end
				end
			end
		end
	else
		local pop = self:getFunctionalClassifiers()
		-- print("pop")
		-- plPretty.dump(pop)
		for num_tournaments = 1, MAX_TOURNAMENTS do
			local winner,loser,winner_id,loser_id = self:binaryTournament(pop)
			if winner ~= nil then
				local median = self.averageFitness
				local child = winner:replicate(median)
				local chosenRollout = self.rollouts[math.random(1,#self.rollouts)]
				child:mutate(chosenRollout.foveationWindows)
				self:insertNewClassifier(child,true)
			end
		end
	end
end

function hFES:insertNewClassifier(classifier,doMatching)
	local insertIndex = self:deleteAndGetIndex()
	print("insertIndexINC:" .. insertIndex)
	self.classifiers[insertIndex] = classifier
	self.hiddenWeightMatrix[insertIndex] = classifier.classifier.hiddenWeights
	self.classifierFitnesses[insertIndex] = classifier.fitness
	self:updateAverageFitness()
	-- print("inserted new child:" .. insertIndex)
	if doMatching then
		self:matchClassifierToHistoricBoardstates(classifier,insertIndex)
	end
	classifier.age = self.timeCount
	classifier.weight = 0.01
	classifier.valueHistory[1] = 0.01
	self:createClassifierOrderingTable()
end

function hFES:matchClassifierToHistoricBoardstates(classifier,index)
	-- print("classifier.hiddenWeights")
	local matchings = self.allBoardStatesMatrix:t()*classifier.classifier.hiddenWeights
	-- print("matchings")
	-- print(matchings)
	print("matchings:" .. #self.allBoardStatesToClassifiers)
	for id=1,matchings:size()[1] do
		if matchings[id] > 0 then
			print("matched" .. id)
			table.insert(classifier.matchedBoardStates,id)
			table.insert(self.allBoardStatesToClassifiers[id],index)
			self.allBoardStatesAndClassifiersMatrix[id][index] = 1
		end
	end
end

function hFES:binaryTournament(pop,pareto)
	local a_id = pop[math.random(1, #pop)]
	local b_id = pop[math.random(1, #pop)]
	local a = self.classifiers[a_id]
	local b = self.classifiers[b_id]
	--Only replicate if both are beyond a certain age. 
	-- if a.valueHistory:storage():size() < 5 or b.valueHistory:storage():size() < 5 then 
	-- 	return
	-- end
	local fita = a.fitness
	local fitb = b.fitness
	if pareto then
		return self:paretoBinaryTournamentComparison(a,b,a_id,b_id,fita,fitb)
	else
		return self:binaryTournamentComparison(a,b,a_id,b_id,fita,fitb)
	end
end

function hFES:binaryTournamentComparison(a,b,a_id,b_id,fita,fitb)
	local winner,loser,winner_id,loser_id
	if fita > fitb then 
		winner = a
		winner_id = a_id
		loser = b
		loser_id = b_id
	else
		loser = a
		loser_id = a_id
		winner = b
		winner_id = b_id
	end
	-- print("returning")
	-- plPretty.dump({winner,loser,winner_id,loser_id})
	return winner,loser,winner_id,loser_id
end

function hFES:paretoBinaryTournamentComparison(a,b,a_id,b_id,fita,fitb)
	local winner,loser,winner_id,loser_id
	if ( fita > fitb and a.totalHashes >= b.totalHashes) or ( fita >= fitb and a.totalHashes > b.totalHashes) then 
		winner = a
		winner_id = a_id
		loser = b
		loser_id = b_id

	elseif ( fitb > fita and b.totalHashes >= a.totalHashes) or ( fitb >= fita and b.totalHashes > a.totalHashes) then 
		loser = a
		loser_id = a_id
		winner = b
		winner_id = b_id
	else
		if math.random() < 0.5 then 
			winner = a
			winner_id = a_id
			loser = b
			loser_id = b_id
		else
			loser = a
			loser_id = a_id
			winner = b
			winner_id = b_id
		end
	end
	return winner,loser,winner_id,loser_id
end

function hFES:getClassifierFitnesses(ids)
	local fitnesses = {}
	for i,id in ipairs(ids) do
		table.insert(fitnesses,self.classifiers[id].fitness)
	end
	return fitnesses
end

function hFES:deleteClassifier()
	local deleteIndex = self:deleteLowestFitClassifier()
	--local deleteIndex = self:deleteLeastHashes()
	-- local deleteIndex = self:deleteXCS()
	local matchedState = #self.classifiers[deleteIndex].matchedBoardStates
	local scores = 0
	-- plPretty.dump(self.allBoardStatesScores)
	for _,bs in ipairs(self.classifiers[deleteIndex].matchedBoardStates) do
		scores = scores + self.allBoardStatesScores[bs]
	end
	local avgScores = scores/matchedState
	table.insert(self.deletionAvgBSScorePerRollout[#self.deletionAvgBSScorePerRollout],avgScores)
	-- print("matchedState")
	-- print(self.classifiers[deleteIndex].matchedBoardStates[matchedState])
	while matchedState ~= nil and  matchedState > 0 do
		local index
		local removeFromBS = self.classifiers[deleteIndex].matchedBoardStates[matchedState]
		-- print("deleteIndex:" .. deleteIndex)
		-- print("matchedState")
		-- print(removeFromBS)
		-- print("classifiers")
		-- plPretty.dump(self.allBoardStatesToClassifiers[removeFromBS])
		for i=1,#self.allBoardStatesToClassifiers[removeFromBS] do
			local class = self.allBoardStatesToClassifiers[removeFromBS][i]
			if class == deleteIndex then
				index = i
				break
			end
		end
		table.remove(self.allBoardStatesToClassifiers[removeFromBS],index)
		table.remove(self.classifiers[deleteIndex].matchedBoardStates)
		self.allBoardStatesAndClassifiersMatrix[removeFromBS][deleteIndex] = 0
		matchedState = #self.classifiers[deleteIndex].matchedBoardStates
	end
	print("deleting:" .. deleteIndex)
	print("weight:" .. self.classifiers[deleteIndex].weight .." fitness:" .. self.classifiers[deleteIndex].fitness)
	self.deletionsPerRollout[#self.deletionsPerRollout] = self.deletionsPerRollout[#self.deletionsPerRollout] + 1
	table.insert(self.deletionFitnessPerRollout[#self.deletionFitnessPerRollout],self.classifiers[deleteIndex].fitness)
	table.insert(self.deletionWeightPerRollout[#self.deletionWeightPerRollout],self.classifiers[deleteIndex].weight)
	table.insert(self.deletionAgePerRollout[#self.deletionAgePerRollout],self.timeCount-self.classifiers[deleteIndex].age)
	self.classifiers[deleteIndex] = nil
	self.classifierFitnesses[deleteIndex] = nil
--	local deleteIndex = self:deleteXCS(self.pop_max)
	self.numClassifiers = self.numClassifiers - 1
	-- self:createClassifierOrderingTable()
	return deleteIndex
end

function hFES:deleteXCS()
	local worstClassifierFitness = -10000000
	local worstClassifier = -1 
	for k,v in pairs(self.classifiers) do 
		if self.classifiers[k].matchSetEstimate > worstClassifierFitness then 
			worstClassifierFitness = self.classifiers[k].matchSetEstimate
			worstClassifier = k 
		end
	end
	-- print("deleting classifier with match set estimate : " .. worstClassifierFitness)

	--Delete it here
	--print("fitness of deleted classifer = " .. self.classifiers[worstClassifier].fitness)
	-- self.classifiers[worstClassifier] = nil 
	-- self.numClassifiers = self.numClassifiers - 1
	return worstClassifier
end


function hFES:deleteLeastHashes(pop_max) 
	
		local worstClassifierFitness = 10000000
		local worstClassifier = -1 
		for k,v in pairs(self.classifiers) do 
			if self.classifiers[k].totalHashes < worstClassifierFitness then 
				worstClassifierFitness = self.classifiers[k].totalHashes
				worstClassifier = k 
			end
		end
--		print("deleting classifier with least hashes : " .. worstClassifierFitness)

		--Delete it here
		--print("fitness of deleted classifer = " .. self.classifiers[worstClassifier].fitness)
		-- self.classifiers[worstClassifier] = nil 
--		self.numClassifiers = self.numClassifiers - 1
		return worstClassifier
end

function hFES:deleteLowestFitClassifier() 
	--print("HERe2")
	--print(self.classifiers)
		local worstClassifierFitness = 10000000
		local worstClassifier = -1 
		for k,v in pairs(self.classifiers) do 
			if self.classifiers[k].fitness < worstClassifierFitness then 
				worstClassifierFitness = self.classifiers[k].fitness
				worstClassifier = k 
			end
		end

		--Delete it here
		--print("fitness of deleted classifer = " .. self.classifiers[worstClassifier].fitness)
		-- self.classifiers[worstClassifier] = nil 
		--self.numClassifiers = self.numClassifiers - 1
		return worstClassifier
end

function hFES:deleteLowestWeightMagClassifier(pop_max) 
	--print("HERe2")
	--print(self.classifiers)
	if self.numClassifiers > pop_max then 
		local worstClassifierFitness = 10000000000	
		local worstClassifier = -1 
		for k,v in pairs(self.classifiers) do 
			w = math.pow(self.classifiers[k].weight,2)
			if w < worstClassifierFitness then 
				worstClassifierFitness = w
				worstClassifier = k 
			end
		end

		--Delete it here
		--print("fitness of deleted classifer = " .. self.classifiers[worstClassifier].fitness)
		-- self.classifiers[worstClassifier] = nil 
		-- self.numClassifiers = self.numClassifiers - 1
	
	end

end


--- Match and Move method FOR TD_learning 
function hFES:makeMoveTD(_niched)
	-- local niched = _niched or true
	local niched
	if _niched == false then
		niched = false
	else
		niched = true
	end
	local bla, preScore = self.problem:getScoreCurrentPosition()
	
	local move_id = shuffled(self.problem:getMoves())


	local  allScores = torch.Tensor(self.problem:getScores(move_id))
	-- allScores = allScores - preScore
	-- allScores = allScores

	local values, activeClassifiers, foveationWindowsMoves, classifersToWindowsMoves, newlyCreatedClassifiers = self:getValues(move_id, allScores, niched)
	-- local chosenMove = self:eGreedyChoice(move_id,values)
	-- self.problem:updateBoard(chosenMove)	
	--local score = self.problem:getScores(move_id) --I'm going to be using the getScores and moving according to get scores for now. 
	local chosenMove = self:eGreedyChoice(move_id, values)
	self.problem:updateBoard(move_id[chosenMove])

	local bla2, postScore = self.problem:getScoreCurrentPosition()
	self:updateRollout(activeClassifiers[chosenMove], postScore, foveationWindowsMoves[chosenMove], classifersToWindowsMoves[chosenMove], newlyCreatedClassifiers)
	-- plPretty.dump(self.classifierFitnesses)

end

function hFES:updateValues()
	local DISCOUNT = 0
	local ERROR_THRESHOLD = 0.01
	local values = {}
	-- remove new classifiers from previous rollouts
	self:cleanRollouts()
	for i = 1, #self.rollouts do 
		local v = 0 
		--print(#self.rollouts[i].activeClassifiers)
		for j = 1, #self.rollouts[i].activeClassifiers do 
			v = v + self.classifiers[self.rollouts[i].activeClassifiers[j]].weight
		end
		table.insert(values, v)
	end
	local alpha = 0.001
	local val = 0 
	for i = 1, #self.rollouts do 
		local totalAccuracy = 0 
		print("num active classifiers = " ..  #self.rollouts[i].activeClassifiers)
		for j = 1, #self.rollouts[i].activeClassifiers do 

			if i == #self.rollouts then 
				val = 0
			else
				val = values[i+1]
			end

			--self.classifiers[self.rollouts[i].activeClassifiers[j]].weight = 
			--	self.classifiers[self.rollouts[i].activeClassifiers[j]].weight + 
			--	alpha * (self.rollouts[i].reward + 0.0*val - values[i])
			-- print(self.rollouts[i].activeClassifiers[j])
			-- print("WEIGHT= " .. self.classifiers[self.rollouts[i].activeClassifiers[j]].weight)
			-- print("adding=" .. alpha * (self.rollouts[i].reward + DISCOUNT*val - values[i]))
			--local oldw = self.classifiers[self.rollouts[i].activeClassifiers[j]].weight 
			self.classifiers[self.rollouts[i].activeClassifiers[j]]:setValue(self.classifiers[self.rollouts[i].activeClassifiers[j]].weight + alpha * (self.rollouts[i].reward + DISCOUNT*val - values[i]))
			--local neww = self.classifiers[self.rollouts[i].activeClassifiers[j]].weight 
			--print("weights changes in rollout = " ..neww-oldw.. " " ..  self.rollouts[i].reward .. " " ..  values[i].. " " .. self.classifiers[self.rollouts[i].activeClassifiers[j]].weight + alpha * (self.rollouts[i].reward + DISCOUNT*val - values[i]))
			

			--XCS TYPE FITNESS CALCULATION HERE... NEED TO CHECK 
			--Update accuracies and relative accuracies.***************
			self.classifiers[self.rollouts[i].activeClassifiers[j]].error = math.sqrt(math.pow(self.rollouts[i].reward + DISCOUNT*val - values[i], 2))
			if self.classifiers[self.rollouts[i].activeClassifiers[j]].error > ERROR_THRESHOLD then 
				self.classifiers[self.rollouts[i].activeClassifiers[j]].accuracy = math.exp(math.log(0.1)*( (self.classifiers[self.rollouts[i].activeClassifiers[j]].error-ERROR_THRESHOLD)/ERROR_THRESHOLD))
				totalAccuracy = totalAccuracy + self.classifiers[self.rollouts[i].activeClassifiers[j]].accuracy 
				--print("ERROR > THRESHOLD **********accuracy = " .. self.classifiers[self.rollouts[i].activeClassifiers[j]].accuracy)
			else
				self.classifiers[self.rollouts[i].activeClassifiers[j]].accuracy = 1 
				totalAccuracy = totalAccuracy + self.classifiers[self.rollouts[i].activeClassifiers[j]].accuracy 
				--print("ERROR < THRESHOLD accuracy = " .. self.classifiers[self.rollouts[i].activeClassifiers[j]].accuracy)
			end
			--Update accuracies and relative accuracies.***************

		end
		--XCS TYPE FITNESS CALCULATION HERE... NEED TO CHECK 
		--START: Calc fitness here after the relative accuracy of the activeClassifiers is known. 
		for j = 1, #self.rollouts[i].activeClassifiers do 
			--print("accuracy = " .. self.classifiers[self.rollouts[i].activeClassifiers[j]].accuracy)
			if totalAccuracy > 0 then 
				self.classifiers[self.rollouts[i].activeClassifiers[j]].relativeAccuracy = self.classifiers[self.rollouts[i].activeClassifiers[j]].accuracy/totalAccuracy
			else
				self.classifiers[self.rollouts[i].activeClassifiers[j]].relativeAccuracy = 0
			end
			-- print("RELATIVE ACCURACY = " .. self.classifiers[self.rollouts[i].activeClassifiers[j]].relativeAccuracy)
			-- print(" total accuracy   = " .. totalAccuracy)
			-- print(" accuracy  = " .. self.classifiers[self.rollouts[i].activeClassifiers[j]].accuracy)
			local classId = self.rollouts[i].activeClassifiers[j]
			print(classId .. "fit before:")
			print(self.classifiers[classId].fitness)
			self.classifiers[classId]:calcFitness()
			print(classId .. "fit after:")
			print(self.classifiers[classId].fitness)

			self.classifierFitnesses[classId] = self.classifiers[classId].fitness
		end
		--END: Calc fitness here after the relative accuracy of the activeClassifiers is known. 

	end
	self:updateAverageFitness()


end

function hFES:cleanRollouts()
	-- make sure a deleted rollout is not in the matched set
	for i=#self.rollouts,1,-1 do
		local newlyCreatedClassifiers = self.rollouts[i].newlyCreatedClassifiers
		for j=i-1,1,-1 do
			local previousClassifiers = self.rollouts[j].activeClassifiers
			-- if previousClassifiers ~= nil then
				for l=#previousClassifiers,1,-1 do
					for _,replacement in ipairs(newlyCreatedClassifiers) do
						if previousClassifiers[l] == replacement then
							print("[CR] removing:" .. previousClassifiers[l])
							table.remove(previousClassifiers,l)
							break
						end
					end
				end
			-- end
		end
	end
end

function hFES:clearRollouts()

	self.rollouts = {}

end

function hFES:getValues(moves, allScores, _niched)
	local niched
	if _niched == false then
		niched = false
	else
		niched = true
	end
	--local rewards = self.problem:getScores(moves) --This calculates the cumulative reward obtained so far including the move. 
	local activeClassifiers = {}
	local values = {}
	local foveationWindowsMoves = {}
	local classifersToWindowsMoves = {}
	local matchedSoFar = {}
	local newlyCreatedClassifiers = {}
	for i,move in ipairs(moves) do
		-- print("adding: ***********************************")
		-- print(self.problem.bs.pp)
		-- print(move)
		self.problem:makePotentialMove(move)
		-- print(self.problem.bs.pp)
		local matchedClassifiers , foveationWindows , classifiersToWindows = self:getActiveClassifiersForMove(move, false, allScores[i], newlyCreatedClassifiers,niched)
		table.insert(activeClassifiers,matchedClassifiers)
		table.insert(values, self:getValuesFromActiveClassifiers(matchedClassifiers))
		table.insert(foveationWindowsMoves,foveationWindows)
		table.insert(classifersToWindowsMoves,classifiersToWindows)
		self.problem:undoLastMove()
	end

	-- for i = 1, #values do 
	-- 	print(values[i])
	-- end

	return values, activeClassifiers, foveationWindowsMoves, classifersToWindowsMoves, newlyCreatedClassifiers
end

function hFES:getValuesFromActiveClassifiers(matchedClassifiers)

	local val = 0 
	for i = 1, #matchedClassifiers do
		-- print("gv")
		-- print("i:" .. i)
		-- print(self.classifiers)
		-- print("class ids")
		-- print("matchedClassifiers:" .. #matchedClassifiers)
		-- for k,v in pairs(self.classifiers) do
		-- 	print(k)
		-- end
		--print("matched classifiers = " .. matchedClassifiers[i])
		--print(self.classifiers[matchedClassifiers[i]])
		val = val + self.classifiers[matchedClassifiers[i]].weight
	end
	--print("Value for this move = " .. val)
	return val 
end 


function hFES:getCurrentActiveClassifiers(moves, visualize, score)
	local activeClassifiers = self:getActiveClassifiersForMove(nil, visualize, score)
	return activeClassifiers
end

function hFES:getActiveClassifiersForMove(move, visualize, score, newlyCreatedClassifiers, _niched)
	local niched
	if _niched == false then
		niched = false
	else
		niched = true
	end
	local foveationSet = self.problem:getFoveationSet()
	local matchedSet = {}
	local foveationWindows = {}
	local classifiersToWindows = {}
	-- update the newlyCreatedClassifiersSet
	for i,foveationPosition in ipairs(foveationSet) do
		for j,foveationWindow in ipairs(foveationPosition.foveationWindows) do
			local newClassifierId
			table.insert(foveationWindows,foveationWindow)
			foveationWindow.matchings = self:matchClassifiersFast(foveationWindow) 

			--Update the matchSetEstimates of classifiers (estimates the size of the matching set over all foveation positions for this classiifer )
			for i,m in ipairs(foveationWindow.matchings) do
					self.classifiers[m].matchSetEstimate = 0.9*self.classifiers[m].matchSetEstimate  + 0.1*#foveationWindow.matchings
			end

			if #foveationWindow.matchings == 0 and visualize == false then
				newClassifierId = self:createClassifier(
														#foveationSet,
														foveationWindow,
														1.0,
														score,
														niched)
				-- print("newClassifierId")
				-- print(newClassifierId)
				-- update the newlyCreatedClassifiers set
				util.addToSet(newClassifierId,newlyCreatedClassifiers)
			end
			self:addClassifiersToSet(foveationWindow.matchings,matchedSet)
			for i,m in ipairs(foveationWindow.matchings) do
				if classifiersToWindows[m] then
					table.insert(classifiersToWindows[m],#foveationWindows)
				else
					classifiersToWindows[m]={#foveationWindows}
				end
			end
			-- add unique boardstate and attatch to classifiers
			local uniqueBS = self:addUniqueBS(foveationWindow,score)
			if (#self.allBoardStatesToClassifiers ~= #self.allBoardStatesScores) then
				os.exit()
			end
			-- print("uniqueBS:" .. tostring(uniqueBS))
			if uniqueBS ~= nil and newClassifierId == nil then
				for _,classifierId in ipairs(foveationWindow.matchings) do
					table.insert(self.classifiers[classifierId].matchedBoardStates,uniqueBS)
					table.insert(self.allBoardStatesToClassifiers[uniqueBS],classifierId)
					self.allBoardStatesAndClassifiersMatrix[uniqueBS][classifierId] = 1
				end
			elseif newClassifierId ~= nil then
				self:matchClassifierToHistoricBoardstates(self.classifiers[newClassifierId],newClassifierId)
			end
		end
	end


	if visualize == false then
		-- print("matched set")
		-- local mCount = 0
		-- for k,v in pairs(matchedSet) do
		-- 	print(k)
		-- 	mCount = mCount + 1
		-- end
		if mCount == 0 then
			print("matchedSet = 0")
			os.exit()
		end
	end

	-- for k,v in ipairs(self.classifiers) do
	-- 	print("c:" .. k)
	-- 	if #self.classifiers[k].matchedBoardStates == 0 then
	-- 		os.exit()
	-- 	end
	-- end

	local activeClassifiers = util.getKeywords(matchedSet)



	--local allinclassifiers = true

	-- for k,v in ipairs(activeClassifiers) do 
	-- 	local found = false
	-- 	for j, cl in pairs(self.classifiers) do 
	-- 		if v == j then 
	-- 			found = true
	-- 			break
	-- 		end 
	-- 	end
	-- 	if found == false then 
	-- 		allinclassifiers = false
	-- 		print("not found " .. v )
	-- 		break
	-- 	end
	-- end
	-- if allinclassifiers == false then 
	-- 	print("exiting ")
	-- 	os.exit()

	-- end


	-- print("activeClassifiers:")
	-- print(activeClassifiers)
	return activeClassifiers,foveationWindows,classifiersToWindows
end

function hFES:addClassifiersToSet(indexes,set)
	for i,index in ipairs(indexes) do
		util.addToSet(index,set)
	end
end

function hFES:deleteAndGetIndex()
	local insertIndex
	local start = self.numClassifiers
	if self.numClassifiers == self.pop_max then
		-- print("deleting class")
		insertIndex = self:deleteClassifier()
		self.numClassifiers = self.numClassifiers + 1
	else
		self.numClassifiers = self.numClassifiers + 1
		insertIndex = self.numClassifiers
		-- print("not deleting, index:" )
		-- print(insertIndex)
	end
	if start == 50 and self.numClassifiers < 50 then
		os.exit()
	end
	return insertIndex
end

function hFES:createClassifier(numPositions, foveationWindow,specificity,score,_niched)
	local niched
	if _niched == false then
		niched = false
	else
		niched = true
	end
	local score = score or 0.0
	local specificity = specificity or 0.1
	print("Creating covering classifier*****/*****************************")
	local insertIndex = self:deleteAndGetIndex()
	print("insertIndexcc:" .. insertIndex)
	-- print("creating classifier")
	local classifier = hfes.NineDotClassifier()
	classifier:buildClassifier(	foveationWindow.dots,
								foveationWindow.lines,
								foveationWindow.lastPP,
								foveationWindow,
								specificity
								)
	-- TO DO PUT IN ECLASSIFIER> 
	print("testing match")
	print(classifier.hiddenWeights*foveationWindow.inputVector)
	if (classifier.hiddenWeights*foveationWindow.inputVector) < 0.0 then
		print("match failed")
		local l = torch.Tensor(676,3)
		l[{{},{1}}] = classifier.hiddenWeights
		l[{{},{2}}] = foveationWindow.inputVector
		l[{{},{3}}] = foveationWindow.inputVector - classifier.hiddenWeights
		plPretty.dump(l)
		os.exit()
	end
	local newClassifier = hfes.EClassifier()
	newClassifier.age = self.timeCount
	newClassifier.classifier=classifier
	newClassifier:setTotalHashes()
	-- newClassifier:setValue(score/numPositions)
	newClassifier:setValue(score/10)
	if niched then
--		newClassifier.fitness = 1.0
		newClassifier.fitness = self.averageFitness
	else
		--WHY???? are you setting fitness to 0.01 
		-- newClassifier.fitness = (score/numPositions) -- self.averageFitness
		newClassifier.fitness = self.averageFitness
--		newClassifier.fitness = 0.01
	end
	newClassifier.matchSetEstimate = 1
	--newClassifier:setValue(0)
	--self.numClassifiers = self.numClassifiers + 1
	self.classifiers[insertIndex] = newClassifier
	foveationWindow.matchings={insertIndex}
	self.hiddenWeightMatrix[insertIndex] = classifier.hiddenWeights
	self.classifierFitnesses[insertIndex] = newClassifier.fitness
	self:updateAverageFitness()
	print("avaerageFitness:" .. self.averageFitness)
	self:createClassifierOrderingTable()
	-- print("inserted " .. insertIndex .." fitness " .. self.classifierFitnesses[insertIndex])
	self.coveringsPerRollout[#self.coveringsPerRollout] = self.coveringsPerRollout[#self.coveringsPerRollout] + 1
	return insertIndex
end

-- function hFES:matchClassifiers(foveationWindow)
-- 	-- print("in match classifiers")
-- 	-- print(self)
-- 	-- print("self.classifiers:")
-- 	-- print(self.classifiers)
-- 	local matchingSet = {}
-- 	for k,classifier in pairs(self.classifiers) do
-- 		-- print("matching class:" .. i)
-- 		-- local matched = classifier.classifier:match(
-- 		-- 							foveationWindow.dots,
-- 		-- 	 						foveationWindow.linesMatrix,
-- 		-- 	 						foveationWindow.pointMatrix)
-- 		local matched = classifier.classifier:match(foveationWindow.binaryVector)

-- 		-- print("fwbinary")
-- 		-- plPretty.dump(foveationWindow.binaryVector)
-- 		-- print("classifier")
-- 		-- plPretty.dump(classifier.classifier.binaryClassifier)
-- 		if matched then
-- 			table.insert(matchingSet,k)
-- 		end
-- 	end
	
-- 	return matchingSet
-- end

function hFES:matchClassifiersFast(foveationWindow)
	local matchingSet = {}
	if self.numClassifiers ~= 0 then
		--Vector matrix multiplication. 
		local inputVector = foveationWindow.inputVector
		-- print("inputVector")
		-- plPretty.dump(inputVector)
		-- print("weights")
		-- plPretty.dump(self.hiddenWeightMatrix)
		local activityVector = self.hiddenWeightMatrix*inputVector 
		activityVector = torch.gt(activityVector, 0) 
		-- plPretty.dump(activityVector)
		for i=1, activityVector:storage():size() do
			if activityVector[i] == 1 then
				table.insert(matchingSet,i)
			end
		end
	end
	-- print("matching set")
	-- plPretty.dump(matchingSet)
	return matchingSet
end

function hFES:printBoardState()
	--Call the problem specific board state printer 
	self.problem:printBoardState()

end

function hFES:resetBoardState()
	--Call the problem specific board state printer 
	self.problem:resetBoardState()

end

function hFES:getImage()
	--Call the problem specific board state printer 
	--return {self.problem:getImage(), self.classifiers}
	self:getCurrentActiveClassifiers(nil, true) --Rematch classifiers to current board position. 
	--print("SENDING CLASSIFIERS " .. #self.classifiers)
	return { self.problem:getImage(),self.classifiers }
end	


function hFES:eGreedyChoice(move_ids, score, epsilon)
	
	-- local epsilon = epsilon or 0.05
	local epsilon = self.epsilon
	--print("In eGreedyChoice")
	local maxScore = -1000
	local maxChoice = -1
	
	if math.random() > epsilon then 
		for i = 1, #move_ids do 
			if score[i] > maxScore then 
				maxScore = score[i]
				maxChoice = i
			end

		end
	else
		maxChoice = math.random(1,#move_ids)
	end

	--print(maxChoice)
	return maxChoice

end

function hFES:getFunctionalClassifiers()
	local pop = {}
	for k,v in pairs(self.classifiers) do
		table.insert(pop,k)
	end
	return pop
end

function hFES:updateAverageFitness(median)
	local median = median or false
	-- if self.numClassifiers >= self.pop_max then
	-- 	if median then
	-- 		self.averageFitness = util.median(self.classifierFitnesses)
	-- 	else
	-- 		self.averageFitness = util.mean(self.classifierFitnesses)
	-- 	end
	-- else
	-- 	local tempArray = {}
	-- 	for k,v in pairs(self.classifierFitnesses) do
	-- 		table.insert(tempArray,v)
	-- 	end
	-- 	if median then
	-- 		self.averageFitness = util.median(tempArray)
	-- 	else
	-- 		self.averageFitness = util.mean(self.classifierFitnesses)
	-- 	end
	-- end
	local average = 0 
	local count = 0
	for k,v in pairs(self.classifiers) do
		-- if self.timeCount - v.age > 5 then
		average = average + v.weight
		count = count + 1
	end
	if count > 0 then
		self.averageFitness = average/count
	else
		self.average = 0
	end
end


function hFES:bip()
 print('bip')
end