---
-- @module FieldOfViewUtils
-- @author Quenty

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Math = Resources:LoadLibrary("Math")

local FieldOfViewUtils = {}

function FieldOfViewUtils.FovToHeight(Fov)
    return 2*math.tan(math.rad(Fov)/2)
end

function FieldOfViewUtils.HeightToFov(Height)
    return 2*math.deg(math.atan(Height/2))
end

function FieldOfViewUtils.SafeLog(Height, LinearAt)
	if Height < LinearAt then
		return (1/LinearAt)*(Height - LinearAt) + math.log(LinearAt)
	else
		return math.log(Height)
	end
end

function FieldOfViewUtils.SafeExp(LogHeight, LinearAt)
	local TransitionAt = math.log(LinearAt)

	if LogHeight <= TransitionAt then
		return LinearAt*(LogHeight - TransitionAt) + LinearAt
	else
		return math.exp(LogHeight)
	end
end

function FieldOfViewUtils.LerpInHeightSpace(Fov0, Fov1, Percent)
	local Height0 = FieldOfViewUtils.FovToHeight(Fov0)
	local Height1 = FieldOfViewUtils.FovToHeight(Fov1)

	local LinearAt = FieldOfViewUtils.FovToHeight(1)

	local LogHeight0 = FieldOfViewUtils.SafeLog(Height0, LinearAt)
	local LogHeight1 = FieldOfViewUtils.SafeLog(Height1, LinearAt)

	local NewLogHeight = Math.Lerp(LogHeight0, LogHeight1, Percent)

	return FieldOfViewUtils.HeightToFov(FieldOfViewUtils.SafeExp(NewLogHeight, LinearAt))
end

return FieldOfViewUtils