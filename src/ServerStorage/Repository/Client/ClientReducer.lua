local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadLibrary("Constants")
local Llama = Resources:LoadLibrary("Llama")

local DEFAULT_STATE = {
	CountdownActive = false,
	CountdownDuration = Constants.CONFIGURATION.TIME_PER_ROUND,
	CountdownVisible = false,
	LeaderboardEntries = {},
	LeaderboardVisible = false,
	Loaded = false,
	MenuLayoutOrder = 0,
	MenuVisible = true,
	TimerVisible = false,

	CountdownFunction = function()
		print("DESTROY")
	end,
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
	elseif Action.type == "CountdownVisible" then
		return Llama.Dictionary.extend(State, {
			CountdownVisible = Action.IsCountdownVisible,
		})
	elseif Action.type == "CountdownDuration" then
		return Llama.Dictionary.extend(State, {
			CountdownDuration = Action.CountdownDuration,
		})
	elseif Action.type == "CountdownFunction" then
		return Llama.Dictionary.extend(State, {
			CountdownFunction = Action.CountdownFunction,
		})
	elseif Action.type == "CountdownActive" then
		return Llama.Dictionary.extend(State, {
			CountdownActive = Action.IsCountdownActive,
		})
	elseif Action.type == "MenuLayoutOrder" then
		return Llama.Dictionary.extend(State, {
			MenuLayoutOrder = Action.MenuLayoutOrder,
		})
	elseif Action.type == "ResetAll" then
		return DEFAULT_STATE
	end

	return State
end

return ClientReducer