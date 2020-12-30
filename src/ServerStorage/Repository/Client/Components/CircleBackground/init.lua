local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Roact = Resources:LoadLibrary("Roact")
local Services = Resources:LoadLibrary("Services")

local RunService: RunService = Services.RunService

local CircleBackground = Roact.PureComponent:extend("CircleBackground")

local DEFAULT_SPEED = 5
local IMAGE = "rbxassetid://1489638729"

function CircleBackground:init()
	self:setState({
		scale = 0,
	})

	self.hover = function()
		if self.hovering then
			return
		end

		self.hovering = true
		if self.step then
			self.step:Disconnect()
		end

		self.step = RunService.Heartbeat:Connect(function(delta)
			local newScale = math.min(1, self.state.scale + delta * self:GetSpeed())
			self:setState({
				scale = newScale,
			})

			if newScale == 1 then
				self.step:Disconnect()
			end
		end)
	end

	self.hoverEnd = function()
		if not self.hovering then
			return
		end

		self.hovering = false
		if self.step then
			self.step:Disconnect()
		end

		self.step = RunService.Heartbeat:Connect(function(delta)
			local newScale = math.max(0, self.state.scale - delta * self:GetSpeed())
			self:setState({
				scale = newScale,
			})

			if newScale == 0 then
				self.step:Disconnect()
			end
		end)
	end
end

function CircleBackground:GetSpeed()
	return self.props.Speed or DEFAULT_SPEED
end

function CircleBackground:render()
	local scale = math.sin(math.pi / 2 * self.state.scale)

	return Roact.createElement("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		[Roact.Event.MouseEnter] = self.hover,
		[Roact.Event.MouseLeave] = self.hoverEnd,
	}, {
		Circle = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = IMAGE,
			ImageTransparency = 0.5,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(scale, scale),
		}),

		Inner = Roact.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
		}, self.props[Roact.Children]),
	})
end

function CircleBackground:willUnmount()
	if self.step then
		self.step:Disconnect()
	end
end

return CircleBackground