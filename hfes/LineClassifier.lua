require "hfes"
local LineClassifier,parent = torch.class('hfes.LineClassifier','hfes.Classifier')

function LineClassifier:__init(lines)
	parent.__init(self)
	self.lines = lines or torch.Tensor({})
end

function LineClassifier:match(input)
	local allMatched = true
	if self.lines:storage():size() then
		for i=1,self.lines:size() do
			local toMatch = self.lines[i]
			local matched = false
			for j=1,input:size() do
				if hfes.utils.matchTensor(toMatch,input[j]) then
					matched = true
					break
				end
			end
			if matched == false then
				allMatched = false
				break
			end
		end
	end
	return allMatched
end

function cover