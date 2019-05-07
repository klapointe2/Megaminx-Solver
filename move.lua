local clockwiseMap = Map.new("64192b73a58") -- maps the change in positions of colors on one face
local swaps = { -- index corresponds to number of clockwise position rotations
	[0] = Map.new("123456789ab"); -- no rotation
	clockwiseMap; -- clockwise once
	clockwiseMap:transform(clockwiseMap); -- clockwise twice
	clockwiseMap:transform(clockwiseMap, clockwiseMap); -- counter-clockwise twice (clockwise 3 times)
	clockwiseMap:invert(); -- counter-clockwise (clockwise 4 times)
}
local clockwise = {
	Map.new("16234579abc8"), -- maps the change in face order
	Map.new("144313412421") -- number of clockwise rotations to apply to the color order on each face because their "top" face changes"
}
local right = {Map.new("32a941c87b65"), Map.new("010000040000")}

local function orientState(state, turn) -- change orientation without making any moves
	local map, rotations = turn[1], turn[2]
	local oldState = copyState(state)
	for i = 1, #map do
		local rot = swaps[rotations[i]]
		local array, new = oldState[map[i]], {}
		for j = 1, #rot do
			new[j] = array[rot[j]]
		end
		state[i] = new
	end
	return state
end

-- first index is positions on the face that new colors are moving into
-- second index is the respective positions on the adjacent face that are being moved
local right_clockwise = {
	{"358", "b96"}; -- white (positions 12, 9 and 6 on the red face move to positions 3, 5, 8 respectively on the white face)
	{"146", "853"}; -- blue
	{"123456789ab", tostring(clockwiseMap)}; -- red (this face is turned clockwise)
	{"69b", "ba8"}; -- green
	{"", ""}; -- purple
	{"", ""}; -- yellow
	{"", ""}; -- grey
	{"", ""}; -- cyan
	{"8ab", "641"}; -- lyellow
	{"146", "146"}; -- pink
	{"", ""}; -- lgreen
	{"", ""}; -- orange
}
for i = 1, 12 do
	local face = right_clockwise[i]
	face[3] = tonumber(("41395678a2bc"):sub(i, i), 13) -- list of the respective adjacent faces pieces are transferred from
	face[1], face[2] = Map.new(face[1]), Map.new(face[2])
end

local function transformState(state, transformation) -- applies a move such as right_clockwise
	local oldState = copyState(state)
	for i = 1, #transformation do
		local t = transformation[i]
		local to_positions, from_positions = t[1], t[2]
		local to_face = state[i]
		local from_face = oldState[t[3]]
		for j = 1, #to_positions do
			to_face[to_positions[j]] = from_face[from_positions[j]]
		end
	end
	return state
end

local identityOrientation = {Map.new("123456789abc"), Map.new("000000000000")} -- white face, blue top
local clockwiseTurn = {[0] = identityOrientation, clockwise} -- index corresponds to number of clockwise turns
local rightTurn = {[0] = identityOrientation, right} -- index corresponds to number of right turns

local function transformOrientation(orientation, transformation, ...)
	local newOrientation = {orientation[1]:transform(transformation[1])}
	local rotations = orientation[2]:transform(transformation[1])
	for i, r in pairs(transformation[2]) do
		rotations[i] = (tonumber(rotations[i]) + tonumber(r))%5
	end
	newOrientation[2] = rotations
	return ... and transformOrientation(newOrientation, ...) or newOrientation
end

for i = 2, 4 do
	clockwiseTurn[i] = transformOrientation(clockwiseTurn[i-1], clockwise)
	rightTurn[i] = transformOrientation(rightTurn[i-1], right)
end

