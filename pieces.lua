adjacent = {"23456", "16ba3", "2a941", "85139", "8c614", "215cb", "89abc", "7c549", "843a7", "2b793", "26c7a", "87b65"}
for i = 1, #adjacent do
	adjacent[i] = expand(adjacent[i], true)
end

local edges = {"24a95", "22222", "44a95", "94a95", "a4a95", "54a95", "24a95", "22222", "44a95", "94a95", "a4a95", "54a95"}
for i = 1, #edges do
	local indices = expand("25a94", true) -- edge position order on each face
	local positions = expand(edges[i], true) -- corresponding edge position on adjacent face
	local map = {}
	for j = 1, #indices do
		map[indices[j]] = positions[j]
	end
	edges[i] = map
end

local cornerlist = {
	{{1, 3}, {2, 1}, {3, 1}}; -- white blue red
	{{1, 1}, {2, 3}, {6, 3}}; -- white blue yellow
	{{1, 8}, {3, 6}, {4,11}}; -- white red green
	{{1,11}, {4, 8}, {5, 6}}; -- white purple green
	{{1, 6}, {5,11}, {6, 8}}; -- white yellow purple
	{{2, 6}, {3, 3}, {10,1}}; -- blue red pink
	{{2, 8}, {6, 1}, {11,3}}; -- blue yellow lgreen
	{{2,11}, {10,3}, {11,1}}; -- blue lgreen pink
	{{3,11}, {4, 6}, {9, 8}}; -- red green lyellow
	{{3, 8}, {9,11}, {10,6}}; -- red pink lyellow
	{{4, 3}, {5, 1}, {8,11}}; -- green purple cyan
	{{4, 1}, {9, 3}, {8, 6}}; -- green lyellow cyan
	{{5, 8}, {6,11}, {12,6}}; -- purple yellow orange
	{{5, 3}, {8, 8}, {12,1}}; -- purple cyan orange
	{{6, 6}, {11,8}, {12,11}}; -- yellow orange lgreen
	{{7, 3}, {8, 1}, {9, 1}}; -- grey cyan lyellow
	{{7, 1}, {8, 3}, {12,3}}; -- grey cyan orange
	{{7, 6}, {11,11},{12,8}}; -- grey lgreen orange
	{{7,11}, {10,8}, {11,6}}; -- grey pink lgreen
	{{7, 8}, {9, 6}, {10,11}}; -- grey lyellow pink
}
local corners = {}
for i = 1, 12 do corners[i] = {} end
for _, c in next, cornerlist do
	corners[c[1][1]][c[1][2]] = {c[1], c[2], c[3]}
	corners[c[2][1]][c[2][2]] = {c[2], c[1], c[3]}
	corners[c[3][1]][c[3][2]] = {c[3], c[1], c[2]}
end

function getEdge(state, face, index)
	local edgemap = {[2] = 1, [5] = 2, [10] = 3, [9] = 4, [4] = 5}
	local faces = {state[face], state[adjacent[face][edgemap[index]]]}
	return {
		faces[1][index],
		faces[2][edges[face][index]],
		faces = faces
	}
end

function getCorner(state, face, index)
	local c = corners[face][index]
	return {
		faces = {state[c[1][1]], state[c[2][1]], state[c[3][1]]};
		positions = {c[1][2], c[2][2], c[3][2]};
		colors = {state[c[1][1]][c[1][2]], state[c[2][1]][c[2][2]], state[c[3][1]][c[3][2]]}
	}
end

function getCenter(state, face)
	return state[face][7]
end

function getFaceFromColor(state, color) -- face on the current orientation
	local face = colors[color]
	for i = 1, 12 do
		if base[state[i][7]] == face then
			return state[i], i
		end
	end
end