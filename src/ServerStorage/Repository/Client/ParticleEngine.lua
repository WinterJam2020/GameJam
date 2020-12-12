local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadLibrary("Constants")

local IProperties = Constants.TYPE_CHECKS.IParticleProperties

local ParticleEngineClient = {
	MaxParticles = 400;
	WindSpeed = 10;
}

local function NewFrame(Name: string): Frame
	local Frame: Frame = Instance.new("Frame")
	Frame.BorderSizePixel = 0
	Frame.Name = Name
	Frame.Archivable = false
	return Frame
end

local Update

--[[**
	Initializes the ParticleEngine.
	@param [ScreenGui] ScreenGui The ScreenGui where the particles will be parented.
	@returns [ParticleEngine]
**--]]
function ParticleEngineClient:Initialize(ScreenGui: ScreenGui)
	self.RemoteEvent = Resources:GetRemoteEvent(Constants.REMOTE_NAME.PARTICLE_ENGINE_EVENT)
	self.RemoteEvent.OnClientEvent:Connect(function(Properties)
		self:Add(Properties)
	end)

	self.ScreenGui = ScreenGui or error("No ScreenGui")
	self.LocalPlayer = Players.LocalPlayer or error("No LocalPlayer")

	self.LastUpdateTime = time()
	self.ParticleCount = 0
	self.Particles = {}
	self.ParticleFrames = table.create(self.MaxParticles)

	for Index = 1, self.MaxParticles do
		self.ParticleFrames[Index] = NewFrame("Particle")
	end

	RunService.Heartbeat:Connect(function()
		debug.profilebegin("ParticleEngineUpdate")
		Update(self)
		debug.profileend()
	end)

	return self
end

--[[**
	Removes a Particle from the ParticleEngine.

	@param [IProperties] Properties The particle you want to remove.
	@returns [void]
**--]]
function ParticleEngineClient:Remove(Properties)
	local TypeSuccess, TypeError = IProperties(Properties)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	if self.Particles[Properties] then
		self.Particles[Properties] = nil
		self.ParticleCount -= 1
	end
end

local EMPTY_VECTOR2 = Vector2.new()
local EMPTY_VECTOR3 = Vector3.new()
local WHITE_COLOR3 = Color3.new(1, 1, 1)
local SIZE_VECTOR2 = Vector2.new(0.2, 0.2)

--[[
{
	Position = Vector3

	Optional:
	Global = Bool
	Velocity = Vector3
	Gravity = Vector3
	WindResistance  = Number
	Lifetime = Number
	Size = Vector2
	Bloom = Vector2
	Transparency = Number
	Color = Color3
	Occlusion = Bool
	RemoveOnCollision = function(BasePart Hit, Vector3 Position))
	Function = function(Table ParticleProperties, Number dt, Number t)
}
--]]

--[[**
	Adds a Particle to the ParticleEngine. See the script to find the properties.
	@param [IParticle] Particle The particle you want to add.
	@returns [void]
**--]]
function ParticleEngineClient:Add(Properties)
	local TypeSuccess, TypeError = IProperties(Properties)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	if self.Particles[Properties] then
		return
	end

	Properties.Position = Properties.Position or EMPTY_VECTOR3
	Properties.Velocity = Properties.Velocity or EMPTY_VECTOR3
	Properties.Size = Properties.Size or SIZE_VECTOR2
	Properties.Bloom = Properties.Bloom or EMPTY_VECTOR2
	Properties.Gravity = Properties.Gravity or EMPTY_VECTOR3
	Properties.Color = Properties.Color or WHITE_COLOR3
	Properties.Transparency = Properties.Transparency or 0.5

	if Properties.Global then
		local Function = Properties.Function
		local RemoveOnCollision = Properties.RemoveOnCollision
		Properties.Global = nil
		Properties.Function = nil
		Properties.RemoveOnCollision = RemoveOnCollision and true or nil

		self.RemoteEvent:FireServer(Properties)

		Properties.Function = Function
		Properties.RemoveOnCollision = RemoveOnCollision
	end

	Properties.Lifetime = Properties.Lifetime and Properties.Lifetime + time()
	if self.ParticleCount > self.MaxParticles then
		self.Particles[next(self.Particles)] = nil
	else
		self.ParticleCount += 1
	end

	self.Particles[Properties] = Properties
	return Properties
