local function copy(list)
	assert(type(list) == "table", "expected a table for first argument, got " .. typeof(list))
	local new = table.create(#list)
	for index, value in ipairs(list) do
		new[index] = value
	end

	return new
end

return copy