--[[
    BEHAVIOR TREES V4

	Originally by iniich_n and tyridge77: https://devforum.roblox.com/t/behaviortree2-create-complex-behaviors-with-ease/451047
	Forked and improved by defaultio

	Improvements/changes:
		- Decorators will work as expected when parents of arbitrary nodes, instead of only Task nodes
		- Calling tree:run() will return the outcome of the tree (success [1], fail [2], running [3])
		- Added repeater node
			- can repeat infinitely with a "count" parameter of nil or <= 0
			- returns success when done repeating
			- returns fail if a "breakOnFail" parameter is true and it receives a failed result from its child
		- Added tree node which will call another tree and return the result of the other tree
		- If a success/fail node is left hanging without a child, it will directly return success/fail
		- Improved ProcessNode organization and readability by adding the interateNodes() iterator and the addNode() function
		- Changed node runner from using string node states to using number enums, to avoid string comparisons. Should be slightly faster.
		- Changed tasks to report their status by returning a status number enum, instead of calling a success/fail/running function on self
		- Added some more assertions in ProcessNode
		- Added comments and documentation so it's a little easier to add new nodes


	Changes by tyridge77(November 23rd, 2020)
		- Added support for live debugging(only in studio)
		- Added support for blackboards
		- Added Tree:Abort(), used for switching between trees but still calling finish on the previously running task


		- Added new Leaf node, Blackboard Query
			- These are used to perform fast and simple comparisons on a specific key in a blackboard
			- For instance, if you wanted a sequence to execute only if the entity's "LowHealth" state was set to true, or if a world's "NightTime" state was set to true(Shared Blackboard)
			- You can do this with tasks , but it's a bit faster if you only need to perform a simple boolean or nil check

			- You can only read from a blackboard using this node. Behavior Trees aren't meant to be visual scripting - just a way to carry out plans

			- Parameters:

				- Board: string that defaults to Entity if no value is specified.
					- Entity will reference the object's blackboard passed into the tree via tree:Run(object)
					- If a value is given, say "WorldStates", it will attempt to grab the Shared Blackboard to use with the same name. You can register these via BehaviorTreeCreator:RegisterSharedBlackboard(name,table)

				- Key: the string index of the key you're trying to query(for instance, "LowHealth")
				- Type: string which specifies what kind of query you're trying to perform.
					- You can choose true,false,set,or unset to perform boolean/nil checks. Alternatively you can specify a string of your choice to perform a string comparison

		- Added new composite node, While
			- Only accepts two children, a condition(1st child), and an action(2nd child)
			- Repeats until either
				- condition returns fail, wherein the node itself returns fail
				- action returns success, wherein the node itself returns success

			- Used for processing stacks of items
				- Say you want an NPC to create a stack of nearby doors, then try to enter each door until there are no doors left to try, or the NPC got through a door.
				- If the NPC got through a door successfully, the node would return success. Otherwise, if there were no doors that were able to be entered, the node will return fail
				- Example pic: https://cdn.discordapp.com/attachments/711758878995513364/783523673704628294/unknown.png
--]]

-- I was going to use behavior trees for the logic behind handling rounds but NO TIME!!!!!!

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local IsStudio = RunService:IsRunning() and RunService:IsStudio()

local BehaviorTree = {
	ClassName = "BehaviorTree";
	SharedBlackboards = {}; -- Dictionary for shared blackboards using the blackboard's string index as key
}

BehaviorTree.__index = BehaviorTree

local SUCCESS, FAIL, RUNNING = 1, 2, 3

-------- Tree Index Lookup --------

-- Trees are now decoupled from instances, and cloning is not supported. This is to make it a bit cleaner and saves on memory
-- Due to this however, we need a new way to keep track of a particular running tree's current index
-- A simple solution which we will use is to use a mandatory object passed into the tree as a dictionary key to house the index
-- This object can be anything as long as it is a unique key(a table, an instance)

-- Used by the BehaviorTree Editor plugin
local RunningTreesFolder
if IsStudio then
	local cam = Instance.new("Camera")
	cam.Name = "NonReplicated"

	RunningTreesFolder = Instance.new("Folder")
	RunningTreesFolder.Name = "RunningTrees(debug)"
	RunningTreesFolder.Parent = cam

	cam.Parent = script
	CollectionService:AddTag(RunningTreesFolder, "_btRunningTrees")
