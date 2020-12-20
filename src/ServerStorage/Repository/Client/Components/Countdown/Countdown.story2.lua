local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local Countdown = require(script.Parent)
-- local Flipper = Resources:LoadLibrary("Flipper")
-- local Janitor = Resources:LoadLibrary("Janitor")
local Roact = Resources:LoadLibrary("Roact")
-- local RoactFlipper = Resources:LoadLibrary("RoactFlipper")

-- local CountdownStory = Roact.Component:extend("CountdownStory")

local VISIBLE_VECTOR2 = Vector2.new(0.5, 0)
-- local HIDDEN_VECTOR2 = Vector2.new(0.5, -1)

-- function CountdownStory:init()
-- 	self.janitor = Janitor.new()
-- 	self.motor = self.janitor:Add(Flipper.SingleMotor.new(1), "Destroy")
-- end

-- function CountdownStory:willUnmount()
-- 	self.janitor = self.janitor:Destroy()
-- end

-- function CountdownStory:render()
-- 	-- local alpha = RoactFlipper.GetBinding(self.motor)

-- 	return Roact.createElement("Frame", {
-- 		BackgroundTransparency = 1,
-- 		Size = UDim2.fromScale(1, 1),
-- 	}, {
-- 		Countdown = Roact.createElement(Countdown, {
-- 			AnchorPoint = VISIBLE_VECTOR2,
-- 			Duration = 2,
-- 			UseGradientProgress = true,
-- 			Position = UDim2.fromScale(0.5, 0),

-- 			-- AnchorPoint = alpha:map(function(value)
-- 			-- 	return print(HIDDEN_VECTOR2:Lerp(VISIBLE_VECTOR2, value))
-- 			-- end),

-- 			-- Destroy = function()
-- 			-- 	self.motor:SetGoal(Flipper.Spring.new(0, {
-- 			-- 		DampingRatio = 1.2,
-- 			-- 		Frequency = 6,
-- 			-- 	}))
-- 			-- end,
-- 		}),
-- 	})
-- end

return function(Target)
	local Tree = Roact.mount(Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Countdown = Roact.createElement(Countdown, {
			AnchorPoint = VISIBLE_VECTOR2,
			Duration = 2,
			UseGradientProgress = true,
			Position = UDim2.fromScale(0.5, 0),
		}),
	}), Target, "CountdownStory")

	return function()
		Roact.unmount(Tree)
	end
end