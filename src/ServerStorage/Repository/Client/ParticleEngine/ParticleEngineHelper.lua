local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local ParticleEngine = Resources:LoadLibrary("ParticleEngine")

local ParticleEngineHelper = {}

function ParticleEngineHelper.Add(Properties)
	ParticleEngine:Add(Properties)
end

function ParticleEngineHelper.Remove(Properties)
	ParticleEngine:Remove(Properties)
end

return ParticleEngineHelper