local function copyDeep(list)
	assert(type(list) == "table", "expected a table for first argument, got " .. typeof(list))
	local new = table.create(#list)
	for index, value in ipairs(new) do
		if type(value) == "table" then
			new[index] = copyDeep(value)
		else
			new[index] = value
		end
	end

	return new
end

return copyDeep