local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Typer = Resources:LoadLibrary("Typer")
local GetLastWordFromPascalCase = require(script.Parent.GetLastWordFromPascalCase)

local Constraints = {}
for _, Constraint in ipairs(Resources:GetFolder("RagdollConstraints"):GetChildren()) do
	Constraints[Constraint.Name] = Constraint
end

local function GetConstraintTemplate(JointName: string): Constraint
	JointName = GetLastWordFromPascalCase(JointName)
	return Constraints[JointName] or Constraints.Default
end

local JointDataDefinition = Typer.MapDefinition {
	Joint = Typer.Instance;
	Attachment0 = Typer.Instance;
	Attachment1 = Typer.Instance;
}

local CreateConstraint = Typer.AssignSignature({JointData = JointDataDefinition}, function(JointData)
	local JointName = JointData.Joint.Name
	local Constraint = GetConstraintTemplate(JointName):Clone()

	Constraint.Attachment0 = JointData.Attachment0
	Constraint.Attachment1 = JointData.Attachment1
	Constraint.Name = JointName .. "RagdollConstraint"

	local RigidPointer = Instance.new("ObjectValue")
	RigidPointer.Name = "RigidJoint"
	RigidPointer.Value = JointData.Joint
	RigidPointer.Parent = Constraint

	return Constraint
end)

local BuildConstraints = Typer.AssignSignature(Typer.Table, function(AttachmentMap): Folder
	local RagdollConstraints = Instance.new("Folder")
	RagdollConstraints.Name = "RagdollConstraints"

	for _, JointData in next, AttachmentMap do
		if JointData.Joint.Name ~= "Root" then
			local RagdollConstraint = CreateConstraint(JointData)
			RagdollConstraint.Parent = RagdollConstraints
		end
	end

	return RagdollConstraints
end)

return BuildConstraints