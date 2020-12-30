local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadLibrary("Constants")
local CatchFactory = Resources:LoadLibrary("CatchFactory")
local ClientReducer = Resources:LoadLibrary("ClientReducer")
local MainMenu = Resources:LoadLibrary("MainMenu")
local ParticleEngine = Resources:LoadLibrary("ParticleEngine")
local Promise = Resources:LoadLibrary("Promise")
local PromiseChild = Resources:LoadLibrary("PromiseChild")
local Roact = Resources:LoadLibrary("Roact")
local RoactRodux = Resources:LoadLibrary("RoactRodux")
local Rodux = Resources:LoadLibrary("Rodux")
local ValueObject = Resources:LoadLibrary("ValueObject")
local GameEvent = Resources:GetRemoteEvent("GameEvent")

local ClientHandler = {
	App = nil;
	GameEvent = nil;
	CanMount = nil;
	LocalPlayer = nil;
	MainGui = nil;
	ParticleEngine = nil;
	RoactTree = nil;
	Store = nil;
	TimeSyncService = nil;
}

local CLIENT_EVENTS = {
	[Constants.DISPLAY_LEADERBOARD] = function(self, Entries)
		self.Store:dispatch({
			type = "LeaderboardEntries",
			LeaderboardEntries = Entries,
		}):dispatch({
			type = "LeaderboardVisible",
			IsLeaderboardVisible = true,
		})
	end;

	[Constants.HIDE_LEADERBOARD] = function(self)
		self.Store:dispatch({
			type = "LeaderboardEntries",
			LeaderboardEntries = {},
		}):dispatch({
			type = "LeaderboardVisible",
			IsLeaderboardVisible = false,
		})
	end;

	[Constants.SHOW_MENU] = function(self)
		self.Store:dispatch({
			type = "MenuVisible",
			IsMenuVisible = true,
		})
	end;

	[Constants.HIDE_MENU] = function(self)
		self.Store:dispatch({
			type = "MenuVisible",
			IsMenuVisible = false,
		})
	end;

	[Constants.SHOW_COUNTDOWN] = function(self)
		self.Store:dispatch({
			type = "CountdownVisible",
			IsCountdownVisible = true,
		})
	end;

	[Constants.HIDE_COUNTDOWN] = function(self)
		self.Store:dispatch({
			type = "CountdownVisible",
			IsCountdownVisible = false,
		})
	end;

	[Constants.IS_COUNTDOWN_ACTIVE] = function(self, IsActive)
		self.Store:dispatch({
			type = "CountdownActive",
			IsCountdownActive = IsActive,
		})
	end;

	[Constants.SET_COUNTDOWN_DURATION] = function(self, Duration: number)
		self.Store:dispatch({
			type = "CountdownDuration",
			CountdownDuration = Duration,
		})
	end;

	[Constants.RESET_UI] = function(self)
		self.Store:dispatch({
			type = "ResetAll",
		})
	end;
}

function ClientHandler:Initialize()
	self.GameEvent = GameEvent
	self.CanMount = ValueObject.new(false)
	self.LocalPlayer = Players.LocalPlayer
	self.TimeSyncService = Resources:LoadLibrary("TimeSyncService"):Initialize()

	PromiseChild(self.LocalPlayer, "PlayerGui", 5):Then(function(PlayerGui: PlayerGui)
		PromiseChild(PlayerGui, "MainGui", 60):Then(function(MainGui: ScreenGui)
			self.MainGui = MainGui
			self.ParticleEngine = ParticleEngine:Initialize(MainGui)
			self.ParticleEngineHelper = Resources:LoadLibrary("ParticleEngineHelper")
		end):Catch(CatchFactory("PromiseChild")):Finally(function()
			self.Store = Rodux.Store.new(ClientReducer, nil, {
				Rodux.loggerMiddleware,
			})

			self.App = Roact.createElement(RoactRodux.StoreProvider, {
				store = self.Store,
			}, {
				Main = Roact.createElement(MainMenu),
			})

			self.CanMount.Value = true
			Resources:LoadClient("CharacterController")
			self.GameEvent.OnClientEvent:Connect(function(FunctionCall, ...)
				local Function = CLIENT_EVENTS[FunctionCall]
				if Function then
					Function(self, ...)
				end
			end)
		end)
	end):Catch(CatchFactory("PromiseChild"))

	return self
end

function ClientHandler:Mount()
	assert(self.CanMount.Value, "Cannot mount!")
	self.RoactTree = Roact.mount(self.App, self.MainGui, "SkiUi")

	-- TODO: Comment this out
	Promise.Delay(2):Then(function()
		print("time to show")
		self.Store:dispatch({
			type = "MenuVisible",
			IsMenuVisible = false,
		}):dispatch({
			type = "LeaderboardVisible",
			IsLeaderboardVisible = true,
		}):dispatch({
			type = "LeaderboardEntries",
			LeaderboardEntries = {
				{
					Time = 150,
					Username = "pobammer",
				},
				{
					Time = 151,
					Username = "e_yv",
				},
				{
					Time = 149,
					Username = "movsb",
				},
			},
		})

		Promise.Delay(1):Then(function()
			self.Store:dispatch({
				type = "LeaderboardEntries",
				LeaderboardEntries = {},
			}):dispatch({
				type = "LeaderboardVisible",
				IsLeaderboardVisible = false,
			}):dispatch({
				type = "MenuVisible",
				IsMenuVisible = true,
			})
		end)
	end)

	return self
end

function ClientHandler:Unmount()
	if self.RoactTree then
		self.RoactTree = Roact.unmount(self.RoactTree)
	end

	self.Store:dispatch({
		type = "ResetAll",
	})

	return self
end

return ClientHandler