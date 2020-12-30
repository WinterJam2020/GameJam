local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Llama = Resources:LoadLibrary("Llama")

local DEFAULT_STATE = {
	Loaded = false,
	MenuVisible = true,
	TimerVisible = false,
	LeaderboardVisible = false,
	LeaderboardEntries = {},
}

local function ClientReducer(State, Action)
	State = State or DEFAULT_STATE
	if Action.type == "Loaded" then
		return Llama.Dictionary.extend(State, {
			Loaded = Action.IsLoaded,
		})
	elseif Action.type == "MenuVisible" then
		return Llama.Dictionary.extend(State, {
			MenuVisible = Action.IsMenuVisible,
		})
	elseif Action.type == "TimerVisible" then
		return Llama.Dictionary.extend(State, {
			TimerVisible = Action.IsTimerVisible,
		})
	elseif Action.type == "LeaderboardVisible" then
		return Llama.Dictionary.extend(State, {
			LeaderboardVisible = Action.IsLeaderboardVisible,
		})
	elseif Action.type == "LeaderboardEntries" then
		return Llama.Dictionary.extend(State, {
			LeaderboardEntries = Action.LeaderboardEntries,
		})
	elseif Action.type == "ResetAll" then
		return DEFAULT_STATE
	end

	return State
end

return ClientReducer