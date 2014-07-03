
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
	os.exit()
	local chosenMove = self:eGreedyChoice(move_id, score)
	self.problem:updateBoard(chosenMove)

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

	return maxChoice

end

function hFES:bip()
 print('bip')
end
