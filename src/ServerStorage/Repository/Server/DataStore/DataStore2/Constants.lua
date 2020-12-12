local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Symbol = Resources:LoadLibrary("Symbol")

return {
	SaveFailure = {
		BeforeSaveError = Symbol("BeforeSaveError");
		DataStoreFailure = Symbol("DataStoreFailure");
		InvalidData = Symbol("InvalidData");
	};
}
