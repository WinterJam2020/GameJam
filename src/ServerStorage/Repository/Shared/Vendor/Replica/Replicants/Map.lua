local Replicant = require(script.Parent.Parent.Replicant)
local Map, Members = Replicant.Extend()
local Metatable = {__index = Members}

function Members:Pairs()
	return next, self.Wrapped, nil
end

function Members:_SetLocal(Key, Value)
	if type(Key) ~= "string" then
		error("Map Replicant keys must be strings")
	end

	self.Wrapped[Key] = Value
end

Map.SerialType = "MapReplicant"
function Map.Constructor(self, InitialValues, ...)
	Replicant.Constructor(self, ...)

	if InitialValues ~= nil then
		for Key, Value in next, InitialValues do
			self:_SetLocal(Key, Value)
		end
	end
end

function Map.new(...)
	local self = setmetatable({}, Metatable)
	Map.Constructor(self, ...)
	return self
end

return Map