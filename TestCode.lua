require("strung").install("match")
local ffi = require("ffi")
local lfs = require("lfs")

ffi.cdef[[
	int printf(const char * format, ...);
]]

local ffi_C = ffi.C

local Libraries = {}

local function GetLibraries(Path)
	for File in lfs.dir(Path) do
		if File ~= "." and File ~= ".." then
			local FilePath = Path .. "/" .. File
			local Attributes = lfs.attributes(FilePath)
			if type(Attributes) == "table" then
				if Attributes.mode == "directory" then
					GetLibraries(FilePath)
				else
					ffi_C.printf("\t%s\n", FilePath)
				end
			else
				ffi_C.printf("Skipping %s\n", FilePath)
			end
		end
	end
end

GetLibraries("src/ServerStorage/Repository")

return false