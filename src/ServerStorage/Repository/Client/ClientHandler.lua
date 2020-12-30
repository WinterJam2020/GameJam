local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local CatchFactory = Resources:LoadLibrary("CatchFactory")
local ClientReducer = Resources:LoadLibrary("ClientReducer")
local Menu = Resources:LoadLibrary("Menu")
local ParticleEngine = Resources:LoadLibrary("ParticleEngine")
local Promise = Resources:LoadLibrary("Promise")
local PromiseChild = Resources:LoadLibrary("PromiseChild")
local Roact = Resources:LoadLibrary("Roact")
local RoactRodux = Resources:LoadLibrary("RoactRodux")
local Rodux = Resources:LoadLibrary("Rodux")
local ValueObject = Resources:LoadLibrary("ValueObject")

local ClientHandler = {
	App = nil;
	CanMount = nil;
	LocalPlayer = nil;
	MainGui = nil;
	ParticleEngine = nil;
	RoactTree = nil;
	Store = nil;
	TimeSyncService = nil;
}

function ClientHandler:Initialize()
	self.CanMount = ValueObject.new(false)
	self.LocalPlayer = Players.LocalPlayer
	self.TimeSyncService = Resources:LoadLibrary("TimeSyncService"):Initialize()

	PromiseChild(self.LocalPlayer, "PlayerGui", 5):Then(function(PlayerGui: PlayerGui)
		PromiseChild(PlayerGui, "MainGui", 60):Then(function(MainGui: ScreenGui)
			self.MainGui = MainGui
			self.ParticleEngine = ParticleEngine:Initialize(MainGui)
			self.ParticleEngineHelper = Resources:LoadLibrary("ParticleEngineHelper")
		end):Catch(CatchFactory("PromiseChild")):Finally(function()
			self.Store = Rodux.Store.new(ClientReducer)
			self.App = Roact.createElement(RoactRodux.StoreProvider, {
				store = self.Store,
			}, {
				Main = Roact.createElement(Menu),
			})

			self.CanMount.Value = true
			Resources:LoadClient("CharacterController")
		end)
	end):Catch(CatchFactory("PromiseChild"))

	return self
end

function ClientHandler:Mount()
	assert(self.CanMount.Value, "Cannot mount!")
	self.RoactTree = Roact.mount(self.App, self.MainGui, "MAIN")
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