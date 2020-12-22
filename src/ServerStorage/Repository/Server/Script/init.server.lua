local GenerateSkiPath = require(script.GenerateSkiPath)
local GenerateMarkers = require(script.GenerateMarkers)
local GenerateGates = require(script.GenerateGates)

local Spline = GenerateSkiPath()
GenerateMarkers(Spline)
GenerateGates(Spline)

local SplineCFrame0 = Spline.GetCFrameOnPath(0)
workspace.CurrentCamera.CFrame = SplineCFrame0 + Vector3.new(0, 20, 0)
workspace.CurrentCamera.Focus = SplineCFrame0 + SplineCFrame0.LookVector * 20

repeat
	wait()
until #game.Players:GetPlayers() > 0
for _, plr in ipairs(game.Players:GetPlayers()) do
	plr:LoadCharacter()
	local chr = plr.Character
	local root = chr:WaitForChild("HumanoidRootPart")
	root.CFrame = Spline.GetCFrameOnPath(0.01) + Vector3.new(0, 20, 0)
end