--- Interface between user input and camera controls
-- @classmod CameraControls

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Resources = require(ReplicatedStorage.Resources)

local GamepadRotateModel = Resources:LoadLibrary("GamepadRotateModel")
local InputObjectUtils = Resources:LoadLibrary("InputObjectUtils")
local Janitor = Resources:LoadLibrary("Janitor")

--- Stolen directly from ROBLOX's core scripts.
-- Looks like a simple integrator.
-- Called (zoom, zoomScale, 1) returns zoom
local function rk4Integrator(position, velocity, t)
	local direction = velocity < 0 and -1 or 1
	local function acceleration(p)
		local accel = direction * math.max(1, (p / 3.3) + 0.5)
		return accel
	end

	local p1 = position
	local v1 = velocity
	local a1 = acceleration(p1)
	local p2 = p1 + v1 * (t / 2)
	local v2 = v1 + a1 * (t / 2)
	local a2 = acceleration(p2)
	local p3 = p1 + v2 * (t / 2)
	local v3 = v1 + a2 * (t / 2)
	local a3 = acceleration(p3)
	local p4 = p1 + v3 * t
	local v4 = v1 + a3 * t
	local a4 = acceleration(p4)

	local positionResult = position + (v1 + 2 * v2 + 2 * v3 + v4) * (t / 6)
	local velocityResult = velocity + (a1 + 2 * a2 + 2 * a3 + a4) * (t / 6)
	return positionResult, velocityResult
end

local CameraControls = {
	ClassName = "CameraControls";
	MOUSE_SENSITIVITY = Vector2.new(math.pi*4, math.pi*1.9);
	DragBeginTypes = {Enum.UserInputType.MouseButton2, Enum.UserInputType.Touch};
}

CameraControls.__index = CameraControls

function CameraControls.new(ZoomCamera, RotatedCamera)
	local self = setmetatable({
		Enabled = false;
		Key = nil;
		GamepadRotateModel = GamepadRotateModel.new();
	}, CameraControls)

	self.Key = tostring(self) .. "CameraControls"
	if ZoomCamera then
		self:SetZoomedCamera(ZoomCamera)
	end

	if RotatedCamera then
		self:SetRotatedCamera(RotatedCamera)
	end

	return self
end

function CameraControls:GetKey()
	return self.Key
end

function CameraControls:IsEnabled()
	return self.Enabled
end

function CameraControls:Enable()
	if self.Enabled then
		return
	end

	assert(not self.Janitor)
	self.Enabled = true

	self.Janitor = Janitor.new()

	self.Janitor:Add(self.GamepadRotateModel.IsRotating.Changed:Connect(function()
		if self.GamepadRotateModel.IsRotating.Value then
			self:_HandleGamepadRotateStart()
		else
			self:_HandleGamepadRotateStop()
		end
	end), "Disconnect")

	ContextActionService:BindAction(self.Key, function(_, _, InputObject)
		if InputObject.UserInputType == Enum.UserInputType.MouseWheel then
			self:_HandleMouseWheel(InputObject)
		end
	end, false, Enum.UserInputType.MouseWheel)

	ContextActionService:BindAction(self.Key .. "Drag", function(_, UserInputState, InputObject)
		if UserInputState == Enum.UserInputState.Begin then
			self:BeginDrag(InputObject)
		end
	end, false, table.unpack(self.DragBeginTypes))

	ContextActionService:BindAction(self.Key .. "Rotate", function(_, _, InputObject)
		self:_HandleThumbstickInput(InputObject)
	end, false, Enum.KeyCode.Thumbstick2)

	self.Janitor:Add(UserInputService.TouchPinch:Connect(function(_, Scale, Velocity, UserInputState)
		self:_HandleTouchPinch(Scale, Velocity, UserInputState)
	end), "Disconnect")

	self.Janitor:Add(function()
		ContextActionService:UnbindAction(self.Key)
		ContextActionService:UnbindAction(self.Key .. "Drag")
		ContextActionService:UnbindAction(self.Key .. "Rotate")
	end, true)
end

function CameraControls:Disable()
	if not self.Enabled then
		return
	end

	self.Enabled = false
	self.Janitor:Destroy()
	self.LastMousePosition = nil
end

function CameraControls:BeginDrag(BeginInputObject)
	if not self.RotatedCamera then
		return self.Janitor:Remove("DragJanitor")
	end

	local DragJanitor = self.Janitor:Add(Janitor.new(), "Destroy", "DragJanitor")
	self.LastMousePosition = BeginInputObject.Position
	local IsMouse = InputObjectUtils.IsMouseUserInputType(BeginInputObject.UserInputType)
	if IsMouse then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	end

	DragJanitor:Add(UserInputService.InputEnded:Connect(function(InputObject)
		if InputObject == BeginInputObject then
			self:_EndDrag()
		end
	end), "Disconnect")

	DragJanitor:Add(UserInputService.InputChanged:Connect(function(InputObject)
		if IsMouse and InputObject.UserInputType == Enum.UserInputType.MouseMovement
			or InputObject == BeginInputObject
		then
			self:_HandleMouseMovement(InputObject)
		end
	end), "Disconnect")

	if self.RotatedCamera.ClassName == "SmoothRotatedCamera" then
		self.RotVelocityTracker = self:_GetVelocityTracker(0.05, Vector2.new())
	end
end

function CameraControls:SetZoomedCamera(ZoomedCamera)
	self.ZoomedCamera = ZoomedCamera or error("No ZoomedCamera!")
	self.StartZoomScale = self.ZoomedCamera.Zoom
	return self
end

