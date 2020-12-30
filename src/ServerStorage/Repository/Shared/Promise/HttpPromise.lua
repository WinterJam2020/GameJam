local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Promise = Resources:LoadLibrary("Promise")
local Services = Resources:LoadLibrary("Services")
local Typer = Resources:LoadLibrary("Typer")

local HttpService: HttpService = Services.HttpService
local RunService: RunService = Services.RunService

local HttpPromise = {}

local IS_SERVER = RunService:IsServer()

local RequestDefinition = Typer.MapDefinition {
	Url = Typer.String;
	Method = Typer.OptionalString;
	Body = Typer.OptionalString;
	Headers = Typer.OptionalTable;
}

function HttpPromise.PromiseRequest(RequestDictionary)
	if not IS_SERVER then
		return Promise.Reject("Cannot run HttpPromise.PromiseRequest on the client!")
	end

	local TypeSuccess, TypeError = RequestDefinition(RequestDictionary)
	if not TypeSuccess then
		return Promise.Reject(TypeError)
	end

	return Promise.Defer(function(Resolve, Reject)
		local Success, Value = pcall(HttpService.RequestAsync, HttpService, RequestDictionary)
		if Success then
			if not Value.Success then
				Reject(string.format("HTTP %d: %s", Value.StatusCode, Value.StatusMessage))
			else
				Resolve(Value)
			end
		else
			Reject(Value)
		end
	end)
end

HttpPromise.PromiseGet = Typer.PromiseAssignSignature(Typer.String, Typer.OptionalBoolean, Typer.OptionalTable, function(Url, NoCache, Headers)
	if not IS_SERVER then
		return Promise.Reject("Cannot run HttpPromise.PromiseGet on the client!")
	end

	Headers = Headers or {}
	if NoCache then
		Headers["Cache-Control"] = "no-cache"
	end

	local RequestDictionary = {
		Url = Url;
		Method = "GET";
		Headers = Headers;
	}

	return HttpPromise.PromiseRequest(RequestDictionary):Then(function(Response)
		return Response.Body
	end)
end)

HttpPromise.PromisePost = Typer.PromiseAssignSignature(
	Typer.String,
	Typer.String,
	Typer.OptionalEnumOfTypeHttpContentType,
	Typer.OptionalBoolean,
	Typer.OptionalTable,
	function(Url, Data, HttpContentType, Compress, Headers)
		if not IS_SERVER then
			return Promise.Reject("Cannot run HttpPromise.PromisePost on the client!")
		end

		Headers = Headers or {}
		HttpContentType = HttpContentType or Enum.HttpContentType.ApplicationJson
		Compress = Compress == nil and false or Compress

		if Compress then
			return Promise.Defer(function(Resolve, Reject)
				local Success, Value = pcall(HttpService.PostAsync, HttpService, Url, Data, HttpContentType, Compress, Headers);
				(Success and Resolve or Reject)(Value)
			end)
		else
			if HttpContentType == Enum.HttpContentType.ApplicationJson then
				Headers["content-type"] = "application/json"
			elseif HttpContentType == Enum.HttpContentType.ApplicationUrlEncoded then
				Headers["content-type"] = "application/x-www-form-urlencoded"
			elseif HttpContentType == Enum.HttpContentType.ApplicationXml then
				Headers["content-type"] = "application/xml"
			elseif HttpContentType == Enum.HttpContentType.TextPlain then
				Headers["content-type"] = "text/plain"
			elseif HttpContentType == Enum.HttpContentType.TextXml then
				Headers["content-type"] = "text/xml"
			end

			local RequestDictionary = {
				Url = Url;
				Method = "POST";
				Headers = Headers;
				Body = Data;
			}

			return HttpPromise.PromiseRequest(RequestDictionary):Then(function(Response)
				return Response.Body
			end)
		end
	end
)

function HttpPromise.PromiseJson(Data)
	return Promise.new(function(Resolve, Reject)
		local Success, Value = pcall(HttpService.JSONEncode, HttpService, Data);
		(Success and Resolve or Reject)(Value)
	end)
end

HttpPromise.PromiseUrlEncode = Typer.PromiseAssignSignature(Typer.String, function(String)
	return Promise.Resolve(HttpService:UrlEncode(String))
end)

HttpPromise.PromiseDecode = Typer.PromiseAssignSignature(Typer.String, function(JsonString)
	return Promise.new(function(Resolve, Reject)
		local Success, Value = pcall(HttpService.JSONDecode, HttpService, JsonString);
		(Success and Resolve or Reject)(Value)
	end)
end)

return HttpPromise