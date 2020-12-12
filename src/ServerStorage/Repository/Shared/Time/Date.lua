-- Since DateTime is so SLOW.

local Suffixes = {"st", "nd", "rd"}
local DayNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
local MonthNames = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}

local CHAR_EXCLAMATION = string.byte("!")

local Patterns = {
	c = "%a %b %e %X %Y";
	D = "%m/%d/%y";
	F = "%Y-%m-%d";
	n = "\n";
	R = "%H:%M";
	r = "%I:%M:%S %p";
	T = "%H:%M:%S";
	t = "\t";
	v = "%e-%b-%Y";
	X = "%T";
	x = "%D";

	["#c"] = "%#x, %#X";
	["#r"] = "%#I:%M:%S %#p";
	["#T"] = "%#H:%M:%S";
	["#X"] = "%#T";
	["#x"] = "%A, %B %#d, %#Y";

	["%"] = "%";
}

type TimeData = {
	day: number,
	hour: number,
	isdst: boolean,
	min: number,
	month: number,
	sec: number,
	wday: number,
	yday: number,
	year: number
}

local function CountDays(Year)
	-- Returns the number of days in a given number of Years
	return 365*Year +
		(Year - Year % 4) / 4 - (Year - Year % 100) / 100 + (Year - Year % 400) / 400 -- the number of Leap days
end

local TimeZoneOffset, TimeZoneOffset2 do
	local TimeData: TimeData = os.date("!*t")
	local Data = os.date("*t", os.time(TimeData))
	local Deviation = (60 * Data.hour + Data.min) - (60 * TimeData.hour + TimeData.min)
	local AbsoluteDeviation = math.abs(Deviation)

	TimeZoneOffset2 = string.format("%s%02d:%02d", Deviation < 0 and "-" or "+", AbsoluteDeviation / 60, AbsoluteDeviation % 60)
	TimeZoneOffset = string.gsub(TimeZoneOffset2, ":", "", 1)
end

