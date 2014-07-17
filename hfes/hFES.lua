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
	self.classifierIdHash = 0
	self.rollouts = {} --Stores the set of active classifiers
	self.pop_max = 5000
	self.hiddenWeightMatrix = self:createFixedMatrix()
	self.indexesToClassifierIndexes = {}

end

function hFES:createFixedMatrix() 

	local length = 676
	self.hiddenWeightMatrix  = torch.Tensor(self.pop_max,length):fill(0)
	return self.hiddenWeightMatrix

end


function hFES:createHiddenWeightMatrix() 
	--Constructs a hidden weight matrix from the existing classifers in self.classifiers 
	local length = 675 + 1 
	local count = 1
	self.hiddenWeightMatrix  = torch.Tensor(self.numClassifiers,length)
	for k,v in pairs(self.classifiers) do
		self.indexesToClassifierIndexes[count] = k
		--print("LENGTH = " .. v.classifier.hiddenWeights:storage():size())
		for i = 1, length do 
			self.hiddenWeightMatrix[count][i] = v.classifier.hiddenWeights[i]
		end
		count = count + 1
	end

end

--- a method
function hFES:print()

 print(self.contents)

end


function shuffled(tab)
local n, order, res = #tab, {}, {}
 
for i=1,n do order[i] = { rnd = math.random(), idx = i } end
table.sort(order, function(a,b) return a.rnd < b.rnd end)
for i=1,n do res[i] = tab[order[i].idx] end
return res
end


-- --- Match and Move method 
-- function hFES:makeMove()
	
	
-- 	local move_id = shuffled(self.problem:getMoves())
-- 	local values = self:getValues(move_id)
-- 	-- local chosenMove = self:eGreedyChoice(move_id,values)
-- 	-- self.problem:updateBoard(chosenMove)
	
-- 	local score = self.problem:getScores(move_id) --I'm going to be using the getScores and moving according to get scores for now. 
-- 	local chosenMove = self:eGreedyChoice(move_id, score)
-- 	self.problem:updateBoard(chosenMove)

-- end


function hFES:updateRollout(activeClassifiers, instantScore, foveationWindowsMoves, classifersToWindowsMoves)

	table.insert(self.rollouts, {	reward = instantScore, activeClassifiers = activeClassifiers,
									foveationWindows=foveationWindowsMoves, classifiersToWindows=classifersToWindowsMoves})

end

function hFES:evolveClassifiers() --Evolve the classifiers!! :) 

