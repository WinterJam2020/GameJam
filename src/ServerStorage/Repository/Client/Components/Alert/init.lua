local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Roact = Resources:LoadLibrary("Roact")
local Services = Resources:LoadLibrary("Services")

local Players: Players = Services.Players
local RunService: RunService = Services.RunService
local TweenService: TweenService = Services.TweenService

local Alert = Roact.Component:extend("Alert")

local function noop()
end

Alert.defaultProps = {
	AlertTime = 2,
	Color = Color3.fromRGB(255, 78, 78),
	OnClose = noop,
	Open = false,
	Window = RunService:IsRunning() and Players.LocalPlayer.PlayerGui.MainGui.Main,
}

local Roact_createElement = Roact.createElement

function Alert:init(props)
	self.fadeBinding, self.updateFadeBinding = Roact.createBinding(props.Open and 0 or 1)
	if props.Open then
		self:Open()
	end
end

function Alert:Open()
	if self.props.Text == "" then
		return
	end

	local total = 0
	self.animateConnection = RunService.Heartbeat:Connect(function(delta)
		total += delta
		self.updateFadeBinding(TweenService:GetValue(
			total / self.props.AlertTime,
			Enum.EasingStyle.Cubic,
			Enum.EasingDirection.In
		))

		if total >= self.props.AlertTime then
			self:setState({
				finished = true,
			})

			self.props.OnClose()
			self.animateConnection:Disconnect()
		end
	end)
end

function Alert:didUpdate(previousProps)
	if self.props.Open ~= previousProps.Open then
		self.updateFadeBinding(self.props.Open and 0 or 1)

		if self.props.Open then
			self:Open()
		else
			self.animateConnection:Disconnect()
		end
	end
end

function Alert:willUnmount()
	if self.animateConnection then
		self.animateConnection:Disconnect()
	end
end

function Alert:render()
	local props = self.props

	return Roact_createElement(Roact.Portal, {
		target = props.Window,
	}, {
		Notification = Roact_createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromScale(0.5, 0.01),
			Size = UDim2.fromScale(0.8, 0.1),
			Text = props.Text,
			TextColor3 = props.Color,
			TextScaled = true,
			TextStrokeColor3 = Color3.new(),
			TextStrokeTransparency = self.fadeBinding,
			TextTransparency = self.fadeBinding,
		}),
	})
end

return Alert