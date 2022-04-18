-- Author: @Jumpathy
-- Name: speaker.lua
-- Description: Speaker objects manager

return function(network,fetch,signal)
	local speakerModule = {}
	speakerModule.internal = {}
	speakerModule.internal.speakers = {}
	speakerModule.speakerAdded = signal.new()
	speakerModule.speakerRemoved = signal.new()
	
	local speakersList = speakerModule.internal.speakers
	local channel

	function speakerModule.new(name,player)
		if(speakersList[name] ~= nil) then
			warn(("[Better Chat]: Speaker '%s' already exists."):format(name))
			return false
		end
		
		local speaker = {}
		speaker.name = name
		speaker.channels = {}
		speaker.isPlayer = (player ~= nil)
		speaker.id = (speaker.isPlayer and player.UserId or nil)
		speaker.player = player
		speaker.muted = false
		speaker.icon = ""
		speaker.events = {
			channelUpdated = signal.new(),
			muteUpdate = signal.new(),
			chatted = signal.new()
		}
		
		if(player) then
			speaker.events.channelUpdated:Connect(function()
				network:fireClients("receiveChannelUpdate",{player},fetch(speaker))
			end)
			speaker.events.muteUpdate:Connect(function()
				network:fireClients("receiveMuteUpdate",{player},speaker.muted)
			end)
		end
		
		function speaker:unmute()
			speaker.muted = false
			speaker.events.muteUpdate:Fire(false)
		end
		
		function speaker:mute()
			speaker.muted = true
			speaker.events.muteUpdate:Fire(true)
		end
		
		function speaker:updateMuteStatus(state)
			speaker.muted = state
			speaker.events.muteUpdate:Fire(state)
		end
		
		function speaker:addToChannel(channelName)
			channel:getByName(channelName):addSpeaker(speaker)
		end
		
		function speaker:removeFromChannel(channelName)
			channel:getByName(channelName):removeSpeaker(speaker)
		end
		
		function speaker:setIcon(icon)
			speaker.icon = icon
		end
		
		function speaker:say(channelName,message,existing)
			local toSendIn = channel:getByName(channelName)
			if(not toSendIn:canSpeakerTalk(speaker)) then
				warn(("%s cannot talk in channel '%s'"):format(speaker.name,channelName))
				return
			end
			local object = toSendIn:sendMessage(speaker,message,existing)
			speaker.events.chatted:Fire(message,object)
			return object
		end
		
		function speaker:Destroy()
			for _,channel in pairs(speaker.channels) do
				pcall(function()
					channel:removeSpeaker(speaker)
				end)
			end
			for _,event in pairs(speaker.events) do
				event:DisconnectAll()
			end
			speakersList[name] = nil
			speakerModule.speakerRemoved:Fire(name)
		end

		speakersList[name] = speaker
		channel:findAutojoinForSpeaker(speaker)
		speakerModule.speakerAdded:Fire(speaker)

		return true,speaker
	end
	
	function speakerModule:getByName(name)
		return speakersList[name]
	end

	function speakerModule:getById(id)
		for _,speaker in pairs(speakersList) do
			if(speaker.id == id) then
				return speaker
			end
		end
	end

	function speakerModule:getSpeakers()
		return speakersList
	end

	function speakerModule:setup(module)
		channel = module
	end

	return speakerModule
end