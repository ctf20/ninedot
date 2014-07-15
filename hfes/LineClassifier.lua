local LineClassifier,parent = torch.class('hfes.LineClassifier','hfes.ClassifierModule')

function LineClassifier:__init(lines)
	parent.__init(self)
	self.lines = lines or torch.Tensor({})
	self.numHashes = 0 
end

function LineClassifier:match(input)
	local allMatched = true
	-- print("line:")
	-- print(input)
	if self.lines:storage() ~= nil then

		for i=1,self.lines:size()[1] do
			-- print("i = " .. i)
			local toMatch = self.lines[i]
			local matched = false
			if input:storage() ~= nil then
				for j=1,input:size()[1] do
					if util.matchTensor(toMatch,input[j]) then
						matched = true
						break
					end
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

function LineClassifier:createCover(lines,specificity)
	local specificity = specificity or 0.5
	local toAdd = {}
	if lines:storage() ~= nil then

		for i=1,lines:size()[1] do

			if math.random() < specificity then
				table.insert(toAdd,{{lines[i][1][1],lines[i][1][2]},{lines[i][2][1],lines[i][2][2]}})
			end
		end
	end
	toAdd = torch.Tensor(toAdd)
	self.lines = toAdd
	return toAdd
end