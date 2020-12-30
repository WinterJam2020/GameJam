local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Services = Resources:LoadLibrary("Services")
local UserInputService: UserInputService = Services.UserInputService

local DeclarationAmbiguous = {
	Ctrl = "LeftControl";
	Cmd = "LeftControl";
	Command = "LeftControl";
	Control = "LeftControl";
	WinKey = "LeftSuper";
	Windows = "LeftSuper";
	Shift = "LeftShift";
	Alt = "LeftAlt";
	Enter = "Return";
	Dash = "Minus";
	Hyphen = "Minus";
	Stop = "Period";

	[0] = "Zero";	["0"] = "Zero";
	[1] = "One";	["1"] = "One";
	[2] = "Two";	["2"] = "Two";
	[3] = "Three";	["3"] = "Three";
	[4] = "Four";	["4"] = "Four";
	[5] = "Five";	["5"] = "Five";
	[6] = "Six";	["6"] = "Six";
	[7] = "Seven";	["7"] = "Seven";
	[8] = "Eight";	["8"] = "Eight";
	[9] = "Nine";	["9"] = "Nine";

	["["] = "LeftBracket";
	["]"] = "RightBracket";
	["\\"] = "BackSlash";
	["'"] = "Quote";
	[";"] = "Semicolon";
	[","] = "Comma";
	["."] = "Period";
	["/"] = "Slash";
	["-"] = "Minus";
	["="] = "Equals";
	["`"] = "Backquote";
}

local KeyUps = {}
local KeyDowns = {}
local Combinations = {}
local Unknown = Enum.KeyCode.Unknown

local function KeyDown(Data, GuiInput)
	if not GuiInput and Data.KeyCode ~= Unknown then
		local KeyValue = Data.KeyCode.Value
		local CombinationHash = Combinations[KeyValue]

		if CombinationHash then
			for Number, Function in next, CombinationHash do
				if UserInputService:IsKeyDown(Number) then
					return Function()
				end
			end
		end

		local Function = KeyDowns[KeyValue]
		if Function then
			return Function()
		end
	end
end

local function KeyUp(Data, GuiInput)
	if not GuiInput and Data.KeyCode ~= Unknown then
		local Function = KeyUps[Data.KeyCode.Value]
		if Function then
			return Function()
		end
	end
end

local Multicaller = {ClassName = "Multicaller"} -- Shhhh, we use this in two different ways. Just don't call your RbxScriptSignal xP
Multicaller.__index = Multicaller

function Multicaller:__call()
	self.BindableEvent:Fire()
	local Function = self[1]
	if Function then
		Function()
	end
end

function Multicaller:Disconnect()
	local Storage = self.KeyEvent.Storage
	local KeyValue = self.KeyEvent.KeyValue
	local Existing = Storage[KeyValue]

	if type(Existing) == "table" then
		Existing[1] = function()
		end
	else
		Storage[KeyValue] = nil
	end
end

local Key = {
	ClassName = "Key";
	__index = {};
}

local DualEvent = {
	ClassName = "DualEvent";
	__index = setmetatable({}, {__index = Key.__index});
}

function DualEvent.__index:IsDown()
	return UserInputService:IsKeyDown(self.KeyValue) and UserInputService:IsKeyDown(self.KeyValue2)
end

function Key.__add(a, b)
	assert(a and b and a.Storage == KeyDowns and b.Storage == KeyDowns, "You can only chain 2 KeyDown events")

	local Storage = Combinations[b.KeyValue]

	if not Storage then
		Storage = {}
		Combinations[b.KeyValue] = Storage
	end

	return setmetatable({
		KeyName = a.KeyName;
		KeyValue = a.KeyValue;
		KeyValue2 = b.KeyValue;
		Storage = Storage;
	}, DualEvent)
end

function Key.__index:IsDown()
	return UserInputService:IsKeyDown(self.KeyValue)
end

function Key.__index:Connect(Function)
	local Storage = self.Storage
	local KeyValue = self.KeyValue
	local Existing = Storage[KeyValue]

	if Existing then
		if type(Existing) == "table" then
			local Connection = Existing.BindableEvent.Event:Connect(Function)
			table.insert(Existing.Connections, Connection)
			return Connection
		else
			local BindableEvent = Instance.new("BindableEvent")
			local Connection = BindableEvent.Event:Connect(Function)
			Storage[KeyValue] = setmetatable({
				Existing;
				BindableEvent = BindableEvent;
				Connections = {Connection};
			}, Multicaller)
			return Connection
		end
	else
		Storage[KeyValue] = Function
		return setmetatable({KeyEvent = self}, Multicaller)
	end
end

function Key.__index:Disconnect()
	local Existing = self.Storage[self.KeyValue]
	if type(Existing) == "table" then
		for _, Connection in ipairs(Existing.Connections) do
			Connection:Disconnect()
		end

		table.clear(Existing.Connections)
		Existing.BindableEvent, Existing.Connections, Existing[1] = Existing.BindableEvent:Destroy(), nil, nil
	end
	self.Storage[self.KeyValue] = nil
end

function Key.__index:Press()
	self.Storage[self.KeyValue]()
end

Key.__index.Fire = Key.__index.Press

function Key.__index:Wait()
	local Existing = self.Storage[self.KeyValue]

	if type(Existing) == "table" then
		Existing.BindableEvent.Event:Wait()
	else
		local Caller = setmetatable({
			Existing;
			BindableEvent = Instance.new("BindableEvent");
			Connections = {};
		}, Multicaller)

		self.Storage[self.KeyValue] = Caller
		Caller.BindableEvent.Event:Wait()

		if #Caller.Connections == 0 then
			self.Storage[self.KeyValue] = Existing
			Caller.BindableEvent, Caller.Connections, Caller[1] = Caller.BindableEvent:Destroy(), nil, nil
		end
	end
end

local Connection1, Connection2

return setmetatable({
	Pause = function(self)
		Connection1:Disconnect()
		Connection2:Disconnect()
		return self
	end;

	Resume = function(self)
		Connection1 = UserInputService.InputBegan:Connect(KeyDown)
		Connection2 = UserInputService.InputEnded:Connect(KeyUp)
		return self
	end;
}, {
	__index = function(self, KeyName)
		local KeyCode = Enum.KeyCode[DeclarationAmbiguous[KeyName] or KeyName]

		local NewKey = {
			KeyUp = setmetatable({
				KeyName = KeyCode.Name;
				KeyValue = KeyCode.Value;
				Storage = KeyUps;
			}, Key);

			KeyDown = setmetatable({
				KeyName = KeyCode.Name;
				KeyValue = KeyCode.Value;
				Storage = KeyDowns;
			}, Key);
		}

		self[KeyCode.Name] = NewKey
		return NewKey
	end;
}):Resume()