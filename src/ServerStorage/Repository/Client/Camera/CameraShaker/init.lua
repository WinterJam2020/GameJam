-- Camera Shaker
-- Crazyman32
-- February 26, 2018

--[[
	CameraShaker.CameraShakeInstance
	cameraShaker = CameraShaker.new(renderPriority, callbackFunction)

	CameraShaker:Start()
	CameraShaker:Stop()
	CameraShaker:Shake(shakeInstance)
	CameraShaker:ShakeSustain(shakeInstance)
	CameraShaker:ShakeOnce(magnitude, roughness [, fadeInTime, fadeOutTime, posInfluence, rotInfluence])
	CameraShaker:StartShake(magnitude, roughness [, fadeInTime, posInfluence, rotInfluence])

	EXAMPLE:
		local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
			camera.CFrame = playerCFrame * shakeCFrame
		end)
		camShake:Start()

		-- Explosion shake:
		camShake:Shake(CameraShaker.Presets.Explosion)

		wait(1)

		-- Custom shake:
		camShake:ShakeOnce(3, 1, 0.2, 1.5)
		wait(1)

		-- Sustained shake:
		local swayShakeInstance = CameraShaker.Presets.GentleSway
		camShake:ShakeSustain(swayShakeInstance)
		wait(3)

		-- Sustained shake fadeout:
		swayShakeInstance:StartFadeOut(3)

		-- "CameraShaker.Presets.GentleSway" or any other preset
		-- will always return a new ShakeInstance. If you want
		-- to fade out a previously sustained ShakeInstance, you
		-- will need to assign it to a variable before sustaining it.

	NOTE:
		This was based entirely on the EZ Camera Shake asset for Unity3D. I was given written
		permission by the developer, Road Turtle Games, to port this to Roblox.

		Original asset link: https://assetstore.unity.com/packages/tools/camera/ez-camera-shake-33148
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local CameraShakeInstance = require(script.CameraShakeInstance)
local Enumeration = Resources:LoadLibrary("Enumerations")
local Services = Resources:LoadLibrary("Services")

local RunService: RunService = Services.RunService

local CameraShaker = {
	CameraShakeInstance = CameraShakeInstance;
	ClassName = "CameraShaker";
	Presets = require(script.CameraShakePresets);
}

CameraShaker.__index = CameraShaker

local PROFILE_TAG = "CameraUpdateMovement"

local v3Zero = Vector3.new()

local defaultPosInfluence = Vector3.new(0.15, 0.15, 0.15)
local defaultRotInfluence = Vector3.new(1, 1, 1)

function CameraShaker.new(renderPriority, callback)
	assert(type(renderPriority) == "number", "RenderPriority must be a number (e.g.: Enum.RenderPriority.Camera.Value)")
	assert(type(callback) == "function", "Callback must be a function")

	return setmetatable({
		_running = false;
		_renderName = "CameraShaker";
		_renderPriority = renderPriority;
		_posAddShake = v3Zero;
		_rotAddShake = v3Zero;
		_camShakeInstances = {};
		_removeInstances = {};
		_callback = callback;
	}, CameraShaker)
end

function CameraShaker:Start()
	if not self._running then
		self._running = true
		local callback = self._callback
		RunService:BindToRenderStep(self._renderName, self._renderPriority, function(dt)
			debug.profilebegin(PROFILE_TAG)
			local cf = self:Update(dt)
			debug.profileend()
			callback(cf)
		end)
	end
end

function CameraShaker:Stop()
	if self._running then
		RunService:UnbindFromRenderStep(self._renderName)
		self._running = false
	end
end

function CameraShaker:Update(dt)
	local posAddShake = v3Zero
	local rotAddShake = v3Zero

	local instances = self._camShakeInstances
	local length = #self._removeInstances

	-- Update all instances:
	for i, c in ipairs(instances) do
		local state = c:GetState()
		if state == Enumeration.CameraShakeState.Inactive and c.DeleteOnInactive then
			length += 1
			self._removeInstances[length] = i
		elseif state ~= Enumeration.CameraShakeState.Inactive then
			posAddShake += c:UpdateShake(dt) * c.PositionInfluence
			rotAddShake += c:UpdateShake(dt) * c.RotationInfluence
		end
	end

	-- Remove dead instances:
	for i = length, 1, -1 do
		local instIndex = self._removeInstances[i]
		table.remove(instances, instIndex)
		self._removeInstances[i] = nil
	end

	return CFrame.new(posAddShake) * CFrame.fromOrientation(0.017453292519943 * rotAddShake.X, 0.017453292519943 * rotAddShake.Y, 0.017453292519943 * rotAddShake.Z)
end

function CameraShaker:Shake(shakeInstance)
	assert(type(shakeInstance) == "table" and shakeInstance._camShakeInstance, "ShakeInstance must be of type CameraShakeInstance")
	table.insert(self._camShakeInstances, shakeInstance)
	return shakeInstance
end

function CameraShaker:ShakeSustain(shakeInstance)
	assert(type(shakeInstance) == "table" and shakeInstance._camShakeInstance, "ShakeInstance must be of type CameraShakeInstance")
	table.insert(self._camShakeInstances, shakeInstance)
	shakeInstance:StartFadeIn(shakeInstance.fadeInDuration)
	return shakeInstance
end

function CameraShaker:ShakeOnce(magnitude, roughness, fadeInTime, fadeOutTime, posInfluence, rotInfluence)
	local shakeInstance = CameraShakeInstance.new(magnitude, roughness, fadeInTime, fadeOutTime)
	shakeInstance.PositionInfluence = typeof(posInfluence) == "Vector3" and posInfluence or defaultPosInfluence
	shakeInstance.RotationInfluence = typeof(rotInfluence) == "Vector3" and rotInfluence or defaultRotInfluence

	table.insert(self._camShakeInstances, shakeInstance)
	return shakeInstance
end

function CameraShaker:StartShake(magnitude, roughness, fadeInTime, posInfluence, rotInfluence)
	local shakeInstance = CameraShakeInstance.new(magnitude, roughness, fadeInTime)
	shakeInstance.PositionInfluence = typeof(posInfluence) == "Vector3" and posInfluence or defaultPosInfluence
	shakeInstance.RotationInfluence = typeof(rotInfluence) == "Vector3" and rotInfluence or defaultRotInfluence

	shakeInstance:StartFadeIn(fadeInTime)
	table.insert(self._camShakeInstances, shakeInstance)
	return shakeInstance
end

return CameraShaker