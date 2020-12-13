local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local Debug = Resources:LoadLibrary("Debug")
local Janitor = Resources:LoadLibrary("Janitor")
local Signal = Resources:LoadLibrary("Signal")
local SortedArray = Resources:LoadLibrary("SortedArray")
local Table = Resources:LoadLibrary("Table")
local Typer = Resources:LoadLibrary("Typer")

Resources:LoadLibrary("Enumerations")

local Templates = Resources:GetLocalTable("Templates")

local Metatables = setmetatable({}, {__mode = "kv"})

local function Empty() end

local function Metatable__index(This, Index)
	local self = Metatables[This] or This -- self is the internal copy
	local Value = self.__RawData[Index]
	local ClassTemplate = self.__Class

	if Value == nil then
		Value = ClassTemplate.Methods[Index]
	else
		return Value
	end

	if Value == nil and not ClassTemplate.Properties[Index] then
		local GetConstructorAndDestructor = ClassTemplate.Events[Index]

		if GetConstructorAndDestructor then
			if self == This then -- if internal access
				local Event = Signal.new(GetConstructorAndDestructor(self))
				rawset(self, Index, Event)
				return Event
			else
				return self[Index].Event
			end
		elseif ClassTemplate.Internals[Index] == nil or self ~= This then
			Debug.Error("[%s] is not a valid Property of " .. tostring(self), Index)
		end
	else
		return Value
	end
end

local function Metatable__newindex(This, Index, Value)
	local self = Metatables[This] or This
	local Type = self.__Class.Properties[Index]

	if Type then
		Type(self, Value)
	elseif self == This and self.__Class.Internals[Index] ~= nil then
		rawset(self, Index, Value)
	else
		Debug.Error(Index .. " is not a modifiable property")
	end
end

local function Metatable__tostring(self)
	return (Metatables[self] or self).__Class.ClassName
end

local function Metatable__Rawset(self, Property, Value)
	self.__RawData[Property] = Value
	return self
end

local function ReturnHelper(Success, ...)
	if Success then
		return ...
	else
		Debug.Error(...)
	end
end

local ThreadDepthTracker = setmetatable({}, {__mode = "k"})

local function Metatable__Super(self, MethodName, ...)
	local Thread = coroutine.running()
	local InSuperclass = ThreadDepthTracker[Thread]
	local PreviousClass = InSuperclass or self.__Class
	local Class = PreviousClass

	while Class.HasSuperclass do
		Class = Class.Superclass
		local Function = Class.Methods[MethodName]

		if Function and Function ~= PreviousClass.Methods[MethodName] then
			if InSuperclass then
				ThreadDepthTracker[Thread] = Class
				return Function(self, ...)
			else
				local NewThread = coroutine.create(Function)
				ThreadDepthTracker[NewThread] = Class

				return ReturnHelper(coroutine.resume(NewThread, self, ...))
			end
		end
	end

	return Debug.Error("Could not find parent method " .. MethodName .. " of " .. PreviousClass.ClassName)
end

local PseudoInstance = {}

local function DefaultInit(self, ...)
	self:SuperInit(...)
end

local DataTableNames = SortedArray.new {"Events", "Methods", "Properties", "Internals"}

local function Filter(This, self, ...)
	-- Filter out `this` and convert to `self`
	-- Try not to construct a table if possible (we keep it light up in here)

	local ArgumentCount = select("#", ...)

	if ArgumentCount > 2 then
		local Arguments

		for Index = 1, ArgumentCount do
			if select(Index, ...) == This then
				Arguments = {...} -- Create a table if absolutely necessary
				Arguments[Index] = self

				for Jndex = Index + 1, ArgumentCount do -- Just loop through the rest normally if a table was already created
					if Arguments[Jndex] == This then
						Arguments[Jndex] = self
					end
				end

				return table.unpack(Arguments)
			end
		end

		return ...
	else
		if This == ... then -- Optimize for most cases where they only returned a single parameter
			return self
		else
			return ...
		end
	end
