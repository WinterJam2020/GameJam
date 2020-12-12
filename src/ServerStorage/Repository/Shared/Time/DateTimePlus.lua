-- Typing
type Any = any
type Boolean = boolean
type Nil = nil
type Number = number
type String = string

type Map<Index, Value> = {[Index]: Value}
type Array<Value> = Map<Number, Value>
type Dictionary<Value> = Map<String, Value>

type TimeDataActual = {
	day: Number?,
	hour: Number?,
	isdst: boolean?,
	min: Number?,
	month: Number?,
	sec: Number?,
	wday: Number?,
	yday: Number?,
	year: Number?
}

type TimeData = {
	Day: Number?,
	Hour: Number?,
	IsDst: boolean?,
	Minute: Number?,
	Month: Number?,
	Second: Number?,
	WeekDay: Number?,
	YearDay: Number?,
	Year: Number?,
	Locale: String?
}

type Duration = {
	Days: Number?,
	Hours: Number?,
	Minutes: Number?,
	Seconds: Number?
}

type DateChangeTable = Duration & {
	Years: Number?,
	Months: Number?,
	Weeks: Number?
}

type StringOrNumber = String | Number

local DEFAULT_LOCALE: String = "en-us"
local UNIVERSAL_PATTERNS: Dictionary<String> = {
	D = "%m/%d/%y";
	F = "%Y-%m-%d";
	n = "\n";
	R = "%H:%M";
	T = "%H:%M:%S";
	["#T"] = "%#H:%M:%S";
	t = "\t";
	v = "%e-%b-%Y";
	["%"] = "%";
}

local function DeclareReplacePatterns(Patterns: Dictionary<String>): Dictionary<String>
	for Index, Value in next, UNIVERSAL_PATTERNS do
		Patterns[Index] = Value
	end

	for Code, Replacement in next, Patterns do
		while 1 do
			local Previous = Replacement
			Replacement = string.gsub(Previous, "%%(#?.)", Patterns)
			if Previous == Replacement then
				break
			end
		end

		Patterns[Code] = Replacement
	end

	return Patterns
end

local LOCALES = {
	["en-us"] = {
		FIRST_DAY_OF_WEEK = 0;
		DAY_NAMES = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
		DAY_NAMES_SHORT = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
		MONTH_NAMES = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
		MONTH_NAMES_SHORT = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
		SUFFIXES = {"st", "nd", "rd"};
		AM_PM = {
			LOWER = {
				[false] = "am";
				[true] = "pm";
			};

			UPPER = {
				[false] = "AM";
				[true] = "PM";
			};
		};

		PATTERNS = DeclareReplacePatterns {
			c = "%a %b %e %X %Y";
			["#c"] = "%#x, %#X";
			r = "%I:%M:%S %p";
			["#r"] = "%#I:%M:%S %#p";
			X = "%T";
			["#X"] = "%#T";
			x = "%D";
			["#x"] = "%A, %B %#d, %#Y";
		};
	};
}

local function GetDay(DateTable: TimeData): Number
	return DateTable.Day
end

local function GetMonthShort(DateTable: TimeData): String
	return LOCALES[DateTable.Locale].MONTH_NAMES_SHORT[DateTable.Month]
end

local function GetHour(DateTable: TimeData): Number
	return DateTable.Hour
end

local function Get12Hour(DateTable: TimeData): Number
	local Hour = DateTable.Hour
	return Hour > 12 and Hour - 12 or Hour == 0 and 12 or Hour
end

local TIME_ZONE_OFFSET, TIME_ZONE_OFFSET2 do
	local DateDataUtc: TimeDataActual = os.date("!*t")
	local DateData = os.date("*t", os.time(DateDataUtc))
	local Deviation = 60*DateData.hour + DateData.min - (60*DateDataUtc.hour + DateDataUtc.min)
	local AbsoluteDeviation = math.abs(Deviation)

	TIME_ZONE_OFFSET2 = string.format("%s%02d:%02d", Deviation < 0 and "-" or "+", AbsoluteDeviation / 60, AbsoluteDeviation % 60)
	TIME_ZONE_OFFSET = string.gsub(TIME_ZONE_OFFSET2, ":", "", 1)
