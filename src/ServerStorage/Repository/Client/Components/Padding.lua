local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Roact = Resources:LoadLibrary("Roact")
local Table = Resources:LoadLibrary("Table")

type PaddingProps = {
	LayoutOrder: number,
	Size: UDim2,
	SizeConstraint: EnumItem,
}

local Roact_createElement = Roact.createElement
local Table_Copy = Table.Copy

local function Padding(props: PaddingProps)
	local newProps: PaddingProps = Table_Copy(props)

	return Roact_createElement("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = newProps.LayoutOrder or 0,
		Size = newProps.Size,
		SizeConstraint = newProps.SizeConstraint,
	})
end

return Padding