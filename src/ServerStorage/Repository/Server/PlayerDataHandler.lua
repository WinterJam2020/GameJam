local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local ProfileService = Resources:LoadLibrary("ProfileService")

local PROFILE_TEMPLATE = {
	BestScore = 0;
}

local PlayerDataHandler = {
	Profiles = {};
}

function PlayerDataHandler:Initialize()
	return self
end

return PlayerDataHandler