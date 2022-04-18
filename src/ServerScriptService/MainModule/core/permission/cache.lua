-- Author: @Jumpathy
-- Name: cache.lua
-- Description: Caching system

local cache = {}

function cache.new(callback)
	local newCache = {internal = {}}

	function newCache.fetch(id,...)
		if(not newCache.internal[id]) then
			newCache.internal[id] = callback(id,...)
		end
		return newCache.internal[id]
	end

	return newCache
end

return cache