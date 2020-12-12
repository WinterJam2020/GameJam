--- Makes transitions between states easier. Uses the `CameraStackService` to tween in and
-- out a new camera state Call `:Show()` and `:Hide()` to do so, and make sure to
-- call `:Destroy()` after usage
-- @classmod CameraStateTweener

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local BaseObject = Resources:LoadLibrary("BaseObject")
local CameraStackService = Resources:LoadLibrary("CameraStackService")
local FadeBetweenCamera = Resources:LoadLibrary("FadeBetweenCamera")
local Scheduler = Resources:LoadLibrary("Scheduler")

local CameraStateTweener = setmetatable({ClassName = "CameraStateTweener"}, BaseObject)
CameraStateTweener.__index = CameraStateTweener

--- Constructs a new camera state tweener
-- @tparam ICameraEffect cameraEffect A camera effect
-- @tparam[opt=20] number speed that the camera tweener tweens at
function CameraStateTweener.new(CameraEffect, Speed)
	local self = setmetatable(BaseObject.new(), CameraStateTweener)

	local CameraBelow, Assign = CameraStackService:GetNewStateBelow()

	self.CameraBelow = CameraBelow
	self.FadeBetween = FadeBetweenCamera.new(CameraBelow, CameraEffect)
	Assign(self.FadeBetween)

	CameraStackService:Add(self.FadeBetween)

	self.FadeBetween.Speed = Speed or 20
	self.FadeBetween.Target = 0
	self.FadeBetween.Value = 0

	self.Janitor:Add(function()
		CameraStackService:Remove(self.FadeBetween)
	end, true)

	return self
end

function CameraStateTweener:GetPercentVisible()
	return self.FadeBetween.Value
end

function CameraStateTweener:Show(DoNotAnimate)
	self:SetTarget(1, DoNotAnimate)
end

function CameraStateTweener:Hide(DoNotAnimate)
	self:SetTarget(0, DoNotAnimate)
end

function CameraStateTweener:IsFinishedHiding()
	return self.FadeBetween.HasReachedTarget and self.FadeBetween.Target == 0
end

function CameraStateTweener:Finish(DoNotAnimate, Function)
	self:Hide(DoNotAnimate)
	if self.FadeBetween.HasReachedTarget then
		Function()
	else
		Scheduler.SpawnDelayed(function()
			while not self.FadeBetween.HasReachedTarget do
				Scheduler.Wait(0.05)
			end

			Function()
		end)
	end
end

function CameraStateTweener:GetCameraBelow()
	return self.CameraBelow
end

function CameraStateTweener:SetTarget(Target, DoNotAnimate)
	self.FadeBetween.Target = Target or error("No target")
	if DoNotAnimate then
		self.FadeBetween.Value = self.FadeBetween.Target
		self.FadeBetween.Velocity = 0
	end

	return self
end

function CameraStateTweener:SetSpeed(Speed)
	self.FadeBetween.Speed = Speed
	return self
end

function CameraStateTweener:SetVisible(IsVisible, DoNotAnimate)
	if IsVisible then
		self:Show(DoNotAnimate)
	else
		self:Hide(DoNotAnimate)
	end
end

function CameraStateTweener:GetFader()
	return self.FadeBetween
end

function CameraStateTweener:Destroy()
	self.Janitor:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

return CameraStateTweener