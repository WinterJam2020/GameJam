--- Ragdolls the humanoid on death
-- @classmod RagdollHumanoidOnDeath
-- @author Quenty

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local BaseObject = Resources:LoadLibrary("BaseObject")
local RagdollBindersServer = Resources:LoadLibrary("RagdollBindersServer")

local RagdollHumanoidOnDeath = setmetatable({ClassName = "RagdollHumanoidOnDeath"}, BaseObject)
RagdollHumanoidOnDeath.__index = RagdollHumanoidOnDeath

function RagdollHumanoidOnDeath.new(Humanoid: Humanoid)
	local self = setmetatable(BaseObject.new(Humanoid), RagdollHumanoidOnDeath)

	self.Janitor:Add(self.Object:GetPropertyChangedSignal("Health"):Connect(function()
		if self.Object.Health <= 0 then
			RagdollBindersServer.Ragdoll:Bind(self.Object)
		end
	end), "Disconnect")

	return self
end

return RagdollHumanoidOnDeath