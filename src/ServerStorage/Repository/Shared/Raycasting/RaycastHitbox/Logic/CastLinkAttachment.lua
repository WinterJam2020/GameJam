local Cast = {}

function Cast.Solve(Point)
	return Point.Attachment.WorldPosition, Point.Attachment0.WorldPosition - Point.Attachment.WorldPosition
end

function Cast.LastPosition(Point)
	Point.LastPosition = Point.Attachment.WorldPosition
end

return Cast