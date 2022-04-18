--[[
                                                                                                                  
	                                                               ,,                                                 
	`7MM"""Yp,           mm     mm                     .g8"""bgd `7MM                 mm          `7MMF'   `7MF'      
	  MM    Yb           MM     MM                   .dP'     `M   MM                 MM            `MA     ,V        
	  MM    dP  .gP"Ya mmMMmm mmMMmm .gP"Ya `7Mb,od8 dM'       `   MMpMMMb.   ,6"Yb.mmMMmm           VM:   ,V pd""b.  
	  MM"""bg. ,M'   Yb  MM     MM  ,M'   Yb  MM' "' MM            MM    MM  8)   MM  MM              MM.  M'(O)  `8b 
	  MM    `Y 8M""""""  MM     MM  8M""""""  MM     MM.           MM    MM   ,pm9MM  MM              `MM A'      ,89 
	  MM    ,9 YM.    ,  MM     MM  YM.    ,  MM     `Mb.     ,'   MM    MM  8M   MM  MM               :MM     ""Yb. 
	.JMMmmmd9   `Mbmmd'  `Mbmo  `Mbmo`Mbmmd'.JMML.     `"bmmmd'  .JMML  JMML.`Moo9^Yo.`Mbmo             VF         88 
	                                                                                                         (O)  .M' 
	                                                                                                          bmmmd'  
	                                                                                                          
	Author: @Jumpathy
	Name: start.lua
	Description: Chat system init
	
	Note: I swear to god, nothing that I make that looks nice can have remotely nice-looking code
--]]

-- services:

local replicatedStorage = game:GetService("ReplicatedStorage")
local userInput = game:GetService("UserInputService")
local guiService = game:GetService("GuiService")
local runService = game:GetService("RunService")
local chatService = game:GetService("Chat")
local heartbeat = runService.Heartbeat

-- platform:

local scaleToOffset = function(size)
	local viewportSize = workspace.CurrentCamera.ViewportSize
	return(UDim2.fromOffset((viewportSize.X * size.X.Scale) + size.X.Offset,(viewportSize.Y * size.Y.Scale) + size.Y.Offset))
end

local platform = function()
	if(userInput.TouchEnabled) then
		return((workspace.CurrentCamera.ViewportSize.Y < 600) and "Phone" or "Tablet")
	else
		return(guiService:IsTenFootInterface() and "Console" or "Desktop")
	end
end

local currentPlatform = platform()
if(currentPlatform ~= "Console") then
	-- wait for server:

	local betterchat_shared = replicatedStorage:WaitForChild("betterchat_shared")
	local network = require(betterchat_shared:WaitForChild("network"))
	local addons = betterchat_shared:WaitForChild("addons"):WaitForChild("Client")
	local signal = require(betterchat_shared:WaitForChild("signal"))
	
	-- client:

	local container = script.Parent
	local modules = container:WaitForChild("modules")
	local core = modules:WaitForChild("core")

	local connections = require(core:WaitForChild("connections"))
	local privacy = require(modules:WaitForChild("privacy"))
	local bubbleChat = require(modules:WaitForChild("bubbleChat"))
	local settingsMenu = require(core:WaitForChild("settingsMenu"))
	
	local localPlayer = game:GetService("Players").LocalPlayer
	local playerGui = localPlayer.PlayerGui
	
	if(not privacy.chatDisabled) then

		-- change:
		
		local gui = script:WaitForChild("Chat"):Clone()
		gui.Parent = playerGui
		
		local container = gui:WaitForChild("Container")
		
		local chatbarContainer = container:WaitForChild("ChatBarContainer"):WaitForChild("Main")
		local chatbox = chatbarContainer:WaitForChild("Container"):WaitForChild("Box"):WaitForChild("Input")
		local environment = {
			utility = require(core:WaitForChild("utility")),
			localization = require(core:WaitForChild("localization"))(),
			richText = require(core:WaitForChild("formatting"):WaitForChild("richText")),
			connections = connections,
			network = network,
			config = network:invoke("requestConfig"),
			messages = {},
			main_ui = container,
			lastRefresh = tick(),
			gui = gui,
			container = container,
			addons = addons,
			signal = signal
		}

		-- channel bar:
		
		function environment:getTextSize()
			return chatbox.TextSize
		end
		
		local channelBarEnabled = environment.config.UI.ChannelBarEnabled
		if(channelBarEnabled) then
			container:WaitForChild("Channelbar").Visible = true
		end
		environment.channelBarUi = container.Channelbar:WaitForChild("Main"):WaitForChild("Container"):WaitForChild("Scroller")

		
		-- bubble:
		
		local label = Instance.new("TextLabel")
		label.RichText = true
		
		local getTextContent = function(text)
			label.Text = text
			return label.ContentText
		end
		environment.bubbleChatEnabled = false
		environment.bubbleChatConfig = environment.config.BubbleChat.Config
		
		if(environment.config.BubbleChat.Enabled) then
			bubbleChat.init(environment.config.BubbleChat,environment.network,environment)
			environment.bubbleChatEnabled = true
		elseif(chatService.BubbleChatEnabled) then
			network.onClientEvent("receiveMessage",function(data)
				if(data.is_singular) then
					local player = data.messages[1].player
					if(player and player.Character) then
						chatService:Chat(player.Character,getTextContent(environment.richText:markdown(data.messages[1]["message"])))
					end
				end
			end)
		end
		
		task.spawn(function()
			if(environment.config.SettingsMenu.Enabled) then
				-- settings menu:
				settingsMenu(environment)
			end
		end)
		
		-- util
		
		local message_senders
		
		task.spawn(function()
			local saveChat = gui:WaitForChild("SaveChat")
			local container = saveChat:WaitForChild("Container")
			local button = container:WaitForChild("Slot"):Clone()
			container.Slot:Destroy()

			local close = function()
				saveChat:TweenPosition(UDim2.fromScale(0.5,-1.5),Enum.EasingDirection.In,Enum.EasingStyle.Linear,0.25,true)
			end

			function environment:openSaveChat(message)
				saveChat.Position = UDim2.fromScale(0.5,-1.5)
				saveChat:TweenPosition(UDim2.fromScale(0.5,0.5),Enum.EasingDirection.In,Enum.EasingStyle.Linear,0.25,true)

				for _,child in pairs(container:GetChildren()) do
					if(child:IsA("TextButton")) then
						child:Destroy()
					end
				end

				for i = 1,20 do
					local option = button:Clone()
					option.Parent = container
					option.Text = ("Slot %s"):format(i)
					environment.utility:linkObjectSignals(option,{
						option.MouseButton1Click:Connect(function()
							task.spawn(function()
								environment:saveToSlot(i,message)
								message_senders.makeSm(("You can now say '/%s' to send that message again"):format(i))
							end)
							close()
						end)
					})
				end
			end

			saveChat:WaitForChild("Header"):WaitForChild("UI"):WaitForChild("Close").MouseButton1Click:Connect(close)
		end)
		
		-- prefixes internal:
		
		function environment:generateReplyCode(id)
			return("reply_"..id)
		end
		
		-- setup:
		
		local chatWindowVisible = environment.config.UI.ChatWindowVisible
		local chatSizes = environment.config.UI.ChatSizes
		local chatModules = require(core:WaitForChild("chat"))(environment)
		local chatbar = chatModules.chatbar:setup(chatbarContainer,chatbox)
		local chatWindow = chatModules.chatWindow:setup(container,chatbar)
		environment.chatWindowVisible = chatWindowVisible
		
		if(not chatWindowVisible) then
			container.ChatBarContainer.Position = UDim2.new(0,0,0,0)
			container.ChatBarContainer.AnchorPoint = Vector2.new(0,0)
			container.ChatWindow.Visible = false
		end

		-- scale:
		
		local baseSize = scaleToOffset(chatSizes[currentPlatform])
		local lastScale
		container.Size = baseSize

		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			local key = tick()
			lastScale = key
			runService.Heartbeat:Wait()
			if(lastScale == key) then
				local newSize = scaleToOffset(chatSizes[currentPlatform])
				local sizeDiff = baseSize - newSize
				container.Size = (newSize + sizeDiff)
				baseSize = newSize
			end
		end)
	
		environment.utility.descendantOfClassAdded(gui,"UICorner",function(corner)
			local roundness = environment.config.UI.Rounding
			if(corner.Name ~= "Ignore") then
				corner.CornerRadius = UDim.new(0,roundness)
			end
		end)
		
		function environment:refreshRounding()
			local roundness = environment.config.UI.Rounding
			for _,object in pairs(gui:GetDescendants()) do
				if(object:IsA("UICorner") and object.Name ~= "Ignore") then
					object.CornerRadius = UDim.new(0,roundness)
				end
			end
		end
		
		-- text scale
		
		local ogTextSizes = {}
		local lastTextSize = environment.config.UI.BaseTextSize
		local base = lastTextSize
		
		local scale = function(obj,original)
			pcall(function()
				local difference = (lastTextSize - base)
				obj.TextSize = original + difference
			end)
		end
		
		function environment:setTextSize(new)
			lastTextSize = new
			for object,original in pairs(ogTextSizes) do
				task.spawn(scale,object,original)
			end
		end
		
		for _,obj in pairs(gui:GetDescendants()) do
			local success,hasTextSize = pcall(function()
				return obj["TextSize"]
			end)
			if(success and hasTextSize) then
				if(not ogTextSizes[obj]) then
					ogTextSizes[obj] = obj.TextSize
				end
			end
		end
		
		gui.DescendantAdded:Connect(function(obj)
			local success,hasTextSize = pcall(function()
				return obj["TextSize"]
			end)
			if(success and hasTextSize) then
				if(not ogTextSizes[obj]) then
					ogTextSizes[obj] = obj.TextSize
				end
			end
			scale(obj,ogTextSizes[obj])
		end)

		-- message:

		local messages = core:WaitForChild("messages")
		local queue = {}

		message_senders = {
			reply = require(messages:WaitForChild("reply"))(environment),
			system = require(messages:WaitForChild("system"))(environment,queue),
			default = require(messages:WaitForChild("default"))(environment),
			makeSm = function(message)
				return message_senders.system(
					unpack(environment.localization:produceSystemMessage(message))
				)
			end,
		}

		environment.message_senders = message_senders

		-- received:

		local scroller = environment.mainUi.scroller
		local realScroller = scroller.Parent
		local messageLimit = environment.config.Messages.ChannelMessageLimit

		local clearScroller = function()
			for k,v in pairs(queue) do
				table.remove(queue,k)
			end
			for _,child in pairs(scroller:GetChildren()) do
				if(child:IsA("Frame")) then
					child:Destroy()
				end
			end
		end
		
		local count = 0
		local currentChannel

		local onMessage = function(message)
			count += 1
			connections:Fire("ChatWindow","MessagesChanged",count)
		end

		local handleDeletionOfOldMessages = function()
			if(#queue > messageLimit) then
				local idx = #queue
				local obj = queue[idx]
				obj:Destroy()
				table.remove(queue,idx)
			end
		end
		
		function environment:sendSystemMessage(text)
			local object = message_senders.system("",text)
			table.insert(queue,1,object)
		end
		
		local getObject = function(data)
			if(data.class == "regular") then
				return message_senders.default(data)
			elseif(data.class == "whisper") then
				-- deprecated (refer to 'regular')
			elseif(data.class == "reply") then
				return message_senders.reply(data,queue)
			end
		end
		
		local onCreated = function(object,data,extra)
			environment.messages[data.id] = {
				object = object,
				data = data,
				extra = extra
			}
		end
		
		local mutelist = {}
		local canMuteSelf = true
		environment.mutelist = mutelist
		
		local createNewMessage = function(data) -- this function initiates every message ever sent :eyes:
			if(mutelist[data.senderId]) then
				return
			end
			local existingMessageById = environment.messages[data.id]
			if(existingMessageById) then
				if(data.class == "reply") then
					existingMessageById.extra.replace(data,queue)
				else
					local api = environment:checkThread(data.id)
					if(api) then
						api:editBaseMessage(data)
					end
					local currentKey = table.find(queue,existingMessageById.object)
					if(currentKey) then
						local object = getObject(data)
						onCreated(object,data)
						queue[currentKey] = object
						existingMessageById.object:Destroy()
					end
				end
			else
				local object,extra = getObject(data)
				onCreated(object,data,extra)
				table.insert(queue,1,object)
				onMessage(object)
			end
			handleDeletionOfOldMessages()
		end
		
		local muteKeys = {
			[false] = "GameChat_ChatMain_SpeakerHasBeenUnMuted",
			[true] = "GameChat_ChatMain_SpeakerHasBeenMuted",
			["failed"] = "GameChat_DoMuteCommand_CannotMuteSelf"
		}
		
		local announceMute = function(player,state)
			message_senders.makeSm(environment.localization:localize(muteKeys[state]):format(player.Name))
		end
		
		function environment:mute(player)
			if(localPlayer == player and (not canMuteSelf)) then
				message_senders.makeSm(environment.localization:localize(muteKeys["failed"]))
				return
			end
			mutelist[player.UserId] = true
			announceMute(player,true)
		end
		
		function environment:unmute(player)
			if(localPlayer == player and (not canMuteSelf)) then
				return
			end
			mutelist[player.UserId] = false
			announceMute(player,false)
		end
		
		local includeBeginningMessageAndScroll = function(id)
			local sm = message_senders.system(unpack(environment.localization:getWelcomeMessage(id)))
			table.insert(queue,sm)
			onMessage(sm)
			environment:checkScrollerPos(true,0)
		end
		
		local refreshHistory = function(channel)
			currentChannel = channel
			local received = network:invoke("requestHistory",channel)
			environment.lastRefresh = tick()
			local current = environment.lastRefresh
			environment.messages = {}
			environment.threads = {}
			heartbeat:Wait()
			clearScroller()
			local last = 0
			local key = 0
			for _,data in pairs(received.messages) do
				key += 1
				if(data.id ~= nil) then
					last = data.id
				end
				task.spawn(function()
					if(not data.replyingTo) then
						data.massMessageLoad = true
						createNewMessage(data)
					else
						data.massMessageLoad = true
						repeat
							runService.Heartbeat:Wait()
						until(environment.messages[data.replyingTo.id])
						if(environment.lastRefresh == current) then
							createNewMessage(data)
						end
					end
				end)
				-- chunking (makes loading much faster, as well as optimizations to only load the message function after the mouse hovers on it)
				if(key == 10) then
					task.wait()
					key = 0
				end
			end
			includeBeginningMessageAndScroll((last or 9999)+1)
		end
		
		local onMessageReceived = function(received) --> this message will handle every single message ever displayed in the chat, kinda crazy tbh
			for _,data in pairs(received.messages) do
				task.spawn(function()
					if(channelBarEnabled) then
						if(currentChannel == data.channelFrom) then
							createNewMessage(data)
						elseif(data.filteredSuccessfully) then
							environment:addNotificationToChannel(data.channelFrom)
						end
					else
						createNewMessage(data)
					end
				end)
			end
		end

		network.onClientEvent("receiveMessage",onMessageReceived)
		network.onClientEvent("receiveMessageCreation",onMessageReceived)
		network.onClientEvent("editMessage",createNewMessage)
		
		function environment:atBottom()
			return(realScroller.CanvasPosition.Y == realScroller.AbsoluteCanvasSize.Y - realScroller.AbsoluteSize.Y)
		end
		
		function environment:checkScrollerPos(bypass,len)
			if(realScroller.CanvasPosition.Y == realScroller.AbsoluteCanvasSize.Y - realScroller.AbsoluteSize.Y or bypass) then
				task.spawn(function()
					heartbeat:Wait()
					environment.utility:tween({realScroller,(len or 0.25),{
						["CanvasPosition"] = Vector2.new(0,realScroller.AbsoluteCanvasSize.Y)
					}})
				end)
			end
		end

		function environment:addMessageToQueue(message)
			onMessage(message)
			table.insert(queue,1,message)
			handleDeletionOfOldMessages()
		end

		refreshHistory("Main")
		function environment:fetchChannelHistory(channelName)
			environment.currentChannel = channelName
			refreshHistory(channelName)
		end
		
		-- core ui:

		local chatOpenState = true
		local locked = false
		
		local toggleChatState = function()
			if(locked) then
				return
			end
			connections:Fire("ChatWindow","VisibilityStateChanged",(not chatOpenState))
			chatOpenState = not chatOpenState
			container.Visible = chatOpenState
		end
		
		function environment:setChatLocked(state)
			locked = state
		end
		
		connections:Connect("ChatWindow","ToggleVisibility",toggleChatState)
		for i = 1,2 do
			toggleChatState()
		end
		
		connections:Connect("ChatWindow","CoreGuiEnabled",function(state)
			container.Visible = state
		end)
				
		-- notifiers
		
		local players = game:GetService("Players")
		local starterGui = game:GetService("StarterGui")
		local notifiers = environment.config.Notifiers
		
		if(notifiers.FriendJoinNotifier) then
			players.PlayerAdded:Connect(function(plr)
				if(plr:IsFriendsWith(localPlayer.UserId)) then
					message_senders.makeSm(environment.localization:localize("GameChat_FriendChatNotifier_JoinMessage"):format(plr.Name))
				end
			end)
		end
		
		if(notifiers.TeamChangeNotifier) then
			local changed = function(name)
				message_senders.makeSm(environment.localization:localize("GameChat_TeamChat_NowInTeam"):format(name))
			end
			localPlayer:GetPropertyChangedSignal("Team"):Connect(function()
				local teamName = localPlayer.Team and localPlayer.Team.Name or "Neutral"
				changed(teamName)
			end)
		end
		
		if(notifiers.BlockedUserNotifier) then
			local blockKeys = {
				["blocked"] = "GameChat_ChatMain_SpeakerHasBeenBlocked",
				["unblocked"] = "GameChat_ChatMain_SpeakerHasBeenUnBlocked"
			}
			
			local blockEvents = {
				["blocked"] = starterGui:GetCore("PlayerBlockedEvent"),
				["unblocked"] = starterGui:GetCore("PlayerUnblockedEvent")
			}
			
			for keyToTrigger,event in pairs(blockEvents) do
				event.Event:Connect(function(player)
					message_senders.makeSm(environment.localization:localize(blockKeys[keyToTrigger]):format(player.Name))
				end)
			end
		end
		
		-- custom commands
		
		environment.utility.childAdded(addons:WaitForChild("Commands"),function(command)
			command.Parent = core:WaitForChild("commands"):WaitForChild("list")
		end)
		
		-- plugins
		
		local api = require(core:WaitForChild("api"))(environment)
		environment.utility.childAdded(addons:FindFirstChild("Plugins") or Instance.new("Folder"),function(module)
			require(module)(api)
		end)
	end
end