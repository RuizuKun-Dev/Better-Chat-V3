-- Author: @Jumpathy
-- Name: channelBar.lua
-- Description: Set up the main channel bar

local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

return function(environment)
	local channelBar = {}
	local defaultChannel = "Main"
	local teamPrefix = environment.localization:getMessagePrefix("Team")
	local whisperPrefix = environment.localization:getMessagePrefix("To")
	local ui = environment.channelBarUi

	local getById = function(id)
		for _,plr in pairs(players:GetPlayers()) do
			if(math.abs(plr.UserId) == id) then
				return plr
			end
		end
	end

	local parseChannelName = function(name)
		if(name:sub(1,5) == "team_") then
			return teamPrefix
		elseif(name:sub(1,8) == "whisper_") then
			local list = name:split("_")
			local ids = {tonumber(list[2]),tonumber(list[3])}
			local target,user =  nil,""
			for _,v in pairs(ids) do
				target = getById(v)
				if(target and (target ~= localPlayer) and (target ~= nil)) then
					user = target:GetAttribute("DisplayName")
					break
				end
			end
			return whisperPrefix .. " " .. user
		else
			return name
		end
	end

	function environment:getChannelName(name)
		return parseChannelName(name)
	end

	local connections = {}

	local clear = function()
		for _,child in pairs(ui:GetChildren()) do
			if(child:IsA("TextButton")) then
				child:Destroy()
			end
		end
		for _,connection in pairs(connections) do
			connection:Disconnect()
		end
		connections = {}
	end

	local getButton = function(text)
		local button = script:WaitForChild("Button"):Clone()
		button.Text = text
		return button
	end

	local currentlySelected
	local last
	local baseSize
	local cb

	local notificationCounts = {}
	local buttons = {}

	local handleNotifications = function(channel)
		local button = buttons[channel]
		if(button ~= nil) then
			if(notificationCounts[channel] ~= nil and (notificationCounts[channel] ~= 0)) then
				button.Notifs.Visible = true
				button.Notifs.Text = notificationCounts[channel]
			else
				button.Notifs.Visible = false
			end
		end
	end

	local clicked = function(channel)
		environment:clearChannelNotifications(channel)
		currentlySelected = channel
		environment:fetchChannelHistory(channel)
	end

	local update = function(channels,size)
		size = size or environment:getTextSize() - 1
		clear()
		local last = baseSize

		local found = false
		for _,channel in pairs(channels) do
			if(currentlySelected ~= nil and (channel == currentlySelected)) then
				found = true
			end

			local parsed = parseChannelName(channel)
			local button = getButton(parsed)
			button.Parent = ui
			button.UIPadding.PaddingLeft = UDim.new(0,math.ceil(size * (5/14)))
			button.UIPadding.PaddingRight = button.UIPadding.PaddingLeft
			button.Size = UDim2.fromOffset(0,(size * (25/14)))
			button.Visible = environment.config.UI.ChannelBarEnabled

			cb = cb or button.Parent.Parent.Parent.Parent
			baseSize = (button.Size.Y.Offset * 1.4)
			cb.Size = UDim2.new(1,0,0,baseSize)

			table.insert(connections,button.MouseButton1Click:Connect(function()
				clicked(channel)
			end))

			buttons[channel] = button
			handleNotifications(channel)
		end
		if(currentlySelected) then
			if(not found) then
				environment:fetchChannelHistory(channels[1])
			end
		end
		if(last ~= baseSize) then
			if(cb.Visible) then
				cb.Visible = false
				cb.Visible = true
			end
		end
	end

	function environment:getChannelBarSize()
		return baseSize
	end

	function environment:clearChannelNotifications(channelName)
		notificationCounts[channelName] = 0
		handleNotifications(channelName)
	end

	function environment:addNotificationToChannel(channelName)
		notificationCounts[channelName] = notificationCounts[channelName] or 0
		notificationCounts[channelName] += 1
		handleNotifications(channelName)
	end

	function environment:openChannelFromBar(channel)
		clicked(channel)
	end

	environment.network.onClientEvent("receiveChannelUpdate",function(channels)
		last = channels
		update(channels)
	end)

	environment.refreshChannelSizes = function(size)
		update(last,size)
	end

	return channelBar
end