local Cast = {}
local EMPTY_VECTOR3 = Vector3.new()

function Cast.Solve(Point)
	local RelativePartToWorldSpace = Point.RelativePart.Position + Point.RelativePart.CFrame:VectorToWorldSpace(Point.Attachment)
	if not Point.LastPosition then
		Point.LastPosition = RelativePartToWorldSpace
	end

	return Point.LastPosition, RelativePartToWorldSpace - (Point.LastPosition and Point.LastPosition or EMPTY_VECTOR3), RelativePartToWorldSpace
end

function Cast.LastPosition(Point, RelativePartToWorldSpace)
	Point.LastPosition = RelativePartToWorldSpace
end

return Cast