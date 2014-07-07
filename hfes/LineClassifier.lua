local LineClassifier,parent = torch.class('hfes.LineClassifier','hfes.ClassifierModule')

function LineClassifier:__init(lines)
	parent.__init(self)
	self.lines = lines or torch.Tensor({})
end

function LineClassifier:match(input)
	local allMatched = true
	if self.lines:storage() ~= nil then
		-- print("lines:" .. self.lines:size()[1])
		-- print("no lines:" .. self.lines:size()[1])
		-- print(type(self.lines:size()[1]))
		for i=1,self.lines:size()[1] do
			-- print("i = " .. i)
			local toMatch = self.lines[i]
			local matched = false
			for j=1,input:size()[1] do
				-- print("testing:" .. j)
				-- print(toMatch)
				-- print("with:")
				-- print(input[j])
				if util.matchTensor(toMatch,input[j]) then
					matched = true
					break
				end
			end
			if matched == false then
				allMatched = false
				-- print("failed to match:")
				-- print(toMatch)
				-- print("with:")
				for j=1,input:size()[1] do
					-- print(input[j])
				end
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
			-- print("line:")
			-- print(lines[i])
			if math.random() < specificity then
				table.insert(toAdd,{{lines[i][1][1],lines[i][1][2]},{lines[i][2][1],lines[i][2][2]}})
			end
		end
	end
	toAdd = torch.Tensor(toAdd)
	self.lines = toAdd
	return toAdd
end