end

local function PatternReplacer(Replacement: String)
	return function(DateTable: TimeData): String
		return string.gsub(LOCALES[DateTable.Locale].PATTERNS[Replacement], "%%(#?.)", DateTable)
	end
end

local TagReplacers
TagReplacers = setmetatable({
	A = function(DateTable: TimeData): String
		return LOCALES[DateTable.Locale].DAY_NAMES[DateTable.WeekDay]
	end;

	a = function(DateTable: TimeData): String
		return LOCALES[DateTable.Locale].DAY_NAMES_SHORT[DateTable.WeekDay]
	end;

	B = function(DateTable: TimeData): String
		return LOCALES[DateTable.Locale].MONTH_NAMES[DateTable.Month]
	end;

	b = GetMonthShort;
	C = function(DateTable: TimeData): String
		return string.format("%02d", DateTable.Year / 100)
	end;

	["#C"] = function(DateTable: TimeData): Number
		local Year = DateTable.Year
		return (Year - Year % 100) / 100
	end;

	c = PatternReplacer("c");
	["#c"] = PatternReplacer("#c");
	D = PatternReplacer("D");
	d = function(DateTable: TimeData): String
		return string.format("%02d", DateTable.Day)
	end;

	["#d"] = GetDay;
	e = function(DateTable: TimeData): String
		return string.format("%2d", DateTable.Day)
	end;

	["#e"] = GetDay;
	F = PatternReplacer("F");
	G = function(DateTable: TimeData): String
		return string.format("%04d", TagReplacers["#G"](DateTable))
	end;

	["#G"] = function(DateTable: TimeData): Number
		-- @returns TimeData.year + 0 if most days of this week are in this year
		-- @returns TimeData.year + 1 if most days of this week are in next year
		-- @returns TimeData.year - 1 if most days of this week are in last year
		local YearDay = DateTable.YearDay
		local Year = DateTable.Year
		local WeekDay = DateTable.WeekDay == 1 and 6 or DateTable.WeekDay - 2
		local MondayOfWeek = DateTable.Day - WeekDay

		if YearDay < 4 then
			return MondayOfWeek < -2 and Year - 1 or Year
		elseif YearDay > 362 then
			return MondayOfWeek > 28 and Year + 1 or Year
		end

		return Year
	end;

	g = function(DateTable: TimeData): String
		return string.format("%02d", TagReplacers["#G"](DateTable) % 100)
	end;

	["#g"] = function(DateTable: TimeData): Number
		return TagReplacers["#G"](DateTable) % 100
	end;

	H = function(DateTable: TimeData): String
		return string.format("%02d", DateTable.Hour)
	end;

	["#H"] = GetHour;
	h = GetMonthShort;
	I = function(DateTable: TimeData): String
		return string.format("%02d", Get12Hour(DateTable))
	end;

	["#I"] = Get12Hour;
	j = function(DateTable: TimeData): String
		return string.format("%03d", DateTable.YearDay)
	end;

	["#j"] = function(DateTable: TimeData): Number
		return DateTable.YearDay
	end;

	k = function(DateTable: TimeData): String
		return string.format("%2d", DateTable.Hour)
	end;

	["#k"] = GetHour;
	l = function(DateTable: TimeData): String
		return string.format("%2d", Get12Hour(DateTable))
	end;

	["#l"] = Get12Hour;
	M = function(DateTable: TimeData): String
		return string.format("%02d", DateTable.Minute)
	end;

	["#M"] = function(DateTable: TimeData): Number
		return DateTable.Minute
	end;

	m = function(DateTable: TimeData): String
		return string.format("%02d", DateTable.Month)
	end;

	["#m"] = function(DateTable: TimeData): Number
		return DateTable.Month
	end;

	n = PatternReplacer("n");
	p = function(DateTable: TimeData): String
		return LOCALES[DateTable.Locale].AM_PM.UPPER[DateTable.Hour > 11]
	end;

	["#p"] = function(DateTable: TimeData): String
		return LOCALES[DateTable.Locale].AM_PM.LOWER[DateTable.Hour > 11]
	end;

	R = PatternReplacer("R");
	r = PatternReplacer("r");
	["#r"] = PatternReplacer("#r");
	S = function(DateTable: TimeData): String
		return string.format("%02d", DateTable.Second)
	end;

	["#S"] = function(DateTable: TimeData): Number
		return DateTable.Second
	end;

	s = function(DateTable: TimeData): String
		local Day = DateTable.Day
		return ((Day < 21 and Day > 3) or (Day > 23 and Day < 31)) and "th" or LOCALES[DateTable.Locale].SUFFIXES[Day % 10 + 1]
	end;

	T = PatternReplacer("T");
	["#T"] = PatternReplacer("#T");
	t = PatternReplacer("t");
	U = function(DateTable: TimeData): String
		return string.format("%02d", 1 + (DateTable.YearDay - DateTable.WeekDay) / 7)
	end;

	["#U"] = function(DateTable: TimeData): Number
		local Delta = DateTable.YearDay - DateTable.WeekDay
		return 1 + (Delta - Delta % 7) / 7
	end;

	u = function(DateTable: TimeData): Number
		return DateTable.WeekDay == 1 and 7 or DateTable.WeekDay - 1
	end;

	V = function(DateTable: TimeData): String
		return string.format("%02d", TagReplacers["#V"](DateTable))
	end;

	["#V"] = function(): Nil
		return error("%V not yet implemented")
	end;

	v = PatternReplacer("v");
	W = function(DateTable: TimeData): String
		return string.format("%02d", TagReplacers["#W"](DateTable))
	end;

	["#W"] = function(DateTable: TimeData): Number
		local Offset = DateTable.WeekDay - 2
		local PreviousMonday = DateTable.YearDay - (Offset == -1 and 6 or Offset)
		local Divisible = PreviousMonday % 7
		return Divisible == 0 and PreviousMonday / 7 or 1 + (PreviousMonday - Divisible) / 7
	end;

	w = function(DateTable: TimeData): Number
		return DateTable.WeekDay - 1
	end;

	X = PatternReplacer("X");
	["#X"] = PatternReplacer("#X");
	x = PatternReplacer("x");
	["#x"] = PatternReplacer("#x");
	Y = function(DateTable: TimeData): Number
		return DateTable.Year
	end;

	y = function(DateTable: TimeData): Number
		return DateTable.Year % 100
	end;

	Z = function(): Nil
		return error("[Date] Impossible to get timezone name without location", 2)
	end;

	z = function(): String
		return TIME_ZONE_OFFSET
	end;

	["%"] = PatternReplacer("%");
	["#z"] = function(): String
		return TIME_ZONE_OFFSET2
	end;
}, {
	__index = function(_, Index: String): Nil
		return error("[Date] invalid tag: %%" .. Index)
	end;
})

