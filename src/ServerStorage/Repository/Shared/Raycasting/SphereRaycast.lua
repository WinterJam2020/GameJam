local Workspace = game:GetService("Workspace")

local testinterval = 16
local inf = math.huge

local ipairs = ipairs

local boxmesh = {
	{p = 0.5, n = Vector3.new(-1, 0, 0)};
	{p = 0.5, n = Vector3.new(1, 0, 0)};
	{p = 0.5, n = Vector3.new(0, -1, 0)};
	{p = 0.5, n = Vector3.new(0, 1, 0)};
	{p = 0.5, n = Vector3.new(0, 0, -1)};
	{p = 0.5, n = Vector3.new(0, 0, 1)};
}

local wedgemesh = {
	{p = 0.5, n = Vector3.new(-1, 0, 0)};
	{p = 0.5, n = Vector3.new(1, 0, 0)};
	{p = 0.5, n = Vector3.new(0, -1, 0)};
	{p = 0, n = Vector3.new(0, math.sqrt(0.5), -math.sqrt(0.5))};
	{p = 0.5, n = Vector3.new(0, 0, 1)};
}

local cornerwedgemesh = {
	{p = 0.5, n = Vector3.new(1, 0, 0)};
	{p = 0.5, n = Vector3.new(0, -1, 0)};
	{p = 0.5, n = Vector3.new(0, 0, -1)};
	{p = 0, n = Vector3.new(0, math.sqrt(0.5), math.sqrt(0.5))};
	{p = 0, n = Vector3.new(-math.sqrt(0.5), math.sqrt(0.5), 0)};
}

--Intersection of a sphereray and a plane
local function solveplanesphereray(p, n, o, d, r)
	local no = n:Dot(o)
	local dn = d:Dot(n)
	local t = (p + r - no) / dn
	local v = o + t * d
	local h = v - r * n
	return v, t, h, n
end

local function solveraysphereray(ro, rd, so, sd, r)
	local rdro = rd:Dot(ro)
	local roro = ro:Dot(ro)
	local rdsd = rd:Dot(sd)
	local rosd = ro:Dot(sd)
	local rdso = rd:Dot(so)
	local roso = ro:Dot(so)
	local sdso = sd:Dot(so)
	local soso = so:Dot(so)
	local m = rdro - rdso
	local a = 1 - rdsd * rdsd
	local b = 2 * (rdsd * m - rosd + sdso)
	local c = roro - 2 * roso + soso - m * m - r * r
	local d = -b / (2 * a)
	local e2 = d * d - c / a

	if 0 < e2 then
		local t = d - math.sqrt(e2)
		local s = rdsd * t - m
		local v = so + t * sd
		local h = ro + s * rd
		local n = (v - h) / r
		return v, t, h, n
	end
end

local function solvepointsphereray(p, o, d, r)
	local oo = o:Dot(o)
	local od = o:Dot(d)
	local op = o:Dot(p)
	local dp = d:Dot(p)
	local pp = p:Dot(p)
	local b = 2 * (od - dp)
	local c = oo - 2 * op + pp - r * r
	local g = -b / 2
	local e2 = g * g - c

	if 0 < e2 then
		local t = g - math.sqrt(e2)
		local v = o + t * d
		local n = (v - p) / r
		return v, t, p, n
	end
end

local function solvespheresphereray(p, e, o, d, r)
	local oo = o:Dot(o)
	local od = o:Dot(d)
	local op = o:Dot(p)
	local dp = d:Dot(p)
	local pp = p:Dot(p)
	local b = 2 * (od - dp)
	local c = oo - 2 * op + pp - (r + e) * (r + e)
	local g = -b / 2
	local e2 = g * g - c

	if 0 < e2 then
		local t = g - math.sqrt(e2)
		local v = o + t * d
		local h = p + e / (r + e) * (v - p)
		local n = (v - h) / (r + e)
		return v, t, h, n
	end
end

local function distplanesphereray(p, n, o, d, r)
	return (p + r - n:Dot(o)) / d:Dot(n)
end

local function distpointsphereray(p, o, d, r)
	local oo = o:Dot(o)
	local od = o:Dot(d)
	local op = o:Dot(p)
	local dp = d:Dot(p)
	local pp = p:Dot(p)
	local b = 2 * (od - dp)
	local c = oo - 2 * op + pp - r * r
	local g = -b / 2
	local e2 = g * g - c

	if 0 < e2 then
		return g - math.sqrt(e2)
	end
end

local function solveplaneplane(ap, an, bp, bn)
	local anbn = an:Dot(bn)
	local s = 1 - anbn * anbn
	return (ap - anbn * bp) / s * an + (bp - ap * anbn) / s * bn, an:Cross(bn) / math.sqrt(s)
end

local function solverayplane(o, d, p, n)
	return o + (p - n:Dot(o)) / d:Dot(n) * d
end

local function distpointplane(v, p, n)
	return v:Dot(n) - p
end

local function sortgreaterdist(a, b)
	return (b.dist or -inf) < (a.dist or -inf)
end

