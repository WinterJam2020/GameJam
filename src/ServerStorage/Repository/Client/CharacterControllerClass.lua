--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadShared("Constants")
-- local Arrow = Resources:LoadShared("Arrow")
local Janitor = Resources:LoadLibrary("Janitor")
local ParticleEngineHelper = Resources:LoadClient("ParticleEngineHelper")
local SplineModule = Resources:LoadLibrary("AstroSpline")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local CharacterRig = ReplicatedStorage.CharacterRig

---- Constants
local TERRAIN_WIDTH = Constants.SKI_PATH.TERRAIN_WIDTH
local ROOT_PART_OFFSET = CFrame.new(0, 2.7 + 1 + 2, 0) -- 2.7: hip height, 1: HRP height/2, 2: fudge
local CAMERA_OFFSET = ROOT_PART_OFFSET * CFrame.new(0, 5, 10) * CFrame.Angles(math.rad(-20), 0, 0)
-- local PUSH_COOLDOWN = 0.5
local MAX_CARVE_ANGLE = 40
-- local MAX_SKID_ANGLE = 80
local GRAVITY = 75

local CHARACTER_COLORS = {
	{ -- blue
		Color = Color3.fromRGB(0, 255, 255),
		SkiTextureID = "rbxassetid://6155083113",
		PoleTextureID = "rbxassetid://6155081816",
		HelmetTextureID = "rbxassetid://6164542515"	
	},
	{ -- red
		Color = Color3.fromRGB(255, 89, 89),
		SkiTextureID = "rbxassetid://6155082723",
		PoleTextureID = "rbxassetid://6155082163",
		HelmetTextureID = "rbxassetid://6164542870"
	},
	{ -- purple
		Color = Color3.fromRGB(180, 128, 255),
		SkiTextureID = "rbxassetid://6155082858",
		PoleTextureID = "rbxassetid://6155082046",
		HelmetTextureID = "rbxassetid://6164542746"
	},
	{ -- white
		Color = Color3.fromRGB(248, 248, 248),
		SkiTextureID = "rbxassetid://6155082509",
		PoleTextureID = "rbxassetid://6155082421",
		HelmetTextureID = "rbxassetid://6164542392"
	},
	{ -- green
		Color = Color3.fromRGB(61, 255, 90),
		SkiTextureID = "rbxassetid://6164543226",
		PoleTextureID = "rbxassetid://6165753009",
		HelmetTextureID = "rbxassetid://6164542607"	
	}
}

---- Initialize
workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
workspace.CurrentCamera.CFrame = CFrame.new(0, 20, 0)
workspace.CurrentCamera.FieldOfView = 100

---- Functions
local function CFrameUpAt(pos: Vector3, up: Vector3, look: Vector3) -- CFrame.lookAt but for up
	local lookProjected = (look - look:Dot(up) * up).Unit
	local right = lookProjected:Cross(up)
    return CFrame.fromMatrix(pos, right, up, -lookProjected)
end

---- Objects
local CharacterController = {ClassName = "CharacterController"}
CharacterController.__index = CharacterController

function CharacterController.new(skiChainCFrames)
	local skiChain = SplineModule.Chain.new(skiChainCFrames)
	local startCFrame = skiChain:GetRotCFrame(0)
	local color = CHARACTER_COLORS[math.random(1, #CHARACTER_COLORS)]
	local rig = CharacterRig:Clone()
	rig.UpperTorso.Color = color.Color
	rig.LeftHand.Color = color.Color
	rig.RightHand.Color = color.Color
	rig.LeftFoot.Color = color.Color
	rig.RightFoot.Color = color.Color
	rig.LeftSki.TextureID = color.SkiTextureID
	rig.RightSki.TextureID = color.SkiTextureID
	rig.LeftPole.TextureID = color.PoleTextureID
	rig.RightPole.TextureID = color.PoleTextureID
	rig.Helmet.TextureID = color.HelmetTextureID
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
	self.Janitor:Destroy()
	table.clear(self)
	setmetatable(self, nil)
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
			if nextAlpha < 0 then
				break
			elseif nextAlpha > 1 then
				alpha = 1
				-- break
				-- print("done skiing")
				-- self.Alpha = 1
				-- Resources("ClientHandler"):StopSkiing()
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
	-- newPosition -= skiChainUp * (newPosition - skiChainPosition):Dot(skiChainUp) -- project onto spline
	-- local splineToProjectedPosition = newPosition - skiChainPosition
	-- newPosition = skiChainPosition
	-- 	+ splineToProjectedPosition.Unit
	-- 	* math.min(splineToProjectedPosition.Magnitude, TERRAIN_WIDTH / 2) -- limit to terrain width

	local newPositionOnSpline = newPosition
		- (newPosition - skiChainPosition):Dot(skiChainUp)
		* skiChainUp
	local distanceToSplineOnSpline = (newPositionOnSpline - skiChainPosition).Magnitude
	distanceToSplineOnSpline = math.clamp(distanceToSplineOnSpline, 0, TERRAIN_WIDTH / 2)
	local isOnRightSideOfSpline = (newPosition - skiChainPosition).Unit:Dot(skiChainCFrame.RightVector) > 0
	if not isOnRightSideOfSpline then
		distanceToSplineOnSpline *= -1
	end
	newPosition = skiChainPosition + skiChainCFrame.RightVector * distanceToSplineOnSpline

	
	local mouseX = 2 * Mouse.X / Mouse.ViewSizeX - 1 -- [-1, 1]
	local newRootCFrame = CFrameUpAt(newPosition, skiChainUp, rootLook)
		* CFrame.Angles(0, mouseX * -math.rad(MAX_CARVE_ANGLE) / 10, 0)

	-- ski particles
	if math.random() > 0.5 then
		local windCFrame = skiChain:GetCFrame(math.clamp(alpha + 0.01, 0, 1))
		ParticleEngineHelper.WindParticle(
			(windCFrame * CFrame.new(
				(2 * math.random() - 1) * TERRAIN_WIDTH / 2,
				math.random() * 20,
				0
			)).Position,
			CFrame.new()
		)
	end

	-- update fields
	self:SetRootCFrame(newRootCFrame)
	self:SetCameraCFrame(newRootCFrame)
	self.Alpha = alpha
	self.SkiChainCFrame = skiChainCFrame
	self.RootCFrame = newRootCFrame

	if alpha == 1 then -- absolute dogshit
		Resources("ClientHandler"):StopSkiing()
		local lastSkiCFrame = skiChain:GetCFrame(1)
		lastSkiCFrame = CFrameUpAt(
			lastSkiCFrame.Position,
			Vector3.new(0, 1, 0),
			lastSkiCFrame.LookVector
		)
		workspace.CurrentCamera.CFrame =
			lastSkiCFrame * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 8, 30)
		local rotationMultiplier = math.random() > 0.5 and 1 or -1
		local random = Random.new()
		local lastRootCFrame = lastSkiCFrame
			* CFrame.new(0, 2, -25)
			* ROOT_PART_OFFSET
			* CFrame.Angles(
				0,
				rotationMultiplier * random:NextNumber(0.8, 1) * math.pi / 2,
				0
			)
		local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0)
		TweenService:Create(self.Root, tweenInfo, {CFrame = lastRootCFrame}):Play()
	end
end

return CharacterController