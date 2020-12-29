local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadShared("Constants")
local SkiPathRemote = Resources:GetRemoteFunction(Constants.REMOTE_NAMES.SKI_PATH_REMOTE_FUNCTION_NAME)
local GenerateSkiPath = Resources:LoadLibrary("GenerateSkiPath")
local GenerateMarkers = Resources:LoadLibrary("GenerateMarkers")
local GenerateGates = Resources:LoadLibrary("GenerateGates")

workspace.Baseplate:Destroy()
local SkiPath, SkiPathCFrames, CameraPathCFrames = GenerateSkiPath()
GenerateMarkers(SkiPath)
GenerateGates(SkiPath)

function SkiPathRemote.OnServerInvoke()
	return SkiPathCFrames, CameraPathCFrames
end