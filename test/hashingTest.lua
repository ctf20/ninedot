--Hashing test 

local bit = require('bit')


--http://bitop.luajit.org/api.html

--========MAKE TEMPLATES ================

--Create a set of 25 x 25 + 5 x 5 + 5 x 5 length binary strings which is what the condition will be (with 11 being a dont care. )
--Turn all 00s into 11s!

--Create 2000 templates 
local templates = {}
local specificity = 0.015


--Create 2000 binary strings as templates. 
for i = 1, 10000 do 
	s = ''
	for j = 1, 25*25 + 5*5 + 5*5 do 
		if math.random() > specificity then --make a dont care.  
			s = s.. '11'
		else
			if math.random() < 0.5 then 
				s= s .. '01'
			else
				s = s .. '10'
			end
		end
	end
	--Add an extra 26 bits to make the total length come up to 1376 bits, which is 32 x 43 
	for j = 1, 26 do 
		--Make these '11' bits so they always match anything 
		s = s .. '1'
	end

	table.insert(templates, s)

end

--Now break them up into 32 bit strings. 
--print("Length = " .. #templates[1])
--print("32 bit parts = " .. #templates[1]/32)

templatesSplit = {}
for t = 1, #templates do 
	tempStrings = {}
	for i = 1, #templates[t]/32 do 
		local s = string.sub(templates[t], (i-1)*32 + 1 , (i-1)*32+ 32)
		--print(#s)
		table.insert(tempStrings,s)
		--print(s)
	end
	table.insert(templatesSplit, tempStrings)
end

--Now convert each 32 bit binary number into an integer and just store the integers directly. 
templatesIntegers = {}
for t = 1, #templatesSplit do 
	tempInts = {}
	for i = 1, #templatesSplit[t] do 
		local s = tonumber(templatesSplit[t][i],2)
		table.insert(tempInts,s)
		--print(s)
		--print (to_binary(s))

	end
	table.insert(templatesIntegers, tempInts)
end



--========MAKE BOARD STATE================

--Now create a board state 
bs = ''
for j = 1, 25*25 + 5*5 + 5*5 do 
		if math.random() < 0.5 then 
			bs = bs .. '01'
		else
			bs = bs .. '10'
		end
end
--Add an extra 26 bits to make the total length come up to 1376 bits, which is 32 x 43 
for j = 1, 26 do 
	--Make these '11' bits so they always match anything 
	bs = bs .. '1'
end

-- Break this into 32 bit parts as well. 
tempbs = {}
for i = 1, #bs/32 do 
	local s = string.sub(bs, (i-1)*32 + 1 , (i-1)*32+ 32)
--	print(#s)
	table.insert(tempbs,s)
--	print(s)
end

--And convert each part to an integer. 
bsIntegers = {}
for i = 1, #tempbs do 
	local s = tonumber(tempbs[i],2)
	--print(s)
	table.insert(bsIntegers,s)
end


-- print("board state =")
-- for i = 1, #tempbsIntegers do 
-- 	print(tempbsIntegers[i] .. " ")
-- end

----This concludes the construction of the data structrues templatesIntegers and bsIntegers








--Returns the indexes of the matched templates, takes the data structures constructed above. 

function getMatches(bsIntegers,templatesIntegers)

	local matchedTemplates = {}

	for i = 1, #templatesIntegers do 
		local mat = 1 
		--print(" template " .. i .. " is ")
		for j = 1, #templatesIntegers[i] do 
			--io.write(templatesIntegers[i][j].. " " )
			--print("")
			--print("comparing")
			--print(to_binary(templatesIntegers[i][j]))
			--print(to_binary(bsIntegers[j]))
			--print("result = ----------")
			--result = bit.band(templatesIntegers[i][j], bsIntegers[j])
			--print(bit.tohex(templatesIntegers[i][j]))
			result = bit.band(bit.tobit(templatesIntegers[i][j]), bit.tobit(bsIntegers[j]))
			--result = bit.band(bit.tohex(12), bit.tohex(12))
			--print(to_binary(result))

			--print(bit.tobit(templatesIntegers[i][j]) .. " AND " .. bit.tobit(bsIntegers[j]) .. " => " .. bit.tobit(result) .. " " )
			if bit.tobit(bsIntegers[j]) ~= bit.tobit(result) then 
				--print("not matched")
				mat = 0 
				break 		
			end	
		end
		if mat == 1 then 
			--print("MATCHED")
			table.insert(matchedTemplates, i)
		end
	end


	return matchedTemplates

end

print("starting get match")
mt = getMatches(bsIntegers,templatesIntegers)
print("MATCHED TEMPLATES  ")
	-- for i = 1, #mt do 
	-- 	print(mt[i])
	-- end