end

local function ParticleWind(CurrentTime, Position)
	local XY, YZ, ZX = Position.X + Position.Y, Position.Y + Position.Z, Position.Z + Position.X
	return Vector3.new(
		(math.sin(YZ + CurrentTime * 2) + math.sin(YZ + CurrentTime)) / 2 + math.sin((YZ + CurrentTime) / 10) / 2,
		(math.sin(ZX + CurrentTime * 2) + math.sin(ZX + CurrentTime)) / 2 + math.sin((ZX + CurrentTime) / 10) / 2,
		(math.sin(XY + CurrentTime * 2) + math.sin(XY + CurrentTime)) / 2 + math.sin((XY + CurrentTime) / 10) / 2
	)
end

local UpdateParameters = RaycastParams.new()
UpdateParameters.FilterType = Enum.RaycastFilterType.Blacklist
UpdateParameters.IgnoreWater = true

local function UpdatePositionVelocity(self, Properties, DeltaTime, CurrentTime)
	Properties.Position += Properties.Velocity * DeltaTime

	local Wind
	if Properties.WindResistance then
		Wind = (ParticleWind(CurrentTime, Properties.Position) * self.WindSpeed - Properties.Velocity) * Properties.WindResistance
	else
		Wind = EMPTY_VECTOR3
	end

	Properties.Velocity += (Properties.Gravity + Wind) * DeltaTime
end

local function UpdateParticle(self, Particle, CurrentTime, DeltaTime)
	if Particle.Lifetime - CurrentTime <= 0 then
		return false
	end

	if Particle.Function then
		Particle:Function(DeltaTime, CurrentTime)
	end

	local LastPosition = Particle.Position
	UpdatePositionVelocity(self, Particle, DeltaTime, CurrentTime)

	if not Particle.RemoveOnCollision then
		return true
	end

	local Displacement: Vector3 = Particle.Position - LastPosition
	local Distance = Displacement.Magnitude
	if Distance > 999 then
		Displacement *= (999 / Distance)
	end

	UpdateParameters.FilterDescendantsInstances = table.create(1, self.LocalPlayer.Character)
	local RaycastResult = Workspace:Raycast(LastPosition, Displacement, UpdateParameters)
	if not RaycastResult then
		return true
	end

	local Hit = RaycastResult.Instance
	if not Hit then
		return true
	end

	if type(Particle.RemoveOnCollision) == "function" then
		if not Particle:RemoveOnCollision(Hit, RaycastResult.Position, RaycastResult.Normal, RaycastResult.Material) then
			return false
		end
	else
		return false
	end

	return true
end

local function UpdateScreenInfo(self, CurrentCamera)
	local AbsoluteSize = self.ScreenGui.AbsoluteSize
	local ScreenSizeX = AbsoluteSize.X
	local ScreenSizeY = AbsoluteSize.Y
	local PlaneSizeY = 2 * math.tan(CurrentCamera.FieldOfView * 0.0087266462599716)

	self.ScreenSizeX = ScreenSizeX
	self.ScreenSizeY = ScreenSizeY
	self.PlaneSizeY = PlaneSizeY
	self.PlaneSizeX = PlaneSizeY * ScreenSizeX / ScreenSizeY
end

