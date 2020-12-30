local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Countdown = Resources:LoadLibrary("Countdown")
local Menu = Resources:LoadLibrary("Menu")
local Leaderboard = Resources:LoadLibrary("Leaderboard")
local Roact = Resources:LoadLibrary("Roact")
local RoactRodux = Resources:LoadLibrary("RoactRodux")

local MainMenu = Roact.Component:extend("MainMenu")
MainMenu.defaultProps = {
	MenuVisible = false,
	CountdownActive = false,
	CountdownVisible = false,
	CountdownDuration = 60,
	CountdownFunction = function()
		print("Destroy!")
	end,

	Visible = true,
}

local print = function(a, p)
	if p then
		print(p, a)
	else
		print(a)
	end

	return a
end

function MainMenu:render()
	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = self.props.Visible,
	}, {
		Menu = Roact.createElement(Menu, {
			StartButtonFunction = function()
				self.props.SetCountdownDuration(60)
				self.props.SetMenuVisible(false)
				self.props.SetCountdownVisible(true)
				self.props.SetCountdownActive(true)
			end,

			Visible = print(self.props.MenuVisible, "MenuVisible"),
		}),

		Leaderboard = Roact.createElement(Leaderboard, {
			Entries = self.props.LeaderboardEntries,
			Visible = self.props.LeaderboardVisible,
		}),

		Countdown = Roact.createElement(Countdown, {
			Active = self.props.CountdownActive,
			AnchorPoint = Vector2.new(0.5, 0.05),
			Destroy = self.props.CountdownFunction,
			Duration = self.props.CountdownDuration,
			Position = UDim2.fromScale(0.5, 0.05),
			Size = UDim2.fromScale(0.5, 0.1),
			Visible = self.props.CountdownVisible,
		}),
	})
end

return RoactRodux.connect(function(state)
	return {
		LeaderboardEntries = state.LeaderboardEntries,
		LeaderboardVisible = state.LeaderboardVisible,
		MenuVisible = state.MenuVisible,
		CountdownActive = state.CountdownActive,
		CountdownVisible = state.CountdownVisible,
		CountdownDuration = state.CountdownDuration,
		CountdownFunction = state.CountdownFunction,
		Visible = state.Visible,
	}
end, function(dispatch)
	return {
		SetLoaded = function(isLoaded)
			dispatch({
				type = "Loaded",
				IsLoaded = isLoaded,
			})
		end,

		SetMenuVisible = function(isMenuVisible)
			dispatch({
				type = "MenuVisible",
				IsMenuVisible = isMenuVisible,
			})
		end,

		SetLeaderboardVisible = function(isLeaderboardVisible)
			dispatch({
				type = "LeaderboardVisible",
				IsLeaderboardVisible = isLeaderboardVisible,
			})
		end,

		SetCountdownVisible = function(isCountdownVisible)
			dispatch({
				type = "CountdownVisible",
				IsCountdownVisible = isCountdownVisible,
			})
		end,

		SetCountdownActive = function(isCountdownActive)
			dispatch({
				type = "CountdownActive",
				IsCountdownActive = isCountdownActive,
			})
		end,

		SetCountdownDuration = function(countdownDuration)
			dispatch({
				type = "CountdownDuration",
				CountdownDuration = countdownDuration,
			})
		end,

		SetCountdownFunction = function(countdownFunction)
			dispatch({
				type = "CountdownFunction",
				CountdownFunction = countdownFunction,
			})
		end,

		ResetUI = function()
			dispatch({
				type = "ResetAll",
			})
		end,
	}
end)(MainMenu)