-- Author: @Jumpathy
-- Name: prompt.lua
-- Description: Message context menu prompt

return function(environment,functions)
	local quickChatEnabled = environment.config.Messages.QuickChat
	local localPlayer = game:GetService("Players").LocalPlayer
	local options = {}
	local lastPrompt;
	
	return {open = function(self,object,data,collector,edit)
		for _,obj in pairs(environment.gui:GetChildren()) do
			if(obj.Name == "EditPrompt") then
				obj:Destroy()
			end
		end
		
		local prompt = script:WaitForChild("EditPrompt"):Clone()
		prompt.Parent = environment.gui
		prompt.Visible = true
		
		prompt.Edit.Visible = options[object]["canEdit"]
		prompt.Reply.Visible = options[object]["canReply"]
		prompt.QuickChat.Visible = (data.senderId == localPlayer.UserId) and quickChatEnabled

		for _,obj in pairs(prompt:GetChildren()) do
			if(obj:IsA("TextButton")) then
				obj.MouseButton1Down:Connect(function()
					if(obj.Name == "Reply") then
						functions:initReply(data)
					elseif(obj.Name == "Edit") then
						edit:CaptureFocus()
					else
						environment:openSaveChat(data.message)
					end
					lastPrompt:Destroy()
					lastPrompt = nil
				end)
			end
		end

		collector:add(object.Changed:Connect(function()
			if(lastPrompt == prompt) then
				prompt.Position = UDim2.fromOffset(
					object.AbsolutePosition.X,object.AbsolutePosition.Y + object.AbsoluteSize.Y
				)
			end
		end))

		lastPrompt = prompt
		object.ZIndex += 1
		object.ZIndex -= 1
	end,set = function(self,object,canEdit,canReply)
		options[object] = {
			canEdit = canEdit,
			canReply = canReply
		}
	end,removeData = function(self,object)
		options[object] = nil
	end}
end