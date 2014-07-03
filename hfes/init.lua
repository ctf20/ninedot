
require 'torch'

hfes = {}

torch.include('hfes','ninedot.lua')

--- creates a class "hierarchical Feature Evolution System"
local hFES = torch.class('hfes.hFES')

--- the initializer
function hFES:__init(num)
	self.contents = "making hFES object "
 	
    -- Create a (n,k,random c, board_size) dot problem object. 
    self.ndp = hfes.ninedot()

    -- Create the hFES model data structures

end

--- a method
function hFES:print()
 print(self.contents)
end

--- Match and Move method 
function hFES:matchAndMove()
	local score = {} --Stores the score associated with each possible move 
	local move_id = {}
	
	score, move_id = self.ndp:getMovesAndScores()

	print("scores = " .. score .. " moves = " .. moves)

end

--- another one
function hFES:bip()
 print('bip')
end

