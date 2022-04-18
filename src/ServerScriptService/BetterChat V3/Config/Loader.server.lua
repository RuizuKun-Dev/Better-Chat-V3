-- Author: @Jumpathy
-- Name: loader.lua
-- Description: Better chat loader

local inDevelopment = false
local configuration = require(script.Parent)
local toRequire = inDevelopment and  game:GetService("ServerScriptService"):WaitForChild("MainModule") or 9375790695
local addons = script.Parent.Parent:WaitForChild("Addons")

require(toRequire)(configuration,addons)