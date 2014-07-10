--- creates a class "hierarchical Feature Evolution System"
local hFES = torch.class('hfes.hFES')


--- the initializer
function hFES:__init(problem)

	print('hFES init')
	self.problem = problem
	self.classifiers = {}

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
	
	print("::::=> Making move")

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
	print("moves:")
	print(moves)
	local foveationSet = self.problem:getFoveationSet()
	print("len f_set:" .. #foveationSet)
	classifiers = {}
	for i,f in ipairs(foveationSet) do
		print("i:" .. i)
		print("len f:" .. #f.foveationWindows)
		for j,foveationWindow in ipairs(f.foveationWindows) do
			print(foveationWindow.dots)
			print("lines")
			print(foveationWindow.lines)
			print("lastPP")
			print(foveationWindow.lastPP)
			local classifier = hfes.NineDotClassifier()
			local specificity1 = 0.1
			classifier:buildClassifier(	foveationWindow.dots,
										foveationWindow.lines,
										foveationWindow.lastPP,
										specificity1
										)
			print("classifier grid")
			print(classifier.grid.grid)
			print("classifier lines")
			print(classifier.lines.lines)
			print("classifier lastPP")
			print(classifier.lastPP.point)
			print("match:")
			print(classifier:match(	foveationWindow.dots,
			 						foveationWindow.lines,
			 						foveationWindow.lastPP))
			table.insert(classifiers,classifier)
		end
	end
	self.classifiers = classifiers 
		
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
	return {self.problem:getImage(), 

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


