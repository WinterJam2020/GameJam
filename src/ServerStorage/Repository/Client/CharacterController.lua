--!nocheck

----| Services |------------------------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
-- local UserInputService = game:GetService("UserInputService")

----| Objects |-------------------------------------------------------------------------------------
local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts
local PlayerModule = require(PlayerScripts:WaitForChild("PlayerModule"))
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Humanoid.RootPart

----| Modules |-------------------------------------------------------------------------------------
local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadShared("Constants")
-- local Arrow = Resources:LoadShared("Arrow")
local SplineClass = Resources:LoadShared("AstroSpline")
local SkiPathRemote = Resources:GetRemoteFunction(Constants.REMOTE_NAMES.SKI_PATH_REMOTE_FUNCTION_NAME)

----| Constants |-----------------------------------------------------------------------------------
local ROOT_PART_HEIGHT = Humanoid.HipHeight + RootPart.Size.Y / 2 + 2 -- +2 is fudge
-- local PUSH_COOLDOWN = 0.5
local MAX_CARVE_ANGLE = 40
-- local MAX_SKID_ANGLE = 80
local GRAVITY = 196.2

----| State variables |-----------------------------------------------------------------------------
local SkiChainCFrames = SkiPathRemote:InvokeServer()
local SkiChain = SplineClass.Chain.new(SkiChainCFrames, 1)
local SkiChainAlpha = 0.001
local SplineCFrame = SkiChain:GetCFrame(SkiChainAlpha)

local GroundCFrame = SplineCFrame
local MouseX = 2 * Mouse.X / Mouse.ViewSizeX - 1
local Velocity = Vector3.new()

----| Initialize |----------------------------------------------------------------------------------
Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
local Controls = PlayerModule:GetControls()
Controls:Disable()
Camera.CameraType = Enum.CameraType.Scriptable
Camera.FieldOfView = 100
RootPart.Anchored = true

----| Main |----------------------------------------------------------------------------------------
--RunService.Heartbeat:Connect(function(dt)

local function CFrameUpAt(pos, up, look)
	local lookProjected = (look - look:Dot(up) * up).Unit
	local right = lookProjected:Cross(up)
	return CFrame.fromMatrix(pos, right, up, -lookProjected)
end

coroutine.wrap(function()
	while true do
		local dt = RunService.Heartbeat:Wait()
		dt *= 0.4

		-- step velocity and position
		local groundLook = GroundCFrame.LookVector
		local gravityForce = Vector3.new(0, -GRAVITY, 0)
		local gravityForceParallel = gravityForce:Dot(groundLook) * groundLook
		local velocity = Velocity + gravityForceParallel * dt
		Velocity = velocity:Dot(groundLook) * groundLook
		local newPosition = GroundCFrame.Position + Velocity * dt

		-- get closest point on spline
		local isMovingForward = Velocity:Dot(SplineCFrame.LookVector) > 0
		local alpha = SkiChainAlpha
		for power = 3, 6 do
			local alphaIncrement = isMovingForward and 10 ^ -power or -10 ^ -power
			local increments = 0
			local distanceToSpline = (SkiChain:GetPosition(alpha) - newPosition).Magnitude
			while increments < 20 do
				local nextAlpha = alpha + alphaIncrement
				if nextAlpha < 0 or nextAlpha > 1 then
					break
				end
				local nextDistanceToSpline = (SkiChain:GetPosition(nextAlpha) - newPosition).Magnitude
				--Arrow("checking " .. power, newPosition, SkiChain:GetPosition(nextAlpha), Color3.fromHSV(power / 6, 1, 1))
				if nextDistanceToSpline > distanceToSpline then
					break
				end
				increments += 1
				alpha = nextAlpha
				distanceToSpline = nextDistanceToSpline
			end
		end

		-- move character
		SkiChainAlpha = alpha
		SplineCFrame = SkiChain:GetRotCFrame(SkiChainAlpha)
		local newPositionOnSpline = newPosition
			- (newPosition - SplineCFrame.Position):Dot(SplineCFrame.UpVector)
			* SplineCFrame.UpVector
		local distanceToSplineOnSpline = (newPositionOnSpline - SplineCFrame.Position).Magnitude
		distanceToSplineOnSpline = math.clamp(distanceToSplineOnSpline, 0, 50)
		local isOnRightSideOfSpline = (newPosition - SplineCFrame.Position).Unit:Dot(SplineCFrame.RightVector) > 0
		if not isOnRightSideOfSpline then
			distanceToSplineOnSpline *= -1
		end

		MouseX = 2 * Mouse.X / Mouse.ViewSizeX - 1
		GroundCFrame = CFrameUpAt(
			SplineCFrame.Position + SplineCFrame.RightVector * distanceToSplineOnSpline,
			SplineCFrame.UpVector,
			GroundCFrame.LookVector
		) * CFrame.Angles(0, MouseX * -math.rad(MAX_CARVE_ANGLE) / 10, 0)
		RootPart.CFrame = GroundCFrame + GroundCFrame.UpVector * ROOT_PART_HEIGHT

		--local cameraCFrame = SkiChain:GetRotCFrame(math.clamp(SkiChainAlpha - 0.002, 0, 1))
		--Camera.CFrame = cameraCFrame + cameraCFrame.UpVector * ROOT_PART_HEIGHT * 2
		Camera.CFrame = RootPart.CFrame + RootPart.CFrame.LookVector * -10
	end
end)()

return true