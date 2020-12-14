---
-- @classmod Ragdollable
-- @author Quenty

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local BaseObject = Resources:LoadLibrary("BaseObject")
local CharacterUtils = Resources:LoadLibrary("CharacterUtils")
local HumanoidAnimatorUtils = Resources:LoadLibrary("HumanoidAnimatorUtils")
local Janitor = Resources:LoadLibrary("Janitor")
local RagdollableConstants = Resources:LoadLibrary("RagdollableConstants")
local RagdollBindersServer = Resources:LoadLibrary("RagdollBindersServer")
local RagdollRigging = Resources:LoadLibrary("RagdollRigging")
local RagdollUtils = Resources:LoadLibrary("RagdollUtils")

local Ragdollable = setmetatable({ClassName = "Ragdollable"}, BaseObject)
Ragdollable.__index = Ragdollable

function Ragdollable.new(Humanoid: Humanoid)
	local self = setmetatable(BaseObject.new(Humanoid), Ragdollable)

	self.Object.BreakJointsOnDeath = false
	RagdollRigging.CreateRagdollJoints(self.Object.Parent, Humanoid.RigType)

	local Player = CharacterUtils.GetPlayerFromCharacter(self.Object)
	if Player then
		self.Player = Player

		self.RemoteEvent = self.Janitor:Add(Instance.new("RemoteEvent"), "Destroy")
		self.RemoteEvent.Name = RagdollableConstants.REMOTE_EVENT_NAME
		self.RemoteEvent.Parent = self.Object

		self.Janitor:Add(self.RemoteEvent.OnServerEvent:Connect(function(...)
			self:_HandleServerEvent(...)
		end), "Disconnect")
	else
		-- NPC
		self.Janitor:Add(RagdollBindersServer.Ragdoll:ObserveInstance(self.Object, function()
			self:_OnRagdollChangedForNPC()
		end), true)

		self:_OnRagdollChangedForNPC()
	end

	return self
end

function Ragdollable:_OnRagdollChangedForNPC()
	if RagdollBindersServer.Ragdoll:Get(self.Object) then
		self:_SetRagdollEnabled(true)
	else
		self:_SetRagdollEnabled(false)
	end
end

function Ragdollable:_HandleServerEvent(Player, State)
	assert(self.Player == Player)

	if State then
		RagdollBindersServer.Ragdoll:Bind(self.Object)
	else
		RagdollBindersServer.Ragdoll:Unbind(self.Object)
	end

	self:_SetRagdollEnabled(State)
end

function Ragdollable:_SetRagdollEnabled(IsEnabled)
	if IsEnabled then
		if not self.Janitor:Get("Ragdoll") then
			self.Janitor:Add(self:_EnableServer(), "Destroy", "Ragdoll")
		end
	else
		self.Janitor:Remove("Ragdoll")
	end
end

function Ragdollable:_EnableServer()
	local ServerJanitor = Janitor.new()
	RagdollRigging.CreateRagdollJoints(self.Object.Parent, self.Object.RigType)

	ServerJanitor:GiveTask(RagdollUtils.SetupState(self.Object))
	ServerJanitor:GiveTask(RagdollUtils.SetupMotors(self.Object))
	ServerJanitor:GiveTask(RagdollUtils.SetupHead(self.Object))
	ServerJanitor:GiveTask(RagdollUtils.PreventAnimationTransformLoop(self.Object))

	HumanoidAnimatorUtils.StopAnimations(self.Object, 0)

	ServerJanitor:Add(self.Object.AnimationPlayed:Connect(function(Track)
		Track:Stop(0)
	end), "Disconnect")

	return ServerJanitor
end

return Ragdollable