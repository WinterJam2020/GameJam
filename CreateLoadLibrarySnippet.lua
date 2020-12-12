local ServerStorage = game:GetService("ServerStorage")

local function ClassifyModuleScriptType(ModuleScript, TopParent)
	if TopParent then
		local FirstModuleScriptParent = ModuleScript:FindFirstAncestorOfClass("ModuleScript")
		if FirstModuleScriptParent and FirstModuleScriptParent:IsDescendantOf(TopParent) then
			return "Submodule"
		end
	end

	local Parent = ModuleScript.Parent
	while Parent and Parent ~= TopParent do
		local ParentName = Parent.Name
		if ParentName == "Server" or ParentName == "Client" then
			return ParentName
		end

		Parent = Parent.Parent
	end

	return "Shared"
end

local Array = {}
local Length = 0
local Parent = ServerStorage.Repository

for _, Descendant in ipairs(Parent:GetDescendants()) do
	if Descendant:IsA("ModuleScript") and ClassifyModuleScriptType(Descendant, Parent) ~= "Submodule" then
		Length += 1
		Array[Length] = Descendant.Name
	end
end

print(string.format("\"local ${1|%s|} = Resources:LoadLibrary(\\\"$1\\\")$0\"", table.concat(Array, ",")))
return false