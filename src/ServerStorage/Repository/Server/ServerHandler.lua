local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadLibrary("Constants")
local GenerateGates = Resources:LoadLibrary("GenerateGates")
local GenerateMarkers = Resources:LoadLibrary("GenerateMarkers")
local GenerateSkiPath = Resources:LoadLibrary("GenerateSkiPath")

Resources:LoadLibrary("ParticleEngine"):Initialize()
Resources:LoadLibrary("TimeSyncService"):Initialize()
-- Resources:LoadLibrary("PlayerDataHandler"):Initialize()
-- Resources:LoadLibrary("RagdollHandler"):Initialize(Constants.CONFIGURATION.RAGDOLL_TAG_NAME)

local GameEvent = Resources:GetRemoteEvent("GameEvent")

return false