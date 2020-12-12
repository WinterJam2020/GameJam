--- Holds camera states and allows for the last camera state to be retrieved. Also
-- initializes an impulse and default camera as the bottom of the stack. Is a singleton.
-- @module CameraStackService

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local CustomCameraEffect = Resources:LoadLibrary("CustomCameraEffect")
local Debug = Resources:LoadLibrary("Debug")
local DefaultCamera = Resources:LoadLibrary("DefaultCamera")
local ImpulseCamera = Resources:LoadLibrary("ImpulseCamera")
local Table = Resources:LoadLibrary("Table")

local Debug_Assert = Debug.Assert
local Debug_Warn = Debug.Warn
local Table_FastRemove = Table.FastRemove

Debug_Assert(RunService:IsClient(), "[CameraStackService] - Only require CameraStackService on client")

local CameraStackService = {}

function CameraStackService:Init(doNotUseDefaultCamera)
	self._stack = {}
	self._disabledSet = {}

	-- Initialize default cameras
	self._rawDefaultCamera = DefaultCamera.new()
	self._impulseCamera = ImpulseCamera.new()
	self._defaultCamera = (self._rawDefaultCamera + self._impulseCamera):SetMode("Relative")

	if doNotUseDefaultCamera then
		Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

		-- TODO: Handle camera deleted too!
		Workspace.CurrentCamera:GetPropertyChangedSignal("CameraType"):Connect(function()
			Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		end)
	else
		self._rawDefaultCamera:BindToRenderStep()
	end

	-- Add camera to stack
	self:Add(self._defaultCamera)

	RunService:BindToRenderStep("CameraStackUpdateInternal", Enum.RenderPriority.Camera.Value + 75, function()
		debug.profilebegin("CameraStackUpdate")

		if next(self._disabledSet) then
			return
		end

		local state = self:GetTopState()
		if state and state ~= self._defaultCamera then
			state:Set(Workspace.CurrentCamera)
		end

		debug.profileend()
	end)
end

function CameraStackService:PushDisable()
	local disabledKey = HttpService:GenerateGUID(false)
	self._disabledSet[disabledKey] = true

	return function()
		self._disabledSet[disabledKey] = nil
	end
end

--- Outputs the camera stack
-- @treturn nil
function CameraStackService:PrintCameraStack()
	local stack = self._stack
	if not stack then
		error("Stack is not initialized yet.")
	end

	for _, value in ipairs(stack) do
		print(tostring(type(value) == "table" and value.ClassName or tostring(value)))
	end
end

--- Returns the default camera
-- @treturn SummedCamera DefaultCamera + ImpulseCamera
function CameraStackService:GetDefaultCamera()
	return self._defaultCamera or error("No DefaultCamera")
end

--- Returns the impulse camera. Useful for adding camera shake
-- @treturn ImpulseCamera
function CameraStackService:GetImpulseCamera()
	return self._impulseCamera or error("No ImpulseCamera")
end

--- Returns the default camera without any impulse cameras
-- @treturn DefaultCamera
function CameraStackService:GetRawDefaultCamera()
	return self._rawDefaultCamera or error("No RawDefaultCamera")
end

function CameraStackService:GetTopCamera()
	return self._stack[#self._stack]
end

--- Retrieves the top state off the stack
-- @treturn[1] CameraState
-- @treturn[2] nil
function CameraStackService:GetTopState()
	local stack = Debug_Assert(self._stack, "Stack is not initialized yet")
	if #stack > 10 then
		Debug_Warn("[CameraStackService] - Stack is bigger than 10 in camerastackService (%d)", #stack)
	end

	local topState = stack[#stack]
	if type(topState) == "table" then
		local state = topState.CameraState or topState
		if state then
			return state
		else
			warn("[CameraStackService] - No top state!")
		end
	else
		warn("[CameraStackService] - Bad type on top of stack")
	end
end

--- Returns a new camera state that retrieves the state below its set state
-- @treturn[1] CustomCameraEffect
-- @treturn[1] NewStateToUse
function CameraStackService:GetNewStateBelow()
	local stack = Debug.Assert(self._stack, "Stack is not initialized yet")
	local _stateToUse = nil

	return CustomCameraEffect.new(function()
		local index = table.find(stack, _stateToUse)
		if index then
			local below = stack[index - 1]
			if below then
				return below.CameraState or below
			else
				warn("[CameraStackService] - Could not get state below, found current state. Returning default.")
				return stack[1].CameraState
			end
		else
			warn("[CameraStackService] - Could not get state, returning default")
			return stack[1].CameraState
		end
	end), function(newStateToUse)
		_stateToUse = newStateToUse
	end
end

--- Retrieves the index of a state
-- @tparam CameraState state
-- @treturn number Index of state
-- @treturn nil If non on stack
function CameraStackService:GetIndex(state)
	return table.find(Debug_Assert(self._stack, "Stack is not initialized yet"), state)
end

function CameraStackService:GetStack()
	return self._stack
end

--- Removes the state from the stack
-- @tparam CameraState state
-- @treturn nil
function CameraStackService:Remove(state)
	local stack = Debug_Assert(self._stack, "Stack is not initialized yet")
	local index = table.find(stack, state)
	if index then
		Table_FastRemove(stack, index)
	end
end

--- Adds a state to the stack
-- @tparam CameraState state
-- @treturn nil
function CameraStackService:Add(state)
	table.insert(Debug_Assert(self._stack, "Stack is not initialized yet"), state)
end

return CameraStackService