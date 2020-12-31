
local equalObjects = require(script.Parent.Parent.equalObjects)

local function equals(...)
	if equalObjects(...) then
		return true
	end

	local argc = select("#", ...)

	for i = 1, argc do
		local list = select(i, ...)

		for j = 1, argc do
			if j ~= i then
				local compare = select(j, ...)

				for k, value in ipairs(list) do
					if value ~= compare[k] then
						return false
					end
				end
			end
		end
	end

	return true
end

return equals