local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
-- local Debug = Resources:LoadLibrary("Debug")
-- local Constants = Resources:LoadLibrary("Constants")
-- local Flipper = Resources:LoadLibrary("Flipper")
-- local Janitor = Resources:LoadLibrary("Janitor")
local Menu = Resources:LoadLibrary("Menu")
local Leaderboard = Resources:LoadLibrary("Leaderboard")
-- local Padding = Resources:LoadLibrary("Padding")
-- local Promise = Resources:LoadLibrary("Promise")
local Roact = Resources:LoadLibrary("Roact")
local RoactRodux = Resources:LoadLibrary("RoactRodux")
-- local Scale = Resources:LoadLibrary("Scale")
-- local SwShButton = Resources:LoadLibrary("SwShButton")
-- local ValueObject = Resources:LoadLibrary("ValueObject")

-- local GameEvent = Resources:GetRemoteEvent("GameEvent")

local MainMenu = Roact.Component:extend("MainMenu")
MainMenu.defaultProps = {
	MenuVisible = false,
	Visible = true,
}

-- function MainMenu:init()
-- 	print(Debug.TableToString(self.state, true, "self.state"))
-- 	print(Debug.TableToString(self.props, true, "self.props"))
-- end

-- function MainMenu:willUnmount()
-- end

local print = function(a, p)
	if p then
		print(p, a)
	else
		print(a)
	end

	return a
end

function MainMenu:render()
	-- print(Debug.TableToString(self.props, true, "self.props"))
	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = self.props.Visible,
	}, {
		Menu = Roact.createElement(Menu, {
			StartButtonFunction = function()
				self.props.SetMenuVisible(false)
			end,

			Visible = print(self.props.MenuVisible, "MenuVisible"),
		}),

		Leaderboard = Roact.createElement(Leaderboard, {
			Entries = self.props.LeaderboardEntries,
			Visible = self.props.LeaderboardVisible,
		}),
	})
end

return RoactRodux.connect(function(state)
	-- print(Debug.TableToString(state, true, "state"))

	return {
		LeaderboardEntries = state.LeaderboardEntries,
		LeaderboardVisible = state.LeaderboardVisible,
		MenuVisible = state.MenuVisible,
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
	}
end)(MainMenu)