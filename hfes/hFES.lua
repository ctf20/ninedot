--- creates a class "hierarchical Feature Evolution System"
local hFES = torch.class('hfes.hFES')


--- the initializer
function hFES:__init(problem)
	print('hFES init')
	print("setting problem")
	self.problem = problem
	print("setting classifiers")
	self.classifiers = {}
	print("self.classifiers")
	print(self.classifiers)
	print("#self.classifiers:" .. #self.classifiers)
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


--- Match and Move method 
function hFES:makeMove()
	
	
	local move_id = shuffled(self.problem:getMoves())
	local values = self:getValues(move_id)
	-- local chosenMove = self:eGreedyChoice(move_id,values)
	-- self.problem:updateBoard(chosenMove)
	
	local score = self.problem:getScores(move_id) --I'm going to be using the getScores and moving according to get scores for now. 
	local chosenMove = self:eGreedyChoice(move_id, score)
	self.problem:updateBoard(chosenMove)

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

function hFES:getValues(moves)
	local rewards = self.problem:getScores(moves)
	local activeClassifiers = {}
	for i,move in ipairs(moves) do
		-- print("adding: ***********************************")
		-- print(self.problem.bs.pp)
		-- print(move)
		self.problem:makePotentialMove(move)
		-- print(self.problem.bs.pp)
		table.insert(activeClassifiers,self:getActiveClassifiersForMove(move))
		self.problem:undoLastMove()
	end
end

function hFES:getCurrentActiveClassifiers(moves)
	local activeClassifiers = self:getActiveClassifiersForMove()
	return activeClassifiers
end

function hFES:getActiveClassifiersForMove(move)
	-- print("moves:")
	-- print(moves)
	local foveationSet = self.problem:getFoveationSet()
	-- print("len f_set:" .. #foveationSet)
	local classifiers = {}
	local matchedSet = {}
	for i,foveationPosition in ipairs(foveationSet) do
		-- print("i:" .. i)
		-- print("len f:" .. #foveationPosition.foveationWindows)
		for j,foveationWindow in ipairs(foveationPosition.foveationWindows) do
			foveationWindow.matchings = self:matchClassifiers(foveationWindow)
			-- print("#matchings start:" .. #foveationWindow.matchings)
			if #foveationWindow.matchings == 0 then
				self:createClassifier(foveationWindow,0.8)
			end
			self:addClassifiersToSet(foveationWindow.matchings,matchedSet)
			-- print("#matchings end:" .. #foveationWindow.matchings)
		end
	end
	-- print("matched set")
	-- print(matchedSet)
	local activeClassifiers = util.getKeywords(matchedSet)
	-- print("activeClassifiers:")
	-- print(activeClassifiers)
	return activeClassifiers
end

function hFES:addClassifiersToSet(indexes,set)
	for i,index in ipairs(indexes) do
		util.addToSet(index,set)
	end
end

function hFES:createClassifier(foveationWindow,specificity)
	--print("here")
	local specificity = specificity or 0.1
	-- print(foveationWindow.dots)
	-- print("lines")
	-- print(foveationWindow.lines)
	-- print("lastPP")
	-- print(foveationWindow.lastPP)
	local classifier = hfes.NineDotClassifier()
	classifier:buildClassifier(	foveationWindow.dots,
								foveationWindow.lines,
								foveationWindow.lastPP,
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
	table.insert(self.classifiers,{classifier=classifier,weight=0.0})
	foveationWindow.matchings={#self.classifiers}
end

function hFES:matchClassifiers(foveationWindow)
	-- print("in match classifiers")
	-- print(self)
	-- print("self.classifiers:")
	-- print(self.classifiers)
	local matchingSet = {}
	for i,classifier in ipairs(self.classifiers) do
		-- print("matching class:" .. i)
		local matched = classifier.classifier:match(
									foveationWindow.dots,
			 						foveationWindow.lines,
			 						foveationWindow.lastPP)
		if matched then
			table.insert(matchingSet,i)
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
	self:getCurrentActiveClassifiers() --Rematch classifiers to current board position. 
	--print("SENDING CLASSIFIERS " .. #self.classifiers)
	return { self.problem:getImage(),self.classifiers }

end	



function hFES:eGreedyChoice(move_id, score)

	print("In eGreedyChoice")
	local maxScore = -1000
	local maxChoice = -1
	
	for i = 1, #move_id do 
		if score[i] > maxScore then 
			maxScore = score[i]
			maxChoice = move_id[i]
		end

	end
	--print(maxChoice)
	return maxChoice

end



function hFES:bip()
 print('bip')
end


