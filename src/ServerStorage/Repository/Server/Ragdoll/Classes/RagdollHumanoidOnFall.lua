---
-- @classmod RagdollHumanoidOnFall
-- @author Quenty

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local BaseObject = Resources:LoadLibrary("BaseObject")
local BindableRagdollHumanoidOnFall = Resources:LoadLibrary("BindableRagdollHumanoidOnFall")
local CharacterUtils = Resources:LoadLibrary("CharacterUtils")
local RagdollBindersServer = Resources:LoadLibrary("RagdollBindersServer")
local RagdollHumanoidOnFallConstants = Resources:LoadLibrary("RagdollHumanoidOnFallConstants")

local RagdollHumanoidOnFall = setmetatable({ClassName = "RagdollHumanoidOnFall"}, BaseObject)
RagdollHumanoidOnFall.__index = RagdollHumanoidOnFall

function RagdollHumanoidOnFall.new(Humanoid: Humanoid)
	local self = setmetatable(BaseObject.new(Humanoid), RagdollHumanoidOnFall)

	local Player = CharacterUtils.GetPlayerFromCharacter(self.Object)
	if Player then
		self.Player = Player

		self.RemoteEvent = self.Janitor:Add(Instance.new("RemoteEvent"), "Destroy")
		self.RemoteEvent.Name = RagdollHumanoidOnFallConstants.REMOTE_EVENT_NAME
		self.RemoteEvent.Parent = self.Object

		self.Janitor:Add(self.RemoteEvent.OnServerEvent:Connect(function(...)
			self:_HandleServerEvent(...)
		end), "Disconnect")
	else
		self.RagdollLogic = self.Janitor:Add(BindableRagdollHumanoidOnFall.new(self.Object, RagdollBindersServer.Ragdoll), "Destroy")
		self.Janitor:Add(self.RagdollLogic.ShouldRagdoll.Changed:Connect(function()
			self:_Update()
		end), "Disconnect")
	end

	return self
end

function RagdollHumanoidOnFall:_HandleServerEvent(Player, Value: boolean)
	assert(Player == self.Player)
	assert(type(Value) == "boolean")

	if Value then
		RagdollBindersServer.Ragdoll:Bind(self.Object)
	else
		RagdollBindersServer.Ragdoll:Unbind(self.Object)
	end
end

function RagdollHumanoidOnFall:_Update()
	if self.RagdollLogic.ShouldRagdoll.Value then
		RagdollBindersServer.Ragdoll:Bind(self.Object)
	else
		if self.Object.Health > 0 then
			RagdollBindersServer.Ragdoll:Unbind(self.Object)
		end
	end
end

return RagdollHumanoidOnFall