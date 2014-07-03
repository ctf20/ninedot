-- local class = require 'class'
-- torch = require "torch"
-- define some dummy A class
local class = require 'class'

A = class('A')

function A:__init(stuff)
  self.stuff = stuff
end

function A:run()
  print(self.stuff)
end

-- define some dummy B class, inheriting from A
B = class('B', 'A')

function B:__init(stuff)
  A.__init(self, stuff) -- call the parent init
end

function B:run5()
  for i=1,5 do
    print(self.stuff)
  end
end

-- create some instances of both classes
local a = A('hello world from A')
local b = B('hello world from B')

-- run stuff
a:run()
b:run()
b:run5()