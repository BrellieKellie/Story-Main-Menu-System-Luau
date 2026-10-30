------------------------------ Module
local MainMenuModuleScript = script.Parent


------------------------------ Instances
-- Menu Scenes
local CameraCFrames = MainMenuModuleScript.CameraCFrames


------------------------------ Data
local MenuDataModule = {}


------------- Story Data
--[[
	["StoryName"] = {
		Chapters = {
			{Name, Image, Description}
		}
	},
]]

MenuDataModule.StoryData = {
	["Area 51"] = {
		Chapters = {
			{Name = "Area 51", PlaceId = 81648437044012, Image = "rbxassetid://16988618776", Description = "A mysterious raid has happened at Area 51. Our commander is sending us on a mission to find out what actually happened…"},
		}
	},
	
	-- Another Story can be added here
}


------------- Settings
MenuDataModule.Settings = {
	
	-- Gui
	MenuFrameTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	
	
	-- Camera
	SceneFieldOfView = 40,
	CameraUpdateSpeed = 0.334,
	CameraUpdateSpeedTouchMultiplier = 0.1,
	CameraPullPercentageClamp = 0.2,
	BlurEffectSize = 15,
	
	
	-- Queue
	CoopMinimumPlayers = 2,
	CoopMaximumPlayers = 6,
	CoopStartTime = 30,
	CoopAddTime = 10
	
}


------------- Camera CFrame's
MenuDataModule.CameraCFrames = {}
for i, Attachment : Attachment in CameraCFrames:GetChildren() do
	MenuDataModule.CameraCFrames[i] = Attachment.WorldCFrame
end


return MenuDataModule
