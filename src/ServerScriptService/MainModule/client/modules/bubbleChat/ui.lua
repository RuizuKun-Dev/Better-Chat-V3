-- Author: @Jumpathy
-- Name: ui.lua
-- Description: Making ui work :sunglo:

return {
	init = function(c)
		local config = c.Config
		local textService = game:GetService("TextService")
		local tweenService = game:GetService("TweenService")
		local padding = config.Padding
		local tweenInfo = TweenInfo.new(0.3,config.EasingStyle,Enum.EasingDirection.Out,0,true,0.3)
		local label = Instance.new("TextLabel")
		label.RichText = true
		
		local getTextContent = function(text)
			label.Text = text
			return label.ContentText
		end
		
		local getBounds = function(text,font)
			return textService:GetTextSize(getTextContent(text),config.TextSize,(font or config.Font),Vector2.new(250,math.huge))
		end

		local pad = function(x,y)
			x += padding * 2
			y += padding * 2
			return x,y
		end

		local create = function(text,parent,font)
			local bounds = getBounds(text,font)
			local bubble,edge,label,caret = Instance.new("Frame"),Instance.new("UICorner"),Instance.new("TextLabel"),Instance.new("ImageLabel")

			bubble.Name = "bubble"
			bubble.AnchorPoint = Vector2.new(0.5,1)
			bubble.BackgroundColor3 = config.BubbleBackgroundColor
			bubble.Position = UDim2.new(0.5,0,0.9,0)
			bubble.Size = UDim2.fromOffset(pad(bounds.X,bounds.Y))

			edge.CornerRadius = UDim.new(0,5)
			edge.Name = "edge"
			edge.Parent = bubble

			label.Name = "Label"
			label.Parent = bubble
			label.AnchorPoint = Vector2.new(0.5,0.5)
			label.BackgroundColor3 = Color3.fromRGB(0,0,0)
			label.BackgroundTransparency = 1
			label.Position = UDim2.new(0.5,0,0.5,0)
			label.Size = UDim2.new(1,0,1,0)
			label.Font = (font or config.BubbleFont)
			label.Text = text
			label.TextColor3 = config.BubbleTextColor
			label.TextSize = config.TextSize
			label.TextWrapped = true
			label.RichText = true
			
			caret.Name = "caret"
			caret.Parent = bubble
			caret.AnchorPoint = Vector2.new(0.5,0)
			caret.BackgroundTransparency = 1
			caret.Position = UDim2.new(0.5,0,0.99,0)
			caret.Size = UDim2.new(0,5,0,5)
			caret.Image = "rbxasset://textures/ui/InGameChat/Caret.png"
			caret.ImageColor3 = config.BubbleBackgroundColor
			if(parent) then
				bubble.Parent = parent
			end
			
			return bubble
		end

		local newDot = function(x)
			local dot = Instance.new("Frame")
			local corner = Instance.new("UICorner")

			dot.Size = UDim2.fromOffset(x/4,x/4)
			dot.BackgroundColor3 = config.TypingIndicatorColor

			corner.Parent = dot
			corner.CornerRadius = UDim.new(1,0)

			return dot
		end

		local animateIndicator = function(dots)
			-- recursive tweening bc the inf loop has undesirable behavior for me (after like 5 minutes of tweening they all line up for some reason)
			task.spawn(function()
				local tweens = {}
				for key,dot in pairs(dots) do
					if(dot:GetFullName() ~= dot.Name) then
						task.wait(0.3)
						local newPos = dot.Position - UDim2.fromOffset(0,5)
						local new
						local loops = 0
						new = function()
							if(dot:GetFullName() ~= dot.Name) then
								local tween = tweenService:Create(dot,tweenInfo,{["Position"] = newPos,["BackgroundTransparency"] = 0.6})
								tween:Play()
								local completed
								completed = tween.Completed:Connect(function()
									completed:Disconnect()
									tween = nil
									new()
								end)
							else
								new = nil
							end
						end
						new()
					end
				end
			end)
		end

		local typingIndicator = function(parent)
			local bubble = create("......",nil,Enum.Font.GothamSemibold)
			local dots = {}

			local xSize = bubble.AbsoluteSize.X
			bubble.Size += UDim2.fromOffset(15,0)
			bubble.Label:Destroy()

			local container = Instance.new("Frame")
			container.Parent = bubble
			container.Size = UDim2.fromScale(1,0.5)
			container.Position = UDim2.fromScale(0.5,0.5)
			container.AnchorPoint = Vector2.new(0.5,0.5)
			container.BackgroundTransparency = 1

			local layout = Instance.new("UIListLayout")
			layout.Parent = container
			layout.Padding = UDim.new(0,5)
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			layout.VerticalAlignment = Enum.VerticalAlignment.Center
			layout.FillDirection = Enum.FillDirection.Horizontal

			for i = 1,3 do
				local dot = newDot(xSize)
				dot.Parent = container
				dot.Name = i
				dots[i] = dot
			end

			for _,dot in pairs(dots) do
				dot.AnchorPoint = Vector2.new(0,0.5)
				dot.Position = UDim2.new(0,dot.AbsolutePosition.X,0.5,0)
			end

			layout:Destroy()
			animateIndicator(dots)
			
			bubble.Parent = parent
			return bubble
		end

		local billboard = function(name)
			local billboard = Instance.new("BillboardGui")
			local container = Instance.new("Frame")

			billboard.Name = name
			billboard.Active = true
			billboard.MaxDistance = 40
			billboard.Size = UDim2.new(5, 0, 5, 0)
			billboard.StudsOffset = Vector3.new(0, 3.5, 2)

			container.Name = "Container"
			container.Parent = billboard
			container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			container.BackgroundTransparency = 1.000
			container.Size = UDim2.new(1, 0, 1, 0)
			return billboard
		end

		return {
			bubble = {
				new = create
			},
			typingIndicator = {
				new = typingIndicator
			},
			billboard = {
				new = billboard
			}
		}
	end,
}