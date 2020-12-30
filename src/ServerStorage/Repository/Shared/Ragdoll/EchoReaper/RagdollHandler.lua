-- EchoReaper
-- Might use this instead, since Quenty's has no docs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Services = Resources:LoadLibrary("Services")
local Typer = Resources:LoadLibrary("Typer")

local Players: Players = Services.Players
local CollectionService: CollectionService = Services.CollectionService
local RunService: RunService = Services.RunService

local RagdollHandler = {}

local RAGDOLL_STATES = {
	[Enum.HumanoidStateType.Dead] = true;
	[Enum.HumanoidStateType.Physics] = true;
}

local function SetRagdollEnabled(Humanoid: Humanoid, IsEnabled: boolean)
	local RagdollConstraints = Humanoid.Parent:FindFirstChild("RagdollConstraints")

	for _, Constraint in ipairs(RagdollConstraints:GetChildren()) do
		if Constraint:IsA("Constraint") then
			local RigidJoint = Constraint.RigidJoint.Value
			local ExpectedValue = not IsEnabled and Constraint.Attachment1.Parent or nil

			if RigidJoint.Part1 ~= ExpectedValue then
				RigidJoint.Part1 = ExpectedValue
			end
		end
	end
end

local function HasRagdollOwnership(Humanoid: Humanoid): boolean
	if RunService:IsServer() then
		return true
	else
		return Players:GetPlayerFromCharacter(Humanoid.Parent) == Players.LocalPlayer
	end
end

local function RagdollAdded(Humanoid: Humanoid)
	RagdollHandler.Connections[Humanoid] = Humanoid.StateChanged:Connect(function(_, NewState)
		if HasRagdollOwnership(Humanoid) then
			if RAGDOLL_STATES[NewState] then
				SetRagdollEnabled(Humanoid, true)
			else
				SetRagdollEnabled(Humanoid, false)
			end
		end
	end)
end

local function RagdollRemoved(Humanoid: Humanoid)
	RagdollHandler.Connections[Humanoid] = RagdollHandler.Connections[Humanoid]:Disconnect()
end

RagdollHandler.Initialize = Typer.AssignSignature(2, Typer.OptionalString, function(self, TagName: string?)
	self.TagName = TagName or "Ragdoll"
	self.Connections = {}

	CollectionService:GetInstanceAddedSignal(self.TagName):Connect(RagdollAdded)
	CollectionService:GetInstanceRemovedSignal(self.TagName):Connect(RagdollRemoved)
	for _, Humanoid in ipairs(CollectionService:GetTagged(self.TagName)) do
		RagdollAdded(Humanoid)
	end
end)

return RagdollHandler