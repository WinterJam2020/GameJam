local Cast = {}

function Cast.Solve(Point)
	if not Point.LastPosition then
		Point.LastPosition = Point.Attachment.WorldPosition
	end

	return Point.LastPosition, Point.Attachment.WorldPosition - Point.LastPosition
end

function Cast.LastPosition(Point, _)
	Point.LastPosition = Point.Attachment.WorldPosition
end

return Cast