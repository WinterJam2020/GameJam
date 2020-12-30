local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Services = Resources:LoadLibrary("Services")
local Typer = Resources:LoadLibrary("Typer")

local CollectionService: CollectionService = Services.CollectionService

local BuildConstraints = require(script.BuildConstraints)
local BuildCollisionFilters = require(script.BuildCollisionFilters)

local function BuildAttachmentMap(Character: Model)
	local AttachmentMap = {}

	for _, Child in ipairs(Character:GetChildren()) do
		if Child:IsA("BasePart") then
			for _, Descendant in ipairs(Child:GetChildren()) do
				if Descendant:IsA("Attachment") then
					local JointName: string = string.match(Descendant.Name, "^(.+)RigAttachment$")
					local Joint = JointName and Descendant.Parent:FindFirstChild(JointName) or nil

					if Joint then
						AttachmentMap[Descendant.Name] = {
							Joint = Joint;
							Attachment0 = Joint.Part0[Descendant.Name];
							Attachment1 = Joint.Part1[Descendant.Name];
						}
					end
				end
			end
		end
	end

	return AttachmentMap
end

local BuildRagdoll = Typer.AssignSignature(Typer.InstanceWhichIsAHumanoid, Typer.OptionalString, function(Humanoid: Humanoid, TagName: string?)
	local Character: Model = Humanoid.Parent
	Humanoid.BreakJointsOnDeath = false

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	if HumanoidRootPart then
		HumanoidRootPart.CanCollide = false
	end

	local AttachmentMap = BuildAttachmentMap(Character)
	local RagdollConstraints = BuildConstraints(AttachmentMap)
	local CollisionFilters = BuildCollisionFilters(AttachmentMap, Character.PrimaryPart)

	CollisionFilters.Parent = RagdollConstraints
	RagdollConstraints.Parent = Character

	CollectionService:AddTag(Humanoid, TagName or "Ragdoll")
end)

return BuildRagdoll