local ReplaceIndexer = {
	__index = function(self, Index: String): StringOrNumber?
		return TagReplacers[Index](self)
	end;
}

local function FixTimeData(TimeData: TimeDataActual, Locale: String): TimeData
	return {
		Day = TimeData.day;
		Hour = TimeData.hour;
		IsDst = TimeData.isdst;
		Minute = TimeData.min;
		Month = TimeData.month;
		Second = TimeData.sec;
		WeekDay = TimeData.wday;
		YearDay = TimeData.yday;
		Year = TimeData.year;
		Locale = Locale;
	}
end

local function ConvertToActual(TimeData: TimeData): TimeDataActual
	return {
		day = TimeData.Day;
		hour = TimeData.Hour;
		isdst = TimeData.IsDst;
		min = TimeData.Minute;
		month = TimeData.Month;
		sec = TimeData.Second;
		wday = TimeData.WeekDay;
		yday = TimeData.YearDay;
		year = TimeData.Year;
	}
end

local function _FormatDate(FormatString: String?, Unix: Number?, Locale: String?): TimeData | String
	local CurrentLocale: String = Locale or DEFAULT_LOCALE
	local TimeData: TimeDataActual
	if FormatString and string.sub(FormatString, 1, 1) == "!" then
		TimeData = os.date("!*t", Unix)
		FormatString = string.sub(FormatString, 2)
	else
		TimeData = os.date("!*t", Unix)
	end

	local NewTimeData: TimeData = {
		Day = TimeData.day;
		Hour = TimeData.hour;
		IsDst = TimeData.isdst;
		Minute = TimeData.min;
		Month = TimeData.month;
		Second = TimeData.sec;
		WeekDay = TimeData.wday;
		YearDay = TimeData.yday;
		Year = TimeData.year;
		Locale = CurrentLocale;
	}

	return FormatString == "*t" and NewTimeData or string.gsub(FormatString or "%c", "%%(#?.)", setmetatable(NewTimeData, ReplaceIndexer))