end

local function SuperInit(self, ...)
	local CurrentClass = self.CurrentClass

	if CurrentClass.HasSuperclass then
		self.CurrentClass = CurrentClass.Superclass
	else
		self.CurrentClass = nil
		self.SuperInit = nil
	end

	CurrentClass.Init(self, ...)
end

function PseudoInstance.Register(_, ClassName, ClassData, Superclass)
	if type(ClassData) ~= "table" then
		Debug.Error("Register takes parameters (string ClassName, table ClassData, Superclass)")
	end

	for _, DataTableName in ipairs(DataTableNames) do
		if not ClassData[DataTableName] then
			ClassData[DataTableName] = {}
		end
	end

	for Property, Function in next, ClassData.Properties do
		if type(Function) == "table" then
			ClassData.Properties[Property] = Typer.AssignSignature(2, Function, function(self, Value)
				self:Rawset(Property, Value)
			end)
		end
	end

	local Internals = ClassData.Internals

	for Index, Value in ipairs(Internals) do
		Internals[Value] = false
		Internals[Index] = nil
	end

	local Events = ClassData.Events

	for Index, Value in ipairs(Events) do
		Events[Value] = Empty
		Events[Index] = nil
	end

	ClassData.Abstract = false

	for MethodName, Method in next, ClassData.Methods do -- Wrap to give internal access to private metatable members
		if Method == 0 then
			ClassData.Abstract = true
		else
			ClassData.Methods[MethodName] = function(self, ...)
				local This = Metatables[self]

				if This then -- External method call
					return Filter(This, self, Method(This, ...))
				else -- Internal method call
					return Method(self, ...)
				end
			end
		end
	end

	ClassData.Init = ClassData.Init or DefaultInit
	ClassData.ClassName = ClassName

	-- Make properties of internal objects externally accessible
	if ClassData.WrappedProperties then
		for ObjectName, Properties in next, ClassData.WrappedProperties do
			for _, Property in ipairs(Properties) do
				if ClassData.Properties[Property] then
					Debug.Error("Identifier \"" .. Property .. "\" was used in both Properties and WrappedProperties")
				else
					ClassData.Properties[Property] = function(This, Value)
						local Object = This[ObjectName]
						if Object then
							Object[Property] = Value
						end

						This:Rawset(Property, Value)
					end
				end
			end
		end

		local PreviousInit = ClassData.Init

		function ClassData.Init(self, ...)
			PreviousInit(self, ...)

			for ObjectName, Properties in next, ClassData.WrappedProperties do
				for _, Property in ipairs(Properties) do
					local Object = self[ObjectName]

					if Object then
						if self[Property] == nil then
							self[Property] = Object[Property] -- This will implicitly error if they do something stupid
						end
					else
						Debug.Error(ObjectName .. " is not a valid member of " .. ClassName)
					end
				end
			end
		end
	end

	if Superclass == nil then
		Superclass = Templates.PseudoInstance
	end

	if Superclass then -- Copy inherited stuff into ClassData
		ClassData.HasSuperclass = true
		ClassData.Superclass = Superclass

		for _, DataTable in ipairs(DataTableNames) do
			local ClassTable = ClassData[DataTable]
			for Index, Value in next, Superclass[DataTable] do
				if not ClassTable[Index] then
					ClassTable[Index] = Value == 0 and Debug.Error(ClassName .. " failed to implement " .. Index .. " from its superclass " .. Superclass.ClassName) or Value
				end
			end
		end
	else
		ClassData.HasSuperclass = false
	end

	local Identifiers = {} -- Make sure all identifiers are unique

	for A, DataTableName in ipairs(DataTableNames) do -- Make sure there aren't any duplicate names
		for Index, Value in next, ClassData[DataTableName] do
			if type(Index) == "string" then
				if Identifiers[Index] then
					Debug.Error("Identifier \"" .. Index .. "\" was used in both " .. DataTableNames[Value] .. " and " .. DataTableName)
				else
					Identifiers[Index] = A
				end
			else
				Debug.Error("%q is not a valid Identifier, found inside " .. DataTableName, Index)
			end
		end
	end

	local LockedClass = Table.Lock(ClassData, nil, ClassName)
	Templates[ClassName] = LockedClass
	return LockedClass
