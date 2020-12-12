local Unit = require(script.Parent.Unit)

return {
	serializers = {
		[Unit] = function(unit, fabric)

			return {
				type = "_unit";
				name = unit.name;
				ref = fabric.serializer:serialize(unit.ref);
			}
		end;
	};

	deserializers = {
		_unit = function(data, fabric, failMode)
			local ref = fabric.serializer:deserialize(data.ref)

			if failMode == fabric.serializer.FailMode.Error then
				assert(ref ~= nil, string.format(
					"Attempt to deserialize a %q unit on a ref that's not present in this realm.",
					tostring(data.name)
				))
			end

			local unit = fabric._collection:getUnitByRef(data.name, ref)

			if unit == nil and failMode == fabric.serializer.FailMode.Error then
				error(string.format(
					"Attempt to deserialize unit %q on %q, but it does not exist in this realm.",
					tostring(data.name),
					tostring(ref)
				))
			end

			return unit
		end
	};
}
