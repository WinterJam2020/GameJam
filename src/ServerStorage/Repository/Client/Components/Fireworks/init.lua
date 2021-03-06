local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Counter = Resources:LoadLibrary("Counter")
local Roact = Resources:LoadLibrary("Roact")

local Fireworks = Roact.PureComponent:extend("Fireworks")

Fireworks.defaultProps = {
	MinPeak = 0.6,
	MaxPeak = 1.1,
	Particles = 20,
	ParticleImage = "rbxassetid://241584018",
	UseImage = false,
	ParticleSpeed = 0.6,
	ParticleSize = UDim2.fromScale(0.05, 0.05),
	TransparencyFadeTime = 0.2,
	ColorGenerator = function()
		return Color3.new(1, 0, 0)
	end,
}

function Fireworks:init(props)
	local particlePositions = table.create(props.Particles)

	for index = 1, props.Particles do
		particlePositions[index] = {
			Direction = math.random() >= 0.5 and 1 or -1,
			Peak = Random.new():NextNumber(props.MinPeak, props.MaxPeak),
			X = math.random(),
			Y = math.random(),
		}
	end

	self.particlePositions = particlePositions
end

local Roact_createElement = Roact.createElement

function Fireworks:render()
	return Roact_createElement(Counter, {
		Render = function(counter)
			local particles = {}

			if self.props.UseImage then
				for index, particlePositions in ipairs(self.particlePositions) do
					particles["Particle" .. index] = Roact_createElement("ImageLabel", {
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Image = self.props.ParticleImage,
						ImageColor3 = self.props.ColorGenerator(),
						ImageTransparency = counter:map(function(alpha)
							if alpha <= self.props.TransparencyFadeTime then
								return 1 - alpha / self.props.TransparencyFadeTime
							end
						end),

						Position = counter:map(function(alpha)
							return UDim2.fromScale(particlePositions.X, particlePositions.Y)
								+ UDim2.fromScale(
									alpha * self.props.ParticleSpeed * particlePositions.Direction,
									(
										-(-((2 * alpha - 1) ^ 2) + 1) * particlePositions.Peak
									) * particlePositions.Peak
								)
						end),

						Size = self.props.ParticleSize,
					}, table.create(1, Roact_createElement("UIAspectRatioConstraint")))
				end
			else
				for index, particlePositions in ipairs(self.particlePositions) do
					particles["Particle" .. index] = Roact_createElement("Frame", {
						BackgroundColor3 = self.props.ColorGenerator(),
						BorderSizePixel = 0,
						BackgroundTransparency = counter:map(function(alpha)
							if alpha <= self.props.TransparencyFadeTime then
								return 1 - alpha / self.props.TransparencyFadeTime
							end
						end),

						Position = counter:map(function(alpha)
							return UDim2.fromScale(particlePositions.X, particlePositions.Y)
								+ UDim2.fromScale(
									alpha * self.props.ParticleSpeed * particlePositions.Direction,
									(
										-(-((2 * alpha - 1) ^ 2) + 1) * particlePositions.Peak
									) * particlePositions.Peak
								)
						end),

						Size = self.props.ParticleSize,
					}, table.create(1, Roact_createElement("UIAspectRatioConstraint")))
				end
			end

			return Roact_createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}, particles)
		end,
	})
end

return Fireworks