local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadShared("Constants")
local SkiPathRemote = Resources:GetRemoteFunction(Constants.REMOTE_NAMES.SKI_PATH_REMOTE_FUNCTION_NAME)
local SkiPathGenerator = Resources:LoadServer("SkiPathGenerator")
SkiPathGenerator:Initialize()

workspace.Baseplate:Destroy()
local SkiPath, SkiPathCFrames = SkiPathGenerator:Generate()

wait(5)

SkiPathGenerator:Clear()
SkiPathGenerator:Generate()

function SkiPathRemote.OnServerInvoke()
	return SkiPathCFrames
end