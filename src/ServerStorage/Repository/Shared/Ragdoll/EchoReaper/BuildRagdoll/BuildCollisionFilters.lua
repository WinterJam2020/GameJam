local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Typer = Resources:LoadLibrary("Typer")
local GetLastWordFromPascalCase = require(script.Parent.GetLastWordFromPascalCase)

local LIMB_TYPE_ALIASES = {
	Hand = "Arm";
	Foot = "Leg";
}

local function GetLimbType(LimbName: string): string
	local LimbType: string = GetLastWordFromPascalCase(LimbName)
	return LIMB_TYPE_ALIASES[LimbType] or LimbType
end

local function GetLimbs(CharacterRoot, AttachmentMap)
	local Limbs = {}
	local LimbRootParts = {}
	local LimbParents = {}

	local function ParsePart(Part, LastLimb)
		if Part.Name ~= "HumanoidRootPart" then
			local LimbType = GetLimbType(Part.Name)
			Limbs[LimbType] = Limbs[LimbType] or {}
			table.insert(Limbs[LimbType], Part)

			if LimbType ~= LastLimb then
				LimbParents[LimbType] = LimbParents[LimbType] or {}
				if LastLimb then
					LimbParents[LimbType][LastLimb] = true
				end

				table.insert(LimbRootParts, {Part = Part, Type = LimbType})
				LastLimb = LimbType
			end
		end

		for _, Child in ipairs(Part:GetChildren()) do
			if Child:IsA("Attachment") and AttachmentMap[Child.Name] then
				local Part1 = AttachmentMap[Child.Name].Attachment1.Parent
				if Part1 and Part1 ~= Part then
					ParsePart(Part1, LastLimb)
				end
			end
		end
	end

	ParsePart(CharacterRoot)
	return Limbs, LimbRootParts, LimbParents
end

local function CreateNoCollision(Part0, Part1): NoCollisionConstraint
	local NoCollisionConstraint = Instance.new("NoCollisionConstraint")
	NoCollisionConstraint.Name = Part0.Name .. "<->" .. Part1.Name
	NoCollisionConstraint.Part0 = Part0
	NoCollisionConstraint.Part1 = Part1
	return NoCollisionConstraint
end

local BuildCollisionFilters = Typer.AssignSignature(Typer.Table, Typer.InstanceWhichIsABasePart, function(AttachmentMap, CharacterRoot: BasePart): Folder
	local NoCollisionConstraints = Instance.new("Folder")
	NoCollisionConstraints.Name = "NoCollisionConstraints"

	local Limbs, LimbRootParts, LimbParents = GetLimbs(CharacterRoot, AttachmentMap)
	for Index, LimbRootPart in ipairs(LimbRootParts) do
		for Jndex = Index + 1, #LimbRootParts do
			local LimbType0, LimbType1 = LimbRootPart.Type, LimbRootParts[Jndex].Type

			if not (LimbParents[LimbType0][LimbType1] or LimbParents[LimbType1][LimbType0]) then
				CreateNoCollision(LimbRootPart.Part, LimbRootParts[Jndex].Part).Parent = NoCollisionConstraints
			end
		end
	end

	for LimbType, Parts in next, Limbs do
		for ParentLimbType in next, LimbParents[LimbType] do
			for _, Part2 in ipairs(Limbs[ParentLimbType]) do
				for _, Part in ipairs(Parts) do
					CreateNoCollision(Part, Part2).Parent = NoCollisionConstraints
				end
			end
		end
	end

	return NoCollisionConstraints
end)

return BuildCollisionFilters