local orientationList = {}
for i = 0, 4 do -- list the 5 faces touching blue
	orientationList[#orientationList+1] = transformOrientation(identityOrientation, rightTurn[i])
end
orientationList[#orientationList+1] = transformOrientation(identityOrientation, clockwiseTurn[1], rightTurn[1]) -- list the blue front
local cyanTop = transformOrientation(identityOrientation, clockwiseTurn[3], rightTurn[1], clockwiseTurn[4]) -- purple front, cyan top
for i = 0, 4 do -- list the 5 faces touching cyan
	orientationList[#orientationList+1] = transformOrientation(cyanTop, rightTurn[i])
end
orientationList[#orientationList+1] = transformOrientation(cyanTop, clockwiseTurn[1], rightTurn[1]) -- list the cyan front

for i = 1, 12 do -- add the other 4 rotations for each front
	for j = 1, 4 do
		orientationList[#orientationList+1] = transformOrientation(orientationList[i], clockwiseTurn[j])
	end
end

local orientationInverseMap = {} -- orientation change to apply to get back to white front, blue top
for i = 1, #orientationList do
	local o = orientationList[i]
	for j = 1, #orientationList do
		local p = orientationList[j]
		local new = transformOrientation(o, p)
		if tostring(new[1]) == "123456789abc" then
			orientationInverseMap[tostring(o[1])] = p
			break
		end
	end
end

local function getStateOrientation(state)
	local front, top = state[1][7], state[2][7]
	for i = 1, #orientationList do
		local o = orientationList[i][1]
		if base[o[1]] == front and base[o[2]] == top then
			return orientationList[i]
		end
	end
end

function returnStateToDefaultOrientation(state)
	local orientation = getStateOrientation(state)
	local inverse = orientationInverseMap[tostring(orientation[1])]
	return orientState(state, inverse)
end

local orientationDict = {}
for i = 1, #orientationList do
	local o = orientationList[i][1]
	local front, top = colors[o[1]], colors[o[2]]
	if not orientationDict[front] then orientationDict[front] = {} end
	orientationDict[front][top] = orientationList[i]
end
function setOrientation(state, front, top)
	local face = orientationDict[front]
	returnStateToDefaultOrientation(state)
	return orientState(state, face[top or next(face)])
end

local transformations = {}
for c = 1, 12 do
	local color = colors[c]
	local state = {}
	for i = 1, 12 do
		state[i] = expand("123456789ab")
		state[i][7] = base[i]
	end
	setOrientation(state, color)
	for i = 1, 4 do orientState(state, right) end
	local oldState = copyState(state)
	local map = {}
	for i = 1, #right_clockwise do
		local t = right_clockwise[i]
		local to, from, adjacent = t[1], t[2], t[3]
		map[tonumber(state[i][7], 13)] = tonumber(state[adjacent][7], 13)
		local to_face = state[i]
		for i = 1, 11 do to_face[i] = i == 7 and to_face[i] or "0" end
		local from_face = oldState[adjacent]
		for j = 1, #to do
			to_face[to[j]] = from_face[from[j]]
		end
	end
	returnStateToDefaultOrientation(state)
	local transformation = {}
	for i = 1, 12 do
		local a, b = {}, {}
		local face = state[i]
		for j = 1, 11 do
			local c = tonumber(face[j], 13)
			if j ~= 7 and c ~= 0 then
				a[#a+1] = tonumber(base[j], 13)
				b[#b+1] = c
			end
		end
		transformation[i] = {a, b, map[i]}
	end
	transformations[c] = transformation
end
function turnFace(state, face, turns) -- relative to current orientation
	for i = 1, turns or 1 do
		transformState(state, transformations[face])
	end
	return state
end
function turnColor(state, color, turns)
	local face = colors[color]
	for i = 1, 12 do
		if state[i][7] == base[face] then
			return turnFace(state, i, turns)
		end
	end
end

function printMoveList(moves)
	for _, move in next, moves do
		print(colors[move[1]].." "..({"clockwise", "clockwise twice", "counter-clockwise twice", "counter-clockwise"})[move[2]])
	end
end

function scrambleState(state, moves)
	local moveList = {}
	for i = 1, moves or 100 do
		local face = math.random(12)
		local turns = math.random(4)
		for j = 1, turns do
			turnFace(state, face)
		end
		moveList[#moveList+1] = {face, turns}
	end
	print("--- scramble ---")
	printMoveList(moveList)
	print("----------------")
	return state
end

function moveSequence(state, moves)
	local moveList = {}
	for i = 1, #moves do
		turnFace(state, moves[i][1], moves[i][2])
		moveList[i] = {base[state[moves[i][1]][7]], moves[i][2]}
	end
	printMoveList(moveList)
end

insertLeft = {{2, 4}, {6, 4}, {2, 1}, {6, 1}, {2, 1}, {1, 1}, {2, 4}, {1, 4}}
insertRight = {{2, 1}, {3, 1}, {2, 4}, {3, 4}, {2, 4}, {1, 4}, {2, 1}, {1, 1}}
insertRightBottom = {{4, 4}, {3, 4}, {4, 1}, {3, 1}, {4, 1}, {1, 1}, {4, 4}, {1, 4}}
insertLeftBottom = {{5, 1}, {6, 1}, {5, 4}, {6, 4}, {5, 4}, {1, 4}, {5, 1}, {1, 1}}
insertMiddleLeft = {{1, 4}, {3, 4}, {1, 3}, {3, 1}, {1, 1}}
insertMiddleRight = {{1, 1}, {6, 1}, {1, 2}, {6, 4}, {1, 4}}