end

--

-------- Blackboards --------

-- Blackboards are just tables for behavior trees that can be read from and written to
-- They can exist on a per-entity or a global/shared level.
-- Trees can read and write entity blackboards but only read from shared blackboards
-- Trees do this using the new Blackboard node

local BLACKBOARD_QUERY_TYPE_TRUE, BLACKBOARD_QUERY_TYPE_FALSE, BLACKBOARD_QUERY_TYPE_NIL, BLACKBOARD_QUERY_TYPE_NOTNIL = 1, 2, 3, 4


-------- TREE NODE PROCESSOR --------

-- Iterates through raw node tree and constructs an optimzied data structure that will be used for quick tree traversal at runtime
-- For each node, OnSuccess and OnFail values are set, which indicate the index of the next node that the runner hit after a success or failure

-- During processing algorithm, OnSuccess and OnFail will be each set to true or false, until it is set to an actual int index.
-- true indicates that a OnSuccess or OnFail should return success. false indicates that a OnSuccess or OnFail should return fail.

local function ProcessNode(Node, Nodes)
	-- Iterate and process all children and descendant nodes, returning an iterator for each descendant node
	local function IterateNodes()
		local ChildIndex, Index = 0, 0
		local ChildNode
		local IsFinalChildNode

		return function()
			Index += 1
			if Index == #Nodes + 1 then
				ChildNode = nil
			end

			if not ChildNode then
				if IsFinalChildNode then
					return nil
				end

				ChildIndex += 1
				ChildNode = Node.Parameters.Nodes[ChildIndex]
				IsFinalChildNode = ChildIndex == #Node.Parameters.Nodes
				Index = #Nodes + 1
				ProcessNode(ChildNode, Nodes)
			end

			local CurrentNode = Nodes[Index]
			return CurrentNode, #Nodes + 1, IsFinalChildNode
		end
	end

	-- Add a new node to the final node table, returning the node and its index
	local function AddNode(NodeType)
		local NewNode = {Type = NodeType}
		Nodes[#Nodes + 1] = NewNode
		return NewNode, #Nodes
	end

	------------------------------
	--------- LEAF NODES ---------

	if Node.Type == "Task" then
		local Run = assert(Node.Parameters.Run, "Can't process tree; task leaf node has no run func parameter")
		local TaskNode = AddNode("Task")
		TaskNode.Start = Node.Parameters.Start
		TaskNode.Run = Run
		TaskNode.Finish = Node.Parameters.Finish
		TaskNode.OnSuccess = true
		TaskNode.OnFail = false
		TaskNode.NodeFolder = Node.Parameters.NodeFolder
	elseif Node.Type == "Blackboard" then
		local BlackboardNode = AddNode("Blackboard")
		BlackboardNode.OnSuccess = true
		BlackboardNode.OnFail = false
		BlackboardNode.Key = Node.Parameters.Key
		BlackboardNode.Board = Node.Parameters.Board

		local ReturnType = string.lower(Node.Parameters.Value)

		local CompareString = false

		if ReturnType == "true" then
			BlackboardNode.ReturnType = BLACKBOARD_QUERY_TYPE_TRUE
		elseif ReturnType == "false" then
			BlackboardNode.ReturnType = BLACKBOARD_QUERY_TYPE_FALSE
		elseif ReturnType == "unset" or ReturnType == "nil" then
			BlackboardNode.ReturnType = BLACKBOARD_QUERY_TYPE_NIL
		elseif ReturnType == "set" then
			BlackboardNode.ReturnType = BLACKBOARD_QUERY_TYPE_NOTNIL
		else
			CompareString = true
			BlackboardNode.ReturnType = Node.Parameters.Value
		end

		BlackboardNode.CompareString = CompareString
	elseif Node.Type == "Tree" then
		local Tree = assert(Node.Parameters.Tree, "Can't process tree; tree leaf node has no linked tree object")

		local TreeNode = AddNode("Tree")
		TreeNode.Tree = Tree
		TreeNode.OnSuccess = true
		TreeNode.OnFail = false
		TreeNode.NodeFolder = Node.Parameters.NodeFolder

		-----------------------------------
		--------- DECORATOR NODES ---------

	elseif Node.Type == "AlwaysSucceed" then
		assert(#Node.Parameters.Nodes <= 1, "Can't process tree; succeed decorator with multiple children")

		if Node.Parameters.Nodes[1] then
			-- All child node outcomes that return failure are switched to return success
			for CurrentNode in IterateNodes() do
				if CurrentNode.OnSuccess == false then
					CurrentNode.OnSuccess = true
				end

				if CurrentNode.OnFail == false then
					CurrentNode.OnFail = true
				end
			end
		else
			-- Hanging succeed node, always return success
			(AddNode("Succeed")).OnSuccess = true
		end
	elseif Node.Type == "AlwaysFail" then
		assert(#Node.Parameters.Nodes <= 1, "Can't process tree; fail decorator with multiple children")

		if Node.Parameters.Nodes[1] then
			-- All child node outcomes that return success are switched to return failure
			for CurrentNode in IterateNodes() do
				if CurrentNode.OnSuccess == true then
					CurrentNode.OnSuccess = false
				end

				if CurrentNode.OnFail == true then
					CurrentNode.OnFail = false
				end
			end
		else
			-- Hanging fail node, always return fail
			(AddNode("Fail")).OnFail = false
		end
	elseif Node.Type == "Invert" then
		assert(#Node.Parameters.Nodes <= 1, "Can't process tree; invert decorator with multiple children")
		assert(#Node.Parameters.Nodes == 1, "Can't process tree; hanging invert decorator")

		-- All child node outcomes are flipped
		for CurrentNode in IterateNodes() do
			if CurrentNode.OnSuccess == true then
				CurrentNode.OnSuccess = false
			elseif CurrentNode.OnSuccess == false then
				CurrentNode.OnSuccess = true
			end

			if CurrentNode.OnFail == false then
				CurrentNode.OnFail = true
			elseif CurrentNode.OnFail == true then
				CurrentNode.OnFail = false
			end
		end
	elseif Node.Type == "Repeat" then
		assert(#Node.Parameters.Nodes <= 1, "Can't process tree; repeat decorator with multiple children")
		assert(#Node.Parameters.Nodes == 1, "Can't process tree; hanging repeat decorator")

		local RepeatStartIndex = #Nodes + 1

		-- It's not necessary to have a repeat node if it repeats indefinitely
		local RepeatCount = Node.Parameters.Count and Node.Parameters.Count > 0 and Node.Parameters.Count or nil

		if RepeatCount and RepeatCount > 0 then
			AddNode("RepeatStart")

			local RepeatNode, RepeatIndex = AddNode("Repeat")
			RepeatNode.RepeatGoal = RepeatCount
			RepeatNode.RepeatCount = 0
			RepeatNode.OnSuccess = true
			RepeatNode.OnFail = false

			RepeatStartIndex = RepeatIndex
		end

		-- Direct all child node outcomes to this node. If break on fail, then leave fail outcomes as they are (fail outcome for breaking)
		local BreakOnFail = Node.Parameters.BreakOnFail

		for CurrentNode in IterateNodes() do
			if CurrentNode.OnSuccess == true or (CurrentNode.OnSuccess == false and not BreakOnFail) then
				CurrentNode.OnSuccess = RepeatStartIndex
			end

			if (CurrentNode.OnFail == false and not BreakOnFail) or CurrentNode.OnFail == true then
				CurrentNode.OnFail = RepeatStartIndex
			end
		end
	elseif Node.Type == "While" then
		assert(#Node.Parameters.Nodes == 2, "Can't process tree; while composite without 2 children")

		local ConditionNode = Node.Parameters.Nodes[1]
		local ActionNode = Node.Parameters.Nodes[2]

		local RepeatStartIndex = #Nodes + 1

		-- It's not necessary to have a repeat node if it repeats indefinitely
		local RepeatCount = Node.Parameters.Count and Node.Parameters.Count > 0 and Node.Parameters.Count or nil

		if RepeatCount and RepeatCount > 0 then
			-- repeat-start resets repeatCount of the following repeat
			AddNode("RepeatStart")

			local RepeatNode, RepeatIndex = AddNode("Repeat")
			RepeatNode.RepeatGoal = RepeatCount
			RepeatNode.RepeatCount = 0
			RepeatNode.OnSuccess = false
			RepeatNode.OnFail = false

			RepeatStartIndex = RepeatIndex
		end

		local ConditionStartIndex = #Nodes + 1
		ProcessNode(ConditionNode, Nodes)

		local ActionStartIndex = #Nodes + 1
		ProcessNode(ActionNode, Nodes)

		for Index = ConditionStartIndex, ActionStartIndex - 1 do
			local CurrentNode = Nodes[Index]
			if CurrentNode.OnSuccess == true then
				CurrentNode.OnSuccess = ActionStartIndex
			end

			if CurrentNode.OnFail == true then
				CurrentNode.OnFail = ActionStartIndex
			end
		end

		for Index = ActionStartIndex, #Nodes do
			local CurrentNode = Nodes[Index]
			if CurrentNode.OnSuccess == false then
				CurrentNode.OnSuccess = RepeatStartIndex
			end

			if CurrentNode.OnFail == false then
				CurrentNode.OnFail = RepeatStartIndex
			end
		end
	elseif Node.Type == "Sequence" then
		assert(#Node.Parameters.Nodes >= 1, "Can't process tree; sequence composite node has no children")

		-- All successful child node outcomes will return the next node, or success if it is the last node
		for CurrentNode, NextNode, IsFinal in IterateNodes() do
			if CurrentNode.OnSuccess == true then
				CurrentNode.OnSuccess = not IsFinal and NextNode or true
			end

			if CurrentNode.OnFail == true then
				CurrentNode.OnFail = not IsFinal and NextNode or true
			end
		end
	elseif Node.Type == "Selector" then
		assert(#Node.Parameters.Nodes >= 1, "Can't process tree; selector composite node has no children")

		-- All fail child node outcome will return the next node, or fail if it is the last node
		for CurrentNode, NextNode, IsFinal in IterateNodes() do
			if CurrentNode.OnSuccess == false then
				CurrentNode.OnSuccess = not IsFinal and NextNode or false
			end

			if CurrentNode.OnFail == false then
				CurrentNode.OnFail = not IsFinal and NextNode or false
			end
		end
	elseif Node.Type == "Random" then
		assert(#Node.Parameters.Nodes >= 1, "Can't process tree; random composite node has no children")

		local RandomNode = AddNode("Random")
		RandomNode.Indices = {}
		for _, ChildNode in ipairs(Node.Parameters.Nodes) do
			if ChildNode.Weight then
				local Base = #RandomNode.Indices
				local Index = #Nodes + 1

				for CurrentIndex = 1, ChildNode.Weight do
					RandomNode.Indices[Base + CurrentIndex] = Index
				end
			else
				table.insert(RandomNode.Indices, #Nodes + 1)
			end

			ProcessNode(ChildNode, Nodes)
		end
	elseif Node.Type == "Root" then
		assert(#Nodes == 0, "Can't process tree; root node found at nonroot location")
		ProcessNode(Node.Tree, Nodes)

		for _, CurrentNode in ipairs(Nodes) do
			-- Set success outcomes next index to #nodes + 1 to indicate success
			-- Set fail outcomes next index to #nodes + 2 to indicate failure
			if CurrentNode.OnSuccess == true then
				CurrentNode.OnSuccess = #Nodes + 1
			elseif CurrentNode.OnSuccess == false then
				CurrentNode.OnSuccess = #Nodes + 2
			end

			if CurrentNode.OnFail == true then
				CurrentNode.OnFail = #Nodes + 1
			elseif CurrentNode.OnFail == false then
				CurrentNode.OnFail = #Nodes + 2
			end
		end
	else
		error("ProcessNode: bad Node.Type " .. tostring(Node.Type))
	end
end

-------- TREE ABORT --------

-- Calls finish() on the running task of the tree, and sets the tree index back to 1
-- Should be used if you want to cancel out of a tree to swap to another(for instance in the case of a state change)

function BehaviorTree:Abort(Object, ...)
	assert(type(Object) == "table", "The first argument of a behavior tree's abort method must be a table!")
	local Nodes = self.Nodes
	local Index = self.IndexLookup[Object]

	if not Index then
		return
	end

	local Node = Nodes[Index]
	if Node.Type == "Task" then
		if Node.Finish then
			Node.Finish(Object, FAIL, ...)
		end
	end

	self.IndexLookup[Object] = 1
end

-------- TREE RUNNER --------

-- Traverses across the processed node tree produced by ProcessNode

-- For each node, calculates success, fail, or running
-- If running, pause the runner and immediately break out of the runner, returning a running state.
-- If success or fail, gets the next node we should move to using node.OnSuccess or node.OnFail

-- When the final node is processed, its OnSuccess/OnFail index will point outside of the scope of nodes, causing the loop to break
-- OnSuccess final nodes will point to #nodes + 1, which indicates a tree outcome of success
-- OnFail final nodes will point to #nodes + 2, which indicates a tree outcome of fail

function BehaviorTree:Run(Object, ...)
	assert(type(Object) == "table", "The first argument of a behavior tree's run method must be a table!")
	local DebugEntityNode
	if IsStudio and self.Folder then
		local TreeName = self.Folder.Name
		local ObjectName = tostring(Object)
		local Entities = RunningTreesFolder:FindFirstChild(TreeName)
		if not Entities then
			Entities = Instance.new("Folder")
			Entities.Name = TreeName
			Entities.Parent = RunningTreesFolder
		end

		local Entity = Entities:FindFirstChild(ObjectName)
		if not Entity then
			Entity = Instance.new("Folder")
			Entity.Name = ObjectName

			local NodeFolder = Instance.new("ObjectValue")
			NodeFolder.Name = "Node"
			NodeFolder.Parent = Entity

			local TreeFolder = Instance.new("ObjectValue")
			TreeFolder.Name = "TreeFolder"
			TreeFolder.Value = self.Folder
			TreeFolder.Parent = Entity

			local DisplayName = Object.Name or Object.name
			if DisplayName and type(DisplayName) ~= "string" then
				DisplayName = nil
			end

			if not DisplayName then
				for _, Value in next, Object do
					if typeof(Value) == "Instance" then
						DisplayName = Value.Name
					end
				end
			end

			if DisplayName then
				local Name = Instance.new("StringValue")
				Name.Name = "Name"
				Name.Value = DisplayName
				Name.Parent = Entity
			end

			Entity.Parent = Entities
		end

		DebugEntityNode = Entity.Node
	end

	if self.Running then
		return
	end

	local Nodes = self.Nodes
	local Index = self.IndexLookup[Object] or 1

	local Blackboard = Object.Blackboard
	if not Blackboard then
		Blackboard = {}
		Object.Blackboard = Blackboard
	end

	if not Object.SharedBlackboards then
		Object.SharedBlackboards = BehaviorTree.SharedBlackboards
	end

	local NodeCount = #Nodes
	local DidResume = self.Paused
	self.Paused = false
	self.Running = true

	while Index <= NodeCount do
		local CurrentNode = Nodes[Index]

		if IsStudio then
			DebugEntityNode.Value = CurrentNode.NodeFolder
		end

		if CurrentNode.Type == "Task" then
			if DidResume then
				DidResume = false
			elseif CurrentNode.Start then
				CurrentNode.Start(Object, ...)
			end

			local Status = CurrentNode.Run(Object,...)
			if Status == nil then
				warn("Node.Run did not call success, running or fail, acting as fail")
				Status = FAIL
			end

			if Status == RUNNING then
				self.Paused = true
				break
			elseif Status == SUCCESS then
				if CurrentNode.Finish then
					CurrentNode.Finish(Object, Status, ...)
				end
				Index = CurrentNode.OnSuccess
			elseif Status == FAIL then
				if CurrentNode.Finish then
					CurrentNode.Finish(Object, Status, ...)
				end

				Index = CurrentNode.OnFail
			else
				error("bad Node.Status")
			end
		elseif CurrentNode.Type == "Blackboard" then
			local Result = false
			local Board

			if CurrentNode.Board == "Entity" then
				Board = Blackboard
			else
				local SharedBoard = BehaviorTree.SharedBlackboards[CurrentNode.Board]
				if not SharedBoard then
					warn(string.format("Shared Blackboard %s is not registered, acting as fail", CurrentNode.Board))
				end

				Board = SharedBoard
			end

			if Board then
				local Value = Board[CurrentNode.Key]
				local String = tostring(Value)
				if CurrentNode.CompareString then
					Result = String and String == CurrentNode.ReturnType
				else
					if CurrentNode.ReturnType == BLACKBOARD_QUERY_TYPE_TRUE then
						Result = Value == true
					elseif CurrentNode.ReturnType == BLACKBOARD_QUERY_TYPE_FALSE then
						Result = Value == false
					elseif CurrentNode.ReturnType == BLACKBOARD_QUERY_TYPE_NIL then
						Result = Value == nil
					elseif CurrentNode.ReturnType == BLACKBOARD_QUERY_TYPE_NOTNIL then
						Result = Value ~= nil
					end
				end
			end

			Index = Result == true and CurrentNode.OnSuccess or CurrentNode.OnFail
		elseif CurrentNode.Type == "Tree" then
			local TreeResult = CurrentNode.Tree:Run(Object, ...)

			if TreeResult == RUNNING then
				self.Paused = true
				break
			elseif TreeResult == SUCCESS then
				Index = CurrentNode.OnSuccess
			elseif TreeResult == FAIL then
				Index = CurrentNode.OnFail
			else
				error("bad tree result")
			end
		elseif CurrentNode.Type == "Random" then
			Index = CurrentNode.Indices[math.random(#CurrentNode.Indices)]
		elseif CurrentNode.Type == "RepeatStart" then
			Index += 1
			local RepeatNode = Nodes[Index]
			RepeatNode.RepeatCount = 0
		elseif CurrentNode.Type == "Repeat" then
			CurrentNode.RepeatCount += 1
			if CurrentNode.RepeatCount > CurrentNode.RepeatGoal then
				Index = CurrentNode.OnSuccess
			else
				Index += 1
			end
		elseif CurrentNode.Type == "Succeed" then -- Hanging succeed node (technically a leaf)
			Index = CurrentNode.OnSuccess
		elseif CurrentNode.Type == "Fail" then -- Hanging fail node (technically a leaf)
			Index = CurrentNode.OnFail
		else
			error("bad Node.Type")
		end
	end

	-- Get tree outcome from the break index outcome
	-- +1 indicates success; +2 indicates fail
	-- If index is <= node count, then tree must be running
	local TreeOutcome
	if Index == NodeCount + 1 then
		TreeOutcome = SUCCESS
	elseif Index == NodeCount + 2 then
		TreeOutcome = FAIL
	else
		TreeOutcome = RUNNING
	end

	self.IndexLookup[Object] = Index <= NodeCount and Index or 1
	self.Running = false
	return TreeOutcome
end

function BehaviorTree.new(Parameters)
	local Tree = Parameters.Tree
	local Nodes = {}
	ProcessNode({
		Type = "Root";
		Tree = Tree;
		Parameters = {};
	}, Nodes)

	return setmetatable({
		Nodes = Nodes;
		IndexLookup = {};
		Folder = Parameters.TreeFolder;
	}, BehaviorTree)
end

function BehaviorTree.Sequence(Parameters)
	return {
		Type = "Sequence";
		Parameters = Parameters;
	}
end

function BehaviorTree.Selector(Parameters)
	return {
		Type = "Selector";
		Parameters = Parameters;
	}
end

function BehaviorTree.Random(Parameters)
	return {
		Type = "Random";
		Parameters = Parameters;
	}
end

function BehaviorTree.While(Parameters)
	return {
		Type = "While";
		Parameters = Parameters;
	}
end

function BehaviorTree.Succeed(Parameters)
	return {
		Type = "AlwaysSucceed";
		Parameters = Parameters;
	}
end

function BehaviorTree.Fail(Parameters)
	return {
		Type = "AlwaysFail";
		Parameters = Parameters;
	}
end

function BehaviorTree.Invert(Parameters)
	return {
		Type = "Invert";
		Parameters = Parameters;
	}
end

function BehaviorTree.Repeat(Parameters)
	return {
		Type = "Repeat";
		Parameters = Parameters;
	}
end

function BehaviorTree.Task(Parameters)
	return {
		Type = "Task";
		Parameters = Parameters;
	}
end

function BehaviorTree.Tree(Parameters)
	return {
		Type = "Tree";
		Parameters = Parameters;
	}
end

function BehaviorTree.BlackboardQuery(Parameters)
	return {
		Type = "Blackboard";
		Parameters = Parameters;
	}
end

return BehaviorTree