end

local DateTimePlus = {
	ClassName = "DateTimePlus";
	MonthLengths = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
	__tostring = function(self): String
		return self.ClassName
	end;
}

do
	local DateTable: TimeDataActual = os.date("!*t")
	type DateTimePlus = typeof(setmetatable({
		Unix = os.time(DateTable);
		TimeData = FixTimeData(DateTable, DEFAULT_LOCALE);
	}, DateTimePlus))
end

function DateTimePlus.new(Seconds: Number?, Utc: Boolean?, Locale: String?): DateTimePlus
	local IsUtc: Boolean = Utc == nil and true or Utc
	local CurrentLocale: String = Locale or DEFAULT_LOCALE
	local DateTable: TimeDataActual = os.date(IsUtc and "!*t" or "*t", Seconds)

	return setmetatable({
		Unix = os.time(DateTable);
		TimeData = FixTimeData(DateTable, CurrentLocale);
	}, DateTimePlus)
end

function DateTimePlus:__index(Index: String)
	if DateTimePlus[Index] then
		return DateTimePlus[Index]
	elseif self.TimeData[Index] then
		return self.TimeData[Index]
	end
end

-- function DateTimePlus:__newindex(Index: String, Value: Any)
-- 	if VALID_SET_UNITS[Index] then
-- 		local Unit = Value
-- 		local Objectified = self:ToObject()
-- 		for UnitIndex, UnitValue in next, Value do
-- 			Objectified[UnitIndex] = UnitValue
-- 		end
-- 	end
-- end

function DateTimePlus:ToObject()
	local Object = {}
	for Index, Value in next, self.TimeData do
		Object[Index] = Value
	end

	return Object
end

local EPOCH_TIME_DATA: TimeDataActual = {
	year = 1970;
	month = 1;
	day = 3;
}

function DateTimePlus.GetUtcOffset(): Number
	return 216000 - os.time(EPOCH_TIME_DATA)
end

function DateTimePlus.IsLeapYear(Year: Number): Boolean
	return Year % 4 == 0 and (Year % 25 ~= 0 or Year % 16 == 0)
end

function DateTimePlus.DaysInMonth(Month: Number, Year: Number): Number
	return Month == 2 and (Year % 4 == 0 and (Year % 25 ~= 0 or Year % 16 == 0)) and 29 or DateTimePlus.MonthLengths[Month]
end

function DateTimePlus.FromObject(TimeData: TimeDataActual): DateTimePlus
	TimeData.day = TimeData.day or 1
	return DateTimePlus.new(os.time(TimeData))
end

function DateTimePlus.Now(): DateTimePlus
	local DateTable: TimeDataActual = os.date("*t")
	return setmetatable({
		Unix = os.time(DateTable);
		TimeData = FixTimeData(DateTable, DEFAULT_LOCALE);
	}, DateTimePlus)
end

function DateTimePlus.Utc(): DateTimePlus
	local DateTable: TimeDataActual = os.date("!*t")
	return setmetatable({
		Unix = os.time(DateTable);
		TimeData = FixTimeData(DateTable, DEFAULT_LOCALE);
	}, DateTimePlus)
end

local function GetFirstReducer(Previous: DateTimePlus, Current: DateTimePlus): DateTimePlus
	return Previous.Unix < Current.Unix and Previous or Current