end

local function AccessProperty(self, Property)
	local _ = self[Property]
end

PseudoInstance:Register("PseudoInstance", { -- Generates a rigidly defined userdata class with `.new()` instantiator
	Internals = {
		"Children", "PropertyChangedSignals", "Janitor";

		rawset = function(self, Property, Value)
			self.__RawData[Property] = Value
			local PropertyChangedSignal = self.PropertyChangedSignals and self.PropertyChangedSignals[Property]

			if PropertyChangedSignal and PropertyChangedSignal.Active then
				PropertyChangedSignal:Fire(Value)
			end

			return self
		end;

		SortByName = function(ChildA, ChildB)
			return ChildA.Name < ChildB.Name
		end;

		ParentalChange = function(self)
			local This = Metatables[self.Parent]

			if This then
				This.Children:Insert(self)
			end
		end;

		ChildNameMatchesObject = function(ChildName, OtherChild)
			return ChildName == OtherChild.Name
		end;

		ChildNamePrecedesObject = function(ChildName, OtherChild)
			return ChildName < OtherChild.Name
		end;

		SetEventActive = function(Event)
			Event.Active = true
		end;

		SetEventInactive = function(Event)
			Event.Active = false
		end;
	};

	Properties = { -- Only Indeces within this table are writable, and these are the default values
		Archivable = Typer.Boolean; -- Values written to these indeces must match the initial type (unless it is a function, see below)
		Parent = Typer.OptionalInstance;
		Name = Typer.String;
	};

	Events = {
		Changed = function(self)
			local Assigned = Janitor.new()

			return function(Event)
				for Property in next, self.__Class.Properties do
					Assigned:Add(self:GetPropertyChangedSignal(Property):Connect(function()
						Event:Fire(Property)
					end), "Disconnect")
				end
			end, Assigned
		end;
	};

	Methods = {
		Clone = function(self)
			if self.Archivable then
				local CurrentClass = self.__Class
				local New = Resources:LoadLibrary("PseudoInstance").new(CurrentClass.ClassName)

				repeat
					for Property in next, CurrentClass.Properties do
						if Property ~= "Parent" then
							local Old = self[Property]
							if Old ~= nil then
								if Typer.Instance(Old) then
									Old = Old:Clone()
								end

								New[Property] = Old
							end
						end
					end

					CurrentClass = CurrentClass.HasSuperclass and CurrentClass.Superclass
				until not CurrentClass

				return New
			else
				return nil
			end
		end;

		GetFullName = function(self)
			return (self.Parent and self.Parent:GetFullName() .. "." or "") .. self.Name
		end;

		IsDescendantOf = function(self, Grandparent)
			return self.Parent == Grandparent or (self.Parent and self.Parent:IsDescendantOf(Grandparent)) or false
		end;

		GetPropertyChangedSignal = function(self, String)
			if type(String) ~= "string" then
				Debug.Error("invalid argument 2: string expected, got %s", String)
			end

			local PropertyChangedSignal = self.PropertyChangedSignals[String]

			if not PropertyChangedSignal then
				if not pcall(AccessProperty, self, String) then
					Debug.Error("%s is not a valid Property of " .. tostring(self), String)
				end

				PropertyChangedSignal = Signal.new(self.SetEventActive, self.SetEventInactive)
				self.Janitor:Add(PropertyChangedSignal, "Destroy")
				self.PropertyChangedSignals[String] = PropertyChangedSignal
			end

			return PropertyChangedSignal.Event
		end;

		FindFirstChild = function(self, ChildName, Recursive)
			local Children = self.Children

			if Recursive then
				for _, Child in ipairs(Children) do
					if Child.Name == ChildName then
						return Child
					end

					local Grandchild = Child:FindFirstChild(ChildName, Recursive)
					if Grandchild then
						return Grandchild
					end
				end
			else -- Much faster than recursive
				return Children:Find(ChildName, self.ChildNameMatchesObject, self.ChildNamePrecedesObject)
			end
		end;

		GetChildren = function(self)
			return self.Children:Copy()
		end;

		IsA = function(self, ClassName)
			local CurrentClass = self.__Class

			repeat
				if ClassName == CurrentClass.ClassName then
					return true
				end

				CurrentClass = CurrentClass.HasSuperclass and CurrentClass.Superclass
			until not CurrentClass

			return ClassName == "<<</sc>>>" -- This is a reference to the old Roblox chat...
		end;

		Destroy = function(self)
			self.Archivable = false
			self.Parent = nil

			for GlobalSelf, InternalSelf in next, Metatables do
				if self == InternalSelf then
					self.Janitor[GlobalSelf] = nil
					Metatables[GlobalSelf] = nil
				end
			end

			self.Janitor:Cleanup()

			-- Nuke the object
			if self.__RawData then
				for Index in next, self.__RawData do
					rawset(self.__RawData, Index, nil)
				end
			end

			for Index, Value in next, self do
				if Signal.IsA(Value) then
					Value:Destroy()
				end

				rawset(self, Index, nil)
			end
		end;
	};

	Init = function(self)
		local Name = self.__Class.ClassName

		-- Default properties
		self.Name = Name
		self.Archivable = true

		-- Read-only
		self:Rawset("ClassName", Name)

		-- Internals
		self.Children = SortedArray.new(nil, self.SortByName)
		self.PropertyChangedSignals = {}

		self:GetPropertyChangedSignal("Parent"):Connect(self.ParentalChange, self)
	end;
}, false)

