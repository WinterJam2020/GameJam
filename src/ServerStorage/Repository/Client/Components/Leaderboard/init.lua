local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Roact = Resources:LoadLibrary("Roact")

local Leaderboard = Roact.Component:extend("Leaderboard")

function Leaderboard:init()
end

function Leaderboard:render()
	return Roact.createElement("Frame", {})
end

return Leaderboard