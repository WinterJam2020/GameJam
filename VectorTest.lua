-- Vector3 class

local vector3 = {__type = "vector3"};
local mt = {__index = vector3};

-- built-in functions

local sqrt = math.sqrt;

-- private functions

local function calcMagnitude(v)
	return sqrt(v.X^2 + v.Y^2 + v.Z^2);
end;

local function normalize(v)
	local magnitude = sqrt(v.X^2 + v.Y^2 + v.Z^2);
	if magnitude > 0 then
		return vector3.new(v.X / magnitude, v.Y / magnitude, v.Z / magnitude);
	else
		-- avoid 'nan' case
		return vector3.new(0, 0, 0);
	end;
end;

-- meta-methods

function mt.__index(v, index)
	if index == "Unit" or index == "unit" then
		return normalize(v);
	elseif index == "Magnitude" or index == "magnitude" then
		return calcMagnitude(v);
	elseif vector3[index] then
		return vector3[index];
	elseif rawget(v, "proxy")[index] then
		return rawget(v, "proxy")[index];
	else
		error(index .. " is not a valid member of Vector3");
	end;
end;

function mt.__newindex(_, index)
	error(index .. " cannot be assigned to");
end;

function mt.__add(a, b)
	local aIsVector = type(a) == "table" and a.__type and a.__type == "vector3";
	local bIsVector = type(b) == "table" and b.__type and b.__type == "vector3";
	if aIsVector and bIsVector then
		return vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z);
	elseif bIsVector then
		-- check for custom type
		local t = type(a);
		local cust = t == "table" and a.__type or t;
		error("bad argument #1 to '?' (Vector3 expected, got " .. cust .. ")");
	elseif aIsVector then
		local t = type(b);
		local cust = t == "table" and b.__type or t;
		error("bad argument #2 to '?' (Vector3 expected, got " .. cust .. ")");
	end;
end;

function mt.__sub(a, b)
	local aIsVector = type(a) == "table" and a.__type and a.__type == "vector3";
	local bIsVector = type(b) == "table" and b.__type and b.__type == "vector3";
	if aIsVector and bIsVector then
		return vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z);
	elseif bIsVector then
		-- check for custom type
		local t = type(a);
		local cust = t == "table" and a.__type or t;
		error("bad argument #1 to '?' (Vector3 expected, got " .. cust .. ")");
	elseif aIsVector then
		local t = type(b);
		local cust = t == "table" and b.__type or t;
		error("bad argument #2 to '?' (Vector3 expected, got " .. cust .. ")");
	end;
end;

function mt.__mul(a, b)
	if type(a) == "number" then
		return vector3.new(a * b.X, a * b.Y, a * b.Z);
	elseif type(b) == "number" then
		return vector3.new(a.X * b, a.Y * b, a.Z * b);
	elseif a.__type and a.__type == "vector3" and  b.__type and b.__type == "vector3" then
		return vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z);
	else
		error("attempt to multiply a Vector3 with an incompatible value type or nil");
	end;
end;

function mt.__div(a, b)
	if type(a) == "number" then
		return vector3.new(a / b.X, a / b.Y, a / b.Z);
	elseif type(b) == "number" then
		return vector3.new(a.X / b, a.Y / b, a.Z / b);
	elseif a.__type and a.__type == "vector3" and  b.__type and b.__type == "vector3" then
		return vector3.new(a.X / b.X, a.Y / b.Y, a.Z / b.Z);
	else
		error("attempt to divide a Vector3 with an incompatible value type or nil");
	end;
end;

function mt.__unm(v)
	return vector3.new(-v.X, -v.Y, -v.Z);
end;

function mt.__tostring(v)
	return v.X .. ", " .. v.Y .. ", " .. v.Z;
end;

mt.__metatable = false;

-- public class

function vector3.new(x, y, z)
	local self = {};
	self.proxy = {};
	self.proxy.X = x or 0;
	self.proxy.Y = y or 0;
	self.proxy.Z = z or 0;
	return setmetatable(self, mt);
end;

function vector3.fromNormalId(id)
	pcall(function()
		id = id.Value or id
	end);
	if id == 0 then -- right
		return vector3.new(1, 0, 0);
	elseif id == 1 then -- top
		return vector3.new(0, 1, 0);
	elseif id == 2 then -- back
		return vector3.new(0, 0, 1);
	elseif id == 3 then -- left
		return vector3.new(-1, 0, 0);
	elseif id == 4 then
		return vector3.new(0, -1, 0);
	elseif id == 5 then
		return vector3.new(0, 0, -1);
	end;
end;

function vector3.fromAxis(id)
	pcall(function()
		id = id.Value or id
	end);
	if id == 0 then -- right
		return vector3.new(1, 0, 0);
	elseif id == 1 then -- top
		return vector3.new(0, 1, 0);
	elseif id == 2 then -- back
		return vector3.new(0, 0, 1);
	end;
end;

function vector3:Lerp(v3, t)
	return self + (v3 - self) * t;
end;

function vector3:Dot(v3)
	local isVector = v3.__type and v3.__type == "vector3";
	if isVector then
		return self.X * v3.X + self.Y * v3.Y + self.Z * v3.Z;
	else
		error("bad argument #1 to 'Dot' (Vector3 expected, got number)");
	end;
end;

function vector3:Cross(v3)
	local isVector = v3.__type and v3.__type == "vector3";
	if isVector then
		return vector3.new(
			self.Y * v3.Z - self.Z * v3.Y,
			self.Z * v3.X - self.X * v3.Z,
			self.X * v3.Y - self.Y * v3.X
		);
	else
		error("bad argument #1 to 'Cross' (Vector3 expected, got number)");
	end;
end;

local function Trajectory(Origin, Target, InitialVelocity, GravityForce)
	local g = -GravityForce
	local ox,oy,oz=Origin.X,Origin.Y,Origin.Z
	local rx,rz=Target.X-ox,Target.Z-oz
	local tx2=rx*rx+rz*rz
	local ty=Target.Y-oy
	if tx2>0 then
		local v2=InitialVelocity*InitialVelocity

		local c0=tx2/(2*(tx2+ty*ty))
		local c1=g*ty+v2
		local c22=v2*(2*g*ty+v2)-g*g*tx2
		if c22>0 then
			local c2=sqrt(c22)
			local t0x2=c0*(c1+c2)
			local t1x2=c0*(c1-c2)

			local tx,t0x,t1x=sqrt(tx2),sqrt(t0x2),sqrt(t1x2)

			local v0x,v0y,v0z=rx/tx*t0x,sqrt(v2-t0x2),rz/tx*t0x
			local v1x,v1y,v1z=rx/tx*t1x,sqrt(v2-t1x2),rz/tx*t1x

			local v0=vector3.new(v0x,ty>g*tx2/(2*v2) and v0y or -v0y,v0z)
			local v1=vector3.new(v1x,v1y,v1z)

			return v0,v1
		else
			return nil, nil, vector3.new(rx, sqrt(tx2), rz).Unit * InitialVelocity
		end
	else
		local v=vector3.new(0,InitialVelocity*(ty>0 and 1 or ty<0 and -1 or 0),0)
		return v,v
	end
end

print(Trajectory(vector3.new(0, 0, 0), vector3.new(50, 20, 0), 500, 196.2))

return vector3;