local Tags = setmetatable({
	-- Sources:
	-- https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man3/strftime.3.html
	-- https://msdn.microsoft.com/en-us/library/fe06s4ak.aspx

	A = function(TimeData) -- Full weekday name
		return DayNames[TimeData.wday]
	end;

	a = function(TimeData) -- Abbreviated weekday name
		return string.sub(DayNames[TimeData.wday], 1, 3)
	end;

	B = function(TimeData) -- Full month name
		return MonthNames[TimeData.month]
	end;

	b = function(TimeData) -- Abbreviated month name
		return string.sub(MonthNames[TimeData.month], 1, 3)
	end;

	C = function(TimeData) -- (year / 100) as decimal number; single digits are preceded by a zero
		return string.format("%02d", TimeData.year / 100)
	end;

	["#C"] = function(TimeData) -- (year / 100) as decimal number
		return (TimeData.year - TimeData.year % 100) / 100
	end;

	d = function(TimeData) -- Day of month as decimal number [01, 31]
		return string.format("%02d", TimeData.day)
	end;

	["#d"] = function(TimeData) -- Day of month as decimal number [1, 31]
		return TimeData.day
	end;

	e = function(TimeData) -- Day of month as decimal number [ 1, 31]
		return string.format("%2d", TimeData.day)
	end;

	G = function(TimeData) -- year that contains the greater part of the week (Monday as the first day of the week)
		return string.format("%04d", TimeData["#G"])
	end;

	["#G"] = function(TimeData)
		-- Returns whether most days of this week are outside this year
		-- @returns TimeData.year + 0 if most days of this week are in this year
		-- @returns TimeData.year + 1 if most days of this week are in next year
		-- @returns TimeData.year - 1 if most days of this week are in last year
		-- Note: Treats Monday as the beginning of the week

		local yday = TimeData.yday

		if yday < 4 then
			local wday = TimeData.wday == 1 and 6 or TimeData.wday - 2 -- [0, 6] Monday as Beginning
			local MondayOfWeek = TimeData.day - wday -- Get the TimeData.day of the first day of this week
			return MondayOfWeek < -2 and TimeData.year - 1 or TimeData.year
		elseif yday > 362 then
			local wday = TimeData.wday == 1 and 6 or TimeData.wday - 2 -- [0, 6] Monday as Beginning
			local MondayOfWeek = TimeData.day - wday -- Get the TimeData.day of the first day of this week
			return MondayOfWeek > 28 and TimeData.year + 1 or TimeData.year
		end

		return TimeData.year
	end;

	g = function(TimeData) -- same year as in %G, but without century [00, 99].
		return string.format("%02d", TimeData["#G"] % 100)
	end;

	["#g"] = function(TimeData) -- same year as in %#G, but without century [0, 99].
		return TimeData["#G"] % 100
	end;

	H = function(TimeData) -- Hour in 24-hour format [00, 23]
		return string.format("%02d", TimeData.hour)
	end;

	["#H"] = function(TimeData) -- Hour in 24-hour format [0, 23]
		return TimeData.hour
	end;

	I = function(TimeData) -- Hour in 12-hour format [01, 12]
		local Hours = TimeData.hour
		return string.format("%02d", Hours > 12 and Hours - 12 or Hours == 0 and 12 or Hours)
	end;

	["#I"] = function(TimeData) -- Hour in 12-hour format [1, 12]
		local Hours = TimeData.hour
		return Hours > 12 and Hours - 12 or Hours == 0 and 12 or Hours
	end;

	j = function(TimeData) -- Day of year as decimal number [001, 366]
		return string.format("%03d", TimeData.yday)
	end;

	["#j"] = function(TimeData) -- Day of year as decimal number [1, 366]
		return TimeData.yday
	end;

	k = function(TimeData) -- Hour in 24-hour format [ 0, 23]
		return string.format("%2d", TimeData.hour)
	end;

	l = function(TimeData) -- Hour in 12-hour format [ 1, 12]
		local Hours = TimeData.hour
		return string.format("%2d", Hours > 12 and Hours - 12 or Hours == 0 and 12 or Hours)
	end;

	M = function(TimeData) -- Minute as decimal number [00, 59]
		return string.format("%02d", TimeData.min)
	end;

	["#M"] = function(TimeData) -- Minute as decimal number [0, 59]
		return TimeData.min
	end;

	m = function(TimeData) -- Month as decimal number [01, 12]
		return string.format("%02d", TimeData.month)
	end;

	["#m"] = function(TimeData) -- Month as decimal number [1, 12]
		return TimeData.month
	end;

	p = function(TimeData) -- Current locale's AM/PM indicator for 12-hour clock
		return TimeData.hour > 11 and "PM" or "AM"
	end;

	["#p"] = function(TimeData) -- Current locale's am/pm indicator for 12-hour clock
		return TimeData.hour > 11 and "pm" or "am"
	end;

	S = function(TimeData) -- Second as decimal number [00, 59]
		return string.format("%02d", TimeData.sec)
	end;

	["#S"] = function(TimeData) -- Second as decimal number [0, 59]
		return TimeData.sec
	end;

	s = function(TimeData) -- Day of year suffix: e.g. 12th, 31st, 22nd
		local Days = TimeData.day
		return (Days < 21 and Days > 3 or Days > 23 and Days < 31) and "th" or Suffixes[Days % 10]
	end;

	U = function(TimeData) -- Week of year, Sunday Based [00, 53]
		return string.format("%02d", 1 + (TimeData.yday - TimeData.wday) / 7)
	end;

	["#U"] = function(TimeData) -- Week of year, Sunday Based [0, 53]
		local x = TimeData.yday - TimeData.wday
		return 1 + (x - x % 7) / 7
	end;

	u = function(TimeData) -- Weekday (Monday as first day of week) [1, 7]
		return TimeData.wday == 1 and 7 or TimeData.wday - 1
	end;

	V = function(TimeData)
		return string.format("%02d", TimeData["#V"])
	end;

	["#V"] = function(TimeData)
		local dn = CountDays(TimeData.year - 1) + TimeData.yday

		local y, yd do
			local g = dn + 306
			y = math.floor((10000 * g + 14780) / 3652425)
			yd = CountDays(y)
			local d = g - yd
			if d < 0 then
				y -= 1
				d = g - yd
			end

			local mi = math.floor((100 * d + 52) / 3060)
			y = math.floor((mi + 2) / 12) + y
		end

		local bool = dn >= yd - 3
		local f = (bool and yd or CountDays(y - 1)) + 3 -- get the date for the 4-Jan of year `y`
		local wday = (f + 1) % 7 -- get the ISO day number, 1 == Monday, 7 == Sunday
		local w1 = f + (1 - (wday == 0 and 7 or wday))

		if dn < w1 then
			local f2 = CountDays(y - (bool and 1 or 2)) + 3 -- get the date for the 4-Jan of year `y`
			local wday2 = (f2 + 1) % 7 -- get the ISO day number, 1 == Monday, 7 == Sunday
			w1 = f2 + (1 - (wday2 == 0 and 7 or wday2))
		end

		return math.floor((dn - w1) / 7 + 1)
	end;

	W = function(TimeData) -- Week of year as decimal number, with Monday as first day of week [0, 53]
		return string.format("%02d", TimeData["#W"])
	end;

	["#W"] = function(TimeData) -- Week of year as decimal number, with Monday as first day of week [0, 53]
		local Offset = TimeData.wday - 2
		local PreviousMonday = TimeData.yday - (Offset == -1 and 6 or Offset) -- [0, 6]
		local Divisible = PreviousMonday % 7
		return Divisible == 0 and PreviousMonday / 7 or 1 + (PreviousMonday - Divisible) / 7
	end;

	w = function(TimeData) -- Weekday [0, 6], Sunday as beginning
		return TimeData.wday - 1
	end;

	Y = function(TimeData) -- Year with century, as decimal number with 4 digits
		return string.format("%04d", TimeData.year)
	end;

	["#Y"] = function(TimeData) -- Year with century, as raw decimal number
		return TimeData.year
	end;

	y = function(TimeData) -- Year without century, as decimal number [00, 99]
		return string.format("%02d", TimeData.year % 100)
	end;

	["#y"] = function(TimeData) -- Year without century, as decimal number [0, 99]
		return TimeData.year % 100
	end;

	Z = function()
		error("Impossible to get timezone without location")
	end;

	z = function() -- Time zone offset from UTC in the form [+-]%02Hours%02Minutes, e.g. +0500
		return TimeZoneOffset
	end;

	["#z"] = function() -- Time zone offset from UTC in the form [+-]%02Hours:%02Minutes, e.g. +05:00
		return TimeZoneOffset2
	end;
}, {
	__index = function(_, Index) -- Error on invalid tag
		error("invalid tag: %%" .. Index)
	end;
})

