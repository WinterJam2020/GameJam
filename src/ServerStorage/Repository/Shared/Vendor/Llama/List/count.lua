local function alwaysTrue()
	return true
end

local function count(list, predicate)
	assert(type(list) == "table", "expected a table for first argument, got " .. typeof(list))
	predicate = predicate or alwaysTrue

	local counter = 0
	for index, value in ipairs(list) do
		if predicate(value, index) then
			counter += 1
		end
	end

	return counter
end

return count