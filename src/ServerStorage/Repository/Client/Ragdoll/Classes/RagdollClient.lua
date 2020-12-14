--- Client side ragdolling meant to be used with a binder
-- @classmod RagdollClient

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Resources = require(ReplicatedStorage.Resources)

local BaseObject = Resources:LoadLibrary("BaseObject")
local CameraStackService = Resources:LoadLibrary("CameraStackService")
local CharacterUtils = Resources:LoadLibrary("CharacterUtils")
local HapticFeedbackUtils = Resources:LoadLibrary("HapticFeedbackUtils")
local Scheduler = Resources:LoadLibrary("Scheduler")

local RagdollClient = setmetatable({ClassName = "RagdollClient"}, BaseObject)
RagdollClient.__index = RagdollClient

function RagdollClient.new(Humanoid: Humanoid)
	local self = setmetatable(BaseObject.new(Humanoid), RagdollClient)
	local Player = CharacterUtils.GetPlayerFromCharacter(self.Object)
	if Player == Players.LocalPlayer then
		self:_SetupHapticFeedback()
		self:_SetupCameraShake(CameraStackService:GetImpulseCamera())
	end

	return self
end

-- TODO: Move out of this open source module
function RagdollClient:_SetupCameraShake(ImpulseCamera)
	local Head = self.Object.Parent:FindFirstChild("Head")
	if not Head then
		return
	end

	local LastVelocity = Head.Velocity
	self.Janitor:Add(RunService.RenderStepped:Connect(function()
		local CameraCFrame = Workspace.CurrentCamera.CFrame

		local Velocity = Head.Velocity
		local DeltaVelocity = Velocity - LastVelocity
		if DeltaVelocity.Magnitude >= 0 then
			ImpulseCamera:Impulse(CameraCFrame:VectorToObjectSpace(CameraCFrame.LookVector:Cross(DeltaVelocity) / -10))
		end

		LastVelocity = Velocity
	end), "Disconnect")
end

function RagdollClient:_SetupHapticFeedback()
	local LastInputType = UserInputService:GetLastInputType()
	if not HapticFeedbackUtils.SetSmallVibration(LastInputType, 1) then
		return
	end

	local Alive = true
	self.Janitor:Add(function()
		Alive = false
	end, true)

	Scheduler.Spawn(function()
		for Index = 1, 0, -0.1 do
			HapticFeedbackUtils.SetSmallVibration(LastInputType, Index)
			Scheduler.Wait2(0.05)
		end

		HapticFeedbackUtils.SetSmallVibration(LastInputType, 0)

		if Alive then
			self.Janitor:Add(function()
				HapticFeedbackUtils.SmallVibrate(LastInputType)
			end, true)
		end
	end)
end

return RagdollClient