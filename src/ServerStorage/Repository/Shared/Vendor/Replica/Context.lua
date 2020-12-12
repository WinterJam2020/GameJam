local Context = {}

function Context.new(Base, KeyPath, Config, Active, RegistryKey)
	return {
		Base = Base;
		KeyPath = KeyPath;
		Config = Config;
		Active = Active;
		RegistryKey = RegistryKey;
	}
end

return Context