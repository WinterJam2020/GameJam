local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Alert = require(script.Parent)
local Roact = Resources:LoadLibrary("Roact")
local Services = Resources:LoadLibrary("Services")

local AlertStory = Roact.Component:extend("AlertStory")

function AlertStory:init()
	self:setState({
		open = false,
	})
end

function AlertStory:render()
	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		CustomAlert = Roact.createElement(Alert, {
			AlertTime = 2,
			-- Color = Color3.fromRGB(23, 141, 170),
			OnClose = function()
				print("OnClose")
			end,

			Open = self.state.open,
			Text = "CustomAlert",
			Window = Services.StarterGui.MainGui,
		}),
	})
end

function AlertStory:didMount()
	self:setState({
		open = true,
	})
end

return function(Target)
	local Tree = Roact.mount(Roact.createElement(AlertStory), Target, "AlertStory")

	return function()
		Roact.unmount(Tree)
	end
end