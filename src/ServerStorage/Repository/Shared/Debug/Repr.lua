type Any = any
type Boolean = boolean
type Number = number
type String = string

type Map<Index, Value> = {[Index]: Value}
type Array<Value> = Map<Number, Value>
type Dictionary<Value> = Map<String, Value>
type GenericTable = Map<Any, Any>

type ReprSettings = {
	Pretty: Boolean,
	RobloxFullName: Boolean,
	RobloxProperFullName: Boolean,
	RobloxClassName: Boolean,
	Tabs: Boolean,
	Semicolons: Boolean,
	Spaces: Number,
	SortKeys: Boolean,
}

local DEFAULT_SETTINGS: ReprSettings = {
	Pretty = true;
	RobloxFullName = false;
	RobloxProperFullName = true;
	RobloxClassName = true;
	Tabs = true;
	Semicolons = true;
	Spaces = 4;
	SortKeys = true;
}

local LUA_KEYWORDS: Dictionary<Boolean> = {
	["and"] = true;
	["break"] = true;
	["do"] = true;
	["else"] = true;
	["elseif"] = true;
	["end"] = true;
	["false"] = true;
	["for"] = true;
	["function"] = true;
	["if"] = true;
	["in"] = true;
	["local"] = true;
	["nil"] = true;
	["not"] = true;
	["or"] = true;
	["repeat"] = true;
	["return"] = true;
	["then"] = true;
	["true"] = true;
	["until"] = true;
	["while"] = true;
	["continue"] = true;
}

