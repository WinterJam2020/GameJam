local function extend(original, extension)
	local new = table.create(#original + #extension)
	for index, value in next, original do
		new[index] = value
	end

	for index, value in next, extension do
		new[index] = value
	end

	return new
end

return extend