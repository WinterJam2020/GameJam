local join = require(script.Parent.join)
local function assign(list, patch)
	return join(patch, list)
end

return assign