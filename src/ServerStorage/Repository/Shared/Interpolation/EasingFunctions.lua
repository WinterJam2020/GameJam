local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Bezier = Resources:LoadLibrary("Bezier")
local Table = Resources:LoadLibrary("Table")

-- @specs https://material.io/guidelines/motion/duration-easing.html#duration-easing-natural-easing-curves
local Sharp = Bezier.new(0.4, 0, 0.6, 1)
local Standard = Bezier.new(0.4, 0, 0.2, 1)
local Acceleration = Bezier.new(0.4, 0, 1, 1)
local Deceleration = Bezier.new(0, 0, 0.2, 1)

-- @specs https://developer.microsoft.com/en-us/fabric#/styles/web/motion#basic-animations
local FabricStandard = Bezier.new(0.8, 0, 0.2, 1) -- used for moving.
local FabricAccelerate = Bezier.new(0.9, 0.1, 1, 0.2) -- used for exiting.
local FabricDecelerate = Bezier.new(0.1, 0.9, 0.2, 1) -- used for entering.

-- @specs https://docs.microsoft.com/en-us/windows/uwp/design/motion/timing-and-easing
local UWPAccelerate = Bezier.new(0.7, 0, 1, 0.5)

--[[
	Disclaimer for Robert Penner's Easing Equations license:

	TERMS OF USE - EASING EQUATIONS

	Open source under the BSD License.

	Copyright © 2001 Robert Penner
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
	* Neither the name of the author nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
	OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

-- For all easing functions:
-- t = elapsed time
-- b = beginning value
-- c = change in value same as: ending - beginning
-- d = duration (total time)

-- Where applicable
-- a = amplitude
-- p = period

local function Linear(t, b, c, d)
	return c * t / d + b
end

local function Smooth(t, b, c, d)
	t /= d
	return c * t * t * (3 - 2 * t) + b
end

local function Smoother(t, b, c, d)
	t /= d
	return c * t * t * t * (t * (6 * t - 15) + 10) + b
end

-- Arceusinator's Easing Functions
local function RevBack(t, b, c, d)
	t = 1 - t / d
	return c * (1 - (math.sin(t * 1.5707963267949) + (math.sin(t * 3.1415926535898) * (math.cos(t * 3.1415926535898) + 1) / 2))) + b
end

local function RidiculousWiggle(t, b, c, d)
	t /= d
	return c * math.sin(math.sin(t * 3.1415926535898) * 1.5707963267949) + b
end

-- YellowTide's Easing Functions
local function Spring(t, b, c, d)
	t /= d
	return (1 + (-math.exp(-6.9 * t) * math.cos(-20.106192982975 * t))) * c + b
end

local function SoftSpring(t, b, c, d)
	t /= d
	return (1 + (-math.exp(-7.5 * t) * math.cos(-10.053096491487 * t))) * c + b
end

-- End of YellowTide's functions

local function InQuad(t, b, c, d)
	t /= d
	return c * t * t + b
end

local function OutQuad(t, b, c, d)
	t /= d
	return -c * t * (t - 2) + b
end

local function InOutQuad(t, b, c, d)
	t /= d * 2
	return t < 1 and c / 2 * t * t + b or -c / 2 * ((t - 1) * (t - 3) - 1) + b
end

local function OutInQuad(t, b, c, d)
	if t < d / 2 then
		t *= 2 / d
		return -c / 2 * t * (t - 2) + b
	else
		t = (t * 2) - d / d
		c /= 2
		return c * t * t + b + c
	end
end

local function InCubic(t, b, c, d)
	t /= d
	return c * t * t * t + b
end

local function OutCubic(t, b, c, d)
	t /= d - 1
	return c * (t * t * t + 1) + b
end

local function InOutCubic(t, b, c, d)
	t /= d * 2
	if t < 1 then
		return c / 2 * t * t * t + b
	else
		t -= 2
		return c / 2 * (t * t * t + 2) + b
	end
end

local function OutInCubic(t, b, c, d)
	if t < d / 2 then
		t *= 2 / d - 1
		return c / 2 * (t * t * t + 1) + b
	else
		t = (t * 2 - d) / d
		c /= 2
		return c * t * t * t + b + c
	end
end

local function InQuart(t, b, c, d)
	t /= d
	return c * t * t * t * t + b
end

local function OutQuart(t, b, c, d)
	t /= d - 1
	return -c * (t * t * t * t - 1) + b
end

local function InOutQuart(t, b, c, d)
	t /= d * 2
	if t < 1 then
		return c / 2 * t * t * t * t + b
	else
		t -= 2
		return -c / 2 * (t * t * t * t - 2) + b
	end
end

local function OutInQuart(t, b, c, d)
	if t < d / 2 then
		t *= 2 / d - 1
		c /= 2
		return -c * (t * t * t * t - 1) + b
	else
		t = (t * 2 - d) / d
		c /= 2
		return c * t * t * t * t + b + c
	end
end

local function InQuint(t, b, c, d)
	t /= d
	return c * t * t * t * t * t + b
end

local function OutQuint(t, b, c, d)
	t /= d - 1
	return c * (t * t * t * t * t + 1) + b
end

local function InOutQuint(t, b, c, d)
	t /= d * 2
	if t < 1 then
		return c / 2 * t * t * t * t * t + b
	else
		t -= 2
		return c / 2 * (t * t * t * t * t + 2) + b
	end
end

local function OutInQuint(t, b, c, d)
	if t < d / 2 then
		t *= 2 / d - 1
		return c / 2 * (t * t * t * t * t + 1) + b
	else
		t = (t * 2 - d) / d
		c /= 2
		return c * t * t * t * t * t + b + c
	end
end

local function InSine(t, b, c, d)
	return -c * math.cos(t / d * 1.5707963267949) + c + b
end

local function OutSine(t, b, c, d)
	return c * math.sin(t / d * 1.5707963267949) + b
end

local function InOutSine(t, b, c, d)
	return -c / 2 * (math.cos(3.1415926535898 * t / d) - 1) + b
end

local function OutInSine(t, b, c, d)
	c /= 2
	return t < d / 2 and c * math.sin(t * 2 / d * 1.5707963267949) + b or -c * math.cos(((t * 2) - d) / d * 1.5707963267949) + 2 * c + b
end

local function InExpo(t, b, c, d)
	if t == 0 then
		return b
	else
		return c * 1024 ^ (t / d - 1) + b - c / 1000
	end
end

local function OutExpo(t, b, c, d)
	if t == d then
		return b + c
	else
		return c * 1.001 * (1 - math.exp(-6.9314718055994531 * (t / d))) + b
	end
end

local function InOutExpo(t, b, c, d)
	t /= d * 2

	if t == 0 then
		return b
	elseif t == 2 then
		return b + c
	elseif t < 1 then
		return c / 2 * 1024 ^ (t - 1) + b - c / 2000
	else
		return c * 0.50025 * (2 - math.exp(-6.9314718055994531 * (t - 1))) + b
	end
end

local function OutInExpo(t, b, c, d)
	c /= 2
	if t < d / 2 then
		if t * 2 == d then
			return b + c
		else
			return c * 1.001 * (1 - math.exp(13.8629436111989062 * t / d)) + b
		end
	else
		if t * 2 - d == 0 then
			return b + c
		else
			return c * 1024 ^ ((t * 2 - d) / d - 1) + b + c - c / 1000
		end
	end
end

local function InCirc(t, b, c, d)
	t /= d
	return -c * (math.sqrt(1 - t * t) - 1) + b
end

local function OutCirc(t, b, c, d)
	t /= d - 1
	return c * math.sqrt(1 - t * t) + b
end

local function InOutCirc(t, b, c, d)
	t /= d * 2
	if t < 1 then
		return -c / 2 * (math.sqrt(1 - t * t) - 1) + b
	else
		t -= 2
		return c / 2 * (math.sqrt(1 - t * t) + 1) + b
	end
end

local function OutInCirc(t, b, c, d)
	c /= 2
	if t < d / 2 then
		t *= 2 / d - 1
		return c * math.sqrt(1 - t * t) + b
	else
		t = (t * 2 - d) / d
		return -c * (math.sqrt(1 - t * t) - 1) + b + c
	end
end

local function InElastic(t, b, c, d, a, p)
	t /= d - 1
	if t == -1 then
		return b
	else
		if t == 0 then
			return b + c
		else
			p = p or d * 0.3
			if a == nil or a < math.abs(c) then
				return -(c * 1024 ^ t * math.sin((t * d - p / 4) * 6.2831853071796 / p)) + b
			else
				return -(a * 1024 ^ t * math.sin((t * d - p / 6.2831853071796 * math.asin(c / a)) * 6.2831853071796 / p)) + b
			end
		end
	end
end

local function OutElastic(t, b, c, d, a, p)
	t /= d
	if t == 0 then
		return b
	else
		if t == 1 then
			return b + c
		else
			p = p or d * 0.3
			if a == nil or a < math.abs(c) then
				return c * math.exp(-6.9314718055994531 * t) * math.sin((t * d - p / 4) * 6.2831853071796 / p) + c + b
			else
				return a * math.exp(-6.9314718055994531 * t) * math.sin((t * d - p / 6.2831853071796 * math.asin(c / a)) * 6.2831853071796 / p) + c + b
			end
		end
	end
end

local function InOutElastic(t, b, c, d, a, p)
	if t == 0 then
		return b
	end

	t /= d * 2 - 1
	if t == 1 then
		return b + c
	end

	p = p or d * 0.45
	a = a or 0

	local s

	if not a or a < math.abs(c) then
		a = c
		s = p / 4
	else
		s = p / 6.2831853071796 * math.asin(c / a)
	end

	if t < 1 then
		return -a / 2 * 1024 ^ t * math.sin((t * d - s) * 6.2831853071796 / p) + b
	else
		return a * math.exp(-6.9314718055994531 * t) * math.sin((t * d - s) * 6.2831853071796 / p) / 2 + c + b
	end
end

local function OutInElastic(t, b, c, d, a, p)
	if t < d / 2 then
		return OutElastic(t * 2, b, c / 2, d, a, p)
	else
		return InElastic(t * 2 - d, b + c / 2, c / 2, d, a, p)
	end
end

local function InBack(t, b, c, d, s)
	s = s or 1.70158
	t /= d
	return c * t * t * ((s + 1) * t - s) + b
end

local function OutBack(t, b, c, d, s)
	s = s or 1.70158
	t /= d - 1
	return c * (t * t * ((s + 1) * t + s) + 1) + b
end

local function InOutBack(t, b, c, d, s)
	s = (s or 1.70158) * 1.525
	t /= d * 2
	if t < 1 then
		return c / 2 * (t * t * ((s + 1) * t - s)) + b
	else
		t -= 2
		return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
	end
end

local function OutInBack(t, b, c, d, s)
	c /= 2
	s = s or 1.70158
	if t < d / 2 then
		t *= 2 / d - 1
		return c * (t * t * ((s + 1) * t + s) + 1) + b
	else
		t = (t * 2 - d) / d
		return c * t * t * ((s + 1) * t - s) + b + c
	end
end

-- local function OutBounce(t, b, c, d)
-- 	t /= d
-- 	if t < 1 / 2.75 then
-- 		return c * (7.5625 * t * t) + b
-- 	elseif t < 2 / 2.75 then
-- 		t -= 1.5 / 2.75
-- 		return c * (7.5625 * t * t + 0.75) + b
-- 	elseif t < 2.5 / 2.75 then
-- 		t -= 2.25 / 2.75
-- 		return c * (7.5625 * t * t + 0.9375) + b
-- 	else
-- 		t -= 2.625 / 2.75
-- 		return c * (7.5625 * t * t + 0.984375) + b
-- 	end
-- end

local function OutBounce(t, b, c, d)
	t /= d
	if t < 0.36363636363636 then
		return c * (7.5625 * t * t) + b
	elseif t < 0.72727272727273 then
		t -= 0.54545454545455
		return c * (7.5625 * t * t + 0.75) + b
	elseif t < 0.90909090909091 then
		t -= 0.81818181818182
		return c * (7.5625 * t * t + 0.9375) + b
	else
		t -= 0.95454545454545
		return c * (7.5625 * t * t + 0.984375) + b
	end
end

local function InBounce(t, b, c, d)
	return c - OutBounce(d - t, 0, c, d) + b
end

local function InOutBounce(t, b, c, d)
	if t < d / 2 then
		return InBounce(t * 2, 0, c, d) / 2 + b
	else
		return OutBounce(t * 2 - d, 0, c, d) / 2 + c / 2 + b
	end
end

local function OutInBounce(t, b, c, d)
	if t < d / 2 then
		return OutBounce(t * 2, b, c / 2, d)
	else
		return InBounce(t * 2 - d, b + c / 2, c / 2, d)
	end
end

return Table.Lock({
	[0] = Standard;
	Deceleration;
	Acceleration;
	Sharp;

	FabricStandard;
	FabricAccelerate;
	FabricDecelerate;

	UWPAccelerate;

	Linear;

	InSine;
	OutSine;
	InOutSine;
	OutInSine;

	InBack;
	OutBack;
	InOutBack;
	OutInBack;

	InQuad;
	OutQuad;
	InOutQuad;
	OutInQuad;

	InQuart;
	OutQuart;
	InOutQuart;
	OutInQuart;

	InQuint;
	OutQuint;
	InOutQuint;
	OutInQuint;

	InBounce;
	OutBounce;
	InOutBounce;
	OutInBounce;

	InElastic;
	OutElastic;
	InOutElastic;
	OutInElastic;

	InCirc;
	OutCirc;
	InOutCirc;
	OutInCirc;

	InCubic;
	OutCubic;
	InOutCubic;
	OutInCubic;

	InExpo;
	OutExpo;
	InOutExpo;
	OutInExpo;

	Smooth;
	Smoother;
	RevBack;
	RidiculousWiggle;
	Spring;
	SoftSpring;
}, nil, script.Name)