local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)

local BaseObject = Resources:LoadLibrary("BaseObject")
local RagdollableConstants = Resources:LoadLibrary("RagdollableConstants")
local CharacterUtils = Resources:LoadLibrary("CharacterUtils")
local RagdollRigging = Resources:LoadLibrary("RagdollRigging")
local HumanoidAnimatorUtils = Resources:LoadLibrary("HumanoidAnimatorUtils")
local Janitor = Resources:LoadLibrary("Janitor")
local RagdollBindersClient = Resources:LoadLibrary("RagdollBindersClient")
local RagdollUtils = Resources:LoadLibrary("RagdollUtils")

local RagdollableClient = setmetatable({ClassName = "RagdollableClient"}, BaseObject)
RagdollableClient.__index = RagdollableClient

Resources:LoadLibrary("PromiseRemoteEventMixin"):Add(RagdollableClient, RagdollableConstants.REMOTE_EVENT_NAME, true)

function RagdollableClient.new(Humanoid: Humanoid)
	local self = setmetatable(BaseObject.new(Humanoid), RagdollableClient)

	self.Player = CharacterUtils.GetPlayerFromCharacter(Humanoid)
	if self.Player == Players.LocalPlayer then
		self:PromiseRemoteEvent():Then(function(RemoteEvent: RemoteEvent)
			self.LocalPlayerRemoteEvent = RemoteEvent or error("No RemoteEvent")
			self:_SetupLocal()
		end)
	else
		self:_SetupLocal()
	end

	return self
end

function RagdollableClient:_SetupLocal()
	self.Janitor:Add(RagdollBindersClient.Ragdoll:ObserveInstance(self.Object, function()
		self:_OnRagdollChanged()
	end), true)

	self:_OnRagdollChanged()
end

function RagdollableClient:_OnRagdollChanged()
	if RagdollBindersClient.Ragdoll:Get(self.Object) then
		self.Janitor:Add(self:_RagdollLocal(), "Destroy", "Ragdoll")
		if self.LocalPlayerRemoteEvent then
			-- Tell the server that we started simulating our ragdoll
			self.LocalPlayerRemoteEvent:FireServer(true)
		end
	else
		self.Janitor:Remove("Ragdoll")
		if self.LocalPlayerRemoteEvent then
			-- Let server know to reset!
			self.LocalPlayerRemoteEvent:FireServer(false)
		end
	end
end

function RagdollableClient:_RagdollLocal()
	local RagdollJanitor = Janitor.new()

	RagdollRigging.CreateRagdollJoints(self.Object.Parent, self.Object.RigType)

	RagdollJanitor:Add(RagdollUtils.SetupState(self.Object))
	RagdollJanitor:Add(RagdollUtils.SetupMotors(self.Object))
	RagdollJanitor:Add(RagdollUtils.SetupHead(self.Object))

	HumanoidAnimatorUtils.StopAnimations(self.Object, 0)
	RagdollJanitor:Add(self.Object.AnimationPlayed:Connect(function(Track)
		Track:Stop(0)
	end), "Disconnect")

	RagdollJanitor:Add(RagdollUtils.PreventAnimationTransformLoop(self.Object))
	return RagdollJanitor
end

return RagdollableClient