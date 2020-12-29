local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadLibrary("Constants")

Resources:LoadLibrary("CameraStackService"):Initialize()
Resources:LoadLibrary("TimeSyncService"):Initialize()
Resources:LoadLibrary("RagdollHandler"):Initialize(Constants.CONFIGURATION.RAGDOLL_TAG_NAME)
Resources:LoadClient("CharacterController")

return false