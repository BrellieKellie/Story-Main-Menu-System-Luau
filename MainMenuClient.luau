-- Main Menu by @LunixHenry2040
-- August 2026

------------------------------ Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


------------------------------ Modules
local RSModuleScripts = ReplicatedStorage.ModuleScripts
local PlayerModuleScripts = RSModuleScripts.Players

local MainMenuModule = require(PlayerModuleScripts.MainMenu)


------------------------------ Player
local Player = Players.LocalPlayer


------------------------------ Gui
local Gui = script.Parent


------------------------------ Initialize
MainMenuModule.InitializeClient(Player, Gui)
