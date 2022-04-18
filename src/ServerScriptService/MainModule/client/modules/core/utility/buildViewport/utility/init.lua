-- Author: @Jumpathy
-- Name: utility.lua
-- Description: Utility functions for building viewport headshots

local zlib = require(script:WaitForChild("zlib"))
local httpService = game:GetService("HttpService")
local utility = {}

function utility:createViewport(size)
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.fromOffset(size,size)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.BackgroundColor3 = Color3.fromRGB(80,80,80)
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local camera = Instance.new("Camera")
	camera.Parent = world
	camera.FieldOfView = 50
	viewport.CurrentCamera = camera
	return viewport,camera,world
end

function utility:create(class,properties)
	local created = Instance.new(class)
	for property,value in pairs(properties) do
		created[property] = value
	end
	return created
end

function utility:compress(text)
	return zlib.Zlib.Compress(text,{
		strategy = "dynamic",
		level = 9
	})
end

function utility:getDescriptionId(description)
	local toAlphabetize = {}
	for property,value in pairs(description) do
		table.insert(toAlphabetize,property)
	end
	table.sort(toAlphabetize)
	local id = {}
	for _,name in pairs(toAlphabetize) do
		table.insert(id,name..":"..tostring(description[name]))
	end
	return utility:compress(table.concat(id,","))
end

function utility:guid()
	return httpService:GenerateGUID():sub(2,37):gsub("-","")
end

return utility