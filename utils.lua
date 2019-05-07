function expand(s, asnumbers)
	local t = {}
	if asnumbers then
		for i = 1, #s do
			t[i] = tonumber(s:sub(i, i), 13)
		end
	else
		for i = 1, #s do
			t[i] = s:sub(i, i)
		end
	end
	return t
end

base = expand("123456789abc")
for i = 1, #base do
	base[base[i]] = i
end

function collapse(t)
	if type(t[1]) == "string" then
		return table.concat(t)
	else
		local s = ""
		for i = 1, #t do
			s = s..("%x"):format(t[i]) -- format as hexadecimal

		end
		return s
	end
end

function copyState(state)
	local copy = {}
	for i = 1, 12 do
		copy[i] = {}
		for j = 1, 11 do
			copy[i][j] = state[i][j]
		end
	end
	return copy
end

function stateToString(state)
	local faces = {}
	for i = 1, 12 do
		faces[i] = collapse(state[i])
	end
	return table.concat(faces, " ")
end

solvedState = {}
for i = 1, 12 do
	solvedState[i] = expand(base[i]:rep(11))
end