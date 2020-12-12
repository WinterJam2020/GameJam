-- CreateGJK
-- EgoMoose
-- December 1, 2020

local MAX_TRIES = 20
local ZERO3 = Vector3.new()

type Map<Index, Value> = {[Index]: Value}
type Array<Value> = Map<number, Value>
type PackedArray<Value> = Array<Value> & {n: number}

local function TripleProduct(A: Vector3, B: Vector3, C: Vector3): Vector3
	return B * C:Dot(A) - A * C:Dot(B)
end

local function ContainsOrigin(Simplex: Array<Vector3>, Direction: Vector3): (boolean, Vector3?)
	local A: Vector3 = Simplex[#Simplex]
	local AO: Vector3 = -A

	if #Simplex == 4 then
		local B: Vector3, C: Vector3, D: Vector3 = Simplex[3], Simplex[2], Simplex[1]
		local AB: Vector3, AC: Vector3, AD: Vector3 = B - A, C - A, D - A
		local ABC: Vector3, ACD: Vector3, ADB: Vector3 = AB:Cross(AC), AC:Cross(AD), AD:Cross(AB)

		ABC = ABC:Dot(AD) > 0 and -ABC or ABC
		ACD = ACD:Dot(AB) > 0 and -ACD or ACD
		ADB = ADB:Dot(AC) > 0 and -ADB or ADB

		if ABC:Dot(AO) > 0 then
			table.remove(Simplex, 1)
			Direction = ABC
		elseif ACD:Dot(AO) > 0 then
			table.remove(Simplex, 2)
			Direction = ACD
		elseif ADB:Dot(AO) > 0 then
			table.remove(Simplex, 3)
			Direction = ADB
		else
			return true
		end
	elseif #Simplex == 3 then
		local B: Vector3, C: Vector3 = Simplex[2], Simplex[1]
		local AB: Vector3, AC: Vector3 = B - A, C - A

		local ABC: Vector3 = AB:Cross(AC)
		local ABPerp: Vector3 = TripleProduct(AC, AB, AB).Unit
		local ACPerp: Vector3 = TripleProduct(AB, AC, AC).Unit

		if ABPerp:Dot(AO) > 0 then
			table.remove(Simplex, 1)
			Direction = ABPerp
		elseif ACPerp:Dot(AO) > 0 then
			table.remove(Simplex, 2)
			Direction = ACPerp
		else
			local IsVector3: boolean = (A - A) == ZERO3
			if not IsVector3 then
				return true
			else
				Direction = ABC:Dot(AO) > 0 and ABC or -ABC
			end
		end
	else
		local B: Vector3 = Simplex[1]
		local AB: Vector3 = B - A
		Direction = TripleProduct(AB, AO, AB).Unit
	end

	return false, Direction
end

local function CreateGJK(SetA, SetB, CentroidA: Vector3, CentroidB: Vector3, SupportA, SupportB)
	return function()
		local Direction: Vector3 = (CentroidA - CentroidB).Unit
		local Simplex = table.pack(SupportA(SetA, Direction) - SupportB(SetB, -Direction))
		local Length: number = Simplex.n

		Direction = -Direction

		for _ = 1, MAX_TRIES do
			Length += 1
			Simplex[Length] = SupportA(SetA, Direction) - SupportB(SetB, -Direction)

			if Simplex[Length]:Dot(Direction) <= 0 then -- simplex[#simplex]
				return false
			else
				local Passed: boolean, NewDirection = ContainsOrigin(Simplex, Direction)
				if Passed then
					return true
				end

				Direction = NewDirection
			end
		end

		return false
	end
end

return CreateGJK