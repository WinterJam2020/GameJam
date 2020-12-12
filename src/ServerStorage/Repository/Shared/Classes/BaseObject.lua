local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Janitor = Resources:LoadLibrary("Janitor")

local BaseObject = {ClassName = "BaseObject"}
BaseObject.__index = BaseObject

function BaseObject.new(Object)
	return setmetatable({
		Janitor = Janitor.new();
		Object = Object;
	}, BaseObject)
end

function BaseObject:Destroy()
	self.Janitor:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

return BaseObject