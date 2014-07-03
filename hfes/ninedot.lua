local ninedot = torch.class('hfes.ninedot')

function ninedot:__init(N, K, boardSize)
	print("creating an {n,k,c}-problem")
	-- Create an (n,k,c) dot problem 

	self.n = N or 1 --Default = A single dot 
	self.k = K or 1 --Default = Single pen down move 
	self.boardSize = boardSize or 10 --Default is a 10 x 10 board. 

	-- Create a board state table which will store the current board state. 
	self.bs = {}
	self.bs.dots = {} --Dot state 

	-- Create a board for storing dots. 
	for i = 1, self.boardSize do 
		self.bs.dots[i] = {}
		for j = 1, self.boardSize do 
			self.bs.dots[i][j] = 0 
		end
	end
	print(self.bs.dots)

	-- Create a data structure for storing an order of lines drawn 
	self.bs.pp = {} -- Line state (sequence of dot positions that the pen has been on.) pp = pen positions 
	--table.insert(self.bs.pp, {0,1}) bs.pp takes a table of coordinates for the pen position, like this. 

	-- The 

end