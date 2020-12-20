local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Countdown = require(script.Parent)
local Roact = Resources:LoadLibrary("Roact")

return function(Target)
	local Tree = Roact.mount(Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Countdown = Roact.createElement(Countdown, {
			AnchorPoint = Vector2.new(0.5, 0),
			Duration = 2,
			UseGradientProgress = true,
			Position = UDim2.fromScale(0.5, 0),
		}),
	}), Target, "CountdownStory")

	return function()
		Roact.unmount(Tree)
	end
end