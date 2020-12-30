--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local UserInputService = game:GetService("UserInputService")

local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadShared("Constants")
-- local Arrow = Resources:LoadShared("Arrow")
local Janitor = Resources:LoadLibrary("Janitor")
local SplineModule = Resources:LoadLibrary("AstroSpline")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local CharacterRig = ReplicatedStorage.CharacterRig

---- Constants
local TERRAIN_WIDTH = Constants.SKI_PATH.TERRAIN_WIDTH
local ROOT_PART_OFFSET = CFrame.new(0, 2.7 + 1 + 2, 0) -- 2.7: hip height, 1: HRP height/2, 2: fudge
local CAMERA_OFFSET = ROOT_PART_OFFSET * CFrame.new(0, 5, 10)
-- local PUSH_COOLDOWN = 0.5
local MAX_CARVE_ANGLE = 40
-- local MAX_SKID_ANGLE = 80
local GRAVITY = 196.2

---- Initialize
workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
workspace.CurrentCamera.FieldOfView = 100

---- Functions
local function CFrameUpAt(pos: Vector3, up: Vector3, look: Vector3) -- CFrame.lookAt but for up
	local lookProjected = (look - look:Dot(up) * up).Unit
	local right = lookProjected:Cross(up)
    return CFrame.fromMatrix(pos, right, up, -lookProjected)
end

---- Objects
local CharacterController = {}
CharacterController.__index = CharacterController

function CharacterController.new(skiChainCFrames)
	local skiChain = SplineModule.Chain.new(skiChainCFrames)
	local startCFrame = skiChain:GetRotCFrame(0)
	local rig = CharacterRig:Clone()
	local root = rig.PrimaryPart
	rig.Name = Player.Name
	root.CFrame = startCFrame * ROOT_PART_OFFSET
	rig.Parent = workspace

	local self = {
		Alpha = 0,
		Janitor = Janitor.new(),
		Rig = rig,
		Root = root,
		RootCFrame = root.CFrame,
		SkiChain = skiChain,
		SkiChainCFrame = startCFrame,
		Velocity = Vector3.new()
	}

	self.Janitor:Add(rig)

	return setmetatable(self, CharacterController)
end

function CharacterController:SetRootCFrame(cframe)
	self.Root.CFrame = cframe * ROOT_PART_OFFSET
end

function CharacterController:SetCameraCFrame(cframe)
	workspace.CurrentCamera.CFrame = cframe * CAMERA_OFFSET
end

function CharacterController:Destroy()
	self.Janitor:Cleanup()
	for k, _ in pairs(self) do
		self[k] = nil
	end
end

function CharacterController:Step(deltaTime)
	local dt = deltaTime * 0.4

	-- step velocity and position
	local rootLook = self.RootCFrame.LookVector
	local gravityForce = Vector3.new(0, -GRAVITY, 0)
	local gravityForceParallel = gravityForce:Dot(rootLook) * rootLook
	local newVelocity = self.Velocity + gravityForceParallel * dt
	newVelocity = newVelocity:Dot(rootLook) * rootLook
	local newPosition = self.RootCFrame.Position + newVelocity * dt
	self.Velocity = newVelocity

	-- get closest point on spline
	local isMovingForward = newVelocity:Dot(self.SkiChainCFrame.LookVector) > 0
	local skiChain = self.SkiChain
	local alpha = self.Alpha
	for power = 3, 6 do
		local alphaIncrement = isMovingForward and 10 ^ -power or -10 ^ -power
		local increments = 0
		local distanceToSpline = (skiChain:GetPosition(alpha) - newPosition).Magnitude
		while increments < 20 do
			local nextAlpha = alpha + alphaIncrement
			if nextAlpha < 0 or nextAlpha > 1 then
				break
			end
			local nextDistanceToSpline = (skiChain:GetPosition(nextAlpha) - newPosition).Magnitude
			if nextDistanceToSpline > distanceToSpline then -- distance function is increasing
				break
			end
			increments += 1
			alpha = nextAlpha
			distanceToSpline = nextDistanceToSpline
		end
	end

	-- move character
	local skiChainCFrame = skiChain:GetRotCFrame(alpha)
	local skiChainPosition = skiChainCFrame.Position
	local skiChainUp = skiChainCFrame.UpVector
	newPosition += skiChainUp * (newPosition - skiChainPosition):Dot(-skiChainUp) -- project onto spline
	local splineToProjectedPosition = newPosition - skiChainPosition
	newPosition = skiChainPosition
		+ splineToProjectedPosition.Unit
		* math.min(splineToProjectedPosition.Magnitude, TERRAIN_WIDTH / 2) -- limit to terrain width
	local mouseX = 2 * Mouse.X / Mouse.ViewSizeX - 1 -- [-1, 1]
	local newRootCFrame = CFrameUpAt(newPosition, skiChainUp, rootLook)
		* CFrame.Angles(0, mouseX * -math.rad(MAX_CARVE_ANGLE) / 10, 0)

	-- update fields
	self:SetRootCFrame(newRootCFrame)
	self:SetCameraCFrame(newRootCFrame)
	self.Alpha = alpha
	self.SkiChainCFrame = skiChainCFrame
	self.RootCFrame = newRootCFrame
end

return true