h = require "hfes"
nd = h.ninedot(9, 5, 5)
points = {{4,2},{2,4}}
-- w=nd:getCenterWindow(points)
-- print(w.dots)
-- print(torch.gt(w.linesMatrix,0))
-- print(w.pointsMatrix)

dataTable = {classifiers=torch.Tensor(100,676),
		hashTable={},
		scoreTable={},
		insertIndex=1}

function addClassifierToHash(hash,insertIndex,hashTable)
	hashTable[hash] = insertIndex
end

function addClassifierToFitnessTable(score,insertIndex,scoreTable)
	scoreTable[insertIndex] = score
end

function addClassifierToWeightMatrix(classifier,classifiers,insertIndex)
	classifiers[insertIndex] = classifier
	if insertIndex % 100 == 0 then
		classifiers = torch.cat(classifiers:t(),torch.Tensor(676,100)):t()
	end
	return classifiers
end

-- _,covered = nd:getScoreCurrentPosition(points)
-- hw,hash = nd:createClassifierFromWindow(w)

-- -- to insert into population
-- classifiers = torch.Tensor(100,676)
-- classifierCount = 1


-- classifiers = addClassifiers(hw,classifiers,classifierCount)
-- classifierCount = classifierCount + 1

function createClassifierAndCache(points,ninedotObj,dataTable)
	local w=nd:getCenterWindow(points)
	local hw,hash = nd:createClassifierFromWindow(w)
	print("hw")
	print(hw)
	local _,score = nd:getScoreCurrentPosition(points)
	dataTable.classifiers = addClassifierToWeightMatrix(hw,dataTable.classifiers,dataTable.insertIndex)
	print("hash:")
	print(hash)
	addClassifierToHash(hash,dataTable.insertIndex,dataTable.hashTable)
	addClassifierToFitnessTable(score,dataTable.insertIndex,dataTable.scoreTable)
	dataTable.insertIndex = dataTable.insertIndex + 1
end

createClassifierAndCache(points,nd,dataTable)
w = nd:getCenterWindow(points)
iv =nd:getInputVector(w)