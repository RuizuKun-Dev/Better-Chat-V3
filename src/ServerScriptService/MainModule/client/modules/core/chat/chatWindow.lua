-- Author: @Jumpathy
-- Name: chatWindow.lua
-- Description: Set up the main chat window

local userInput = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local heartbeat = runService.Heartbeat
local currentCamera = workspace.CurrentCamera
local channelBar = require(script.Parent:WaitForChild("channelBar"))

local resizeInputs,endInputs = {
	[Enum.UserInputType.MouseMovement] = true,
	[Enum.UserInputType.Touch] = true
},{
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true
}

local touchEnabled = userInput.TouchEnabled

return function(environment)
	-- channel bar:

	local separate = environment.config.UI.SeparateChatbarFromMenu

	task.spawn(channelBar,environment)

	local chatWindow = {}
	local utility = environment.utility
	local api = {}
	local mainUi
	local currentState = true
	local currentlyFocused
	local zone
	local currentStateForMouse = nil

	-------- Fade: --------

	local fadeState = function(length,state)
		utility:tween({
			mainUi.window,length,{
				["BackgroundTransparency"] = state and 3/4 or 1
			}
		},{
			mainUi.bar,length,{
				["BackgroundTransparency"] = separate and (state and 3/4 or 1) or 1
			}
		},{
			mainUi.box.Parent,length,{
				["BackgroundTransparency"] = state and 0 or 1
			}
		},{
			mainUi.box,length,{
				["TextColor3"] = state and Color3.fromRGB(100,100,100) or Color3.fromRGB(255,255,255),
				["PlaceholderColor3"] = state and Color3.fromRGB(80,80,80) or Color3.fromRGB(200,200,200)
			}
		},{
			environment.resizeButton,length,{
				["BackgroundTransparency"] = state and 0 or 1
			}
		},{
			environment.resizeButton.Icon,length,{
				["ImageTransparency"] = state and 0 or 1
			}
		},{
			mainUi.channelBar.Main.Container,length,{
				["BackgroundTransparency"] = (state and 3/4 or 1)
			}
		},{
			mainUi.channelButton,length,{
				["BackgroundTransparency"] = (state and 0 or 1)
			}
		},{
			mainUi.scroller.Parent,length,{
				["ScrollBarThickness"] = (state and 5 or 0),
				["ScrollBarImageTransparency"] = (state and 0 or 1)
			}
		},{
			mainUi.autofillContainer,length,{
				["BackgroundTransparency"] = (state and 3/4 or 1)
			}
		})
		currentState = state
	end

	local fade = function(state)
		if(not state) then
			currentStateForMouse = nil
		end
		fadeState(0.16,state)
	end

	local getChatbarSize = function()
		return(mainUi.chatbarContainer.Main.AbsoluteSize.Y)
	end

	-------- Focus area for mouse: --------

	local last
	local offset
	local uiVariable;

	local corners = {
		["BottomRight"] = function(offsetBottom)
			mainUi.channelBar.Visible = true
			mainUi.resizeButton.Parent = mainUi.channelBar.Main
			return  UDim2.new(1,-8,1,offsetBottom),Vector2.new(1,1)
		end,
		["TopLeft"] = function()
			return UDim2.fromOffset(16,8),Vector2.new(0,0)
		end,
		["TopRight"] = function()
			return UDim2.new(1,-16,0,8),Vector2.new(1,0)
		end,
		["BottomLeft"] = function(offsetBottom)
			mainUi.channelBar.Visible = true
			mainUi.resizeButton.Parent = mainUi.channelBar.Main
			return UDim2.new(0,16,1,offsetBottom),Vector2.new(0,1)
		end,
	}

	local corner = environment.config.UI.CornerPosition or "TopLeft"
	local calculatePosition = corners[corner] or corners["TopLeft"]
	environment.cornerPosition = corners[corner] and corner or "TopLeft"

	local recalculateFocusZone = function()
		--[[
		local size = mainUi.autofillContainer.AbsoluteSize
		local vis = mainUi.chatWindow.Visible
		local offset = (5 + (mainUi.bar.Parent.AbsoluteSize.Y - (vis and 35 or -0)) + size.Y + (size.Y > 0 and 5 or 0))
		local base = UDim2.new(1,0,(vis and 1 or 0),offset)
		zone.Size = base
		]]

		local chatWindowSizeBase = (mainUi.chatbarContainer.Position.Y.Offset)
		local s2 = mainUi.chatbarContainer.Main.Autofill.Container.AbsoluteSize.Y
		local totaled = chatWindowSizeBase + getChatbarSize() + (s2) + (s2 > 0 and 5 or 0)
		local new = UDim2.new(1,0,0,totaled)

		if(zone.Size ~= new) then
			last = new
			zone.Size = new
			local position,anchorPoint = calculatePosition(-((totaled - zone.Parent.AbsoluteSize.Y)+5))
			zone.Parent.AnchorPoint = anchorPoint
			zone.Parent.Position = position
			offset = uiVariable.AbsolutePosition
		end		
	end

	local mouseEnterState = function(state)
		if((not currentlyFocused) and (not state)) then
			if(currentState) then
				fade(false)
			end
		elseif((not currentlyFocused) and (state) and (not currentState)) then
			fade(true)
		end
	end

	local focusState = function(state,doContinue)
		currentlyFocused = state
		if(doContinue) then
			if(state) then
				fade(true)
			elseif(currentState and (not state)) then
				fade(false)
			end
		end
	end

	function chatWindow:setup(ui,chatbar)
		uiVariable = ui
		local channelBar = ui:WaitForChild("Channelbar")
		mainUi = {
			chatWindow = ui:WaitForChild("ChatWindow"),
			window = ui:WaitForChild("ChatWindow"):WaitForChild("Main"),
			bar = chatbar.chatbox.Parent.Parent,
			box = chatbar.chatbox,
			scroller = ui:WaitForChild("ChatWindow"):WaitForChild("Main"):WaitForChild("Scroller"):WaitForChild("MessageContainer"),
			channelBar = channelBar,
			channelButton = chatbar.chatbox.Parent.Parent.Container.Channel,
			chatbarContainer = ui:WaitForChild("ChatBarContainer")
		}		
		mainUi.autofillContainer = mainUi.box.Parent.Parent.Parent:WaitForChild("Autofill")
		environment.mainUi = mainUi
		zone = mainUi.window.Parent.Parent:WaitForChild("Zone")
		local resizeButton = chatbar.chatbox.Parent.Parent:WaitForChild("Resize")
		environment.resizeButton = resizeButton
		mainUi.resizeButton = resizeButton
		mainUi.box.Changed:Connect(recalculateFocusZone)
		mainUi.autofillContainer.Changed:Connect(recalculateFocusZone)

		if(environment.cornerPosition:find("Bottom") and (not environment.config.UI.ChannelBarEnabled)) then
			resizeButton.Changed:Connect(function()
				mainUi.channelBar.Visible = resizeButton.Visible
			end)
		end

		-------- Mouse event custom: --------

		local mouseIn = false
		local positionBounds = {}
		local holdingResize = false

		local mouseEnter = function()
			mouseIn = true
			mouseEnterState(true)
		end

		local mouseLeave = function()
			mouseIn = false
			if(not holdingResize) then
				mouseEnterState(false)
			end
		end

		local checkBounds = function(input)
			if(not offset or (not zone)) then
				return
			end
			local position = input.Position
			local chatSize = ui.AbsoluteSize
			if(environment.mouseMoved) then
				for object,callback in pairs(environment.mouseMoved) do
					if(object:GetFullName() ~= object.Name) then
						task.spawn(environment.mouseMoved[object],position)
					else
						environment.mouseMoved[object] = nil
					end
				end
			end
			positionBounds = {
				x  = {
					offset.X,(offset.X + zone.AbsoluteSize.X)
				},y = {
					offset.Y,(offset.Y + zone.AbsoluteSize.Y)
				}
			}
			local inBounds = false
			if(position.X >= positionBounds.x[1] and position.X <= positionBounds.x[2]) then
				if(position.Y >= positionBounds.y[1] and position.Y <= positionBounds.y[2]) then
					inBounds = true
				end
			end
			if(currentStateForMouse ~= inBounds) then
				currentStateForMouse = inBounds
				local func = (inBounds and mouseEnter or mouseLeave)
				func()
			end
		end

		if(not touchEnabled) then
			userInput.InputChanged:Connect(function(input)
				if(input.UserInputType == Enum.UserInputType.MouseMovement) then
					checkBounds(input)
				end
			end)
		else
			userInput.InputBegan:Connect(function(input,gameProcessed)
				if(input.UserInputType == Enum.UserInputType.Touch) then
					local ended
					ended = input.Changed:Connect(function()
						if(input.UserInputState == Enum.UserInputState.End) then
							ended:Disconnect()
						end
						checkBounds(input)
					end)
					checkBounds(input)
				end
			end)
		end

		-------- Resize button: --------

		local resizeConnection
		local baseSize = ui.AbsoluteSize
		local minX,maxX = baseSize.X/2,baseSize.X * 1.75
		local minY,maxY = baseSize.Y/2,baseSize.Y * 1.75
		local scroller = mainUi.scroller.Parent

		resizeButton.MouseButton1Down:Connect(function()
			holdingResize = true
			resizeConnection = userInput.InputChanged:Connect(function(input)
				if(resizeInputs[input.UserInputType]) then
					scroller.Size = UDim2.fromOffset(scroller.AbsoluteSize.X,scroller.AbsoluteSize.Y)
					-- since each button is in a different corner they all need to be calculated differently :cry:
					if(corner == "TopLeft") then
						ui:TweenSize(UDim2.fromOffset(
							math.clamp(input.Position.X,minX,maxX),
							math.clamp(input.Position.Y + (separate and 0 or getChatbarSize()),minY,maxY)
							),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.015,true)
					elseif(corner == "BottomRight") then
						local viewportSize = workspace.CurrentCamera.ViewportSize
						local xAxis = (viewportSize.X - input.Position.X) + resizeButton.AbsoluteSize.X/2
						local yAxis = (viewportSize.Y - input.Position.Y) - resizeButton.AbsoluteSize.Y
						ui:TweenSize(UDim2.fromOffset(
							math.clamp(xAxis,minX,maxX),
							math.clamp(yAxis,minY,maxY)
							),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.015,true)
					elseif(corner == "TopRight") then
						local viewportSize = workspace.CurrentCamera.ViewportSize
						local xAxis = (viewportSize.X - input.Position.X)
						local yAxis = (input.Position.Y + resizeButton.AbsoluteSize.Y/2) 
						ui:TweenSize(UDim2.fromOffset(
							math.clamp(xAxis,minX,maxX),
							math.clamp(yAxis,minY,maxY)
							),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.015,true)
					elseif(corner == "BottomLeft") then
						local viewportSize = workspace.CurrentCamera.ViewportSize
						local yAxis = (viewportSize.Y - input.Position.Y) - resizeButton.AbsoluteSize.Y
						ui:TweenSize(UDim2.fromOffset(
							math.clamp(input.Position.X + 8,minX,maxX),
							math.clamp(yAxis,minY,maxY)
							),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.015,true)
					end
					heartbeat:Wait()
					environment.textChanged()
				end
			end)
		end)

		userInput.InputEnded:Connect(function(input)
			if(endInputs[input.UserInputType] and holdingResize) then
				holdingResize = false
				if(not currentStateForMouse) then
					mouseEnterState(false)
				end
				resizeConnection:Disconnect()
				scroller.Size = UDim2.new(1,-15,1,-10)
			end
		end)

		-------- Channel bar: --------

		local padding = 5

		local handleChannelbar = function()
			local size = environment:getChannelBarSize()

			if(channelBar.Visible) then
				channelBar.Size = UDim2.new(1,0,0,0)
				channelBar:TweenSize(UDim2.new(1,0,0,size),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.16,true)
				mainUi.window.Parent:TweenSizeAndPosition(
					UDim2.new(1,0,1,(-size - (size + padding))),
					UDim2.new(0,0,0,size + padding),
					Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.16,true
				)
			else
				mainUi.window.Parent:TweenSizeAndPosition(
					UDim2.new(1,0,1,(-size)),
					UDim2.new(0,0,0,0),
					Enum.EasingDirection.In,Enum.EasingStyle.Quad,0.16,true
				)
			end
		end

		mainUi.chatWindow.Changed:Connect(function()
			if(environment.chatWindowVisible) then
				if(separate) then
					mainUi.chatbarContainer.Position = UDim2.fromOffset(0,(mainUi.window.Parent.Position.Y.Offset + (mainUi.window.Parent.AbsoluteSize.Y) + 5))
				else
					mainUi.chatbarContainer.Position = UDim2.fromOffset(0,(mainUi.window.Parent.Position.Y.Offset + (mainUi.window.Parent.AbsoluteSize.Y)) - (mainUi.chatbarContainer.AbsoluteSize.Y))
				end
			end
		end)

		channelBar:GetPropertyChangedSignal("Visible"):Connect(handleChannelbar)
		handleChannelbar()

		-------- Focus detection: --------

		mainUi.box.Focused:Connect(function()
			focusState(true,true)
		end)
		mainUi.box.FocusLost:Connect(function()
			focusState(false,(not mouseIn))
		end)
		fade(false)
	end

	return chatWindow
end