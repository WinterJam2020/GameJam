local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

Resources:LoadLibrary("ParticleEngine"):Initialize()
Resources:LoadLibrary("TimeSyncService"):Initialize()
Resources:LoadLibrary("PlayerDataHandler"):Initialize()