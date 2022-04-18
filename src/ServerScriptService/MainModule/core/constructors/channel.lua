-- Author: @Jumpathy
-- Name: channel.lua
-- Description: Channel objects manager

local chatService = game:GetService("Chat")
local players = game:GetService("Players")

return function(network,config,signal)
	local channelModule = {}
	channelModule.internal = {}
	channelModule.internal.channels = {}

	local channelsList = channelModule.internal.channels
	local messagesLimit = config.Messages.ChannelMessageLimit
	local speaker
	local messages

	local shallowCopy = function(original)
		local copy = {}
		for key,value in pairs(original) do
			copy[key] = value
		end
		return copy
	end

	-- check out the sick networking I had a stroke trying to write :skull:

	local canCommunicate = function(senderId,userId)
		local canCommunicate = false
		if(senderId ~= nil) then
			local success,chat = pcall(function()
				return chatService:CanUsersChatAsync(senderId,userId)
			end)
			if(success) then
				canCommunicate = chat
			end
		end
		return canCommunicate
	end

	local getFilteredMessage = function(object,speaker)
		local messageOwner = object.sender
		local filterObject = object.filtered
		if(((not object.data.isPlayer) or canCommunicate(messageOwner.UserId,speaker.player.UserId))) then
			local messageContent = filterObject:GetChatForUserAsync(not object.data.isPlayer and "" or speaker.player.UserId)
			local copiedData = shallowCopy(object.data)
			copiedData.message = messageContent
			return copiedData
		end
	end

	local replicateMessage = function(channel,object)
		local messageOwner = object.sender
		for _,speaker in pairs(channel.speakers) do
			task.spawn(function()
				if(speaker.player ~= nil) then 
					if(((not object.data.isPlayer) or canCommunicate(messageOwner.UserId,speaker.player.UserId))) then
						local toSend = getFilteredMessage(object,speaker)
						if(toSend.replyingTo ~= nil) then
							toSend.replyingTo = getFilteredMessage(toSend.replyingTo,speaker)
							if(not toSend.replyingTo) then -- failed to communicate
								return
							end
						end
						network:fireClients("receiveMessage",{speaker.player},{messages = {toSend},is_singular = true})
					end
				end
			end)
		end
	end

	local replicateRawMessage = function(channel,object)
		for _,speaker in pairs(channel.speakers) do
			task.spawn(function()
				if(speaker.player ~= nil) then
					network:fireClients("receiveMessage",{speaker.player},{messages = {object},is_singular = true})
				end
			end)
		end
	end

	local replicateEditedMessage = function(channel,object)
		local messageOwner = object.sender
		for _,speaker in pairs(channel.speakers) do
			task.spawn(function()
				if(speaker.player ~= nil and (object.data.isPlayer)) then 
					if(canCommunicate(messageOwner.UserId,speaker.player.UserId)) then
						local toSend = getFilteredMessage(object,speaker)
						if(toSend.replyingTo ~= nil) then
							toSend.replyingTo = getFilteredMessage(toSend.replyingTo,speaker)
							if(not toSend.replyingTo) then -- failed to communicate
								return
							end
						end
						network:fireClients("editMessage",{speaker.player},toSend)
					end
				elseif(not object.data.isPlayer and (speaker.player ~= nil)) then
					local toSend = getFilteredMessage(object,speaker)
					if(toSend.replyingTo ~= nil) then
						toSend.replyingTo = getFilteredMessage(toSend.replyingTo,speaker)
						if(not toSend.replyingTo) then -- failed to communicate
							return
						end
					end
					network:fireClients("editMessage",{speaker.player},toSend)
				end
			end)
		end
	end

	local replicateUnfilteredMessage = function(channel,object)
		local messageOwner = object.sender
		for _,speaker in pairs(channel.speakers) do
			task.spawn(function()
				if(speaker.player ~= nil) then 
					if((not object.data.isPlayer) or canCommunicate(messageOwner.UserId,speaker.player.UserId)) then
						local toSend = shallowCopy(object.data)
						toSend.message = string.rep("_",toSend.length)
						if(toSend.replyingTo ~= nil) then
							toSend.replyingTo = getFilteredMessage(toSend.replyingTo,speaker)
							if(not toSend.replyingTo) then -- failed to communicate
								return
							end
						end
						network:fireClients("receiveMessageCreation",{speaker.player},{messages = {toSend},is_singular = true})
					end
				end
			end)
		end
	end

	local fetchChannelHistoryForSpeaker = function(channel,speaker)
		-- Flow: Loop through channel history -> ensure message sender is still in game -> 
		-- see if it's a reply and see if the original message owner is still in-game -> add to history
		local receive = {messages = {}}
		for _,object in pairs(channel.history) do
			if(speaker.player ~= nil) then 
				local canSeeMessage = false
				if(object.data.isPlayer) then
					if(object.senderId ~= nil) then
						if(players:GetPlayerByUserId(object.senderId)) then
							canSeeMessage = canCommunicate(object.senderId,speaker.player.UserId)
						end
					end
				else
					canSeeMessage = true
				end
				if(canSeeMessage) then
					local toSend = getFilteredMessage(object,speaker)
					local checkThreadReplies = function()
						if(toSend.replyingTo ~= nil) then
							if(not players:GetPlayerByUserId(toSend.replyingTo.sender and toSend.replyingTo.sender.UserId or 0)) then
								if(toSend.replyingTo.isPlayer) then
									return -- message doesnt exist
								end
							end
							toSend.replyingTo = getFilteredMessage(toSend.replyingTo,speaker)
							if(not toSend.replyingTo) then -- failed to communicate
								return
							end
						end
					end
					checkThreadReplies()
					table.insert(receive.messages,1,toSend)
				end
			else
				table.insert(receive.messages,1,object)
			end
		end
		return receive
	end

	function channelModule.new(name,autojoin)
		if(channelsList[name] ~= nil) then
			warn(("[Better Chat]: Channel '%s' already exists."):format(name))
			return false
		end
		local channel = {}
		channel.name = name
		channel.autoJoin = autojoin
		channel.speakers = {}
		channel.history = {}
		channel.messageProcessing = {}
		channel.messageCount = 0
		channel.events = {
			chatted = signal.new(),
			speakerAdded = signal.new(),
			speakerRemoved = signal.new()
		}

		function channel:Destroy()
			channelsList[name] = nil
			for _,speaker in pairs(channel.speakers) do
				speaker.channels[name] = nil
				speaker.events.channelUpdated:Fire()
			end
			for _,event in pairs(channel.events) do
				event:DisconnectAll()
			end
			for k,v in pairs(channel) do
				channel[k] = nil
			end
		end

		function channel:registerMessageProcess(name,callback)
			table.insert(channel.messageProcessing,{
				name = name,
				callback = callback
			})
		end

		function channel:unregisterMessageProcess(name)
			for key,processData in pairs(channel.messageProcessing) do
				if(processData.name == name) then
					table.remove(channel.messageProcessing,key)
					break
				end
			end
		end

		function channel:canSpeakerTalk(speaker)
			return(table.find(channel.speakers,speaker) ~= nil)
		end

		function channel:addSpeaker(speaker)
			if(not table.find(channel.speakers,speaker)) then
				table.insert(channel.speakers,speaker)
				speaker.channels[name] = channel
				speaker.events.channelUpdated:Fire()
				channel.events.speakerAdded:Fire(speaker)
			end
		end

		function channel:removeSpeaker(speaker)
			local key = table.find(channel.speakers,speaker)
			if(key) then
				table.remove(channel.speakers,key)
				speaker.channels[name] = nil
				speaker.events.channelUpdated:Fire()
				channel.events.speakerRemoved:Fire(speaker.name)
			end
		end

		local callbacks = {
			onFiltered = function(object)
				replicateMessage(channel,object)
			end,
			onCreated = function(object)
				replicateUnfilteredMessage(channel,object)
			end,
			processMessage = function(object,isFiltered)
				for _,process in pairs(channel.messageProcessing) do
					process.callback(object)
				end
			end,
		}

		function channel:sendMessage(speaker,message,replyTo)
			local object = messages.new(message,speaker,name,replyTo,callbacks)
			channel.messageCount += 1
			table.insert(channel.history,1,object)
			if(#channel.history > messagesLimit) then
				table.remove(channel.history,#channel.history)
			end
			channel.events.chatted:Fire(object)
			return object
		end

		function channel:editMessage(id,new)
			for _,message in pairs(channel.history) do
				if(message.data.id == id) then
					messages.edit(message,new)
					replicateEditedMessage(channel,message)
					break
				end
			end
		end

		function channel:getMessageById(id)
			for _,message in pairs(channel.history) do
				if(message.data.id == id) then
					return message
				end
			end
		end

		function channel:getHistoryForSpeaker(speaker)
			if(channel:canSpeakerTalk(speaker)) then
				return fetchChannelHistoryForSpeaker(channel,speaker)
			end
		end

		channelsList[name] = channel
		for _,speaker in pairs(speaker:getSpeakers()) do
			channelModule:findAutojoinForSpeaker(speaker)
		end
		return true,channel
	end

	function channelModule:getByName(name)
		return channelsList[name]
	end

	function channelModule:findAutojoinForSpeaker(speaker)
		for _,channel in pairs(channelsList) do
			if(channel.autoJoin) then
				channel:addSpeaker(speaker)
			end
		end
	end

	function channelModule:setup(speakerModule,messageModule)
		speaker = speakerModule
		messages = messageModule
	end

	return channelModule
end