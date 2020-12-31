local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Llama = Resources:LoadLibrary("Llama")
local Roact = Resources:LoadLibrary("Roact")

local Roact_createElement = Roact.createElement
local Llama_Dictionary_assign = Llama.Dictionary.assign

local function AutoFixedScrollingFrame(props)
	local count = 0
	for _ in next, props[Roact.Children] do
		count += 1
	end

	local rows = math.ceil(count / props.CellsPerRow)

	return Roact_createElement("ScrollingFrame", Llama_Dictionary_assign(props.ScrollingFrame, {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, (rows * props.CellSize.Y.Offset) + (rows * props.CellPadding.Y.Offset)),
	}), Llama_Dictionary_assign(props[Roact.Children], {
		UIGridLayout = Roact_createElement("UIGridLayout", Llama_Dictionary_assign(props.GridLayout or {}, {
			CellPadding = props.CellPadding,
			CellSize = props.CellSize,
			FillDirectionMaxCells = props.CellsPerRow,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})),
	}))
end

return AutoFixedScrollingFrame