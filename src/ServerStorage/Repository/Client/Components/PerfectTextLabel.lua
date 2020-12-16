local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Resources = require(ReplicatedStorage.Resources)
local Roact = Resources:LoadLibrary("Roact")
local Table = Resources:LoadLibrary("Table")

local function PerfectTextLabel(props)
	local newProps = Table.Copy(props)

	assert(newProps.Text ~= nil, "Text is nil")
	assert(newProps.TextSize ~= nil, "TextSize is nil")
	assert(newProps.Font ~= nil, "Font is nil")

	local textSize = TextService:GetTextSize(
		newProps.Text,
		newProps.TextSize,
		newProps.Font,
		Vector2.new(newProps.MaxWidth or math.huge, math.huge)
	) + Vector2.new(2, 2)

	local textSizeY = textSize.Y
	if newProps.MaxHeight ~= nil then
		textSizeY = math.min(textSize.Y, newProps.MaxHeight)
	end

	newProps.MaxWidth = nil
	newProps.BackgroundTransparency = 1
	newProps.Size = UDim2.new(
		UDim.new(0, textSize.X),
		newProps.ForceY or UDim.new(0, textSizeY)
	)

	newProps.TextYAlignment = newProps.TextYAlignment or Enum.TextYAlignment.Center

	newProps.ForceY = nil
	newProps.MaxHeight = nil

	if newProps.RenderParent then
		local renderParent = newProps.RenderParent
		newProps.RenderParent = nil
		return renderParent(Roact.createElement("TextLabel", newProps), newProps.Size)
	else
		return Roact.createElement("TextLabel", newProps)
	end
end

return PerfectTextLabel