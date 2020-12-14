-- This one is faster, but way less accurate.

--[[
By AxisAngle, (Trey Reynolds)
Documentation
http://www.roblox.com/item.aspx?id=227509468

Region constructors:
	Region Region.new(CFrame RegionCFrame, Vector3 RegionSize)
		> Returns a new Region object

	Region Region.FromPart(Instance Part)
		> Returns a new Region objects

Region methods:
	table Region:Cast([Instance or table Ignore])
		> Returns all parts in the Region, ignoring the Ignore

	bool Region:CastPart(Instance Part)
		> Returns true if Part is within Region, false otherwise

	table Region:CastParts(table Parts)
		> Returns a table of all parts within the region

	bool Region:CastPoint(Vector3 Point)
		> Returns true if Point intersects Region, false otherwise

	bool Region:CastSphere(Vector3 SphereCenter, number SphereRadius)
		> Returns true if Sphere intersects Region, false otherwise

	bool Region:CastBox(CFrame BoxCFrame, Vector3 BoxSize)
		> Returns true if Box intersects Region, false otherwise

Region properties: (Regions are mutable)
	CFrame	CFrame
	Vector3	Size
	Region3	Region3

Region functions:
	Region3 Region.Region3BoundingBox(CFrame BoxCFrame, Vector3 BoxSize)
		> Returns the enclosing boundingbox of Box

	table Region.FindAllPartsInRegion3(Region3 Region3, [Instance or table Ignore])
		> Returns all parts within a Region3 of any size

	bool Region.BoxPointCollision(CFrame BoxCFrame, Vector3 BoxSize, Vector3 Point)
		> Returns true if the Point is intersecting the Box, false otherwise

	bool Region.BoxSphereCollision(CFrame BoxCFrame, Vector3 BoxSize, Vector3 SphereCenter, number SphereRadius)
		> Returns true if the Sphere is intersecting the Box, false otherwise

	bool Region.BoxCollision(CFrame Box0CFrame, Vector3 Box0Size, CFrame Box1CFrame, Vector3 Box1Size, [bool AssumeTrue])
		> Returns true if the boxes are intersecting, false otherwise
		If AssumeTrue is left blank, it does the full check to see if Box0 is intersecting Box1
		If AssumeTrue is true, it skips the heavy check and assumes that any part that could possibly be in the Region is
		If AssumeTrue is false, it skips the heavy check and assumes that any part that could possible be outside the Region is

	bool Region.CastPoint(Vector3 Point, [Instance or table Ignore])
		> Returns true if the point intersects a part, false otherwise
]]

-- i think i hear astro screaming

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local function BoxPointCollision(CoordinateFrame, Size, Point)
	local Relative = CoordinateFrame:PointToObjectSpace(Point)
	local sx = Size.X / 2
	local rx = Relative.X
	return rx * rx < sx * sx and rx * rx < sx * sx and rx * rx < sx * sx
end

local function BoxSphereCollision(CoordinateFrame: CFrame, Size: Vector3, Center: Vector3, Radius: number)
	local Relative = CoordinateFrame:PointToObjectSpace(Center)
	local sx, sy, sz = Size.X / 2, Size.Y / 2, Size.Z / 2
	local rx, ry, rz = Relative.X, Relative.Y, Relative.Z
	local dx = rx > sx and rx - sx or rx < -sx and rx + sx or 0
	local dy = ry > sy and ry - sy or ry < -sy and ry + sy or 0
	local dz = rz > sz and rz - sz or rz < -sz and rz + sz or 0
	return dx * dx + dy * dy + dz * dz < Radius * Radius
end

--[[
# Constructors:

- `RegionModule.new(CoordinateFrame: CFrame, Size: Vector3): Region`
- `RegionModule.FromPart(BasePart: BasePart): Region`

## Region

### Properties

- `CFrame Region.CFrame`
- `Vector3 Region.Size`
- `Region3 Region.Region3`

### Methods

- `BasePart[] Region:Cast(<Instance[], Instance> IgnoreList)`
- `boolean Region:CastPart(BasePart BasePart)`
- `BasePart[] Region:CastParts(BasePart[] BaseParts)`
- `boolean Region:CastPoint(CFrame Point)`
- `boolean Region:CastSphere(Vector3 Center, number Radius)`
- `boolean Region:CastBox(CFrame CoordinateFrame, Vector3 Size)`
--]]