end

local function GetLastReducer(Previous: DateTimePlus, Current: DateTimePlus): DateTimePlus
	return Previous.Unix > Current.Unix and Previous or Current
end

function DateTimePlus.GetFirst(...): DateTimePlus
	local Dates: Array<DateTimePlus> = {...}
	local Length: Number = #Dates
	if Length == 0 then
		error("Cannot reduce an empty array without an initial value.", 2)
	end

	local Accumulator: DateTimePlus = Dates[1]
	for Index = 2, Length do
		Accumulator = GetFirstReducer(Accumulator, Dates[Index])
	end

	return Accumulator
end

function DateTimePlus.GetLast(...): DateTimePlus
	local Dates: Array<DateTimePlus> = {...}
	local Length: Number = #Dates
	if Length == 0 then
		error("Cannot reduce an empty array without an initial value.", 2)
	end

	local Accumulator: DateTimePlus = Dates[1]
	for Index = 2, Length do
		Accumulator = GetLastReducer(Accumulator, Dates[Index])
	end

	return Accumulator
end

function DateTimePlus:Get(Unit: String)
	return self.TimeData[Unit]
end

function DateTimePlus:Set(Unit: TimeData): DateTimePlus
	local DateTable: TimeData = self:ToObject()
	for Index, Value in next, Unit do
		DateTable[Index] = Value
	end

	return DateTimePlus.new(os.time(ConvertToActual(DateTable)))
end

function DateTimePlus:Easter(): DateTimePlus
	local TimeData: TimeData = self.TimeData
	local Year: Number = TimeData.Year

	local A: Number = math.floor(Year / 100) * 1483 - math.floor(Year / 400) * 2225 + 2613
	local B: Number = math.floor((Year % 19 * 3510 + math.floor(A / 25) * 319) / 330) % 29
	local C: Number = 148 - B - ((math.floor(Year * 1.25) + A - B) % 7)

	return DateTimePlus.new(os.time {
		year = Year;
		month = math.floor(C / 31);
		day = C % 31 + 1;
	})
end

function DateTimePlus:__add(Other: DateChangeTable): DateTimePlus
	local DateTable: TimeData = self.TimeData
	local Year: Number = DateTable.Year + (Other.Years or 0)
	local Month: Number = DateTable.Month + (Other.Months or 0)

	if Month > 12 then
		local PreviousMonth: Number = Month
		Month %= 12
		Year += (PreviousMonth - Month) / 12
	end

	if Month > 12 then
		Year += math.floor(Month / 12)
		Month -= 12 * Year
	end

	return DateTimePlus.new(os.time {
		year = Year;
		month = Month;
		day = DateTable.Day;
	}) + (((((Other.Weeks or 0) * 7 + (Other.Days or 0)) * 24 + (Other.Hours or 0)) * 60 + (Other.Minutes or 0)) * 60 + (Other.Seconds or 0))
end

function DateTimePlus:__sub(Other: DateChangeTable): DateTimePlus
	local DateTable: TimeData = self.TimeData
	local Year: Number = DateTable.Year - (Other.Years or 0)
	local Month: Number = DateTable.Month - (Other.Months or 0)

	if Month < 1 then
		local PreviousMonth: Number = Month
		Month = (Month - 1) % 12 + 1
		Year -= (PreviousMonth - Month - 2) / 12
	end

	return DateTimePlus.new(os.time {
		year = Year;
		month = Month;
		day = DateTable.Day;
	}) + (((((Other.Weeks or 0) * 7 + (Other.Days or 0)) * 24 + (Other.Hours or 0)) * 60 + (Other.Minutes or 0)) * 60 + (Other.Seconds or 0))
end

-- function DateTimePlus:EndOf(Unit: String): DateTimePlus
-- 	local DateTable: TimeDataActual = ConvertToActual(self:ToObject())
-- 	if Unit == "Week" then
-- 		DateTable.day -= DateTable.wday - 1
-- 		Unit = "Day"
-- 	end

-- 	repeat
-- 		local Success
-- 	until 1
-- end

return DateTimePlus