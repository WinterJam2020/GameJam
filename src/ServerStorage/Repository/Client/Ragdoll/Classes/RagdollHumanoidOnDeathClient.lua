--- Ragdolls the humanoid on death
-- @classmod RagdollHumanoidOnDeathClient
-- @author Quenty

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)

local BaseObject = Resources:LoadLibrary("BaseObject")
local CharacterUtils = Resources:LoadLibrary("CharacterUtils")
local RagdollBindersClient = Resources:LoadLibrary("RagdollBindersClient")
local RagdollRigging = Resources:LoadLibrary("RagdollRigging")

local RagdollHumanoidOnDeathClient = setmetatable({ClassName = "RagdollHumanoidOnDeathClient"}, BaseObject)
RagdollHumanoidOnDeathClient.__index = RagdollHumanoidOnDeathClient

function RagdollHumanoidOnDeathClient.new(Humanoid: Humanoid)
	local self = setmetatable(BaseObject.new(Humanoid), RagdollHumanoidOnDeathClient)

	if self.Object:GetState() == Enum.HumanoidStateType.Dead then
		self:_HandleDeath()
	else
		self.Janitor:Add(self.Object.Died:Connect(function()
			self:_HandleDeath()
		end), "Disconnect", "DiedEvent")
	end

	return self
end

function RagdollHumanoidOnDeathClient:_HandleDeath()
	-- Disconnect!
	self.Janitor:Remove("DiedEvent")
	if CharacterUtils.GetPlayerFromCharacter(self.Object) == Players.LocalPlayer then
		RagdollBindersClient.Ragdoll:BindClient(self.Object)
	end

	local Character = self.Object.Parent
	delay(Players.RespawnTime - 0.5, function()
		if not Character:IsDescendantOf(Workspace) then
			return
		end

		-- fade into the mist...
		RagdollRigging.DisableParticleEmittersAndFadeOutYielding(Character, 0.4)
	end)
end

return RagdollHumanoidOnDeathClient