local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)

local BaseObject = Resources:LoadLibrary("BaseObject")
local BindableRagdollHumanoidOnFall = Resources:LoadLibrary("BindableRagdollHumanoidOnFall")
local CharacterUtils = Resources:LoadLibrary("CharacterUtils")
local RagdollBindersClient = Resources:LoadLibrary("RagdollBindersClient")
local RagdollHumanoidOnFallConstants = Resources:LoadLibrary("RagdollHumanoidOnFallConstants")

local RagdollHumanoidOnFallClient = setmetatable({ClassName = "RagdollHumanoidOnFallClient"}, BaseObject)
RagdollHumanoidOnFallClient.__index = RagdollHumanoidOnFallClient

Resources:LoadLibrary("PromiseRemoteEventMixin"):Add(RagdollHumanoidOnFallClient, RagdollHumanoidOnFallConstants.REMOTE_EVENT_NAME, true)

function RagdollHumanoidOnFallClient.new(Humanoid: Humanoid)
	local self = setmetatable(BaseObject.new(Humanoid), RagdollHumanoidOnFallClient)

	local Player = CharacterUtils.GetPlayerFromCharacter(Humanoid)
	if Player == Players.LocalPlayer then
		self.RagdollLogic = self.Janitor:Add(BindableRagdollHumanoidOnFall.new(self.Object, RagdollBindersClient.Ragdoll), "Destroy")
		self.Janitor:Add(self.RagdollLogic.ShouldRagdoll.Changed:Connect(function()
			self:_Update()
		end), "Disconnect")
	end

	return self
end

function RagdollHumanoidOnFallClient:_Update()
	if self.RagdollLogic.ShouldRagdoll.Value then
		RagdollBindersClient.Ragdoll:BindClient(self.Object)
		self:PromiseRemoteEvent():Then(function(RemoteEvent: RemoteEvent)
			RemoteEvent:FireServer(true)
		end)
	end
end

return RagdollHumanoidOnFallClient