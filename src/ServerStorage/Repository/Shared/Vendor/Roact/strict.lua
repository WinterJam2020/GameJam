local function strict(t, name)
	name = name or tostring(t)

	return setmetatable(t, {
		__index = function(_, key)
			error(string.format(
				"%q (%s) is not a valid member of %s",
				tostring(key),
				typeof(key),
				name
			), 2)
		end,

		__newindex = function(_, key)
			error(string.format(
				"%q (%s) is not a valid member of %s",
				tostring(key),
				typeof(key),
				name
			), 2)
		end,
	})
end

return strict