--There's a reason why this hasn't been done before by ROBLOX users (as far as I know)
--It's really mathy, really long, and really confusing.
--0.000033 seconds is the worst, 0.000018 looks like the average case.
--Also I ran out of local variables so I had to redo everything so that I could reuse the names lol.
--So don't even try to read it.
local function BoxCollision(CFrame0, Size0, CFrame1, Size1, AssumeTrue): boolean
	local m00, m01, m02, m03, m04, m05, m06, m07, m08, m09, m10, m11 = CFrame0:GetComponents()
	local m12, m13, m14, m15, m16, m17, m18, m19, m20, m21, m22, m23 = CFrame1:GetComponents()
	local m24, m25, m26 = Size0.X / 2, Size0.Y / 2, Size0.Z / 2
	local m27, m28, m29 = Size1.X / 2, Size1.Y / 2, Size1.Z / 2
	local m30, m31, m32 = m12 - m00, m13 - m01, m14 - m02

	m00 = m03 * m30 + m06 * m31 + m09 * m32
	m01 = m04 * m30 + m07 * m31 + m10 * m32
	m02 = m05 * m30 + m08 * m31 + m11 * m32
	m12 = m15 * m30 + m18 * m31 + m21 * m32
	m13 = m16 * m30 + m19 * m31 + m22 * m32
	m14 = m17 * m30 + m20 * m31 + m23 * m32
	m30 = m12 > m27 and m12 - m27 or m12 < -m27 and m12 + m27 or 0
	m31 = m13 > m28 and m13 - m28 or m13 < -m28 and m13 + m28 or 0
	m32 = m14 > m29 and m14 - m29 or m14 < -m29 and m14 + m29 or 0

	local m33 = m00 > m24 and m00 - m24 or m00 < -m24 and m00 + m24 or 0
	local m34 = m01 > m25 and m01 - m25 or m01 < -m25 and m01 + m25 or 0
	local m35 = m02 > m26 and m02 - m26 or m02 < -m26 and m02 + m26 or 0
	local m36 = m30 * m30 + m31 * m31 + m32 * m32

	m30 = m33 * m33 + m34 * m34 + m35 * m35
	m31 = m24 < m25 and (m24 < m26 and m24 or m26) or (m25 < m26 and m25 or m26)
	m32 = m27 < m28 and (m27 < m29 and m27 or m29) or (m28 < m29 and m28 or m29)

	if m36 < m31 * m31 or m30 < m32 * m32 then
		return true
	elseif m36 > m24 * m24 + m25 * m25 + m26 * m26 or m30 > m27 * m27 + m28 * m28 + m29 * m29 then
		return false
	elseif AssumeTrue == nil then
		--LOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOL
		--(This is how you tell if something was made by Axis Angle)
		m30 = m03 * m15 + m06 * m18 + m09 * m21
		m31 = m03 * m16 + m06 * m19 + m09 * m22
		m32 = m03 * m17 + m06 * m20 + m09 * m23
		m03 = m04 * m15 + m07 * m18 + m10 * m21
		m06 = m04 * m16 + m07 * m19 + m10 * m22
		m09 = m04 * m17 + m07 * m20 + m10 * m23
		m04 = m05 * m15 + m08 * m18 + m11 * m21
		m07 = m05 * m16 + m08 * m19 + m11 * m22
		m10 = m05 * m17 + m08 * m20 + m11 * m23
		m05 = m29 * m29
		m08 = m27 * m27
		m11 = m28 * m28
		m15 = m24 * m30
		m16 = m25 * m03
		m17 = m26 * m04
		m18 = m24 * m31
		m19 = m25 * m06
		m20 = m26 * m07
		m21 = m24 * m32
		m22 = m25 * m09
		m23 = m26 * m10
		m33 = m15 + m16 + m17 - m12

		if m33 * m33 < m08 then
			m34 = m18 + m19 + m20 - m13
			if m34 * m34 < m11 then
				m35 = m21 + m22 + m23 - m14
				if m35 * m35 < m05 then
					return true
				end
			end
		end

		m33 = -m15 + m16 + m17 - m12
		if m33 * m33 < m08 then
			m34 = -m18 + m19 + m20 - m13
			if m34 * m34 < m11 then
				m35 = -m21 + m22 + m23 - m14
				if m35 * m35 < m05 then
					return true
				end
			end
		end

		m33 = m15 - m16 + m17 - m12
		if m33 * m33 < m08 then
			m34 = m18 - m19 + m20 - m13
			if m34 * m34 < m11 then
				m35 = m21 - m22 + m23 - m14
				if m35 * m35 < m05 then
					return true
				end
			end
		end

		m33 = -m15 - m16 + m17 - m12
		if m33 * m33 < m08 then
			m34 = -m18 - m19 + m20 - m13
			if m34 * m34 < m11 then
				m35 = -m21 - m22 + m23 - m14
				if m35 * m35 < m05 then
					return true
				end
			end
		end

		m33 = m15 + m16 - m17 - m12
		if m33 * m33 < m08 then
			m34 = m18 + m19 - m20 - m13
			if m34 * m34 < m11 then
				m35 = m21 + m22 - m23 - m14
				if m35 * m35 < m05 then
					return true
				end
			end
		end

		m33 = -m15 + m16 - m17 - m12
		if m33 * m33 < m08 then
			m34 = -m18 + m19 - m20 - m13
			if m34 * m34 < m11 then
				m35 = -m21 + m22 - m23 - m14
				if m35 * m35 < m05 then
					return true
				end
			end
		end

		m33 = m15 - m16 - m17 - m12
		if m33 * m33 < m08 then
			m34 = m18 - m19 - m20 - m13
			if m34 * m34 < m11 then
				m35 = m21 - m22 - m23 - m14
				if m35 * m35 < m05 then
					return true
				end
			end
		end

		m33 = -m15 - m16 - m17 - m12
		if m33 * m33 < m08 then
			m34 = -m18 - m19 - m20 - m13
			if m34 * m34 < m11 then
				m35 = -m21 - m22 - m23 - m14
				if m35 * m35 < m05 then
					return true
				end
			end
		end

		m12 = m24 * m24
		m13 = m25 * m25
		m14 = m26 * m26
		m15 = m27 * m04
		m16 = m28 * m07
		m17 = m27 * m30
		m18 = m28 * m31
		m19 = m27 * m03
		m20 = m28 * m06
		m21 = m29 * m10
		m22 = m29 * m32
		m23 = m29 * m09
		m35 = (m02 - m26 + m15 + m16) / m10

		if m35 * m35 < m05 then
			m33 = m00 + m17 + m18 - m35 * m32
			if m33 * m33 < m12 then
				m34 = m01 + m19 + m20 - m35 * m09
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 + m26 + m15 + m16) / m10
		if m35 * m35 < m05 then
			m33 = m00 + m17 + m18 - m35 * m32
			if m33 * m33 < m12 then
				m34 = m01 + m19 + m20 - m35 * m09
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 - m26 - m15 + m16) / m10
		if m35 * m35 < m05 then
			m33 = m00 - m17 + m18 - m35 * m32
			if m33 * m33 < m12 then
				m34 = m01 - m19 + m20 - m35 * m09
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 + m26 - m15 + m16) / m10
		if m35 * m35 < m05 then
			m33 = m00 - m17 + m18 - m35 * m32
			if m33 * m33 < m12 then
				m34 = m01 - m19 + m20 - m35 * m09
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 - m26 + m15 - m16) / m10
		if m35 * m35 < m05 then
			m33 = m00 + m17 - m18 - m35 * m32
			if m33 * m33 < m12 then
				m34 = m01 + m19 - m20 - m35 * m09
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 + m26 + m15 - m16) / m10
		if m35 * m35 < m05 then
			m33 = m00 + m17 - m18 - m35 * m32
			if m33 * m33 < m12 then
				m34 = m01 + m19 - m20 - m35 * m09
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 - m26 - m15 - m16) / m10
		if m35 * m35 < m05 then
			m33 = m00 - m17 - m18 - m35 * m32
			if m33 * m33 < m12 then
				m34 = m01 - m19 - m20 - m35 * m09
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 + m26 - m15 - m16) / m10
		if m35 * m35 < m05 then
			m33 = m00 - m17 - m18 - m35 * m32
			if m33 * m33 < m12 then
				m34 = m01 - m19 - m20 - m35 * m09
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m00 - m24 + m17 + m18) / m32
		if m35 * m35 < m05 then
			m33 = m01 + m19 + m20 - m35 * m09
			if m33 * m33 < m13 then
				m34 = m02 + m15 + m16 - m35 * m10
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 + m24 + m17 + m18) / m32
		if m35 * m35 < m05 then
			m33 = m01 + m19 + m20 - m35 * m09
			if m33 * m33 < m13 then
				m34 = m02 + m15 + m16 - m35 * m10
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 - m24 - m17 + m18) / m32
		if m35 * m35 < m05 then
			m33 = m01 - m19 + m20 - m35 * m09
			if m33 * m33 < m13 then
				m34 = m02 - m15 + m16 - m35 * m10
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 + m24 - m17 + m18) / m32
		if m35 * m35 < m05 then
			m33 = m01 - m19 + m20 - m35 * m09
			if m33 * m33 < m13 then
				m34 = m02 - m15 + m16 - m35 * m10
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 - m24 + m17 - m18) / m32
		if m35 * m35 < m05 then
			m33 = m01 + m19 - m20 - m35 * m09
			if m33 * m33 < m13 then
				m34 = m02 + m15 - m16 - m35 * m10
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 + m24 + m17 - m18) / m32
		if m35 * m35 < m05 then
			m33 = m01 + m19 - m20 - m35 * m09
			if m33 * m33 < m13 then
				m34 = m02 + m15 - m16 - m35 * m10
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 - m24 - m17 - m18) / m32
		if m35 * m35 < m05 then
			m33 = m01 - m19 - m20 - m35 * m09
			if m33 * m33 < m13 then
				m34 = m02 - m15 - m16 - m35 * m10
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 + m24 - m17 - m18) / m32
		if m35 * m35 < m05 then
			m33 = m01 - m19 - m20 - m35 * m09
			if m33 * m33 < m13 then
				m34 = m02 - m15 - m16 - m35 * m10
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m01 - m25 + m19 + m20) / m09
		if m35 * m35 < m05 then
			m33 = m02 + m15 + m16 - m35 * m10
			if m33 * m33 < m14 then
				m34 = m00 + m17 + m18 - m35 * m32
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 + m25 + m19 + m20) / m09
		if m35 * m35 < m05 then
			m33 = m02 + m15 + m16 - m35 * m10
			if m33 * m33 < m14 then
				m34 = m00 + m17 + m18 - m35 * m32
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 - m25 - m19 + m20) / m09
		if m35 * m35 < m05 then
			m33 = m02 - m15 + m16 - m35 * m10
			if m33 * m33 < m14 then
				m34 = m00 - m17 + m18 - m35 * m32
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 + m25 - m19 + m20) / m09
		if m35 * m35 < m05 then
			m33 = m02 - m15 + m16 - m35 * m10
			if m33 * m33 < m14 then
				m34 = m00 - m17 + m18 - m35 * m32
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 - m25 + m19 - m20) / m09
		if m35 * m35 < m05 then
			m33 = m02 + m15 - m16 - m35 * m10
			if m33 * m33 < m14 then
				m34 = m00 + m17 - m18 - m35 * m32
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 + m25 + m19 - m20) / m09
		if m35 * m35 < m05 then
			m33 = m02 + m15 - m16 - m35 * m10
			if m33 * m33 < m14 then
				m34 = m00 + m17 - m18 - m35 * m32
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 - m25 - m19 - m20) / m09
		if m35 * m35 < m05 then
			m33 = m02 - m15 - m16 - m35 * m10
			if m33 * m33 < m14 then
				m34 = m00 - m17 - m18 - m35 * m32
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 + m25 - m19 - m20) / m09
		if m35 * m35 < m05 then
			m33 = m02 - m15 - m16 - m35 * m10
			if m33 * m33 < m14 then
				m34 = m00 - m17 - m18 - m35 * m32
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m02 - m26 + m16 + m21) / m04
		if m35 * m35 < m08 then
			m33 = m00 + m18 + m22 - m35 * m30
			if m33 * m33 < m12 then
				m34 = m01 + m20 + m23 - m35 * m03
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 + m26 + m16 + m21) / m04
		if m35 * m35 < m08 then
			m33 = m00 + m18 + m22 - m35 * m30
			if m33 * m33 < m12 then
				m34 = m01 + m20 + m23 - m35 * m03
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 - m26 - m16 + m21) / m04
		if m35 * m35 < m08 then
			m33 = m00 - m18 + m22 - m35 * m30
			if m33 * m33 < m12 then
				m34 = m01 - m20 + m23 - m35 * m03
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 + m26 - m16 + m21) / m04
		if m35 * m35 < m08 then
			m33 = m00 - m18 + m22 - m35 * m30
			if m33 * m33 < m12 then
				m34 = m01 - m20 + m23 - m35 * m03
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 - m26 + m16 - m21) / m04
		if m35 * m35 < m08 then
			m33 = m00 + m18 - m22 - m35 * m30
			if m33 * m33 < m12 then
				local Axi = m01 + m20 - m23 - m35 * m03
				if Axi * Axi < m13 then
					return true
				end
			end
		end

		m35 = (m02 + m26 + m16 - m21) / m04
		if m35 * m35 < m08 then
			m33 = m00 + m18 - m22 - m35 * m30
			if m33 * m33 < m12 then
				local sAn = m01 + m20 - m23 - m35 * m03
				if sAn * sAn < m13 then
					return true
				end
			end
		end

		m35 = (m02 - m26 - m16 - m21) / m04
		if m35 * m35 < m08 then
			m33 = m00 - m18 - m22 - m35 * m30
			if m33 * m33 < m12 then
				local gle = m01 - m20 - m23 - m35 * m03
				if gle * gle < m13 then
					return true
				end
			end
		end

		m35 = (m02 + m26 - m16 - m21) / m04
		if m35 * m35 < m08 then
			m33 = m00 - m18 - m22 - m35 * m30
			if m33 * m33 < m12 then
				m34 = m01 - m20 - m23 - m35 * m03
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m00 - m24 + m18 + m22) / m30
		if m35 * m35 < m08 then
			m33 = m01 + m20 + m23 - m35 * m03
			if m33 * m33 < m13 then
				m34 = m02 + m16 + m21 - m35 * m04
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 + m24 + m18 + m22) / m30
		if m35 * m35 < m08 then
			m33 = m01 + m20 + m23 - m35 * m03
			if m33 * m33 < m13 then
				m34 = m02 + m16 + m21 - m35 * m04
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 - m24 - m18 + m22) / m30
		if m35 * m35 < m08 then
			m33 = m01 - m20 + m23 - m35 * m03
			if m33 * m33 < m13 then
				m34 = m02 - m16 + m21 - m35 * m04
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 + m24 - m18 + m22) / m30
		if m35 * m35 < m08 then
			m33 = m01 - m20 + m23 - m35 * m03
			if m33 * m33 < m13 then
				m34 = m02 - m16 + m21 - m35 * m04
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 - m24 + m18 - m22) / m30
		if m35 * m35 < m08 then
			m33 = m01 + m20 - m23 - m35 * m03
			if m33 * m33 < m13 then
				m34 = m02 + m16 - m21 - m35 * m04
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 + m24 + m18 - m22) / m30
		if m35 * m35 < m08 then
			m33 = m01 + m20 - m23 - m35 * m03
			if m33 * m33 < m13 then
				m34 = m02 + m16 - m21 - m35 * m04
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 - m24 - m18 - m22) / m30
		if m35 * m35 < m08 then
			m33 = m01 - m20 - m23 - m35 * m03
			if m33 * m33 < m13 then
				m34 = m02 - m16 - m21 - m35 * m04
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 + m24 - m18 - m22) / m30
		if m35 * m35 < m08 then
			m33 = m01 - m20 - m23 - m35 * m03
			if m33 * m33 < m13 then
				m34 = m02 - m16 - m21 - m35 * m04
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m01 - m25 + m20 + m23) / m03
		if m35 * m35 < m08 then
			m33 = m02 + m16 + m21 - m35 * m04
			if m33 * m33 < m14 then
				m34 = m00 + m18 + m22 - m35 * m30
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 + m25 + m20 + m23) / m03
		if m35 * m35 < m08 then
			m33 = m02 + m16 + m21 - m35 * m04
			if m33 * m33 < m14 then
				m34 = m00 + m18 + m22 - m35 * m30
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 - m25 - m20 + m23) / m03
		if m35 * m35 < m08 then
			m33 = m02 - m16 + m21 - m35 * m04
			if m33 * m33 < m14 then
				m34 = m00 - m18 + m22 - m35 * m30
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 + m25 - m20 + m23) / m03
		if m35 * m35 < m08 then
			m33 = m02 - m16 + m21 - m35 * m04
			if m33 * m33 < m14 then
				m34 = m00 - m18 + m22 - m35 * m30
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 - m25 + m20 - m23) / m03
		if m35 * m35 < m08 then
			m33 = m02 + m16 - m21 - m35 * m04
			if m33 * m33 < m14 then
				m34 = m00 + m18 - m22 - m35 * m30
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 + m25 + m20 - m23) / m03
		if m35 * m35 < m08 then
			m33 = m02 + m16 - m21 - m35 * m04
			if m33 * m33 < m14 then
				m34 = m00 + m18 - m22 - m35 * m30
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 - m25 - m20 - m23) / m03
		if m35 * m35 < m08 then
			m33 = m02 - m16 - m21 - m35 * m04
			if m33 * m33 < m14 then
				m34 = m00 - m18 - m22 - m35 * m30
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 + m25 - m20 - m23) / m03
		if m35 * m35 < m08 then
			m33 = m02 - m16 - m21 - m35 * m04
			if m33 * m33 < m14 then
				m34 = m00 - m18 - m22 - m35 * m30
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m02 - m26 + m21 + m15) / m07
		if m35 * m35 < m11 then
			m33 = m00 + m22 + m17 - m35 * m31
			if m33 * m33 < m12 then
				m34 = m01 + m23 + m19 - m35 * m06
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 + m26 + m21 + m15) / m07
		if m35 * m35 < m11 then
			m33 = m00 + m22 + m17 - m35 * m31
			if m33 * m33 < m12 then
				m34 = m01 + m23 + m19 - m35 * m06
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 - m26 - m21 + m15) / m07
		if m35 * m35 < m11 then
			m33 = m00 - m22 + m17 - m35 * m31
			if m33 * m33 < m12 then
				m34 = m01 - m23 + m19 - m35 * m06
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 + m26 - m21 + m15) / m07
		if m35 * m35 < m11 then
			m33 = m00 - m22 + m17 - m35 * m31
			if m33 * m33 < m12 then
				m34 = m01 - m23 + m19 - m35 * m06
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 - m26 + m21 - m15) / m07
		if m35 * m35 < m11 then
			m33 = m00 + m22 - m17 - m35 * m31
			if m33 * m33 < m12 then
				m34 = m01 + m23 - m19 - m35 * m06
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 + m26 + m21 - m15) / m07
		if m35 * m35 < m11 then
			m33 = m00 + m22 - m17 - m35 * m31
			if m33 * m33 < m12 then
				m34 = m01 + m23 - m19 - m35 * m06
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 - m26 - m21 - m15) / m07
		if m35 * m35 < m11 then
			m33 = m00 - m22 - m17 - m35 * m31
			if m33 * m33 < m12 then
				m34 = m01 - m23 - m19 - m35 * m06
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m02 + m26 - m21 - m15) / m07
		if m35 * m35 < m11 then
			m33 = m00 - m22 - m17 - m35 * m31
			if m33 * m33 < m12 then
				m34 = m01 - m23 - m19 - m35 * m06
				if m34 * m34 < m13 then
					return true
				end
			end
		end

		m35 = (m00 - m24 + m22 + m17) / m31
		if m35 * m35 < m11 then
			m33 = m01 + m23 + m19 - m35 * m06
			if m33 * m33 < m13 then
				m34 = m02 + m21 + m15 - m35 * m07
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 + m24 + m22 + m17) / m31
		if m35 * m35 < m11 then
			m33 = m01 + m23 + m19 - m35 * m06
			if m33 * m33 < m13 then
				m34 = m02 + m21 + m15 - m35 * m07
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 - m24 - m22 + m17) / m31
		if m35 * m35 < m11 then
			m33 = m01 - m23 + m19 - m35 * m06
			if m33 * m33 < m13 then
				m34 = m02 - m21 + m15 - m35 * m07
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 + m24 - m22 + m17) / m31
		if m35 * m35 < m11 then
			m33 = m01 - m23 + m19 - m35 * m06
			if m33 * m33 < m13 then
				m34 = m02 - m21 + m15 - m35 * m07
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 - m24 + m22 - m17) / m31
		if m35 * m35 < m11 then
			m33 = m01 + m23 - m19 - m35 * m06
			if m33 * m33 < m13 then
				m34 = m02 + m21 - m15 - m35 * m07
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 + m24 + m22 - m17) / m31
		if m35 * m35 < m11 then
			m33 = m01 + m23 - m19 - m35 * m06
			if m33 * m33 < m13 then
				m34 = m02 + m21 - m15 - m35 * m07
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 - m24 - m22 - m17) / m31
		if m35 * m35 < m11 then
			m33 = m01 - m23 - m19 - m35 * m06
			if m33 * m33 < m13 then
				m34 = m02 - m21 - m15 - m35 * m07
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m00 + m24 - m22 - m17) / m31
		if m35 * m35 < m11 then
			m33 = m01 - m23 - m19 - m35 * m06
			if m33 * m33 < m13 then
				m34 = m02 - m21 - m15 - m35 * m07
				if m34 * m34 < m14 then
					return true
				end
			end
		end

		m35 = (m01 - m25 + m23 + m19) / m06
		if m35 * m35 < m11 then
			m33 = m02 + m21 + m15 - m35 * m07
			if m33 * m33 < m14 then
				m34 = m00 + m22 + m17 - m35 * m31
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 + m25 + m23 + m19) / m06
		if m35 * m35 < m11 then
			m33 = m02 + m21 + m15 - m35 * m07
			if m33 * m33 < m14 then
				m34 = m00 + m22 + m17 - m35 * m31
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 - m25 - m23 + m19) / m06
		if m35 * m35 < m11 then
			m33 = m02 - m21 + m15 - m35 * m07
			if m33 * m33 < m14 then
				m34 = m00 - m22 + m17 - m35 * m31
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 + m25 - m23 + m19) / m06
		if m35 * m35 < m11 then
			m33 = m02 - m21 + m15 - m35 * m07
			if m33 * m33 < m14 then
				m34 = m00 - m22 + m17 - m35 * m31
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 - m25 + m23 - m19) / m06
		if m35 * m35 < m11 then
			m33 = m02 + m21 - m15 - m35 * m07
			if m33 * m33 < m14 then
				m34 = m00 + m22 - m17 - m35 * m31
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 + m25 + m23 - m19) / m06
		if m35 * m35 < m11 then
			m33 = m02 + m21 - m15 - m35 * m07
			if m33 * m33 < m14 then
				m34 = m00 + m22 - m17 - m35 * m31
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 - m25 - m23 - m19) / m06
		if m35 * m35 < m11 then
			m33 = m02 - m21 - m15 - m35 * m07
			if m33 * m33 < m14 then
				m34 = m00 - m22 - m17 - m35 * m31
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		m35 = (m01 + m25 - m23 - m19) / m06
		if m35 * m35 < m11 then
			m33 = m02 - m21 - m15 - m35 * m07
			if m33 * m33 < m14 then
				m34 = m00 - m22 - m17 - m35 * m31
				if m34 * m34 < m12 then
					return true
				end
			end
		end

		return false
	else
		return AssumeTrue
	end
