-- Author: @Jumpathy
-- Name: autofill.lua
-- Description: Autofilling scripting-end system

local userInput = game:GetService("UserInputService")

return function(environment,chatbox)
	environment.utility.childAdded(environment.addons:WaitForChild("Autofills"),function(child)
		child.Parent = script.Parent:WaitForChild("autofills")
	end)
	
	local mainUi = environment.mainUi
	local autofillContainer,scroller,chatboxAutofill,selected = nil,nil,nil,nil
	local buttons,fills,options,pointers,held,heldGeneral = {},{},{},{},{},{}
	local pointer = 0
	
	local inBounds = function(gui1,gui2) 
		local gui1_topLeft = gui1.AbsolutePosition
		local gui1_bottomRight = gui1_topLeft + gui1.AbsoluteSize
		local gui2_topLeft = gui2.AbsolutePosition
		local gui2_bottomRight = gui2_topLeft + gui2.AbsoluteSize
		return ((gui1_topLeft.x < gui2_bottomRight.x and gui1_bottomRight.x > gui2_topLeft.x) and (gui1_topLeft.y < gui2_bottomRight.y and gui1_bottomRight.y > gui2_topLeft.y))
	end
	
	local returnTrue = function()
		return true
	end

	local new_button = function(text,order)
		local template = script:WaitForChild("Object"):Clone()
		template.LayoutOrder = order
		template.Label.Text = text
		return template
	end

	local clearAutofill = function()
		for _,obj in pairs(scroller:GetChildren()) do
			if(obj:IsA("TextButton")) then
				obj:Destroy()
			end
		end
	end
	
	local moveToCanvas = function(button)
		local s = button.AbsoluteSize.Y
		local currentPos = scroller.CanvasPosition.Y
		local base = (scroller.AbsoluteSize.Y + (scroller.AbsolutePosition.Y))
		environment.utility:tween({scroller,0.1,{
			CanvasPosition =  Vector2.new(0,((
				currentPos + (button.AbsolutePosition.Y - base)
			)+s))
		}})
	end

	local hovering = function(button)
		chatboxAutofill.Text = fills[button]
		selected = options[button]
		if(not inBounds(scroller,button)) then
			moveToCanvas(button)
		end
	end

	local handleMouseInput = function(button,inFrame)
		if(inFrame) then
			hovering(button)
			for _,btn in pairs(buttons) do
				environment.utility:tween({btn,0.01,{
					["BackgroundTransparency"] = ((inFrame and (btn == button)) and 0.5 or 1)
				}})
			end
		end
	end

	if(not mainUi) then
		local conn
		conn = game:GetService("RunService").Heartbeat:Connect(function()
			mainUi = environment.mainUi
			if(mainUi) then
				conn:Disconnect()
				autofillContainer = mainUi.autofillContainer
				scroller = autofillContainer.Container:WaitForChild("Scroller")
				chatboxAutofill = chatbox:WaitForChild("Bar")
			end
		end)
	end

	local picked = function(option)
		if(option.gsub) then
			chatbox.Text = chatbox.Text:gsub(unpack(option.gsub))
		end
		chatbox:CaptureFocus()
		chatbox.CursorPosition = 10000
	end

	local api,last = {},nil

	function api:fill(main)
		environment.autofillOpen = #main >= 1
		clearAutofill()
		buttons = {}
		fills = {}
		options = {}
		chatboxAutofill.Text = ""
		selected = nil
		pointer = 0
		pointers = {}
		last = tick()
				
		for key,option in pairs(main) do
			local button = new_button(option.text,key)
			button.Name = option.text
			button.Parent = scroller
			pointers[key] = button
			options[button] = option
			local changed,clicked = nil,nil
			changed = button.Changed:Connect(function()
				if(button:GetFullName() == button.Name) then
					clicked:Disconnect()
					changed:Disconnect()
				end
			end)
			clicked = button.MouseButton1Click:Connect(function()
				picked(option)
			end)
			table.insert(buttons,button)
			fills[button] = option.autofillBar
			local lastState
			environment.mouseMoved[button] = function(position)
				local inBounds = false
				if(position.X <= (button.AbsolutePosition.X + button.AbsoluteSize.X)) then
					if(position.X >= (button.AbsolutePosition.X)) then
						if(position.Y >= (button.AbsolutePosition.Y - button.AbsoluteSize.Y/2)) then
							if(position.Y <= (button.AbsolutePosition.Y + button.AbsoluteSize.Y/2)) then
								inBounds = true
							end
						end
					end
				end
				if(inBounds ~= lastState) then
					lastState = inBounds
					handleMouseInput(button,inBounds)
				end
			end
			if(key == 1) then
				lastState = true
				handleMouseInput(button,true)
			end
		end
		
		local contentSize = scroller.Layout.AbsoluteContentSize.Y
		local buttonLimit = 8
		local ySize = math.clamp(contentSize,0,(20 * buttonLimit) + (2 * buttonLimit))
		scroller.Size = UDim2.new(1,-10,0,ySize)
		scroller.CanvasSize = UDim2.new(1,0,0,contentSize)
		
		local baseSize = UDim2.new(1,0,0,ySize + (#main >= 1 and 8 or 0))
		scroller.Parent.Size = baseSize
		scroller.Parent.Parent.Size = baseSize
	end
	
	local lapse = function(input,callback,otherCondition)
		held[input] = true
		heldGeneral[input.KeyCode] = true
		otherCondition = otherCondition or returnTrue
		local began = tick()
		while(held[input] and otherCondition()) do
			local elapsed = tick() - began
			callback()
			task.wait(math.clamp((0.5 - (elapsed / 4)),0.1,math.huge))
		end
	end
	
	userInput.InputEnded:Connect(function(input)
		held[input] = nil
		heldGeneral[input.KeyCode] = nil
	end)
	
	userInput.InputBegan:Connect(function(input,gameProcessed)
		if(chatbox:IsFocused()) then
			local current = last
			if(input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.Tab) then
				if(selected ~= nil) then
					picked(selected)
				end
			elseif(input.KeyCode == Enum.KeyCode.Down and not heldGeneral[input.KeyCode]) then
				if(#pointers >= 1) then
					lapse(input,function()
						pointer = math.clamp(pointer + 1,1,#pointers)
						handleMouseInput(pointers[pointer],true)
					end,function()
						return(#pointers >= 1 and last == current)
					end)
				end
			elseif(input.KeyCode == Enum.KeyCode.Up and not heldGeneral[input.KeyCode]) then
				if(#pointers >= 1) then
					lapse(input,function()
						pointer = math.clamp(pointer - 1,1,#pointers)
						handleMouseInput(pointers[pointer],true)
					end,function()
						return(#pointers >= 1 and last == current)
					end)
				end
			end
		end
	end)

	return api
end