function PseudoInstance.new(ClassName: string, ...)
	local Class = Templates[ClassName]

	if not Class then
		Resources:LoadLibrary(ClassName)
		Class = Templates[ClassName] or Debug.Error("Invalid ClassName: " .. ClassName)
	end

	if Class.Abstract then
		error("Cannot instantiate an abstract " .. ClassName)
	end

	local self = newproxy(true)
	local Metatable = getmetatable(self)

	-- This one can be overwritten by an internal function if so desired :D
	Metatable.Rawset = Metatable__Rawset

	for Index, Value in next, Class.Internals do
		Metatable[Index] = Value
	end

	-- Internal members
	Metatable.__Class = Class
	Metatable.__index = Metatable__index
	Metatable.__RawData = {}
	Metatable.__newindex = Metatable__newindex
	Metatable.__tostring = Metatable__tostring
	Metatable.__metatable = "[PseudoInstance] Locked metatable"
	Metatable.__type = ClassName -- Calling `typeof` will error without having this value :/

	-- Internally accessible methods
	Metatable.Super = Metatable__Super

	-- These two are only around for instantiation and are cleared after a successful and full instantiation
	Metatable.SuperInit = SuperInit
	Metatable.CurrentClass = Class

	-- Internally accessible cleaner
	Metatable.Janitor = Janitor.new()

	Metatables[self] = setmetatable(Metatable, Metatable)

	Metatable.Janitor:Add(self, "Destroy")
	Metatable:Superinit(...)

	if rawget(Metatable, "CurrentClass") then
		local StoppedOnClass = Class

		while StoppedOnClass.HasSuperclass and StoppedOnClass.Superclass ~= Metatable.CurrentClass do
			StoppedOnClass = StoppedOnClass.Superclass
		end

		Debug.Error("Must call self:SuperInit(...) from " .. StoppedOnClass.ClassName .. ".Init")
	end

	return self
end

return Table.Lock(PseudoInstance, nil, script.Name)