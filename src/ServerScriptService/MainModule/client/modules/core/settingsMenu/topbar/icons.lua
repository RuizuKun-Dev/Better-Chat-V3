-- Author: @Jumpathy
-- Credit: @ForeverHD (topbarPlus)
-- Name: icons.lua
-- Description: Topbar icons for the chat

local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local starterGui = game:GetService("StarterGui")

return function(environment)
	local topbarPlusReference = replicatedStorage:FindFirstChild("TopbarPlusReference")
	local iconModule = script.Parent:WaitForChild("topbarPlus")
	if(topbarPlusReference) then
		iconModule = topbarPlusReference.Value
	end

	local icon = require(iconModule)
	local controller = require(iconModule.IconController)
	local callback = environment.toggleSettingsMenu
	local settingIcon = icon.new():setImage(environment.config.SettingsMenu.TopbarButton.Icon)
	settingIcon.selected:Connect(callback)
	settingIcon.deselected:Connect(callback)
	if(environment.config.SettingsMenu.ApiEnabledAndUIDisabled == true) then
		settingIcon:setEnabled(false)
	end
	
	if(not environment.config.SettingsMenu.TopbarButton.Enabled) then
		settingIcon:setEnabled(false)
	end
	
	environment.settingIcon = settingIcon
	
	function environment:toggleSettingsTopbar()
		settingIcon:deselect()
	end
	
	function environment:openSettingsMenu()
		settingIcon:select()
	end
	
	local types = Enum.CoreGuiType:GetEnumItems()
	local cache = {}
	
	runService.Heartbeat:Connect(function()
		for _,class in pairs(types) do
			local current = starterGui:GetCoreGuiEnabled(class)
			if(cache[class] ~= current) then
				if(cache[class] ~= nil) then
					controller.updateTopbar()
				end
				cache[class] = current
			end
		end
	end)
end