--[[
    BEHAVIOR TREE CREATOR V4

	Originally by tyridge77: https://devforum.roblox.com/t/btrees-visual-editor-v2-0/461015
	Forked and improved by defaultio


	Changes by tyridge77(November 23rd, 2020)
	- Trees are now created only once, and decoupled from objects
	- You now create trees simply by doing BehaviorTreeCreator:Create(treeFolder) - if a tree is already made for that folder it'll return that
	- You now run Trees via Tree:Run(object)
	- You can now abort a tree via Tree:Abort(object) , used for switching between trees but still calling finish on the previously running task
	- Added support for live debugging
	- Added BehaviorTreeCreator:RegisterBlackboard(name,table)
		- This is used in conjunction with the new blackboard query node
	- Changed up some various internal stuff
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Resources = require(ReplicatedStorage.Resources)
local BehaviorTree3 = Resources:LoadLibrary("BehaviorTree3")

local TREE_TAG = "_BTree"

local TreeCreator = {}

local Trees = {}
local SourceTasks = {}
local TreeIds = {}

--------------------------------------------
-------------- PUBLIC METHODS --------------

-- Create tree object from a treeFolder.
function TreeCreator:Create(TreeFolder)
	assert(TreeFolder, "Invalid parameters, expecting treeFolder, object")

	local Tree = self:_GetTree(TreeFolder)
	if Tree then
		return Tree
	else
		warn("Couldn't get tree for", TreeFolder)
	end
end

function TreeCreator:RegisterSharedBlackboard(Index, Table)
	assert(Index and Table and type(Index) == "string" and type(Table) == "table", "RegisterSharedBlackboard takes two arguments in the form of [string] index,[table] table")
	BehaviorTree3.SharedBlackboards[Index] = Table
end

---------------------------------------------
-------------- PRIVATE METHODS --------------

local function GetModule(ModuleScript)
	local Found = SourceTasks[ModuleScript]
	if Found then
		return Found
	else
		Found = require(ModuleScript)
		SourceTasks[ModuleScript] = Found
		return Found
	end
end

local function GetModuleScript(Folder)
	local Found = Folder:FindFirstChildOfClass("ModuleScript")
	if Found then
		return Found
	else
		local Link = Folder:FindFirstChild("Link")
		if Link then
			local Linked = Link.Value
			if Linked then
				return GetModuleScript(Linked)
			end
		end
	end
end

local function GetSourceTask(Folder)
	local ModuleScript = GetModuleScript(Folder)
	if ModuleScript then
		return GetModule(ModuleScript)
	end
end

function TreeCreator:_BuildNode(Folder)
	local NodeType = Folder.Type.Value
	local Weight = Folder:FindFirstChild("Weight") and Folder.Weight.Value or 1

	-- Get outputs, sorted in index order
	local Outputs = Folder.Outputs:GetChildren()
	local OrderedChildren = table.create(#Outputs)
	for Index, ObjectValue in ipairs(Outputs) do
		OrderedChildren[Index] = ObjectValue
	end

	table.sort(OrderedChildren, function(A, B)
		return tonumber(A.Name) < tonumber(B.Name)
	end)

	for Index, OrderedChild in ipairs(OrderedChildren) do
		OrderedChildren[Index] = self:_BuildNode(OrderedChild.Value)
	end

	-- Get parameters from parameters folder
	local Parameters = {}
	for _, Value in ipairs(Folder.Parameters:GetChildren()) do
		if Value.Name ~= "Index" then
			Parameters[string.lower(Value.Name)] = Value.Value
		end
	end

	-- Add nodes and task module/tree to node parameters
	Parameters.Nodes = OrderedChildren
	Parameters.NodeFolder = Folder
	if NodeType == "Task" then
		local SourceTask = assert(GetSourceTask(Folder), "could't build tree; task node had no module")
		Parameters.Start = SourceTask.Start
		Parameters.Run = SourceTask.Run
		Parameters.Finish = SourceTask.Finish
	elseif NodeType == "Tree" then
		Parameters.Tree = assert(self:_GetTreeFromId(Parameters.TreeId), string.format("could't build tree; couldn't get tree object for tree node with TreeID: %s!", tostring(Parameters.TreeId)))
	end

	-- Initialize node with BehaviorTree3
	local Node = BehaviorTree3[NodeType](Parameters)
	Node.Weight = Weight
	return Node
end

function TreeCreator:_CreateTree(TreeFolder)
	print("Attempt create tree:", TreeFolder)
	local Nodes = TreeFolder.Nodes
	local RootFolder = assert(Nodes:FindFirstChild("Root"), string.format("Could not find Root under BehaviorTrees.Trees.%s.Nodes!", TreeFolder.Name))
	assert(#RootFolder.Outputs:GetChildren() == 1, string.format("The root node does not have exactly one connection for %s!", TreeFolder.Name))

	local FirstNodeFolder = RootFolder.Outputs:GetChildren()[1].Value
	local Root = self:_BuildNode(FirstNodeFolder)
	local Tree = BehaviorTree3.new {
		Tree = Root;
		TreeFolder = TreeFolder;
	}

	Trees[TreeFolder] = Tree
	TreeIds[TreeFolder.Name] = Tree
	return Tree
end

function TreeCreator:_GetTree(TreeFolder)
	return Trees[TreeFolder] or self:_CreateTree(TreeFolder)
end

-- For tree ndoes to get a tree from
function TreeCreator:_GetTreeFromId(TreeId)
	local Tree = TreeIds[TreeId]
	if not Tree then
		for _, Folder in ipairs(CollectionService:GetTagged(TREE_TAG)) do
			if Folder.Name == TreeId then
				return self:_GetTree(Folder)
			end
		end
	else
		return Tree
	end
end

return TreeCreator