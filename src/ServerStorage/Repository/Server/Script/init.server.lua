local GenerateSkiPath = require(script.GenerateSkiPath)
local GenerateMarkers = require(script.GenerateMarkers)
local GenerateGates = require(script.GenerateGates)

local Spline = GenerateSkiPath()
GenerateMarkers(Spline)
GenerateGates(Spline)

workspace.CurrentCamera.CFrame = Spline.GetCFrameOnPath(0) + Vector3.new(0, 20, 0)
workspace.CurrentCamera.Focus = Spline.GetCFrameOnPath(0)

repeat
	wait()
until #game.Players:GetPlayers() > 0
for _, plr in ipairs(game.Players:GetPlayers()) do
	plr:LoadCharacter()
	local chr = plr.Character
	local root = chr:WaitForChild("HumanoidRootPart")
	root.CFrame = Spline.GetCFrameOnPath(0.01) + Vector3.new(0, 20, 0)
end