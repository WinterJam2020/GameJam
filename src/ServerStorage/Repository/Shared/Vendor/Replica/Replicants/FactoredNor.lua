local FactoredOr = require(script.Parent.FactoredOr)
local FactoredNor, Members, Super = FactoredOr.Extend()
local Metatable = {__index = Members}

function Members:Pairs()
	return next, self.Wrapped, nil
end

function Members:ResolveState()
	return not Super.ResolveState(self)
end

FactoredNor.SerialType = "FactoredNorReplicant"
function FactoredNor.new(...)
	local self = setmetatable({}, Metatable)
	FactoredNor.Constructor(self, ...)
	return self
end

return FactoredNor