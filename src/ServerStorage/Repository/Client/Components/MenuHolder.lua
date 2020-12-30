local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Menu = Resources:LoadLibrary("Menu")
local Roact = Resources:LoadLibrary("Roact")

local MenuHolder = Roact.Component:extend("MenuHolder")

function MenuHolder:init(props)
	self:setState({
		mainVisible = props.MainVisible,
	})
end

function MenuHolder:render()
	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		MainMenu = Roact.createElement(Menu, {
			Visible = self.props.MainVisible,
		}),
	})
end

return MenuHolder