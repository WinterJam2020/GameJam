local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local CharacterUtils = Resources:LoadLibrary("CharacterUtils")
local Janitor = Resources:LoadLibrary("Janitor")
local PromiseChild = Resources:LoadLibrary("PromiseChild")
local RagdollRigging = Resources:LoadLibrary("RagdollRigging")

local RagdollUtils = {}

local EMPTY_FUNCTION = function() end

function RagdollUtils.SetupState(Humanoid: Humanoid)
	local StateJanitor = Janitor.new()

	local function UpdateState()
		if Humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
			Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end
	end

	local function TeleportRootPartToUpperTorso()
		if CharacterUtils.GetPlayerFromCharacter(Humanoid) ~= Players.LocalPlayer then
			return
		end

		local RootPart = Humanoid.RootPart
		if not RootPart then
			return
		end

		local Character = Humanoid.Parent
		if not Character then
			return
		end

		local UpperTorso = Character:FindFirstChild("UpperTorso")
		if not UpperTorso then
			return
		end

		RootPart.CFrame = UpperTorso.CFrame
	end

	StateJanitor:Add(function()
		StateJanitor:Cleanup() -- GC other events
		TeleportRootPartToUpperTorso()
		Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end, true)

	StateJanitor:Add(Humanoid.StateChanged:Connect(UpdateState), "Disconnect")
	UpdateState()

	return StateJanitor
end

-- We need this on all clients/servers to override animations!
function RagdollUtils.PreventAnimationTransformLoop(Humanoid: Humanoid)
	local LoopJanitor = Janitor.new()

	local Character = Humanoid.Parent
	if not Character then
		warn("[RagdollUtils.PreventAnimationTransformLoop] - No character")
		return LoopJanitor
	end

	LoopJanitor:AddPromise(PromiseChild(Humanoid.Parent, "LowerTorso")):Then(function(LowerTorso)
		return PromiseChild(LowerTorso, "Root")
	end):Then(function(Root)
		-- This may desync the server and the client, but will result in
		-- no teleporting on the client.
		local LastTransform = Root.Transform

		LoopJanitor:Add(RunService.Stepped:Connect(function()
			Root.Transform = LastTransform
		end), "Disconnect")
	end)

	return LoopJanitor
end

function RagdollUtils.SetupMotors(Humanoid: Humanoid)
	local Character = Humanoid.Parent
	local RigType = Humanoid.RigType

	-- We first disable the motors on the network owner (the player that owns this character).
	--
	-- This way there is no visible round trip hitch. By the time the server receives the joint
	-- break physics data for the child parts should already be available. Seamless transition.
	--
	-- If we initiated ragdoll by disabling joints on the server there's a visible hitch while the
	-- server waits at least a full round trip time for the network owner to receive the joint
	-- removal, start simulating the ragdoll, and replicate physics data. Meanwhile the other body
	-- parts would be frozen in air on the server and other clients until physics data arives from
	-- the owner. The ragdolled player wouldn't see it, but other players would.
	--
	-- We also specifically do not disable the root joint on the client so we can maintain a
	-- consistent mechanism and network ownership unit root. If we did disable the root joint we'd
	-- be creating a new, seperate network ownership unit that we would have to wait for the server
	-- to assign us network ownership of before we would start simulating and replicating physics
	-- data for it, creating an additional round trip hitch on our end for our own character.
	local Motors = RagdollRigging.DisableMotors(Character, RigType)

	-- Apply velocities from animation to the child parts to mantain visual momentum.
	--
	-- This should be done on the network owner's side just after disabling the kinematic joint so
	-- the child parts are split off as seperate dynamic bodies. For consistent animation times and
	-- visual momentum we want to do this on the machine that controls animation state for the
	-- character and will be simulating the ragdoll, in this case the client.
	--
	-- It's also important that this is called *before* any animations are canceled or changed after
	-- death! Otherwise there will be no animations to get velocities from or the velocities won't
	-- be consistent!
	local Animator = Humanoid:FindFirstChildWhichIsA("Animator")
	if Animator then
		Animator:ApplyJointVelocities(Motors)
	end

	return function()
		for _, Motor in ipairs(Motors) do
			Motor.Enabled = true
		end
	end
end

function RagdollUtils.SetupHead(Humanoid)
	local Model = Humanoid.Parent
	if not Model then
		return EMPTY_FUNCTION
	end

	local Head = Model:FindFirstChild("Head")
	if not Head then
		return EMPTY_FUNCTION
	end

	if Head:IsA("MeshPart") then
		return EMPTY_FUNCTION
	end

	local OriginalSizeValue = Head:FindFirstChild("OriginalSize")
	if not OriginalSizeValue then
		return EMPTY_FUNCTION
	end

	local SpecialMesh = Head:FindFirstChildWhichIsA("SpecialMesh")
	if not SpecialMesh then
		return EMPTY_FUNCTION
	end

	if SpecialMesh.MeshType ~= Enum.MeshType.Head then
		return EMPTY_FUNCTION
	end

	local SetupJanitor = Janitor.new()
	-- More accurate physics for heads! Heads start at 2,1,1
	SetupJanitor:AddPromise(PromiseChild(Humanoid, "HeadScale")):Then(function(HeadScale)
		local function UpdateHeadSize()
			Head.Size = Vector3.new(1, 1, 1)*HeadScale.Value
		end

		SetupJanitor:Add(HeadScale.Changed:Connect(UpdateHeadSize), "Disconnect")
		UpdateHeadSize()

		SetupJanitor:Add(function()
			Head.Size = OriginalSizeValue.Value * HeadScale.Value
		end, true)
	end)

	return SetupJanitor
end

return RagdollUtils