end

local function Region3BoundingBox(CoordinateFrame: CFrame, Size: Vector3)
 	local x, y, z, xx, yx, zx, xy, yy, zy, xz, yz, zz = CoordinateFrame:GetComponents()
	local sx, sy, sz = Size.X / 2, Size.Y / 2, Size.Z / 2
	local px = sx * math.abs(xx) + sy * math.abs(yx) + sz * math.abs(zx)
	local py = sx * math.abs(xy) + sy * math.abs(yy) + sz * math.abs(zy)
	local pz = sx * math.abs(xz) + sy * math.abs(yz) + sz * math.abs(zz)
	return Region3.new(Vector3.new(x - px, y - py, z - pz), Vector3.new(x + px, y + py, z + pz))
end

local function FindAllPartsInRegion3(Region: Region3, Ignore)
	Ignore = type(Ignore) == "table" and Ignore or {Ignore}
	local Last = #Ignore
	repeat
		local Parts = Workspace:FindPartsInRegion3WithIgnoreList(Region, Ignore, 100)
		local Start = #Ignore
		for Index, Part in ipairs(Parts) do
			Ignore[Start + Index] = Part
		end
	until #Parts < 100

	return {table.unpack(Ignore, Last + 1, #Ignore)}
end

local function CastPoint(Region, Point: CFrame)
	return BoxPointCollision(Region.CFrame, Region.Size, Point)
end

local function CastSphere(Region, Center: Vector3, Radius: number)
	return BoxSphereCollision(Region.CFrame, Region.Size, Center, Radius)
end

local function CastBox(Region, CoordinateFrame: CFrame, Size: Vector3)
	return BoxCollision(Region.CFrame, Region.Size, CoordinateFrame, Size)
end

local function CastPart(Region, Part: BasePart)
	return (not Part:IsA("Part") or Part.Shape == Enum.PartType.Block) and
		BoxCollision(Region.CFrame, Region.Size, Part.CFrame, Part.Size)
		or BoxSphereCollision(Region.CFrame, Region.Size, Part.Position, Part.Size.X)
end

local function CastParts(Region, Parts)
	local Inside = {}
	local Length = 0
	for _, Part in ipairs(Parts) do
		if CastPart(Region, Part) then
			Length += 1
			Inside[Length] = Part
		end
	end

	return Inside
end

local function Cast(Region, Ignore)
	local Inside = {}
	local Length = 0
	for _, Part in ipairs(FindAllPartsInRegion3(Region.Region3, Ignore)) do
		if CastPart(Region, Part) then
			Length += 1
			Inside[Length] = Part
		end
	end

	return Inside
end

local CurrentPlayers
local CurrentLength

local function GetPlayers(Region)
	local FoundPlayers = {}
	local Length = 0

	for _, Player in ipairs(CurrentPlayers) do
		local Character = Player.Character
		if Character then
			local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
			if HumanoidRootPart and CastPart(Region, HumanoidRootPart) then
				Length += 1
				FoundPlayers[Length] = Player
			end
		end
	end

	return FoundPlayers
end

local Region = {}

do
	CurrentPlayers = Players:GetPlayers()
	CurrentLength = #CurrentPlayers

	Players.PlayerAdded:Connect(function(Player)
		CurrentLength += 1
		CurrentPlayers[CurrentLength] = Player
	end)

	Players.PlayerRemoving:Connect(function(Player)
		local Index = table.find(CurrentPlayers, Player)
		if Index then
			CurrentPlayers[Index] = CurrentPlayers[CurrentLength]
			CurrentPlayers[CurrentLength] = nil
			CurrentLength -= 1
		end
	end)
end

local function NewRegion(CoordinateFrame: CFrame, Size: Vector3)
	local Object = {
		CFrame = CoordinateFrame;
		Size = Size;
		Region3 = Region3BoundingBox(CoordinateFrame, Size);
		Cast = Cast;
		CastPart = CastPart;
		CastParts = CastParts;
		CastPoint = CastPoint;
		CastSphere = CastSphere;
		CastBox = CastBox;
		GetPlayers = GetPlayers;
	}

	return setmetatable({}, {
		__index = Object;
		__newindex = function(_, Index, Value)
			Object[Index] = Value
			Object.Region3 = Region3BoundingBox(Object.CFrame, Object.Size)
		end;
	})
end

Region.Region3BoundingBox = Region3BoundingBox
Region.FindAllPartsInRegion3 = FindAllPartsInRegion3
Region.BoxPointCollision = BoxPointCollision
Region.BoxSphereCollision = BoxSphereCollision
Region.BoxCollision = BoxCollision
Region.GetPlayers = GetPlayers
Region.new = NewRegion

function Region.FromPart(Part: BasePart)
	return NewRegion(Part.CFrame, Part.Size)
end

return Region