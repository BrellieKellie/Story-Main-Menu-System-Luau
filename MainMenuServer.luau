-- Main Menu by @LunixHenry2040
-- August 2026

------------------------------ Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")


------------------------------ Modules
local RSModuleScripts = ReplicatedStorage.ModuleScripts
local PlayerModuleScripts = RSModuleScripts.Players

local MainMenuModule = require(PlayerModuleScripts.MainMenu)
local Queues = require(PlayerModuleScripts.MainMenu.Queues)


------------------------------ Initialize
MainMenuModule.InitializeServer()