Tags.h = Tags.b
Tags["#e"] = Tags["#d"]
Tags["#k"] = Tags["#H"]
Tags["#l"] = Tags["#I"]

for Tag, Replacement in next, Patterns do
	repeat
		local Previous = Replacement
		Replacement = string.gsub(Replacement, "%%(#?.)", Patterns)
	until Previous == Replacement -- Pre-optimize by evaluating recursive tags
	-- e.g. "%#c" => "%#x, %#X" => "%A, %B %#d, %#Y, %#T" => "%A, %B %#d, %#Y, %#H:%M:%S"

	Tags[Tag] = function(self)
		return string.gsub(Replacement, "%%(#?.)", self)
	end
end

function Tags:__index(Index)
	return Tags[Index](self) -- We use this trick to make gsub automatically call from Tags
end

local function Date(StringToFormat, Unix)
	local TimeData: TimeData

	if StringToFormat and string.byte(StringToFormat) == CHAR_EXCLAMATION then
		TimeData = os.date("!*t", Unix)
		StringToFormat = string.sub(StringToFormat, 2)
	else
		TimeData = os.date("*t", Unix)
	end

	return StringToFormat == "*t" and TimeData or
		string.gsub(StringToFormat or "%c", "%%(#?.)", setmetatable(TimeData, Tags))
end

return Date