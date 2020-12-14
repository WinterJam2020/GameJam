--- Base class for ragdolls, meant to be used with binders
-- @classmod Ragdoll

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local BaseObject = Resources:LoadLibrary("BaseObject")

local Ragdoll = setmetatable({ClassName = "Ragdoll"}, BaseObject)
Ragdoll.__index = Ragdoll

function Ragdoll.new(Humanoid: Humanoid)
	return setmetatable(BaseObject.new(Humanoid), Ragdoll)
end

return Ragdoll