--[[
	face structure
	{   1, 2, 3,
	   4,      5,
	  6,   7,   8,
	    9,    a,
		   b
	}

	color order, clockwise from top

	white   blue  red     green   purple  yellow
	blue    white yellow  lgreen  pink    red
	red     white blue    pink    lyellow green
	green   white red     lyellow cyan    purple
	purple  white green   cyan    orange  yellow
	yellow  white purple  orange  lgreen  blue
	grey    cyan  lyellow pink    lgreen  orange
	cyan    grey  orange  purple  green   lyellow
	lyellow grey  cyan    green   red     pink
	pink    grey  lyellow red     blue    lgreen
	lgreen  grey  pink    blue    yellow  orange
	orange  grey  lgreen  yellow  purple  cyan
	
	"64192b73a58"				"b96a4871523"
		6, 4, 1,  clockwise		    b, 9, 6,  clockwise twice
	   9,      2,				   a,      4,
	  b,   7,   3,				  8,   7,   1,
		a,    5,				    5,    2,
		   8						   3

	"3582a17b496"				"8ab59376241"
		3, 5, 8,  counter-		    8, a, b,  counter-clockwise twice
	   2,      a, clockwise		   5,      9,
	  1,   7,   b,				  3,   7,   6,
		4,    9,				    2,    4,
		   6						   1

	"123456789ab"
		1, 2, 3,  identity
	   4,      5,
	  6,   7,   8,
		9,    a,
		   b

face order: front face, top face, right face, right bottom face, left bottom face, left face,
back face (face opposite the front face), opposite top, opposite right, opposite right bottom, opposite left bottom, opposite left
the array "clockwise" describes how the faces move when the whole puzzle is rotated clockwise
face 1 is the center, and then 2-6 rotate from 23456 to 62345, where the left face (6) becomes the top face (2)
the back face (7) is also fixed, and its adjacent faces 8-13 rotate from 89abc to c89ab
thus the clockwise transformation is 1 62345 7 9abc8

each face has a "top" that gives context to the order of positions on the face
the top of the front face is the top face, and the top of the top face is the front face
the top face is the top of all of its adjacent faces, and the bottom face (opposite the top face) is the top of all of its adjacent faces
when the whole puzzle is moved, the front face or the top face changes. when it is turned right, the front face changes, and when it is rotated clockwise, the top face changes.
these moves involve switching the positions of the faces, but it also involves rotating the order of the positions on each face (without them actually being moved) to adjust for the new context.
for instance, after a clockwise turn, the "top" of the left face used to be the top face, but the left face was moved on top, so now the "top" of it is in the direction of the new right face, so the represented order of the positions on the face needs to be rotated clockwise once.

clockwise transformation
	first index is the new face, second rotates the color order
	{"1", 1}; -- front face
	{"6", 4}; -- top face
	{"2", 1}; -- right face
	{"3", 2}; -- bottom right face
	{"4", 4}; -- bottom left face
	{"5", 2}; -- left face
	{"7", 4}; -- back face
	{"9", 4}; -- top relative to the back face
	{"a", 4}; -- right relative to the back face
	{"b", 3}; -- bottom right relative to the back face
	{"c", 1}; -- bottom left relative to the back face
	{"8", 3}; -- left relative to the back face
]]

require("utils")

colors = {"white", "blue", "red", "green", "purple", "yellow", "grey", "cyan", "lyellow", "pink", "lgreen", "orange"}
for i = 1, #colors do colors[colors[i]] = i end -- map colors to indices

function displayOrientation(o)
	local rotationNames = {[0] = "no rotation", "clockwise", "clockwise twice", "counter-clockwise twice", "counter-clockwise"}
	local rotationNames2 = {[0] = "", "cw", "cw2", "ccw2", "ccw"}
	local faceNames = {"front", "top", "right", "bottom right", "bottom left", "left", "front'", "top'", "right'", "bottom right'", "bottom left'", "left'"}
	local faceNames2 = {"F", "T", "R", "r", "l", "L", "F'", "T'", "R'", "r'", "l'", "L'"}
	local faces, rotations = o[1], o[2]
	print(faces, rotations, o[3] or "")
	print(colors[tonumber(faces:sub(1, 1), 13)].." front, "..colors[tonumber(faces:sub(2, 2), 13)].." top")
	for i = 1, #faces do
		--print(("%13s %7s %23s"):format(faceNames[i], colors[tonumber(faces:sub(i, i), 13)], rotationNames[tonumber(rotations:sub(i, i))]))
		print(("%-2s %-7s %-4s"):format(faceNames2[i], colors[tonumber(faces:sub(i, i), 13)], rotationNames2[tonumber(rotations:sub(i, i))])) -- abbreviated version
	end
end

function displayState(state, detailed)
	if detailed then
		for i = 1, 12 do
			--print(colors[i], "("..i..")")
			local face = expand(collapse(state[i]))
			print(colors[tonumber(face[7], 13)])
			for j = 1, #face do
				--face[j] = colors[tonumber(face[j], 13)]
			end
			print("  "..face[1]..", "..face[2]..", "..face[3]..",")
			print(" "..face[4]..",      "..face[5]..",")
			print(face[6]..",   "..face[7]..",   "..face[8]..",")
			print("  "..face[9]..",    "..face[10]..",")
			print("     "..face[11])
		end
	end
	print(stateToString(state))
end