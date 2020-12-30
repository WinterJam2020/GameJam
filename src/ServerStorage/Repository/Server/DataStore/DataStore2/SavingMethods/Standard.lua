-- Standard saving of data stores
-- The key you provide to DataStore2 is the name of the store with GetDataStore
-- GetAsync/UpdateAsync are then called based on the user ID

local DataStoreServiceRetriever = require(script.Parent.Parent.DataStoreServiceRetriever)
local Promise = require(script.Parent.Parent.Promise)

local Standard = {ClassName = "Standard"}
Standard.__index = Standard

function Standard:Get()
	return Promise.Defer(function(Resolve)
		Resolve(self.dataStore:GetAsync(self.userId))
	end)
end

function Standard:Set(Value)
	return Promise.Defer(function(Resolve)
		self.dataStore:UpdateAsync(self.userId, function()
			return Value
		end)

		Resolve()
	end)
end

function Standard.new(dataStore2)
	return setmetatable({
		dataStore = DataStoreServiceRetriever.Get():GetDataStore(dataStore2.Name),
		userId = dataStore2.UserId,
	}, Standard)
end

return Standard
