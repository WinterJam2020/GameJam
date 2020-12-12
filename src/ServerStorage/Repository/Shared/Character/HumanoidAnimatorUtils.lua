---
-- @module HumanoidAnimatorUtils

local HumanoidAnimatorUtils = {}

function HumanoidAnimatorUtils.GetOrCreateAnimator(Humanoid)
	local Animator = Humanoid:FindFirstChildOfClass("Animator")
	if not Animator then
		Animator = Instance.new("Animator")
		Animator.Name = "Animator"
		Animator.Parent = Humanoid
	end

	return Animator
end

function HumanoidAnimatorUtils.StopAnimations(Humanoid, FadeTime)
	for _, Track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
		Track:Stop(FadeTime)
	end
end

function HumanoidAnimatorUtils.IsPlayingAnimationTrack(Humanoid, Track)
	for _, PlayingTrack in ipairs(Humanoid:GetPlayingAnimationTracks()) do
		if PlayingTrack == Track then
			return true
		end
	end

	return false
end

return HumanoidAnimatorUtils