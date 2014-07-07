local LineClassifier,parent = torch.class('hfes.LineClassifier','hfes.Classifier')

function LineClassifier:__init(lines)
	parent.__init(self)
	self.lines = lines or torch.Tensor({})
end

function LineClassifier:match(input)
	local allMatched = true
	if self.lines:storage() ~= nil then --If no lines then match. 
		for i=1,self.lines:size() do
			local toMatch = self.lines[i]
			local matched = false
			for j=1,input:size() do
				if util.matchTensor(toMatch,input[j]) then
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

function LineClassifier:createCover(lines,specificity)
	local specificity = specificity or 0.5
	local toAdd = {}
	if lines:storage() ~= nil then --Have to use storage() check to see if lines is empty. Cant use size. 
		for i=1,lines:size()[1] do
			if math.random() < specificity then
				table.insert(toAdd,{lines[i][1],lines[i][2],lines[i][3],lines[i][4]})
			end
		end
	end
	toAdd = torch.Tensor(toAdd)
	self.lines = toAdd
	return toAdd
end