local function ParticleRender(self, CameraPosition, CameraInverse, Frame, Particle)
	local RealPosition = CameraInverse * Particle.Position
	local LastScreenPosition = Particle.LastScreenPosition

	local ScreenSizeX = self.ScreenSizeX
	local ScreenSizeY = self.ScreenSizeY
	local PlaneSizeX = self.PlaneSizeX
	local PlaneSizeY = self.PlaneSizeY

	if not (RealPosition.Z < -1 and LastScreenPosition) then
		if RealPosition.Z > 0 then
			Particle.LastScreenPosition = nil
		else
			local ScreenPosition = RealPosition / RealPosition.Z
			Particle.LastScreenPosition = Vector2.new(
				(0.5 - ScreenPosition.X / PlaneSizeX) * ScreenSizeX,
				(0.5 + ScreenPosition.Y / PlaneSizeY) * ScreenSizeY
			)
		end

		return false
	end

	local ScreenPosition = RealPosition / RealPosition.Z
	local Bloom = Particle.Bloom
	local Transparency = Particle.Transparency
	local PositionX = (0.5 - ScreenPosition.X / PlaneSizeX) * ScreenSizeX
	local PositionY = (0.5 + ScreenPosition.Y / PlaneSizeY) * ScreenSizeY
	local PreSizeY = -Particle.Size.Y / RealPosition.Z * ScreenSizeY / PlaneSizeY
	local SizeX = -Particle.Size.X / RealPosition.Z * ScreenSizeY / PlaneSizeY + Bloom.X
	local RealPositionX, RealPositionY = PositionX - LastScreenPosition.X, PositionY - LastScreenPosition.Y
	local SizeY = PreSizeY + math.sqrt(RealPositionX * RealPositionX + RealPositionY * RealPositionY) + Bloom.Y
	Particle.LastScreenPosition = Vector2.new(PositionX, PositionY)

	if Particle.Occlusion then
		local Position: Vector3 = Particle.Position - CameraPosition
		local Magnitude = Position.Magnitude
		if Magnitude > 999 then
			Position *= (999 / Magnitude)
		end

		UpdateParameters.FilterDescendantsInstances = table.create(1, self.LocalPlayer.Character)
		if Workspace:Raycast(CameraPosition, Position, UpdateParameters) then
			return false
		end
	end

	Frame.Position = UDim2.fromOffset((PositionX + LastScreenPosition.X - SizeX) / 2, (PositionY + LastScreenPosition.Y - SizeY) / 2)
	Frame.Size = UDim2.fromOffset(SizeX, SizeY)
	Frame.Rotation = 90 + math.atan2(RealPositionY, RealPositionX) * 57.295779513082
	Frame.BackgroundColor3 = Particle.Color
	Frame.BackgroundTransparency = Transparency + (1 - Transparency) * (1 - PreSizeY / SizeY)

	return true
end

local function UpdateRender(self)
	local CurrentCamera = Workspace.CurrentCamera
	UpdateScreenInfo(self, CurrentCamera)

	local CameraCFrame = CurrentCamera.CFrame
	local CameraInverse = CameraCFrame:Inverse()
	local CameraPosition = CameraCFrame.Position

	local ParticleFrames = self.ParticleFrames
	local ScreenGui = self.ScreenGui

	local FrameIndex, Frame = next(ParticleFrames)
	for Particle in next, self.Particles do
		if ParticleRender(self, CameraPosition, CameraInverse, Frame, Particle) then
			Frame.Parent = ScreenGui
			FrameIndex, Frame = next(ParticleFrames, FrameIndex)
		end
	end

	while FrameIndex and Frame.Parent do
		Frame.Parent = nil
		FrameIndex, Frame = next(ParticleFrames, FrameIndex)
	end
end

function Update(self)
	local CurrentTime = time()
	local DeltaTime = CurrentTime - self.LastUpdateTime
	self.LastUpdateTime = CurrentTime

	local ToRemove = {}
	for Particle in next, self.Particles do
		if not UpdateParticle(self, Particle, CurrentTime, DeltaTime) then
			ToRemove[Particle] = true
		end
	end

	for Particle in next, ToRemove do
		self:Remove(Particle)
	end

	UpdateRender(self)
end

return ParticleEngineClient