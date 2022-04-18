-- Author: @Jumpathy
-- Name: profile.lua
-- Description: User profiles using ProfileService (used for group chat saves and stuff like that)
-- Credit: @loleris - ProfileService (https://devforum.roblox.com/t/save-your-player-data-with-profileservice-datastore-module/667805)

return function(config,cb)
	local constructors
	local profiles,pending,initialized = {raw = {}},{},false
	local profileService = require(script:WaitForChild("profileService"))
	local players = game:GetService("Players")

	local handleRelease = function(player)
		player:Kick("[Data could not be loaded]")
	end

	function profiles:get(player)
		if(initialized) then
			if(not profiles.raw[player]) then
				local event = Instance.new("BindableEvent")
				task.delay(0,function()
					local running = coroutine.running()
					pending[player] = pending[player] or {}
					table.insert(pending[player],running)
					coroutine.yield()
					event:Fire()
				end)
				event.Event:Wait()
				event:Destroy()
			end
			local current = profiles.raw[player]
			return (current and true or false),(current and current["Data"] or nil)
		else
			return true,{}
		end
	end

	function profiles.new(name)
		initialized = true
		local profileStore = profileService.GetProfileStore(name,{})
		local playerAdded = function(player)
			local profile = profileStore:LoadProfileAsync("pl-"..tostring(player.UserId))
			if(profile ~= nil) then
				profile:AddUserId(player.UserId)
				profile:Reconcile()
				profile:ListenToRelease(function()
					profiles.raw[player] = nil
					handleRelease(player)
				end)
				if(player:GetFullName() ~= player.Name) then
					profiles.raw[player] = profile
					constructors = constructors or cb()
					for _,group in pairs(profile.Data.groups or {}) do
						constructors.group.createChannelObject(group.name,group.id)
					end
				else
					profile:Release()
				end
			else
				handleRelease(player)
			end
			if(pending[player]) then
				for _,thread in pairs(pending[player]) do
					coroutine.resume(thread)
				end
				pending[player] = nil
			end
		end

		local disconnectProfile = function(player)
			if(profiles.raw[player] ~= nil) then
				profiles.raw[player]:Release()
			end
		end

		players.PlayerRemoving:Connect(disconnectProfile)
		players.PlayerAdded:Connect(playerAdded)
		for _,player in pairs(players:GetPlayers()) do
			task.spawn(playerAdded,player)
		end
	end

	return profiles
end