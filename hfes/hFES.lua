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
			local a = self.classifiers[pop[math.random(1, #pop)]]
			local b = self.classifiers[pop[math.random(1,#pop)]]

			--Only replicate if both are beyond a certain age. 
			if a.valueHistory:storage():size() < 5 or b.valueHistory:storage():size() < 5 then 
				print("value history = " .. a.valueHistory:storage():size())
				print("value history = " .. b.valueHistory:storage():size())
				print("NOT REPLICATING ************************************")
				return 
			else
				print("REPLICATING**************^^^^^^^^^^^^^^^^^^^^&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&")
				print("value history = " .. a.valueHistory:storage():size())
				print("value history = " .. b.valueHistory:storage():size())
			end

			-- while( a == b) do 
			-- 	local b = math.random(1,#pop)
			-- end
			local fita = a.fitness
			local fitb = b.fitness
			
			local winner 
			local loser 

			if fita > fitb then 
				winner = a
				loser = b
			else
				loser = a
				winner = b
			end

			--Winner will be replicated 
			local child = winner:replicate()
			--And mutated 
			child:mutate()
			--And must now be injected into the self.classifiers data structure. 
			--table.insert(self.classifiers,child)
			--If self.classifers > LIMIT then remove the worst classifier. 
			--  if self.numClassifiers > POP_MAX then 
			-- 	--print("HERe1")
			-- 	-- print(self.classifiers)
			-- 	-- holeNumber = self:deleteWorstClassifier(POP_MAX)
			-- 	self.classifiers[holeNumber] = child
			-- else
			table.insert(self.classifiers, child)
			self.numClassifiers = self.numClassifiers + 1 
			--print("CREATING CHILD ")
			-- end

		end


	end

end

function hFES:deleteClassifiers(pop_max)

	while self.numClassifiers > pop_max do 

		self:deleteWorstClassifier(pop_max)

	end

end

function hFES:deleteWorstClassifier(pop_max) 
	--print("HERe2")
	--print(self.classifiers)
	if self.numClassifiers > pop_max then 
		local worstClassifierFitness = 10000000
		local worstClassifier = -1 
		for k,v in pairs(self.classifiers) do 
			if self.classifiers[k].fitness < worstClassifierFitness then 
				worstClassifierFitness = self.classifiers[k].fitness
				worstClassifier = k 
			end
		end

		--Delete it here
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
	
	local values = {}
	for i = 1, #self.rollouts do 
		local v = 0 
		for j = 1, #self.rollouts[i].activeClassifiers do 
			v = v + self.classifiers[self.rollouts[i].activeClassifiers[j]].weight
		end
		table.insert(values, v)
	end
	local alpha = 0.05
	local val = 0 
	for i = 1, #self.rollouts do 
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
			self.classifiers[self.rollouts[i].activeClassifiers[j]]:setValue(self.classifiers[self.rollouts[i].activeClassifiers[j]].weight + alpha * (self.rollouts[i].reward + 0.0*val - values[i]))

		end
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
		local matchedClassifiers,foveationWindows,classifiersToWindows = self:getActiveClassifiersForMove(move, false, allScores[i])
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
		print("matched classifiers = " .. matchedClassifiers[i])
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
			foveationWindow.matchings = self:matchClassifiers(foveationWindow)
			-- print("#matchings start:" .. #foveationWindow.matchings)
			if #foveationWindow.matchings == 0 and visualize == false then
				-- self:deleteExcessClassifiers()
				self:createClassifier(foveationWindow,1.0, score)
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
	-- print("activeClassifiers:")
	-- print(activeClassifiers)
	return activeClassifiers,foveationWindows,classifiersToWindows
end

function hFES:addClassifiersToSet(indexes,set)
	for i,index in ipairs(indexes) do
		util.addToSet(index,set)
	end
end

function hFES:createClassifier(foveationWindow,specificity,score)
	local score = score or 0.0
	local specificity = specificity or 0.1
	print("Creating classifier**********************************")
	-- print(foveationWindow.dots)
	-- print("lines")
	-- print(foveationWindow.lines)
	-- print("lastPP")
	-- print(foveationWindow.lastPP)
	local classifier = hfes.NineDotClassifier()
	classifier:buildClassifier(	foveationWindow.dots,
								foveationWindow.lines,
								foveationWindow.lastPP,
								foveationWindow,
								specificity
								)
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
	local newClassifier = hfes.EClassifier()
	newClassifier.classifier=classifier
	newClassifier:setValue(score)
	table.insert(self.classifiers,newClassifier)
	self.numClassifiers = self.numClassifiers + 1
	foveationWindow.matchings={self.numClassifiers}
end

function hFES:matchClassifiers(foveationWindow)
	-- print("in match classifiers")
	-- print(self)
	-- print("self.classifiers:")
	-- print(self.classifiers)
	local matchingSet = {}
	for k,classifier in pairs(self.classifiers) do
		-- print("matching class:" .. i)
		-- local matched = classifier.classifier:match(
		-- 							foveationWindow.dots,
		-- 	 						foveationWindow.linesMatrix,
		-- 	 						foveationWindow.pointMatrix)
		local matched = classifier.classifier:match(foveationWindow.binaryVector)
		-- print("fwbinary")
		-- plPretty.dump(foveationWindow.binaryVector)
		-- print("classifier")
		-- plPretty.dump(classifier.classifier.binaryClassifier)
		if matched then
			table.insert(matchingSet,k)
		end
	end
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


