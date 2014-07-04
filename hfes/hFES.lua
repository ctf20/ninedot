--- creates a class "hierarchical Feature Evolution System"
local hFES = torch.class('hfes.hFES')


--- the initializer
function hFES:__init(problem)

	print('hFES init')
	self.problem = problem

end


--- a method
function hFES:print()

 print(self.contents)

end


--- Match and Move method 
function hFES:makeMove()
	
	print("Making move")

	local move_id = self.problem:getMoves()
	local score = self.problem:getScores(move_id)
	local chosenMove = self:eGreedyChoice(move_id, score)
	self.problem:updateBoard(chosenMove)

	-- local move_id = self.problem:getMoves()
	-- local values = self:getValues(move_id)
	-- os.exit()
	-- local chosenMove = self:eGreedyChoice(move_id,values)
	-- self.problem:updateBoard(chosenMove)

end



function hFES:getValues(moves)

	local values = {}
	for mov = 1, #moves do 

		local matchSet = {}
		local foveationSet = self.problem:getFoveationSet()		
		for i = 1, #foveationSet do 
			local M = self.getMatchSet()
			table.insert(matchSet, M)  
		end
		-- Calculate value from MatchSet 

	end

	return values

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
	return self.problem:getImage()

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