function CameraControls:SetRotatedCamera(RotatedCamera)
	self.RotatedCamera = RotatedCamera or error("No RotatedCamera!")
	return self
end

--- This code was the same algorithm used by ROBLOX. It makes it so you can zoom easier at further distances.
function CameraControls:_HandleMouseWheel(InputObject)
	if self.ZoomedCamera then
		self.ZoomedCamera.TargetZoom = rk4Integrator(self.ZoomedCamera.TargetZoom, math.clamp(-InputObject.Position.Z, -1, 1)*1.4, 1)
	end

	if self.RotatedCamera and self.RotatedCamera.ClassName == "PushCamera" then
		self.RotatedCamera:StopRotateBack()
	end
end

function CameraControls:_HandleTouchPinch(Scale, Velocity, UserInputState)
	if self.ZoomedCamera then
		if UserInputState == Enum.UserInputState.Begin then
			self.StartZoomScale = self.ZoomedCamera.Zoom
			self.ZoomedCamera.Zoom = self.StartZoomScale*1/Scale
		elseif UserInputState == Enum.UserInputState.End then
			self.ZoomedCamera.Zoom = self.StartZoomScale*1/Scale
			self.ZoomedCamera.TargetZoom = self.ZoomedCamera.Zoom + -Velocity/5
		elseif UserInputState == Enum.UserInputState.Change then
			if self.StartZoomScale then
				self.ZoomedCamera.TargetZoom = self.StartZoomScale*1/Scale
				self.ZoomedCamera.Zoom = self.ZoomedCamera.TargetZoom
			else
				warn("[CameraControls._HandleTouchPinch] - No self.StartZoomScale")
			end
		end
	end
end

--- This is also a ROBLOX algorithm. Not sure why screen resolution is locked like it is.
function CameraControls._MouseTranslationToAngle(_, TranslationVector)
	return Vector2.new(TranslationVector.X / 1920, TranslationVector.Y / 1200)
end

function CameraControls._GetVelocityTracker(_, Strength, StartVelocity)
	Strength = Strength or 1

	local LastUpdate = time()
	local Velocity = StartVelocity

	return {
		Update = function(_, DeltaTime)
			local Elapsed = time() - LastUpdate
			LastUpdate = time()
			Velocity /= (2 ^ (Elapsed / Strength)) + (DeltaTime / (0.0001 + Elapsed)) * Strength
		end;

		GetVelocity = function(self)
			self:Update(StartVelocity * 0)
			return Velocity
		end;
	}
end

function CameraControls:_HandleMouseMovement(InputObject, IsMouse)
	if self.LastMousePosition then
		if self.RotatedCamera then
			-- This calculation may seem weird, but either .Position updates (if it's locked), or .Delta updates (if it's not).
			local Delta
			if IsMouse then
				Delta = -InputObject.Delta + self.LastMousePosition - InputObject.Position
			else
				Delta = -InputObject.Delta
			end

			local DeltaAngle = Vector2.new(Delta.X / 1920, Delta.Y / 1200) * self.MOUSE_SENSITIVITY
			self.RotatedCamera:RotateXY(DeltaAngle)

			if self.RotVelocityTracker then
				self.RotVelocityTracker:Update(DeltaAngle)
			end
		end

		self.LastMousePosition = InputObject.Position
	end
end

function CameraControls:_HandleThumbstickInput(InputObject)
	self.GamepadRotateModel:HandleThumbstickInput(InputObject)
end

function CameraControls:_ApplyRotVelocityTracker(RotVelocityTracker)
	if self.RotatedCamera then
		local Position = self.RotatedCamera.AngleXZ
		local Velocity = RotVelocityTracker:GetVelocity().X
		local NewVelocityTarget = Position + Velocity
		local Target = self.RotatedCamera.TargetAngleXZ

		if math.abs(NewVelocityTarget - Position) > math.abs(Target - Position) then
			self.RotatedCamera.TargetAngleXZ = NewVelocityTarget
		end

		self.RotatedCamera:SnapIntoBounds()
	end
end

function CameraControls:_EndDrag()
	if self.RotVelocityTracker then
		self:_ApplyRotVelocityTracker(self.RotVelocityTracker)
		self.RotVelocityTracker = nil
	end

	self.LastMousePosition = nil
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	self.Janitor:Remove("DragJanitor")
end

function CameraControls:_HandleGamepadRotateStop()
	if self.RotVelocityTracker then
		self:_ApplyRotVelocityTracker(self.RotVelocityTracker)
		self.RotVelocityTracker = nil
	end

	self.Janitor:Remove("DragJanitor")
end

function CameraControls:_HandleGamepadRotateStart()
	if not self.RotatedCamera then
		return self.Janitor:Remove("DragJanitor")
	end

	local DragJanitor = self.Janitor:Add(Janitor.new(), "Destroy", "DragJanitor")
	if self.RotatedCamera.ClassName == "SmoothRotatedCamera" then
		self.RotVelocityTracker = self:_GetVelocityTracker(0.05, Vector2.new())
	end

	DragJanitor:Add(RunService.Stepped:Connect(function()
		local DeltaAngle = self.GamepadRotateModel:GetThumbstickDeltaAngle() / 10

		if self.RotatedCamera then
			self.RotatedCamera:RotateXY(DeltaAngle)
		end

		if self.RotVelocityTracker then
			self.RotVelocityTracker:Update(DeltaAngle)
		end
	end), "Disconnect")
end

function CameraControls:Destroy()
	self.GamepadRotateModel:Destroy()
	self:Disable()
	setmetatable(self, nil)
end

return CameraControls