require("utils")

Map = {
	new = function(str)
		local map = str and expand(str, true) or {}
		return setmetatable(map, {
			__index = Map;
			__tostring = collapse
		})
	end;
	transform = function(self, transformation, ...)
		local new = Map.new()
		for i = 1, #transformation do
			new[i] = self[transformation[i]]
		end
		return ... and new:transform(...) or new
	end;
	invert = function(self) -- map:transform(map:invert()) = identity
		local inverse, dict = Map.new(), {}
		for i = 1, #self do
			dict[self[i]] = i
		end
		for i = 1, #self do
			inverse[i] = dict[i]
		end
		return inverse
	end
}