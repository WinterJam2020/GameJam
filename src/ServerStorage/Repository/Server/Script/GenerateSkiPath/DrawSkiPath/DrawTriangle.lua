local function DrawTriangle(a, b, c, depth, desiredRightVec)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)

	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end

	ab, ac, bc = b - a, c - a, c - b

	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))

	local sign
	if right:Dot(desiredRightVec) > 0 then
		sign = -1
	else
		sign = 1
	end

	local cf0 = CFrame.fromMatrix(
		(a + b)/2 + right*depth/2*sign,
		right,
		up,
		back
	)
	local size0 = Vector3.new(depth, height, math.abs(ab:Dot(back)))
	local cf1 = CFrame.fromMatrix(
		(a + c)/2 + right*depth/2*sign,
		-right,
		up,
		-back
	)
	local size1 = Vector3.new(depth, height, math.abs(ac:Dot(back)))

	return cf0, cf1, size0, size1
end

return DrawTriangle