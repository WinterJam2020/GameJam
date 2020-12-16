local function Map(Number, Minimum0, Maximum0, Minimum1, Maximum1)
	return (((Number - Minimum0) * (Maximum1 - Minimum1)) / (Maximum0 - Minimum0)) + Minimum1
end

local function MapColor(Color)
	print(string.format("%.2f, %.2f, %.2f", Map(Color.R, 0, 255, 0, 10), Map(Color.G, 0, 255, 0, 10), Map(Color.B, 0, 255, 0, 10)))
end

local Color = {}
function Color.new(R, G, B)
	return {R = R, G = G, B = B}
end

print(MapColor(Color.new(135, 255, 151)))

return true