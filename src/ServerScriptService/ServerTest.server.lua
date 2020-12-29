local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local GenerateSkiPath = Resources:LoadLibrary("GenerateSkiPath")
local GenerateMarkers = Resources:LoadLibrary("GenerateMarkers")
local GenerateGates = Resources:LoadLibrary("GenerateGates")

local SplineRemote = ReplicatedStorage.SplineRemote

workspace.Baseplate:Destroy()
local SkiPath, SkiPathCFrames, CameraPathCFrames = GenerateSkiPath()
GenerateMarkers(SkiPath)
GenerateGates(SkiPath)

function SplineRemote.OnServerInvoke()
	return SkiPathCFrames, CameraPathCFrames
end