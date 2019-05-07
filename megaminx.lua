local tick = require("socket").gettime
package.path = package.path..";../?.lua"
require("utils")
require("display")
require("map")
require("pieces")
require("move")

local function findState(origin, visited, searchFunction, faces, test)
	visited[stateToString(origin)] = true
	if not faces then
		faces = {}
		for i = 1, 12 do faces[i] = i end
	end
	local paths = {{origin, {}}}
	local depth = 0
	while true do
		depth = depth + 1
		--print("depth: "..depth)
		local newPaths = {}
		for _, pair in next, paths do
			local state, moves = pair[1], pair[2]
			for _, face in next, faces do
				local copy = state
				for turns = 1, 4 do
					local new = turnFace(copyState(copy), face)
					local serial = stateToString(new)
					if not visited[serial] then
						visited[serial] = true
						local newMoves = {table.unpack(moves)}
						newMoves[#newMoves+1] = {base[state[face][7]], turns}
						if searchFunction(copyState(new)) then return new, newMoves end
						newPaths[#newPaths+1] = {new, newMoves}
					end
					copy = new
				end
			end
		end
		if newPaths[1] and #newPaths[1][2] > 1 then -- try doing the opposite of the first move
			for _, pair in next, newPaths do
				local state, moves = pair[1], pair[2]
				local firstMove = moves[1]
				local face, facei = getFaceFromColor(state, colors[firstMove[1]])
				local new = copyState(state)
				turnFace(new, facei, 5 - firstMove[2])
				local newMoves = {table.unpack(moves)}
				newMoves[#newMoves+1] = {firstMove[1], 5-firstMove[2]}
				if searchFunction(copyState(new)) then
					return new, newMoves
				end
			end
		end
		paths = newPaths
	end
end

local function countWhiteStarEdges(state)
	local count = 0
	if state[2][2] == "2" and state[1][2] == "1" then count = count + 1 end
	if state[3][4] == "3" and state[1][5] == "1" then count = count + 1 end
	if state[4][10] == "4" and state[1][10] == "1" then count = count + 1 end
	if state[5][9] == "5" and state[1][9] == "1" then count = count + 1 end
	if state[6][5] == "6" and state[1][4] == "1" then count = count + 1 end
	return count
end
local function checkWhiteStarOrder(state) -- returns whether the white star edges are in the correct relative order
	if countWhiteStarEdges(state) ~= 5 then return false end
	local edges = {2, 5, 10, 9, 4, 2}
	for i = 1, 5 do
		local edge1 = base[getEdge(state, 1, edges[i])[2]]
		local edge2 = base[getEdge(state, 1, edges[i+1])[2]]
		if edge2 ~= (edge1-1)%5+2 then
			return false
		end
	end
	return true
end
local function countWhiteCorners(state)
	if countWhiteStarEdges(state) ~= 5 then
		state = copyState(state)
		for i = 1, 4 do
			turnColor(state, "white")
			if countWhiteStarEdges(state) == 5 then break end
		end
	end
	local count = 0
	if state[1][1] == "1" and state[2][3] == "2" then count = count + 1 end
	if state[1][3] == "1" and state[3][1] == "3" then count = count + 1 end
	if state[1][6] == "1" and state[6][8] == "6" then count = count + 1 end
	if state[1][8] == "1" and state[3][6] == "3" then count = count + 1 end
	if state[1][11] == "1" and state[4][8] == "4" then count = count + 1 end
	return count
end
local function fixWhiteLayer(state) -- rotate the white face back into place
	if countWhiteStarEdges(state) == 5 then return state end
	state, moves = findState(state, {}, function(state)
		return countWhiteStarEdges(state) == 5
	end)
	printMoveList(moves)
	return state
end

local function positionWhiteEdges(state) -- move the white edges to the white half
	local function countGoodEdges(state)
		local c = 0
		local edges = {2, 4, 5, 9, 10}
		local faces = {2, 6, 3, 5, 4}
		for i, edge in next, edges do
			if state[1][edge] ~= "1" then
				for _, j in next, edges do
					if state[faces[i]][j] == "1" then
						c = c + 1
					end
				end
			else
				c = c + 1
			end
		end
		return c
	end
	local count = countGoodEdges(state)
	local solved = countWhiteStarEdges(state)
	local visited = {}
	if count == 5 then return state, moves end
	print("--- move edges ---")
	while count ~= 5 do
		local moves;
		state, moves = findState(state, visited, function(state)
			return countWhiteStarEdges(state) >= solved and countGoodEdges(state) > count
		end)
		count = countGoodEdges(state)
		solved = countWhiteStarEdges(state)
		printMoveList(moves)
		--print("edges in place: "..count)
	end
	print("------------------")
	return state
end

local function solveWhiteStar(state)
	local count = countWhiteStarEdges(state)
	local visited = {}
	while count ~= 5 do
		state = positionWhiteEdges(state)
		local moves;
		state, moves = findState(state, visited, function(state)
			return countWhiteStarEdges(state) > count
		end)
		count = countWhiteStarEdges(state)
		print("--- solve edge ---")
		printMoveList(moves)
		print("------------------")
		print("star edges solved: "..count)
	end
	return state
end

local function cornerInPosition(state, corner)
	local color1, color2, color3 = corner.colors[1], corner.colors[2], corner.colors[3]
	local set = {["1"] = true, [state[1][2]] = true, [state[3][2]] = true}
	return set[color1] and set[color2] and set[color3]
end

local function findPositionedCorner(state, ispositioned)
	for color = 2, 6 do
		local face, index = getFaceFromColor(state, colors[color])
		local position;
		for _, position in next, {1, 3, 6, 8, 11} do
			if face[position] == "1" then
				local corner = getCorner(state, index, position)
				if not ispositioned or cornerInPosition(state, corner) then
					return colors[color], corner
				end
			end
		end
	end
end

local function positionWhiteCorner(state)
	local corners = countWhiteCorners(state)
	if findPositionedCorner(state) then return state end
	state, moves = findState(state, {}, function(state)
		if findPositionedCorner(state) then
			return countWhiteCorners(state) >= corners and checkWhiteStarOrder(state)
		end
	end)
	print("--- position corner ---")
	printMoveList(moves)
	print("-----------------------")
	return state
end

local function solveWhiteCorners(state)
	local count = countWhiteCorners(state)
	while count ~= 5 do
		state = positionWhiteCorner(state)
		setOrientation(state, "blue", "white")
		local color, corner = findPositionedCorner(state)
		setOrientation(state, color, "white")
		if corner.positions[1] > 3 then
			local whiteturns = 0
			while not ((state[1][2] == corner.colors[2] and state[3][2] == corner.colors[3]) or (state[1][2] == corner.colors[3] and state[3][2] == corner.colors[2])) do
				state = turnColor(state, "white")
				whiteturns = whiteturns + 1
			end
			if whiteturns ~= 0 then
				print("--- white turn ---")
				printMoveList({{1, whiteturns}})
				print("------------------")
			end
			color, corner = findPositionedCorner(state, true) -- find the in-position color on the front face
		end
		local sequence8 = {{4, 4}, {3, 4}, {4, 1}, {3, 1}}
		print("--- white corner ---")
		if corner.positions[1] == 1 then
			--moveSequence(state, {{6, 1}, {5, 1}, {6, 4}, {4, 1}})
			--moveSequence(state, sequence8)
			moveSequence(state, {{6, 1}, {5, 1}, {6, 4}, {4, 1}}) -- remove corner
		elseif corner.positions[1] == 3 then
			--moveSequence(state, {{3, 4}, {4, 1}, {3, 1}})
			--moveSequence(state, sequence8)
			moveSequence(state, {{3, 4}, {4, 1}, {3, 1}}) -- remove corner
		elseif corner.positions[1] == 6 then
			moveSequence(state, {{2, 1}, {1, 4}, {5, 4}, {1, 1}, {2, 4}})
		elseif corner.positions[1] == 8 then
			moveSequence(state, sequence8)
		elseif corner.positions[1] == 11 then
			moveSequence(state, {{4, 1}, {3, 4}, {4, 4}, {3, 1}})
		end
		print("--------------------")
		returnStateToDefaultOrientation(state)
		state = fixWhiteLayer(state)
		count = countWhiteCorners(state)
		print("corners solved: "..count.."/5")
	end
	return state
end

local function getPositionedEdge(state) -- edge in position for second layer
	state = copyState(state)
	setOrientation(state, "blue", "white")
	for color = 2, 6 do
		local face, index = getFaceFromColor(state, colors[color])
		local right, ri = getFaceFromColor(state, colors[(color-3)%5+2])
		local left, li = getFaceFromColor(state, colors[(color-1)%5+2])
		if face[9] == face[7] then
			local neighbor = getEdge(state, index, 9)[2]
			if neighbor == left[7] then
				return color, "left"
			end
		elseif face[10] == face[7] then
			local neighbor = getEdge(state, index, 10)[2]
			if neighbor == right[7] then
				return color, "right"
			end
		end
	end
end

local function countSecondLayerEdges(state) -- counts number of solved edges in the second layer
	state = copyState(state)
	setOrientation(state, "blue", "white")
	local count = 0
	local buried = {} -- second-layer edges in the second layer but in the wrong place
	for color = 2, 6 do
		local face, index = getFaceFromColor(state, colors[color])
		local right, ri = getFaceFromColor(state, colors[(color-3)%5+2])
		local edge = getEdge(state, index, 5)
		local neighbor = edge[2]
		if face[5] == face[7] then
			if neighbor == right[7] then count = count + 1 end
		elseif base[face[5]] > 1 and base[face[5]] < 7 and base[neighbor] > 1 and base[neighbor] < 7 then
			buried[#buried+1] = neighbor
		end
	end
	return count, buried
end

local function positionEdge(state) -- position edge on the second layer
	if getPositionedEdge(state) then return state end
	local count, buried = countSecondLayerEdges(state)
	while count ~= 5 and count + #buried == 5 do
		setOrientation(state, colors[base[buried[1]]], "white")
		print("--- remove edge ---")
		moveSequence(state, {{4, 4}, {3, 4}, {4, 1}, {3, 1}, {4, 1}, {1, 1}, {4, 4}, {1, 4}}) -- insert right
		print("-------------------")
		returnStateToDefaultOrientation(state)
		count, buried = countSecondLayerEdges(state)
	end
	state, moves = findState(state, {}, function(state)
		return getPositionedEdge(state) and countSecondLayerEdges(state) >= count
	end, {7, 8, 9, 10, 11, 12})
	print("--- position edge ---")
	printMoveList(moves)
	print("---------------------")
	return state
end

local function solveSecondLayer(state)
	local count = countSecondLayerEdges(state)
	while count ~= 5 do
		state = positionEdge(state)
		local color, direction = getPositionedEdge(state)
		setOrientation(state, colors[color], "white")
		print("--- insert edge ---")
		if direction == "right" then
			moveSequence(state, insertRightBottom)
		else
			moveSequence(state, insertLeftBottom)
		end
		print("-------------------")
		count = countSecondLayerEdges(state)
		print("L2 edges: "..count)
		state = returnStateToDefaultOrientation(state)
	end
	return state
end

local function countCorrectCorners1(state) -- middle layer corners
	state = setOrientation(copyState(state), "cyan", "grey")
	local count = 0
	local buried = {} -- middle layer corners in the upper middle 5 corner positions
	for color = 8, 12 do
		local face, index = getFaceFromColor(state, colors[color])
		local corner = getCorner(state, index, 11)
		if corner.colors[1] == corner.faces[1][7] and corner.colors[2] == corner.faces[2][7] then -- corner colors match center colors
			count = count + 1
		end
		local hole = getCorner(state, index, 6)
		local topColors, bottomColors = 0, 0
		for i = 1, 3 do
			if base[hole.colors[i]] > 7 then
				topColors = topColors + 1 -- grey side, not including grey
			elseif base[hole.colors[i]] < 7 then
				bottomColors = bottomColors + 1 -- white side
			end
		end
		if topColors == 1 and bottomColors == 2 then
			buried[#buried+1] = colors[color]
		end
	end
	return count, buried
end

local function solveCorners1(state) -- solve the 5 corners on the white half
	setOrientation(state, "cyan", "grey")
	local count, buried = countCorrectCorners1(state)
	while count ~= 5 do
		while count ~= 5 and count + #buried == 5 do
			setOrientation(state, buried[1], "grey")
			print("--- remove corner ---")
			moveSequence(state, {{1, 1}, {2, 1}, {1, 4}})
			print("---------------------")
			count, buried = countCorrectCorners1(state)
		end
		local moves;
		local clock = tick()
		state, moves = findState(state, {}, function(state)
			return countCorrectCorners1(state) > count
		end, {1, 2, 3, 6, 10, 11})
		print("took "..(tick() - clock).." seconds")
		count, buried = countCorrectCorners1(state)
		print("--- solve corner ---")
		printMoveList(moves)
		print("--------------------")
		print("corners solved: "..count.."/5")
	end
	return returnStateToDefaultOrientation(state)
end

local function getPositionedMiddleEdge(state) -- edge in position for second layer
	state = copyState(state)
	setOrientation(state, "cyan", "grey")
	for color = 8, 12 do
		local face, index = getFaceFromColor(state, colors[color])
		if face[2] == face[7] then
			local edge = getEdge(state, index, 2)
			local left = getEdge(state, index, 9).faces[2][7]
			local right = getEdge(state, index, 10).faces[2][7]
			if edge[2] == left then
				return color, "left"
			elseif edge[2] == right then
				return color, "right"
			end
		end
	end
end

local function countMiddleEdges(state) -- counts number of solved edges in the middle layer
	state = copyState(state)
	setOrientation(state, "cyan", "grey")
	local count = 0
	local buried = {} -- middle-layer edges in the middle layer but in the wrong place
	local flipped = {} -- middle-layer edges on the grey face but flipped
	local active = 0 -- non-flipped edges on the grey face
	for color = 8, 12 do
		local face, index = getFaceFromColor(state, colors[color])
		local edge1 = getEdge(state, index, 9)
		if face[9] == face[7] and edge1[2] == edge1.faces[2][7] then
			count = count + 1
		elseif (base[face[9]] > 7 and base[edge1[2]] < 7) or (base[face[9]] < 7 and base[edge1[2]] > 7) then
			buried[#buried+1] = {colors[color], edge1, "left"}
		end
		local edge2 = getEdge(state, index, 10)
		if face[10] == face[7] and edge2[2] == edge2.faces[2][7] then
			count = count + 1
		elseif (base[face[10]] > 7 and base[edge2[2]] < 7) or (base[face[10]] < 7 and base[edge2[2]] > 7) then
			buried[#buried+1] = {colors[color], edge2, "right"}
		end
		local edge0 = getEdge(state, index, 2)
		if base[edge0[1]] < 7 and base[edge0[2]] > 7 then
			flipped[#flipped+1] = {colors[color], edge0}
		elseif base[edge0[1]] > 7 and base[edge0[2]] < 7 then
			active = active + 1
		end
	end
	return count, buried, flipped, active
end

local function positionMiddleEdge(state) -- position edge on the middle layer
	if getPositionedMiddleEdge(state) then return state end
	setOrientation(state, "cyan", "grey")
	local count, buried, flipped, active = countMiddleEdges(state)
	while count ~= 10 and (count + #buried + #flipped == 10 or active == 0) do
		if not buried[1] and not flipped[1] then break end
		if buried[1] then
			local color = buried[1][1]
			local edge = buried[1][2]
			setOrientation(state, color, "grey")
			print("--- remove edge ---")
			if buried[1][3] == "left" then
				moveSequence(state, insertMiddleLeft)
			else
				moveSequence(state, insertMiddleRight)
			end
			print("-------------------")
		elseif flipped[1] then
			local color = flipped[1][1]
			local edge = flipped[1][2]
			setOrientation(state, color, "grey")
			print("--- flip edge ---")
			moveSequence(state, {{3, 1}, {2, 4}, {3, 4}, {1, 4}, {2, 4}, {1, 1}})
			print("-----------------")
		end
		count, buried, flipped, active = countMiddleEdges(state)
	end
	state, moves = findState(state, {}, function(state)
		return countCorrectCorners1(state) == 5 and getPositionedMiddleEdge(state) and countMiddleEdges(state) >= count
	end, {1, 2, 3, 6, 10, 11})
	print("--- position edge ---")
	printMoveList(moves)
	print("---------------------")
	return state
end

local function solveMiddleEdges1(state) -- edges connecting 2-6 and 8-12
	local count = countMiddleEdges(state)
	while count ~= 10 do
		state = positionMiddleEdge(state)
		local color, direction = getPositionedMiddleEdge(state)
		setOrientation(state, colors[color], "grey")
		print("--- insert edge ---")
		if direction == "right" then
			moveSequence(state, insertMiddleRight)
		else
			moveSequence(state, insertMiddleLeft)
		end
		print("-------------------")
		count = countMiddleEdges(state)
		print("Middle edges: "..count.."/10")
		state = returnStateToDefaultOrientation(state)
	end
	return state
end

local function countCorrectCorners2(state) -- grey half middle layer corners
	state = setOrientation(state, "cyan", "grey")
	local count, buried = 0, {}
	for _, color in next, {8, 9, 10, 11, 12} do
		local face, index = getFaceFromColor(state, colors[color])
		local corner = getCorner(state, index, 6)
		if corner.colors[1] == corner.faces[1][7] and corner.colors[2] == corner.faces[2][7] then -- corner colors match center colors
			count = count + 1
		elseif corner.colors[1] ~= "7" and corner.colors[2] ~= "7" and corner.colors[3] ~= "7" then
			buried[#buried+1] = colors[color]
		end
	end
	return count, buried
end

local function solveCorners2(state) -- solve the 5 corners on the grey half
	setOrientation(state, "cyan", "grey")
	local function findCorner(state)
		for color = 8, 12 do
			local face, index = getFaceFromColor(state, colors[color])
			for _, corner in next, {getCorner(state, index, 1), getCorner(state, index, 1)} do
				local color1, color2, color3 = corner.colors[1], corner.colors[2], corner.colors[3]
				if color1 ~= "7" and color2 ~= "7" and color3 ~= "7" then
					local faces = {[corner.faces[1][7]] = true, [corner.faces[2][7]] = true, [corner.faces[3][7]] = true}
					local count = 0
					if faces[color1] then count = count + 1 end
					if faces[color2] then count = count + 1 end
					if faces[color3] then count = count + 1 end
					if count == 2 then
						return color, corner
					end
				end
			end
		end
	end
	local count, buried = countCorrectCorners2(state)
	while count ~= 5 do
		while buried[1] do
			setOrientation(state, buried[1], "grey")
			for turns, index in next, {3, 1, 6, 11, 8} do -- insert a corner with a grey side
				local corner = getCorner(state, 2, index)
				if corner.colors[1] == "7" or corner.colors[2] == "7" or corner.colors[3] == "7" then
					if turns ~= 1 then -- corner already in place
						print("--- position grey corner ---")
						moveSequence(state, {{2, turns-1}})
						print("----------------------------")
					end
					break
				end
			end
			print("--- remove corner ---")
			moveSequence(state, {{1, 1}, {2, 1}, {1, 4}})
			print("---------------------")
			count, buried = countCorrectCorners2(state)
			returnStateToDefaultOrientation(state)
		end
		setOrientation(state, "cyan", "grey")
		local moves;
		if not findCorner(state) then
			state, moves = findState(state, {}, function(state)
				return countCorrectCorners2(state) >= count and countCorrectCorners1(state) == 5 and findCorner(state)
			end, {1, 2, 3, 6, 10, 11})
			print("--- position corner ---")
			printMoveList(moves)
			print("-----------------------")
		end
		local color, corner = findCorner(state)
		if color ~= base[corner.colors[1]] then
			setOrientation(state, colors[color], "grey")
			if (color == base[corner.colors[2]] and corner.faces[2] == "7") or (color == base[corner.colors[3]] and corner.faces[3] == "7") then
				print("--- rotate corner clockwise ---")
				moveSequence(state, {{1, 1}, {2, 2}, {1, 4}, {2, 4}})
				print("-------------------------------")
			else
				print("--- rotate corner counter-clockwise ---")
				moveSequence(state, {{2, 1}, {1, 1}, {2, 3}, {1, 4}})
				print("---------------------------------------")
			end
		else
			state, moves = findState(state, {}, function(state)
				return countCorrectCorners2(state) > count and countCorrectCorners1(state) == 5
			end, {1, 2, 3, 6, 10, 11})
			count, buried = countCorrectCorners2(state)
			print("--- insert corner ---")
			printMoveList(moves)
			print("---------------------")
			print("corners solved: "..count.."/5")
		end
		returnStateToDefaultOrientation(state)
	end
	return returnStateToDefaultOrientation(state)
end

local function solveMiddleEdges2(state) -- edges in-between faces 8-12
	setOrientation(state, "cyan", "grey")
	local function countEdges(state)
		local count, buried = 0, {}
		for color = 8, 12 do
			local face, index = getFaceFromColor(state, colors[color])
			local edge = getEdge(state, index, 4)
			if edge[1] == edge.faces[1][7] and edge[2] == edge.faces[2][7] then
				count = count + 1
			elseif edge[1] ~= "7" and edge[2] ~= "7" then
				buried[#buried+1] = colors[color]
			end
		end
		return count, buried
	end
	local function findEdge(state)
		for color = 8, 12 do
			local face, index = getFaceFromColor(state, colors[color])
			local edge = getEdge(state, index, 2)
			if edge[1] == face[7] and edge[2] ~= "7" then
				local left = getEdge(state, index, 4).faces[2][7]
				return colors[color], edge[2] == left and "left" or "right"
			end
		end
	end
	local function position(state)
		if not findEdge(state) then
			print("--- position edge ---")
			local moves;
			state, moves = findState(state, {}, function(state)
				for color = 8, 12 do
					local face, index = getFaceFromColor(state, colors[color])
					local edge = getEdge(state, index, 2)
					if edge[1] == face[7] and edge[2] ~= "7" then
						return true
					end
				end
			end, {2})
			printMoveList(moves)
			print("---------------------")
		end
		return state
	end
	local count, buried = countEdges(state)
	while count ~= 5 do
		while count ~= 5 and count + #buried == 5 do
			setOrientation(state, buried[1], "grey")
			print("--- remove edge ---")
			moveSequence(state, insertLeft)
			print("-------------------")
			count, buried = countEdges(state)
		end
		state = position(state)
		local color, direction = findEdge(state)
		setOrientation(state, color, "grey")
		print("--- insert edge ---")
		moveSequence(state, direction == "left" and insertLeft or insertRight)
		print("-------------------")
		count, buried = countEdges(state)
	end
	return returnStateToDefaultOrientation(state)
end

local function solveGreyStar(state)
	local function countGreyEdges(state)
		local count = 0
		local face = getFaceFromColor(state, "grey")
		for _, edge in next, {2, 4, 5, 9, 10} do
			if face[edge] == "7" then
				count = count + 1
			end
		end
		return count
	end
	local sequence = {{1, 1}, {2, 1}, {3, 1}, {2, 4}, {3, 4}, {1, 4}}
	local count = countGreyEdges(state)
	while count ~= 5 do
		print("--- move grey edges ---")
		for color = 8, 12 do
			setOrientation(state, colors[color], "grey")
			if count == 0
			 or (state[2][4] == "7" and state[2][5] == "7" and state[2][10] == "7")
			 or (state[2][5] == "7" and state[2][9] == "7" and state[2][10] == "7")
			 or (count == 1 and state[2][5] == "7") then
				moveSequence(state, sequence)
				break
			end
		end
		print("-----------------------")
		count = countGreyEdges(state)
	end
	return returnStateToDefaultOrientation(state)
end

local function checkGreyEdgesSolved(state)
	for _, index in next, {2, 4, 5, 9, 10} do
		local edge = getEdge(state, 2, index)
		if edge[2] ~= edge.faces[2][7] then
			return false
		end
	end
	return true
end

local function permuteGreyEdges(state)
	local sequence = {{3, 1}, {2, 1}, {3, 4}, {2, 1}, {3, 1}, {2, 3}, {3, 4}, {2, 1}}
	setOrientation(state, "cyan", "grey")
	if checkGreyEdgesSolved(state) then return returnStateToDefaultOrientation(state) end
	local states = {{state, {}}}
	local copy = copyState(state)
	for i = 1, 4 do
		copy = turnFace(copyState(copy), 2, 1)
		states[#states+1] = {copy, {{7, i}}}
	end
	while true do
		local pair = table.remove(states, 1)
		local state, moves = pair[1], pair[2]
		if checkGreyEdgesSolved(state) then
			print("--- permute grey edges ---")
			printMoveList(moves)
			print("--------------------------")
			return returnStateToDefaultOrientation(state)
		end
		for color = 8, 12 do
			local new = copyState(state)
			setOrientation(new, colors[color], "grey")
			local newMoves = {table.unpack(moves)}
			for i = 1, #sequence do
				local move = {base[new[sequence[i][1]][7]], sequence[i][2]}
				newMoves[#newMoves+1] = move
				turnFace(new, sequence[i][1], sequence[i][2])
			end
			states[#states+1] = {new, newMoves}
		end
	end
end

local function permuteGreyCorners(state)
	local sequence = {{6, 4}, {2, 2}, {3, 1}, {2, 3}, {6, 1}, {2, 2}, {3, 4}, {2, 3}}
	setOrientation(state, "cyan", "grey")
	local function checkSolved(state)
		if not checkGreyEdgesSolved(state) then return false end
		for _, index in next, {1, 3, 6, 8, 11} do
			local corner = getCorner(state, 2, index)
			local check = {[corner.colors[1]] = true, [corner.colors[2]] = true, [corner.colors[3]] = true}
			if not check[corner.faces[2][7]] or not check[corner.faces[3][7]] then
				return false
			end
		end
		return true
	end
	if checkSolved(state) then return returnStateToDefaultOrientation(state) end
	local states = {{state, {}}}
	local copy = copyState(state)
	for i = 1, 4 do
		copy = turnFace(copyState(copy), 2, 1)
		states[#states+1] = {copy, {{7, i}}}
	end
	while true do
		local pair = table.remove(states, 1)
		local state, moves = pair[1], pair[2]
		if checkSolved(state) then
			print("--- permute grey corners ---")
			printMoveList(moves)
			print("--------------------------")
			return returnStateToDefaultOrientation(state)
		end
		for color = 8, 12 do
			local new = copyState(state)
			setOrientation(new, colors[color], "grey")
			local newMoves = {table.unpack(moves)}
			for i = 1, #sequence do
				local move = {base[new[sequence[i][1]][7]], sequence[i][2]}
				newMoves[#newMoves+1] = move
				turnFace(new, sequence[i][1], sequence[i][2])
			end
			states[#states+1] = {new, newMoves}
		end
	end
end

local function solveGreyCorners(state)
	setOrientation(state, "cyan", "grey")
	local function checkSolved(state)
		for i = 1, 11 do
			if state[2][i] ~= "7" then
				return false
			end
		end
		return true
	end
	while not checkSolved(state) do
		for turns, index in next, {1, 6, 11, 8, 3} do  -- position an unsolved corner
			if state[2][index] ~= "7" then
				if turns ~= 1 then -- corner already in place
					print("--- position grey corner ---")
					moveSequence(state, {{2, turns-1}})
					print("----------------------------")
				end
				break
			end
		end
		print("--- solve grey corner ---")
		while state[2][1] ~= "7" do
			moveSequence(state, {{3, 4}, {4, 4}, {3, 1}, {4, 1}})
		end
		print("-------------------------")
	end
	local function checkCorrectRotation(state)
		return getEdge(state, 2, 2)[2] == "8"
	end
	if checkCorrectRotation(state) then return state end
	state, moves = findState(state, {}, function(state)
		return checkCorrectRotation(state)
	end, {2})
	printMoveList(moves)
	return returnStateToDefaultOrientation(state)
end

local state = {}
local function loadLongInput(input)
	for v in input:gmatch("[^\n]+") do
		local t = {}
		for w in v:gmatch("%S+") do
			if not colors[w] then print(w) end
			t[#t+1] = base[colors[w]]
		end
		assert(#t == 11, #t.." colors on face "..#state)
		state[#state+1] = t
	end
	assert(#state == 12, #state.." faces")
end
local function loadInput(input)
	for v in (input):gmatch("%S+") do
		state[#state+1] = expand(v)
	end
	for v in input:gmatch("%S+") do
		print((v:gsub(".", function(c) return colors[base[c]].." " end)))
	end
end
local function generateScramble(steps, seed)
	seed = seed or os.time()
	math.randomseed(seed)
	print("seed: "..seed)
	return scrambleState(copyState(solvedState), steps or 10)
end
-- "white", "blue", "red", "green", "purple", "yellow", "grey", "cyan", "lyellow", "pink", "lgreen", "orange"
loadLongInput([[red red grey pink purple white white lyellow purple yellow lgreen
pink pink pink lyellow cyan blue blue grey orange pink yellow
lgreen cyan white green lgreen red red lgreen blue orange blue
green green yellow orange lyellow yellow green yellow yellow lgreen pink
purple purple green grey yellow orange purple grey orange orange green
orange purple blue lyellow grey green yellow purple blue grey orange
pink yellow cyan green blue orange grey purple pink lyellow lgreen
lyellow white lyellow grey red cyan cyan red white white white
grey cyan lyellow lgreen lgreen green lyellow white red yellow yellow
red cyan orange grey red blue pink pink white green cyan
purple blue cyan green pink blue lgreen red lgreen blue purple
lyellow lyellow grey purple cyan lgreen orange cyan white red white]])
--loadInput("11111111111 222222272aa 33333333333 77744444444 99955555555 96666666666 275277747a6 8ca88888888 ccc99899899 aa7abaab595 bbacb2bbb7b 44bcbccccac")
--state = generateScramble(10)

local steps = {
	{solveWhiteStar, "solve white star", "solved white star"};
	{solveWhiteCorners, "solve white face", "solved white face"};
	{solveSecondLayer, "solve second layer", "solved second layer"};
	{solveCorners1, "solve bottom 5 corners", "solved first 5 corners"};
	{solveMiddleEdges1, "solve bottom 10 edges", "solved 10 middle edges"};
	{solveCorners2, "solve middle 5 corners", "solved second 5 corners"};
	{solveMiddleEdges2, "solve middle 5 edges", "solved 5 middle edges"};
	{solveGreyStar, "solve grey star", "solved grey star"};
	{permuteGreyEdges, "permute grey edges", "permuted grey edges"};
	{permuteGreyCorners, "permute grey corners", "permuted grey corners"};
	{solveGreyCorners, "solve grey corners", "solved grey corners"};
}
-- 1555712746 solveWhiteStar 37.947241783142
-- 1555712652 solveMiddleEdges1 28.925415039062
-- 1555731571 solveWhiteStar 66.267526388168
-- 1555732156 solveSecondLayer 11.728622674942
-- 1555732003 solveWhiteStar 106.88071632385
local times = {66.267526388168, 1.6490550041199, 26.597831487656, 6.6231844425201, 45.765759706497, 2.7544193267822, 0.088949918746948, 0.012991666793823, 1.1059844493866, 4.8908445835114, 0.77863430976868}

local function solve(state)
	local slower = {}
	for i = 1, #steps do
		local clock = tick()
		print(steps[i][2])
		state = steps[i][1](state)
		print(steps[i][3])
		displayState(state)
		local time = tick() - clock
		print("(step took "..time.." seconds)\n")
		if time > times[i] then
			slower[#slower+1] = "step "..i.." ("..steps[i][2].."): +"..(time - times[i])
		end
		times[i] = math.max(times[i], time)
	end
	for i = 1, #slower do print(slower[i]) end
	print("{"..table.concat(times, ", ").."}")
end

solve(state)
--[[for i = 1, 10 do
	solve(generateScramble(10))
	print("solved "..i)
end]]