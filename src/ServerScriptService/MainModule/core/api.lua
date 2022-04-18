-- Author: @Jumpathy
-- Name: api.lua
-- Description: Better chat server API

return function(constructors)
	local api = {}
	
	api.channel = constructors.channel
	api.speaker = constructors.speaker
	api.network = constructors.network
	
	return api
end