--Choose two classifiers from each of the moves in the rollout 
	local MAX_TOURNAMENTS = 1 
	local POP_MAX = 100
	for r = 1, #self.rollouts do --For each rollout, get the population 
		local pop = self.rollouts[r].activeClassifiers 

		for num_tournaments = 1, MAX_TOURNAMENTS do
			--Choose two classifiers at random
			local a_id = pop[math.random(1, #pop)]
			local b_id = pop[math.random(1, #pop)]
			local a = self.classifiers[a_id]
			local b = self.classifiers[b_id]

			--Only replicate if both are beyond a certain age. 
			if a.valueHistory:storage():size() < 5 or b.valueHistory:storage():size() < 5 then 
				--print("value history = " .. a.valueHistory:storage():size())
				--print("value history = " .. b.valueHistory:storage():size())
				--print("NOT REPLICATING ************************************")
				return 
			else
			-- 	print("REPLICATING**************^^^^^^^^^^^^^^^^^^^^&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&")
			-- 	print("value history = " .. a.valueHistory:storage():size())
			-- 	print("value history = " .. b.valueHistory:storage():size())
			end

			-- while( a == b) do 
			-- 	local b = math.random(1,#pop)
			-- end
			local fita = a.fitness
			local fitb = b.fitness
			
			local winner 
			local loser 

			-- if fita > fitb then 
			-- 	winner = a
			-- 	winner_id = a_id
			-- 	loser = b
			-- 	loser_id = b_id
			-- else
			-- 	loser = a
			-- 	loser_id = a_id
			-- 	winner = b
			-- 	winner_id = b_id
			-- end
			--print("fit a = " .. fita .. "fitb = " .. fitb .. " total hash a = ".. a.totalHashes .. " tot hash b = " .. b.totalHashes)
			
			--TOURNAMENT SELECTION IS NOW A MULTI-OBJECTIVE FUNCTION OF FITNESS AND GENERALITY 
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

			--Winner will be replicated 
			local child = winner:replicate()
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
			-- print("parent:")
			-- plPretty.dump(winner.classifier.grid.grid)
			-- plPretty.dump(winner.classifier.lastPP.pointMatrix)
			-- print("child:")
			-- plPretty.dump(child.classifier.grid.grid)
			-- plPretty.dump(child.classifier.lastPP.pointMatrix)
			-- print("window")
			-- plPretty.dump(windows[1].dots)
			-- --And must now be injected into the self.classifiers data structure. 
			--table.insert(self.classifiers,child)
			--If self.classifers > LIMIT then remove the worst classifier. 
			--  if self.numClassifiers > POP_MAX then 
			-- 	--print("HERe1")
			-- 	-- print(self.classifiers)
			-- 	-- holeNumber = self:deleteWorstClassifier(POP_MAX)
			-- 	self.classifiers[holeNumber] = child
			-- else
			local insertIndex = self:deleteAndGetIndex()
			self.classifierIdHash = insertIndex
			self.classifiers[insertIndex] = child
			self.hiddenWeightMatrix[insertIndex] = child.classifier.hiddenWeights
			--print("CREATING CHILD ")
			-- end

		end


	end

end

function hFES:deleteClassifier()
	local deleteIndex = self:deleteLowestFitClassifier(self.pop_max)
--	local deleteIndex = self:deleteXCS(self.pop_max)
	self.numClassifiers = self.numClassifiers - 1
	return deleteIndex
end

function hFES:deleteClassifiers(pop_max)
	if self.numClassifiers > pop_max then 

		--self:deleteLowestFitClassifier(pop_max)
		self:deleteXCS(pop_max)
		--self:deleteLeastHashes(pop_max)
		--self:deleteLowestWeightMagClassifier(pop_max)
	end

end



-- function hFES:deleteXCS(pop_max) 
	
-- 	--ALWAYS DELETE A CLASSIFIER FROM THE LATEST MATCH SET, THIS SHOULD BE MATCH SET PROPORTIONATE REALLY 

-- 	if self.numClassifiers > pop_max then 
-- 		local worstClassifierFitness = -10000000
-- 		local worstClassifier = -1 
-- 		for k,v in pairs(self.classifiers) do 
-- 			if self.classifiers[k].matchSetEstimate > worstClassifierFitness then 
-- 				worstClassifierFitness = self.classifiers[k].matchSetEstimate
-- 				worstClassifier = k 
-- 			end
-- 		end
-- 		print("deleting classifier with match set estimate : " .. worstClassifierFitness)

-- 		--Delete it here
-- 		--print("fitness of deleted classifer = " .. self.classifiers[worstClassifier].fitness)
-- 		self.classifiers[worstClassifier] = nil 
-- 		self.numClassifiers = self.numClassifiers - 1
-- 	end
-- end

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
	self.classifiers[worstClassifier] = nil 
	-- self.numClassifiers = self.numClassifiers - 1
	return worstClassifier
end


function hFES:deleteLeastHashes(pop_max) 
	
	if self.numClassifiers > pop_max then 
		local worstClassifierFitness = 10000000
		local worstClassifier = -1 
		for k,v in pairs(self.classifiers) do 
			if self.classifiers[k].totalHashes < worstClassifierFitness then 
				worstClassifierFitness = self.classifiers[k].totalHashes
				worstClassifier = k 
			end
		end
		print("deleting classifier with least hashes : " .. worstClassifierFitness)

		--Delete it here
		--print("fitness of deleted classifer = " .. self.classifiers[worstClassifier].fitness)
		self.classifiers[worstClassifier] = nil 
		self.numClassifiers = self.numClassifiers - 1
	
	end

end



function hFES:deleteLowestFitClassifier(pop_max) 
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
		self.classifiers[worstClassifier] = nil 
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
		self.classifiers[worstClassifier] = nil 
		self.numClassifiers = self.numClassifiers - 1
	
	end

end


--- Match and Move method FOR TD_learning 
function hFES:makeMoveTD()
	
	local bla, preScore = self.problem:getScoreCurrentPosition()
	
	local move_id = shuffled(self.problem:getMoves())


	local  allScores = torch.Tensor(self.problem:getScores(move_id))
	allScores = allScores - preScore

	local values, activeClassifiers, foveationWindowsMoves, classifersToWindowsMoves = self:getValues(move_id, allScores)
	-- local chosenMove = self:eGreedyChoice(move_id,values)
	-- self.problem:updateBoard(chosenMove)	
	--local score = self.problem:getScores(move_id) --I'm going to be using the getScores and moving according to get scores for now. 
	local chosenMove = self:eGreedyChoice(move_id, values)
	self.problem:updateBoard(move_id[chosenMove])

	local bla2, postScore = self.problem:getScoreCurrentPosition()
	print("instant reward = " .. preScore .. " " .. postScore)
	self:updateRollout(activeClassifiers[chosenMove], postScore-preScore, foveationWindowsMoves[chosenMove], classifersToWindowsMoves[chosenMove])

end

function hFES:updateValues()

	local DISCOUNT = 0.0 
	local ERROR_THRESHOLD = 0.01
	local values = {}
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
		for j = 1, #self.rollouts[i].activeClassifiers do 

			if i == #self.rollouts then 
				val = 0
			else
				val = values[i+1]
			end

			--self.classifiers[self.rollouts[i].activeClassifiers[j]].weight = 
			--	self.classifiers[self.rollouts[i].activeClassifiers[j]].weight + 
			--	alpha * (self.rollouts[i].reward + 0.0*val - values[i])
			--print(self.rollouts[i].activeClassifiers[j])
			--print("WEIGHT= " .. self.classifiers[self.rollouts[i].activeClassifiers[j]].weight)
			self.classifiers[self.rollouts[i].activeClassifiers[j]]:setValue(self.classifiers[self.rollouts[i].activeClassifiers[j]].weight + alpha * (self.rollouts[i].reward + DISCOUNT*val - values[i]))
			--print("value in rollout = " .. self.classifiers[self.rollouts[i].activeClassifiers[j]].valueHistory:storage():size())
			

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
			
			self.classifiers[self.rollouts[i].activeClassifiers[j]]:calcFitnessXCS()
		end
		--END: Calc fitness here after the relative accuracy of the activeClassifiers is known. 

	end


end

function hFES:clearRollouts()

	self.rollouts = {}

end

-- 	local values = {}
-- 	for mov = 1, #moves do 

-- 		local matchSet = {}
-- 		local foveationSet = self.problem:getFoveationSet()		
-- 		for i = 1, #foveationSet do 
-- 			local M = self.getMatchSet()
-- 			table.insert(matchSet, M)  
-- 		end
-- 		-- Calculate value from MatchSet 

-- 	end

-- 	return values

-- end

function hFES:getValues(moves, allScores)

	--local rewards = self.problem:getScores(moves) --This calculates the cumulative reward obtained so far including the move. 
	local activeClassifiers = {}
	local values = {}
	local foveationWindowsMoves = {}
	local classifersToWindowsMoves = {}
	for i,move in ipairs(moves) do
		-- print("adding: ***********************************")
		-- print(self.problem.bs.pp)
		-- print(move)
		self.problem:makePotentialMove(move)
		-- print(self.problem.bs.pp)
		local matchedClassifiers , foveationWindows , classifiersToWindows = self:getActiveClassifiersForMove(move, false, allScores[i])
		table.insert(activeClassifiers,matchedClassifiers)
		table.insert(values, self:getValuesFromActiveClassifiers(matchedClassifiers))
		table.insert(foveationWindowsMoves,foveationWindows)
		table.insert(classifersToWindowsMoves,classifiersToWindows)
		self.problem:undoLastMove()
	end

	-- for i = 1, #values do 
	-- 	print(values[i])
	-- end

	return values, activeClassifiers, foveationWindowsMoves, classifersToWindowsMoves
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

function hFES:getActiveClassifiersForMove(move, visualize, score)
	-- print("moves:")
	-- print(moves)
	local foveationSet = self.problem:getFoveationSet()
	-- print("len f_set:" .. #foveationSet)
	local matchedSet = {}
	local foveationWindows = {}
	local classifiersToWindows = {}
	for i,foveationPosition in ipairs(foveationSet) do
		-- print("i:" .. i)
		-- print("len f:" .. #foveationPosition.foveationWindows)
		for j,foveationWindow in ipairs(foveationPosition.foveationWindows) do
			table.insert(foveationWindows,foveationWindow)
			-- foveationWindow.matchings = self:matchClassifiers(foveationWindow) 
			-- self:createHiddenWeightMatrix()
			foveationWindow.matchings = self:matchClassifiersFast(foveationWindow) 


			--Update the matchSetEstimates of classifiers (estimates the size of the matching set over all foveation positions for this classiifer )
			for i,m in ipairs(foveationWindow.matchings) do
					self.classifiers[m].matchSetEstimate = 0.9*self.classifiers[m].matchSetEstimate  + 0.1*#foveationWindow.matchings
					--print("MATCH ESTIMATE = " .. self.classifiers[m].matchSetEstimate)
			end

			-- print("#matchings start:" .. #foveationWindow.matchings)
			if #foveationWindow.matchings == 0 and visualize == false then
				-- self:deleteExcessClassifiers()
				self:createClassifier(#foveationSet, foveationWindow,1.0, score)
				print("Creating classifier. Score = " .. score)
			end
			self:addClassifiersToSet(foveationWindow.matchings,matchedSet)
			for i,m in ipairs(foveationWindow.matchings) do
				if classifiersToWindows[m] then
					table.insert(classifiersToWindows[m],#foveationWindows)
				else
					classifiersToWindows[m]={#foveationWindows}
				end
			end
			-- print("#matchings end:" .. #foveationWindow.matchings)
		end
	end



	-- print("matched set")
	-- print(matchedSet)
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
	if self.numClassifiers >= self.pop_max then
		insertIndex = self:deleteClassifier()
	else
		self.numClassifiers = self.numClassifiers + 1
		insertIndex = self.numClassifiers
	end
	return insertIndex
end

function hFES:createClassifier(numPositions, foveationWindow,specificity,score)
	local score = score or 0.0
	local specificity = specificity or 0.1
	--print("Creating classifier**********************************")
	-- print(foveationWindow.dots)
	-- print("lines")
	-- print(foveationWindow.lines)
	-- print("lastPP")
	-- print(foveationWindow.lastPP)
	-- print("delete old classifier")
	local insertIndex = self:deleteAndGetIndex()
	-- print("creating classifier")
	local classifier = hfes.NineDotClassifier()
	classifier:buildClassifier(	foveationWindow.dots,
								foveationWindow.lines,
								foveationWindow.lastPP,
								foveationWindow,
								specificity
								)
	--print("classifier hidden weights")
	--plPretty.dump(classifier.hiddenWeights)
	-- print("classifier grid")
	-- print(classifier.grid.grid)
	-- print("classifier lines")
	-- print(classifier.lines.lines)
	-- print("classifier lastPP")
	-- print(classifier.lastPP.point)
	-- print("match:")
	-- print(classifier:match(	foveationWindow.dots,
	--  						foveationWindow.lines,
	--  						foveationWindow.lastPP))
	-- TO DO PUT IN ECLASSIFIER> 
	local newClassifier = hfes.EClassifier()
	newClassifier.classifier=classifier
	newClassifier:setTotalHashes()
	newClassifier:setValue(score/numPositions)
	newClassifier.matchSetEstimate = 1
	--newClassifier:setValue(0)
	--self.numClassifiers = self.numClassifiers + 1
	self.classifierIdHash = insertIndex
	self.classifiers[insertIndex] = newClassifier
	foveationWindow.matchings={insertIndex}
	self.hiddenWeightMatrix[insertIndex] = classifier.hiddenWeights
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

function hFES:getMatchSet()

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
	
	local epsilon = epsilon or 0.05

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



function hFES:bip()
 print('bip')
end


