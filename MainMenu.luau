-- Main Menu by @LunixHenry2040
-- August 2026


------------------------------ Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


------------------------------------------------------------
------------------------------ Modules
local MenuGui = require(script.Gui)
local MenuQueues = require(script.Queues)

local MainMenu = {}

-- Initialize the main menu. Client-sided.
function MainMenu.InitializeClient(Player : Player, Gui : ScreenGui)
	
	------------------------------ Setup
	local MenuFrames = MenuGui.SetupClient(Player, Gui)
	
end


-- Initialize the main menu. Server-sided.
function MainMenu.InitializeServer()
	------------------------------ Setup
	MenuGui.SetupServer()
	MenuQueues.QueueHandlerServer()
	
end



return MainMenu
