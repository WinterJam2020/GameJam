local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Fireworks = require(script.Parent)
local Roact = Resources:LoadLibrary("Roact")

return function(Target)
	local RandomLib = Random.new(tick() % 1 * 1E7)
	local Handle = Roact.mount(
		Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.6, 0.6),
		}, {
			UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint"),

			Fireworks = Roact.createElement(Fireworks, {
				-- ParticleColor = Color3.new(1, 0, 0),
				ParticleSize = UDim2.fromOffset(5, 5),
				ColorGenerator = function()
					return Color3.fromRGB(RandomLib:NextInteger(0, 255), RandomLib:NextInteger(0, 255), RandomLib:NextInteger(0, 255))
				end,
			}),
		}), Target, "Fireworks"
	)

	return function()
		Roact.unmount(Handle)
	end
end