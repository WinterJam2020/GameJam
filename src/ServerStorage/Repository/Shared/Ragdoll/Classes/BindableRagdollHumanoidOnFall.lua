local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local BaseObject = Resources:LoadLibrary("BaseObject")
local Scheduler = Resources:LoadLibrary("Scheduler")

local FRAMES_TO_EXAMINE = 8
local FRAME_TIME = 0.1
local RAGDOLL_DEBOUNCE_TIME = 1
local REQUIRED_MAX_FALL_VELOCITY = -30

local BindableRagdollHumanoidOnFall = setmetatable({ClassName = "BindableRagdollHumanoidOnFall"}, BaseObject)
BindableRagdollHumanoidOnFall.__index = BindableRagdollHumanoidOnFall

function BindableRagdollHumanoidOnFall.new(Humanoid, RagdollBinder)
	local self = setmetatable(BaseObject.new(Humanoid), BindableRagdollHumanoidOnFall)
	self.RagdollBinder = assert(RagdollBinder)
	self.ShouldRagdoll = self.Janitor:Add(Instance.new("BoolValue"), "Destroy")
	self.ShouldRagdoll.Value = false

	-- Setup Ragdoll
	self:_InitLastVelocityRecords()
	self.LastRagdollTime = 0

	local Alive = true
	self.Janitor:Add(function()
		Alive = false
	end, true)

	Scheduler.Spawn(function()
		Scheduler.Wait2(math.random() * FRAME_TIME) -- Apply jitter
		while Alive do
			self:_UpdateVelocity()
			Scheduler.Wait2(FRAME_TIME)
		end
	end)

	self.Janitor:Add(self.RagdollBinder:ObserveInstance(self.Object, function(Class)
		if not Class then
			self.LastRagdollTime = time()
			self.ShouldRagdoll.Value = false
		end
	end), true)

	return self
end

function BindableRagdollHumanoidOnFall:_InitLastVelocityRecords()
	self.LastVelocityRecords = {}
	for _ = 1, FRAMES_TO_EXAMINE + 1 do -- Add an extra frame because we remove before inserting
		table.insert(self.LastVelocityRecords, Vector3.new())
	end
end

function BindableRagdollHumanoidOnFall:_GetLargestSpeedInRecords()
	local LargestSpeed = -math.huge

	for _, VelocityRecord in ipairs(self.LastVelocityRecords) do
		local Speed = VelocityRecord.Magnitude
		if Speed > LargestSpeed then
			LargestSpeed = Speed
		end
	end

	return LargestSpeed
end

function BindableRagdollHumanoidOnFall:_RagdollFromFall()
	self.ShouldRagdoll.Value = true

	Scheduler.Spawn(function()
		while self.Destroy
			and self:_GetLargestSpeedInRecords() >= 3
			and self.ShouldRagdoll.Value
		do
			Scheduler.Wait2(0.03)
		end

		if self.Destroy and self.ShouldRagdoll.Value then
			Scheduler.Wait2(0.75)
		end

		if self.Destroy and self.Object.Health > 0 then
			self.ShouldRagdoll.Value = false
		end
	end)
end

function BindableRagdollHumanoidOnFall:_UpdateVelocity()
	table.remove(self.LastVelocityRecords, 1)
	local RootPart = self.Object.RootPart
	if not RootPart then
		return table.insert(self.LastVelocityRecords, Vector3.new())
	end

	local CurrentVelocity = RootPart.Velocity

	local FellForAllFrames = true
	local MostNegativeVelocityY = math.huge
	for _, VelocityRecord in ipairs(self.LastVelocityRecords) do
		if VelocityRecord.Y >= -2 then
			FellForAllFrames = false
			break
		end

		if VelocityRecord.Y < MostNegativeVelocityY then
			MostNegativeVelocityY = VelocityRecord.Y
		end
	end

	table.insert(self.LastVelocityRecords, CurrentVelocity)
	if not FellForAllFrames or MostNegativeVelocityY >= REQUIRED_MAX_FALL_VELOCITY or self.Object.Health <= 0 or self.Object.Sit then
		return
	end

	local CurrentState = self.Object:GetState()
	if CurrentState == Enum.HumanoidStateType.Physics or CurrentState == Enum.HumanoidStateType.Swimming or (time() - self.LastRagdollTime) <= RAGDOLL_DEBOUNCE_TIME then
		return
	end

	self:_RagdollFromFall()
end

return BindableRagdollHumanoidOnFall