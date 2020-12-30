-- Camera Shake Instance
-- Crazyman32
-- February 26, 2018

--[[
	cameraShakeInstance = CameraShakeInstance.new(magnitude, roughness, fadeInTime, fadeOutTime)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Enumeration = Resources:LoadLibrary("Enumerations")

local CameraShakeInstance = {ClassName = "CameraShakeInstance"}
CameraShakeInstance.__index = CameraShakeInstance

function CameraShakeInstance.new(magnitude, roughness, fadeInTime, fadeOutTime)
	fadeInTime = fadeInTime or 0
	fadeOutTime = fadeOutTime or 0

	assert(type(magnitude) == "number", "Magnitude must be a number")
	assert(type(roughness) == "number", "Roughness must be a number")
	assert(type(fadeInTime) == "number", "FadeInTime must be a number")
	assert(type(fadeOutTime) == "number", "FadeOutTime must be a number")

	return setmetatable({
		Magnitude = magnitude;
		Roughness = roughness;
		PositionInfluence = Vector3.new();
		RotationInfluence = Vector3.new();
		DeleteOnInactive = true;
		roughMod = 1;
		magnMod = 1;
		fadeOutDuration = fadeOutTime;
		fadeInDuration = fadeInTime;
		sustain = fadeInTime > 0;
		currentFadeTime = fadeInTime > 0 and 0 or 1;
		tick = Random.new(tick() % 1 * 1E7):NextNumber(-100, 100);
		_camShakeInstance = true;
	}, CameraShakeInstance)
end

function CameraShakeInstance:UpdateShake(dt)
	local _tick = self.tick
	local currentFadeTime = self.currentFadeTime

	local offset = Vector3.new(
		math.noise(_tick, 0) / 2,
		math.noise(0, _tick) / 2,
		math.noise(_tick, _tick) / 2
	)

	if self.fadeInDuration > 0 and self.sustain then
		if currentFadeTime < 1 then
			currentFadeTime += dt / self.fadeInDuration
		elseif self.fadeOutDuration > 0 then
			self.sustain = false
		end
	end

	if not self.sustain then
		currentFadeTime -= dt / self.fadeOutDuration
	end

	if self.sustain then
		self.tick = _tick + dt * self.Roughness * self.roughMod
	else
		self.tick = _tick + dt * self.Roughness * self.roughMod * currentFadeTime
	end

	self.currentFadeTime = currentFadeTime
	return offset * self.Magnitude * self.magnMod * currentFadeTime
end

function CameraShakeInstance:StartFadeOut(fadeOutTime)
	if fadeOutTime == 0 then
		self.currentFadeTime = 0
	end

	self.fadeOutDuration = fadeOutTime
	self.fadeInDuration = 0
	self.sustain = false
end

function CameraShakeInstance:StartFadeIn(fadeInTime)
	if fadeInTime == 0 then
		self.currentFadeTime = 1
	end

	self.fadeInDuration = fadeInTime or self.fadeInDuration
	self.fadeOutDuration = 0
	self.sustain = true
end

function CameraShakeInstance:GetScaleRoughness()
	return self.roughMod
end

function CameraShakeInstance:SetScaleRoughness(v)
	self.roughMod = v
end

function CameraShakeInstance:GetScaleMagnitude()
	return self.magnMod
end

function CameraShakeInstance:SetScaleMagnitude(v)
	self.magnMod = v
end

function CameraShakeInstance:GetNormalizedFadeTime()
	return self.currentFadeTime
end

function CameraShakeInstance:IsShaking()
	return self.currentFadeTime > 0 or self.sustain
end

function CameraShakeInstance:IsFadingOut()
	return not self.sustain and self.currentFadeTime > 0
end

function CameraShakeInstance:IsFadingIn()
	return self.currentFadeTime < 1 and self.sustain and self.fadeInDuration > 0
end

function CameraShakeInstance:GetState()
	if self:IsFadingIn() then
		return Enumeration.CameraShakeState.FadingIn
	elseif self:IsFadingOut() then
		return Enumeration.CameraShakeState.FadingOut
	elseif self:IsShaking() then
		return Enumeration.CameraShakeState.Sustained
	else
		return Enumeration.CameraShakeState.Inactive
	end
end

return CameraShakeInstance