local function solvemeshsphereray(rawmesh, cframe, scale, origin, direction, radius)
	local o = cframe:PointToObjectSpace(origin)
	local d = cframe:VectorToObjectSpace(direction)
	local r = radius--lelel

	local mesh = {}
	local meshLength = 0
	local nfront = 0
	for _, plane in ipairs(rawmesh) do
		local sn = plane.n / scale
		local n = sn.Unit
		local p = plane.p / sn.Magnitude
		local newplane = {
			p = p;
			n = n;
		}

		if n:Dot(d) < 0 then
			newplane.dist = distplanesphereray(p, n, o, d, r)
			nfront += 1
		end

		meshLength += 1
		mesh[meshLength] = newplane
	end

	table.sort(mesh, sortgreaterdist)

	for i = 1, nfront do
		local aplane = mesh[i]
		local apos, adist, ahit, anorm = solveplanesphereray(aplane.p, aplane.n, o, d, r)
		local agood = true
		for j, bplane in ipairs(mesh) do
			if i ~= j then
				if 0 < distpointplane(ahit, bplane.p, bplane.n) then
					agood = false
					local aborigin, abdirection = solveplaneplane(aplane.p, aplane.n, bplane.p, bplane.n)
					local abpos, abdist, abhit, abnorm = solveraysphereray(aborigin, abdirection, o, d, r)
					if abpos then
						local abgood = true
						for k, cplane in ipairs(mesh) do
							if i ~= k and j ~= k then
								local dist = distpointplane(abhit, cplane.p, cplane.n)
								if 0 < dist then
									abgood = false
									local abcpoint = solverayplane(aborigin, abdirection, cplane.p, cplane.n)
									local abcpos, abcdist, abchit, abcnorm = solvepointsphereray(abcpoint, o, d, r)
									if abcpos then
										local abcgood = true
										for l, dplane in ipairs(mesh) do
											if i ~= l and j ~= l and k ~= l then
												if 0 < distpointplane(abchit, dplane.p, dplane.n) then
													abcgood = false
													break
												end
											end
										end

										if abcgood then
											return
												cframe * abcpos,
												abcdist,
												cframe * abchit,
												cframe:VectorToWorldSpace(abcnorm)
										end
									end
								end
							end
						end

						if abgood then
							return
								cframe * abpos,
								abdist,
								cframe * abhit,
								cframe:VectorToWorldSpace(abnorm)
						end
					end
				end
			end
		end

		if agood then
			return
				cframe * apos,
				adist,
				cframe * ahit,
				cframe:VectorToWorldSpace(anorm)
		end
	end
end

local function sortdist(a, b)
	return a.dist < b.dist
end

local function solvepartsphereray(part, origin, direction, radius)
	local class = part.ClassName
	if class == "Part" then
		local shape = part.Shape.Name
		if shape == "Block" then
			return solvemeshsphereray(boxmesh, part.CFrame, part.Size, origin, direction, radius)
		elseif shape == "Ball" or shape == "Cylinder" then--LELELELELEL
			return solvespheresphereray(part.Position, part.Size.X / 2, origin, direction, radius)
		end
	elseif class == "TrussPart" then
		return solvemeshsphereray(boxmesh, part.CFrame, part.Size, origin, direction, radius)
	elseif class == "WedgePart" then
		return solvemeshsphereray(wedgemesh, part.CFrame, part.Size, origin, direction, radius)
	elseif class == "CornerWedgePart" then
		return solvemeshsphereray(cornerwedgemesh, part.CFrame, part.Size, origin, direction, radius)
	end
end

local function getallparts(directory)
	local current = {directory}
	local currentLength = 1
	local i = 0
	while i < currentLength do
		i += 1
		for _, child in ipairs(current[i]:GetChildren()) do
			currentLength += 1
			current[currentLength] = child
		end
	end

	local parts = {}
	local length = 0
	for _, child in ipairs(current) do
		if child:IsA("BasePart") then
			length += 1
			parts[length] = child
		end
	end

	return parts
end

local function SphereRaycast(origin, direction, radius, ignore)
	local tested = {}
	if type(ignore) == "table" then
		for _, value in ipairs(ignore) do
			for _, part in ipairs(getallparts(value)) do
				tested[part] = true
			end
		end
	elseif ignore then
		for _, part in ipairs(getallparts(ignore)) do
			tested[part] = true
		end
	end

	local interval = testinterval
	local length = direction.Magnitude
	local udirection = direction.Unit
	local dx = udirection.X
	local dy = udirection.Y
	local dz = udirection.Z
	local radvec = Vector3.new(radius, radius, radius)
	local absvec = Vector3.new(math.abs(dx), math.abs(dy), math.abs(dz))

	local t = 0
	repeat
		local stop
		if length - t < interval then
			stop = true
			interval = length - t
		end

		local lower = origin + (t + interval / 2) * udirection - interval / 2 * absvec - radvec
		local upper = origin + (t + interval / 2) * udirection + interval / 2 * absvec + radvec
		t += interval

		local sorted = {}
		local sortedLength = 0
		for _, part in ipairs(Workspace:FindPartsInRegion3(Region3.new(lower, upper), nil, 100)) do
			if not tested[part] then
				tested[part] = true
				local dist = distpointsphereray(part.Position, origin, udirection, radius + part.Size.Magnitude / 2)
				if dist then
					sortedLength += 1
					sorted[sortedLength] = {
						part = part;
						dist = dist;
					}
				end
			end
		end

		table.sort(sorted, sortdist)

		local bestdist = direction.Magnitude
		local bestpart, bestpos, besthit, bestnorm
		for _, package in ipairs(sorted) do
			if package.dist < bestdist then
				local pos, dist, hit, norm = solvepartsphereray(package.part, origin, udirection, radius)
				if dist and 0 < dist and dist < bestdist then
					bestdist = dist
					bestpart = package.part
					bestpos = pos
					besthit = hit
					bestnorm = norm
				end
			else
				break
			end
		end

		if bestpos then
			return bestpart, bestpos, bestdist, besthit, bestnorm
		end
	until stop
end

return SphereRaycast