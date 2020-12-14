local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local CatchFactory = Resources:LoadLibrary("CatchFactory")
local Enumeration = Resources:LoadLibrary("Enumerations")
local ProfileService = Resources:LoadLibrary("ProfileService")
-- local SyncedPoller = Resources:LoadLibrary("SyncedPoller")
local Typer = Resources:LoadLibrary("Typer")

local PlayerDataHandler = {
	Profiles = {};
	DefaultData = {
		HighScore = 0;
		Points = 0;
		Inventory = {BasicSkis = true};
	};
}

function PlayerDataHandler:Initialize()
	self.GameStore = ProfileService.GetProfileStore(
		"WinterGame" .. (RunService:IsStudio() and "Build" or "Release"),
		self.DefaultData
	)

	local function PlayerAdded(Player: Player)
		CollectionService:AddTag(Player, "PlayerDataConnected")
		self.GameStore:LoadProfileAsync(tostring(Player.UserId), Enumeration.DataStoreHandler.ForceLoad):Then(function(Profile)
			if Profile then
				Profile:Reconcile()
				Profile:ListenToRelease(function()
					self.Profiles[Player] = nil
					Player:Kick("Saved your data.")
				end)

				if Player:IsDescendantOf(Players) then
					self.Profiles[Player] = Profile
				else
					Profile:Release()
				end
			else
				Player:Kick("Couldn't load your data.")
			end
		end):Catch(function(Error)
			CatchFactory("GameStore::LoadProfileAsync")(Error)
			Player:Kick(tostring(Error))
		end):Finally(function()
			local Leaderstats = Instance.new("Folder")
			Leaderstats.Name = "leaderstats"

			Leaderstats.Parent = Player
		end)
	end

	local function PlayerRemoving(Player: Player)
		local Profile = self.Profiles[Player]
		if Profile then
			Profile:Release()
		end
	end

	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(PlayerRemoving)

	for _, Player in ipairs(Players:GetPlayers()) do
		if not CollectionService:HasTag(Player, "PlayerDataConnected") then
			PlayerAdded(Player)
		end
	end

	return self
end

function PlayerDataHandler:SetPoints(Player: Player, Points: number)
	local Profile = self.Profiles[Player]
	if Profile then
		Profile.Data.Points = Points
	end
end

function PlayerDataHandler:SetHighScore(Player: Player, HighScore: number)
	local Profile = self.Profiles[Player]
	if Profile then
		Profile.Data.HighScore = HighScore
	end
end

function PlayerDataHandler:IncrementPoints(Player: Player, IncrementBy: number)
	local Profile = self.Profiles[Player]
	if Profile then
		Profile.Data.Points += IncrementBy
	end
end

function PlayerDataHandler:IncrementHighScore(Player: Player, IncrementBy: number)
	local Profile = self.Profiles[Player]
	if Profile then
		Profile.Data.HighScore += IncrementBy
	end
end

PlayerDataHandler.Get = Typer.AssignSignature(2, Typer.InstanceWhichIsAPlayer, function(self, Player)
	return self.Profiles[Player]
end)

return PlayerDataHandler