local function IsLuaIdentifier(String: String): Boolean
	return not (type(String) ~= "string" or #String == 0 or string.find(String, "[^%d%a_]") or tonumber(string.sub(String, 1, 1)) or LUA_KEYWORDS[String])
end

local function ProperFullName(Object): String
	if Object == nil or Object == game then
		return ""
	end

	local String: String = Object.Name
	local UsePeriod: Boolean = true
	if not IsLuaIdentifier(String) then
		String = string.format("[%q]", String)
		UsePeriod = false
	end

	if not Object.Parent or Object.Parent == game then
		return String
	else
		return ProperFullName(Object.Parent) .. (UsePeriod and "." or "") .. String
	end
end

local Depth: Number = 0
local Shown: GenericTable
local INDENT: String

local NormalIds: Array<EnumItem> = Enum.NormalId:GetEnumItems()

local function GetFloat(Number: Number): String
	local String: String = tostring(Number)
	if tonumber(String) == Number then
		return String
	else
		for Index = 15, 99 do
			String = string.format("%." .. Index .. "f", Number)
			if tonumber(String) == Number then
				return String
			end
		end

		error("Something failed?", 2)
	end
end

local function IntegerOrFloat(Number: String | Number): String
	local NewNumber: Number = tonumber(Number)
	return NewNumber % 1 == 0 and string.format("%d", NewNumber) or GetFloat(NewNumber)
end

-- Typed Luau is not that good. :/
-- Even TypeScript is better. And that's not official.

local function DictionaryJoin(...)
	local New = {}
	for Index = 1, select("#", ...) do
		local Dictionary: ReprSettings = select(Index, ...)
		for Key, Value in next, Dictionary do
			New[Key] = Value
		end
	end

	return New
end

local function Repr(Value: Any, ReprSettings: ReprSettings?): String
	local ReprSettings2: ReprSettings = DictionaryJoin(DEFAULT_SETTINGS, ReprSettings == nil and {} or ReprSettings)
	INDENT = string.rep(" ", ReprSettings2.Spaces)
	if ReprSettings2.Tabs then
		INDENT = "\t"
	end

	local NewValue: Any = Value
	local Tabs: String = string.rep(INDENT, Depth)

	if Depth == 0 then
		Shown = {}
	end

	local TypeOf: String = typeof(Value)
	if TypeOf == "string" then
		return string.format("%q", NewValue)
	elseif TypeOf == "number" then
		if NewValue == math.huge then
			return "math.huge"
		end

		if NewValue == -math.huge then
			return "-math.huge"
		end

		return IntegerOrFloat(NewValue)
	elseif TypeOf == "boolean" then
		return tostring(NewValue)
	elseif TypeOf == "nil" then
		return "nil"
	elseif TypeOf == "table" then
		if Shown[NewValue] then
			return "{CYCLIC}"
		end

		Shown[NewValue] = true
		local IsArray: Boolean = true
		for Key in next, NewValue do
			if type(Key) ~= "number" then
				IsArray = false
				break
			end
		end

		local String: String = "{" .. (ReprSettings2.Pretty and "\n" .. INDENT .. Tabs or "")

		if IsArray then
			local Length: Number = #NewValue
			if Length == 0 then
				Shown[NewValue] = false
				return "{}"
			else
				String = "{"
				for Index, ArrayValue in ipairs(NewValue) do
					if Index ~= 1 then
						String ..= ", "
					end

					Depth += 1
					String ..= Repr(ArrayValue, ReprSettings2)
					Depth -= 1
				end

				Shown[NewValue] = false
				return String .. "}"
			end
		else
			local KeyOrder: Array<String> = {}
			local Length: Number = 0
			local KeyValueStrings: Dictionary<String> = {}
			for Key, DictionaryValue in next, NewValue do
				Depth += 1
				local KeyString: String = IsLuaIdentifier(Key) and Key or ("[" .. Repr(Key, ReprSettings2) .. "]")
				local ValueString: String = Repr(DictionaryValue, ReprSettings2)

				Length += 1
				KeyOrder[Length] = KeyString

				KeyValueStrings[KeyString] = ValueString
				Depth -= 1
			end

			if ReprSettings2.SortKeys then
				table.sort(KeyOrder)
			end

			local First: Boolean = true
			for _, KeyString in ipairs(KeyOrder) do
				if not First then
					String ..= (ReprSettings2.Semicolons and ";" or ",") .. (ReprSettings2.Pretty and ("\n" .. INDENT .. Tabs) or " ")
				end

				String ..= string.format("%s = %s", KeyString, KeyValueStrings[KeyString])
				First = false
			end
		end

		Shown[NewValue] = false
		if ReprSettings2.Pretty then
			String ..= "\n" .. Tabs
		end

		return String .. "}"
	elseif TypeOf == "table" and type(NewValue.__tostring) == "function" then
		return tostring(NewValue.__tostring(NewValue))
	elseif TypeOf == "table" and getmetatable(NewValue) and type(getmetatable(NewValue).__tostring) == "function" then
		return tostring(getmetatable(NewValue).__tostring(NewValue))
	elseif typeof then
		if TypeOf == "Instance" then
			return ((ReprSettings2.RobloxFullName and (ReprSettings2.RobloxProperFullName and ProperFullName(NewValue) or NewValue:GetFullName()) or NewValue.Name) .. (ReprSettings2.RobloxClassName and (string.format(" (%s)", NewValue.ClassName)) or ""))
		elseif TypeOf == "Axes" then
			local Array: Array<String> = {}
			local Length: Number = 0
			if NewValue.X then
				Length += 1
				Array[Length] = Repr(Enum.Axis.X, ReprSettings2)
			end

			if NewValue.Y then
				Length += 1
				Array[Length] = Repr(Enum.Axis.Y, ReprSettings2)
			end

			if NewValue.Z then
				Length += 1
				Array[Length] = Repr(Enum.Axis.Z, ReprSettings2)
			end

			return string.format("Axes.new(%s)", table.concat(Array, ", "))
		elseif TypeOf == "BrickColor" then
			return string.format("BrickColor.new(%q)", NewValue.Name)
		elseif TypeOf == "CFrame" then
			return string.format("CFrame.new(%s)", table.concat({NewValue:GetComponents()}, ", "))
		elseif TypeOf == "Color3" then
			return string.format("Color3.fromRGB(%d, %d, %d)", NewValue.R * 255, NewValue.G * 255, NewValue.B * 255)
		elseif TypeOf == "ColorSequence" then
			if #NewValue.Keypoints > 2 then
				return string.format("ColorSequence.new(%s)", Repr(NewValue.Keypoints, ReprSettings2))
			else
				if NewValue.Keypoints[1].Value == NewValue.Keypoints[2].Value then
					return string.format("ColorSequence.new(%s)", Repr(NewValue.Keypoints[1].Value, ReprSettings2))
				else
					return string.format(
						"ColorSequence.new(%s, %s)",
						Repr(NewValue.Keypoints[1].Value, ReprSettings2),
						Repr(NewValue.Keypoints[2].Value, ReprSettings2)
					)
				end
			end
		elseif TypeOf == "ColorSequenceKeypoint" then
			return string.format("ColorSequenceKeypoint.new(%s, %s)", IntegerOrFloat(NewValue.Time), Repr(NewValue.Value, ReprSettings2))
		elseif TypeOf == "DockWidgetPluginGuiInfo" then
			return string.format(
				"DockWidgetPluginGuiInfo.new(%s, %s, %s, %s, %s, %s, %s)",
				Repr(NewValue.InitialDockState, ReprSettings2),
				Repr(NewValue.InitialEnabled, ReprSettings2),
				Repr(NewValue.InitialEnabledShouldOverrideRestore, ReprSettings2),
				Repr(NewValue.FloatingXSize, ReprSettings2),
				Repr(NewValue.FloatingYSize, ReprSettings2),
				Repr(NewValue.MinWidth, ReprSettings2),
				Repr(NewValue.MinHeight, ReprSettings2)
			)
		elseif TypeOf == "Enums" then
			return "Enums"
		elseif TypeOf == "Enum" then
			return string.format("Enum.%s", tostring(NewValue))
		elseif TypeOf == "EnumItem" then
			return string.format("Enum.%s.%s", tostring(NewValue.EnumType), NewValue.Name)
		elseif TypeOf == "Faces" then
			local Array: Array<String> = {}
			local Length: Number = 0
			for _, EnumItem in ipairs(NormalIds) do
				if NewValue[EnumItem.Name] then
					Length += 1
					Array[Length] = Repr(EnumItem, ReprSettings2)
				end
			end

			return string.format("Faces.new(%s)", table.concat(Array, ", "))
		elseif TypeOf == "NumberRange" then
			if NewValue.Min == NewValue.Max then
				return string.format("NumberRange.new(%s)", IntegerOrFloat(NewValue.Min))
			else
				return string.format("NumberRange.new(%s, %s)", IntegerOrFloat(NewValue.Min), IntegerOrFloat(NewValue.Max))
			end
		elseif TypeOf == "NumberSequence" then
			if #NewValue.Keypoints > 2 then
				return string.format("NumberSequence.new(%s)", Repr(NewValue.Keypoints, ReprSettings2))
			else
				if NewValue.Keypoints[1].Value == NewValue.Keypoints[2].Value then
					return string.format("NumberSequence.new(%s)", IntegerOrFloat(NewValue.Keypoints[1].Value))
				else
					return string.format("NumberSequence.new(%s, %s)", IntegerOrFloat(NewValue.Keypoints[1].Value), IntegerOrFloat(NewValue.Keypoints[2].Value))
				end
			end
		elseif TypeOf == "NumberSequenceKeypoint" then
			if NewValue.Envelope ~= 0 then
				return string.format("NumberSequenceKeypoint.new(%s, %s, %s)", IntegerOrFloat(NewValue.Time), IntegerOrFloat(NewValue.Value), IntegerOrFloat(NewValue.Envelope))
			else
				return string.format("NumberSequenceKeypoint.new(%s, %s)", IntegerOrFloat(NewValue.Time), IntegerOrFloat(NewValue.Value))
			end
		elseif TypeOf == "PathWaypoint" then
			return string.format(
				"PathWaypoint.new(%s, %s)",
				Repr(NewValue.Position, ReprSettings2),
				Repr(NewValue.Action, ReprSettings2)
			)
		elseif TypeOf == "PhysicalProperties" then
			return string.format(
				"PhysicalProperties.new(%s, %s, %s, %s, %s)",
				IntegerOrFloat(NewValue.Density),
				IntegerOrFloat(NewValue.Friction),
				IntegerOrFloat(NewValue.Elasticity),
				IntegerOrFloat(NewValue.FrictionWeight),
				IntegerOrFloat(NewValue.ElasticityWeight)
			)
		elseif TypeOf == "Random" then
			return "<Random>"
		elseif TypeOf == "Ray" then
			return string.format(
				"Ray.new(%s, %s)",
				Repr(NewValue.Origin, ReprSettings2),
				Repr(NewValue.Direction, ReprSettings2)
			)
		elseif TypeOf == "RaycastParams" then
			return string.format(
				"RaycastParams.new({\n\tFilterDescendantsInstances = %s;\n\tFilterType = %s;\n\tIgnoreWater = %s;\n})",
				Repr(NewValue.FilterDescendantsInstances, ReprSettings2),
				Repr(NewValue.FilterType, ReprSettings2),
				Repr(NewValue.IgnoreWater, ReprSettings2)
			)
		elseif TypeOf == "RaycastResult" then
			return string.format(
				"RaycastResult({\n\tInstance = %s;\n\tPosition = %s;\n\tNormal = %s;\n\tMaterial = %s;\n})",
				Repr(NewValue.Instance, ReprSettings2),
				Repr(NewValue.Position, ReprSettings2),
				Repr(NewValue.Normal, ReprSettings2),
				Repr(NewValue.Material, ReprSettings2)
			)
		elseif TypeOf == "RBXScriptConnection" then
			return "<RBXScriptConnection>"
		elseif TypeOf == "RBXScriptSignal" then
			return "<RBXScriptSignal>"
		elseif TypeOf == "Rect" then
			return string.format("Rect.new(%s, %s, %s, %s)", IntegerOrFloat(NewValue.Min.X), IntegerOrFloat(NewValue.Min.Y), IntegerOrFloat(NewValue.Max.X), IntegerOrFloat(NewValue.Max.Y))
		elseif TypeOf == "Region3" then
			local Min: Vector3 = NewValue.CFrame.Position + NewValue.Size / -2
			local Max: Vector3 = NewValue.CFrame.Position + NewValue.Size / 2
			return string.format("Region3.new(%s, %s)", Repr(Min, ReprSettings2), Repr(Max, ReprSettings2))
		elseif TypeOf == "Region3int16" then
			return string.format(
				"Region3int16.new(%s, %s)",
				Repr(NewValue.Min, ReprSettings2),
				Repr(NewValue.Max, ReprSettings2)
			)
		elseif TypeOf == "TweenInfo" then
			return string.format(
				"TweenInfo.new(%s, %s, %s, %s, %s, %s)",
				IntegerOrFloat(NewValue.Time),
				Repr(NewValue.EasingStyle, ReprSettings2),
				Repr(NewValue.EasingDirection, ReprSettings2),
				IntegerOrFloat(NewValue.RepeatCount),
				Repr(NewValue.Reverses, ReprSettings2),
				IntegerOrFloat(NewValue.DelayTime)
			)
		elseif TypeOf == "UDim" then
			return string.format("UDim.new(%s, %s)", IntegerOrFloat(NewValue.Scale), IntegerOrFloat(NewValue.Offset))
		elseif TypeOf == "UDim2" then
			return string.format("UDim2.new(%s, %s, %s, %s)", IntegerOrFloat(NewValue.X.Scale), IntegerOrFloat(NewValue.X.Offset), IntegerOrFloat(NewValue.Y.Scale), IntegerOrFloat(NewValue.Y.Offset))
		elseif TypeOf == "Vector2" then
			return string.format("Vector2.new(%s, %s)", IntegerOrFloat(NewValue.X), IntegerOrFloat(NewValue.Y))
		elseif TypeOf == "Vector2int16" then
			return string.format("Vector2int16.new(%s, %s)", IntegerOrFloat(NewValue.X), IntegerOrFloat(NewValue.Y))
		elseif TypeOf == "Vector3" then
			return string.format("Vector3.new(%s, %s, %s)", IntegerOrFloat(NewValue.X), IntegerOrFloat(NewValue.Y), IntegerOrFloat(NewValue.Z))
		elseif TypeOf == "Vector3int16" then
			return string.format("Vector3int16.new(%s, %s, %s)", IntegerOrFloat(NewValue.X), IntegerOrFloat(NewValue.Y), IntegerOrFloat(NewValue.Z))
		else
			return "<Roblox:" .. TypeOf .. ">"
		end
	else
		return "<" .. TypeOf .. ">"
	end
end

return Repr