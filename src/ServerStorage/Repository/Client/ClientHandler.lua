local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local ClientReducer = Resources:LoadLibrary("ClientReducer")
local CatchFactory = Resources:LoadLibrary("CatchFactory")
local Menu = Resources:LoadLibrary("Menu")
local ParticleEngine = Resources:LoadLibrary("ParticleEngine")
local Promise = Resources:LoadLibrary("Promise")
local PromiseChild = Resources:LoadLibrary("PromiseChild")
local Roact = Resources:LoadLibrary("Roact")
local RoactRodux = Resources:LoadLibrary("RoactRodux")
local Rodux = Resources:LoadLibrary("Rodux")

Resources:LoadClient("CharacterController")

local ClientHandler = {
	LocalPlayer = nil;
	MainGui = nil;
	ParticleEngine = nil;
	TimeSyncService = nil;

	App = nil;
	RoactTree = nil;
	Store = nil;
}

function ClientHandler:Initialize()
	self.LocalPlayer = Players.LocalPlayer
	self.TimeSyncService = Resources:LoadLibrary("TimeSyncService"):Initialize()

	PromiseChild(self.LocalPlayer, "PlayerGui", 5):Then(function(PlayerGui: PlayerGui)
		PromiseChild(PlayerGui, "MainGui", 60):Then(function(MainGui: ScreenGui)
			self.MainGui = MainGui
			self.ParticleEngine = ParticleEngine:Initialize(MainGui)
			self.ParticleEngineHelper = Resources:LoadLibrary("ParticleEngineHelper")
		end):Catch(CatchFactory("PromiseChild"))
	end):Catch(CatchFactory("PromiseChild")):Finally(function()
		self.Store = Rodux.Store.new(ClientReducer)
		self.App = Roact.createElement(RoactRodux.StoreProvider, {
			store = self.Store,
		}, {
			Main = Roact.createElement(Menu),
		})
	end)

	return self
end

function ClientHandler:Mount()
	self.RoactTree = Roact.mount(self.App, self.MainGui)
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