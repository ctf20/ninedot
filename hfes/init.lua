require 'torch'
hfes = {}
hfes.utils = {}
local function getSize(a)
	local sizeTable = {}
	for i = 1,#a:size() do
		table.insert(sizeTable,a:size()[i])
	end
	return torch.Tensor(sizeTable)
end

function hfes.utils.matchTensor(a,b)
	return torch.sum(torch.eq(a,b)) == torch.prod(getSize(a),1)[1]
end

function hfes.utils.matchTensorWithIgnores(template,pattern)
	local match = true
	for i=1,#template:storage() do
		if template:storage()[i] ~= -1 then
			if template:storage()[i] ~= pattern:storage()[i] then
				match = false
				break
			end
		end
	end
	return match
end

torch.include('hfes','hFES.lua')
torch.include('hfes','ninedot.lua')
torch.include('hfes','MatchingUtils.lua')

return hfes