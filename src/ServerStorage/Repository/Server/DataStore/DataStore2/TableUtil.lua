local TableUtil = {}

function TableUtil.clone(tbl)
	local clone = {}

	for key, value in next, tbl do
		if type(value) == "table" then
			clone[key] = TableUtil.clone(value)
		else
			clone[key] = value
		end
	end

	return clone
end

return TableUtil
