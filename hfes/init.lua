
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

end

   --- a method
   function hFES:print()
     print(self.contents)
   end

   --- another one
   function hFES:bip()
     print('bip')
   end

