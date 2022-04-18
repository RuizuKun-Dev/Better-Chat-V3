-- Author: @Jumpathy
-- Name: quickChatDropdown.lua
-- Description: Quick chat individual option component function

local boxScale = {}
local textService = game:GetService("TextService")
local tweenService = game:GetService("TweenService")

function boxScale.new(box,callback)
	local scale = function()
		local text = (box.Text ~= "" and box.Text or box.PlaceholderText)
		local bounds = textService:GetTextSize(text,box.TextSize,box.Font,Vector2.new(box.AbsoluteSize.X-10,math.huge))
		box.Size = UDim2.new(1,0,0,bounds.Y + 10)
		callback(0)
	end
	box:GetPropertyChangedSignal("Text"):Connect(scale)
	scale()
end

local tween = function(object,properties,length)
	local info = TweenInfo.new(length,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
	tweenService:Create(object,info,properties):Play()
end

local quickChatDropdown = {}

local images = {
	[false] = "rbxassetid://8677555693",
	[true] = "rbxassetid://8677748645";
}

function quickChatDropdown.new(text,title,callback)
	local object = script:WaitForChild("Dropdown"):Clone()
	local container = object:WaitForChild("Container")
	local scroller = container:WaitForChild("Scroller")
	local box = scroller:WaitForChild("Box")
	local layout = scroller:WaitForChild("UIListLayout")
	local state = false
		
	scroller.Command.Text = ("Send in chat using '/%s'"):format(title)
	object.Title.Text = title
	box.Text = text

	local scale = function(length)
		local size = (state and UDim2.new(1,0,0,layout.AbsoluteContentSize.Y + 15) or UDim2.fromScale(1,0))
		tween(container,{
			Size = size
		},length)
		tween(object,{
			Size = UDim2.new(1,-10,0,30 + math.clamp(size.Y.Offset-5,0,math.huge))
		},length)
	end

	boxScale.new(box,scale)

	local button = object:WaitForChild("Title"):WaitForChild("Icon")
	button.MouseButton1Click:Connect(function()
		state = not state
		button.Image = images[state]
		scale(0.2)
	end)

	local options = {
		scroller:WaitForChild("Options"):WaitForChild("Save"),
		scroller:WaitForChild("Options"):WaitForChild("Delete")
	}

	local api = {
		setText = function(self,text)
			box.Text = text
		end,
		getText = function()
			return box.Text
		end,
		getBox = function()
			return box
		end,
		reparent = function(self,parent)
			object.Parent = parent
		end,
	}

	for _,option in pairs(options) do
		option.MouseButton1Click:Connect(function()
			callback(option.Name,api)
		end)
	end

	return api
end

return quickChatDropdown