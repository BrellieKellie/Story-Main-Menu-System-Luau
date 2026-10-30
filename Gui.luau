------------------------------ Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")


------------------------------ Gui
local OriginalGui = StarterGui:WaitForChild("MainMenu")

local GuiData = {
	Home = {OpenPos = OriginalGui.Home.Position, ClosedPos = OriginalGui.Home.Position + UDim2.new(0, 0, 2, 0)},
	StoryQueues = {OpenPos = OriginalGui.StoryQueues.Position, ClosedPos = OriginalGui.StoryQueues.Position + UDim2.new(0, 0, 2, 0)},
	StorySelector = {OpenPos = OriginalGui.StorySelector.Position, ClosedPos = OriginalGui.StorySelector.Position + UDim2.new(0, 0, 2, 0)},
	QueueLobby = {OpenPos = OriginalGui.QueueLobby.Position, ClosedPos = OriginalGui.QueueLobby.Position + UDim2.new(0, 0, 2, 0)},
}

local OriginalGuiItems = script.Parent.GuiItems


------------------------------ Modules
-- ReplicatedStorage
local RSModuleScripts = ReplicatedStorage.ModuleScripts
local PlayersModuleScripts = RSModuleScripts.Players
local GuiModule = require(PlayersModuleScripts.GuiModule)

-- Internal
local MainMenuModuleScript = script.Parent
local Queues = require(MainMenuModuleScript.Queues)
local MenuData = require(MainMenuModuleScript.Data)

local StoryData = MenuData.StoryData
local Settings = MenuData.Settings
local CameraCFrames = MenuData.CameraCFrames


-- Bindables
local MenuBindables = MainMenuModuleScript.Bindables
local Bindables = {
	-- Server to Client
	UpdateQueueLobbyUi = MenuBindables.UpdateQueueLobbyUi,
	UpdateStoryQueuesUi = MenuBindables.UpdateStoryQueuesUi,
	
	-- Client to Server
	StartSolo = MenuBindables.StartSolo,
}



-- [Module] MenuGuiModule.
local MenuGuiModule = {}


------------------------------ Internal Declarations
local ActiveMenuPlayers = {}
local PlayerFuncConnections = {}



------------------------------ Camera Handling

function LockCamera(Player : Player, Camera : Camera, Gui : ScreenGui, Mouse : Mouse)

	-- Player / Camera
	local Mouse = Player:GetMouse()

	local IsPlayerLockedV : BoolValue = Player:WaitForChild("StatusValues").IsPlayerLocked
	local CameraBlur : BlurEffect = Camera:WaitForChild("Blur")

	-- Run changes
	Player.CameraMode = Enum.CameraMode.Classic
	Player.CameraMinZoomDistance = StarterPlayer:GetAttribute("CameraFirstPersonDistance")
	task.wait(0.1)
	Player.CameraMinZoomDistance = StarterPlayer.CameraMinZoomDistance
	
	IsPlayerLockedV:SetAttribute("IsCameraLocked", true)
	Gui:SetAttribute("CurrentCameraCFrame", CameraCFrames[1])
	Camera.CameraType = Enum.CameraType.Scriptable
	GuiModule.CreateTween(Camera, {FieldOfView = Settings.SceneFieldOfView}, Settings.MenuFrameTweenInfo)
	Camera.CFrame = Gui:GetAttribute("CurrentCameraCFrame")
	GuiModule.SetBlur(CameraBlur, Settings.BlurEffectSize, 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	PlayerFuncConnections[Player.Name].RunServiceRenderStepped = RunService.RenderStepped:Connect(function(DeltaTime)
		GuiModule.PullCameraOrientationToMouse(
			Mouse, 
			Camera, 
			Gui:GetAttribute("CurrentCameraCFrame"), 
			Settings.CameraPullPercentageClamp, 
			Settings.CameraUpdateSpeed * 
				if UserInputService.PreferredInput == Enum.PreferredInput.Touch then Settings.CameraUpdateSpeedTouchMultiplier 
				else 1, 
			DeltaTime
		)
	end)

end
function UnlockCamera(Player : Player, Camera : Camera, Gui : ScreenGui)
	-- Player / Camera
	local FieldOfViewV : NumberValue = Player:WaitForChild("settings").FieldOfView
	local IsPlayerLockedV : BoolValue = Player:WaitForChild("StatusValues").IsPlayerLocked
	local IsLockFirstPersonV : BoolValue =  Player:WaitForChild("StatusValues").IsLockFirstPerson
	local CameraBlur : BlurEffect = Camera:WaitForChild("Blur")

	-- Run changes
	IsPlayerLockedV:SetAttribute("IsCameraLocked", false)
	task.wait()
	
	if IsLockFirstPersonV.Value then
		Player.CameraMode = Enum.CameraMode.LockFirstPerson
	end

	Gui:SetAttribute("CurrentCameraCFrame", CFrame.new())
	Camera.CameraType = Enum.CameraType.Custom
	--Camera.FieldOfView = FieldOfViewV.Value -- Is already set in PlayerManager
	GuiModule.SetBlur(CameraBlur, 0, 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	if PlayerFuncConnections[Player.Name]["RunServiceRenderStepped"] then PlayerFuncConnections[Player.Name]["RunServiceRenderStepped"]:Disconnect() end

end


------------------------------ Menu Handling

-- Close all menus except for the ones in ExcludedMenus.
function CloseAllMenuFrames(MenuFrames, ExcludedMenus)
	for name, Frame : Frame in MenuFrames do
		if not ExcludedMenus or not table.find(ExcludedMenus, Frame) then
			GuiModule.CreateTween(Frame, {Position = GuiData[name].ClosedPos}, Settings.MenuFrameTweenInfo)
		end
	end
end


local OpenMenuFrameDB = false
-- Open the specified menu frame, and close all other frames.
function OpenMenuFrame(MenuFrame : Frame, MenuFrames)
	if not MenuFrames or not MenuFrames[MenuFrame.Name] or OpenMenuFrameDB then return end
	OpenMenuFrameDB = true
	CloseAllMenuFrames(MenuFrames, {MenuFrames[MenuFrame.Name]})
	local MenuTween : Tween = GuiModule.CreateTween(MenuFrames[MenuFrame.Name], {Position = GuiData[MenuFrame.Name].OpenPos}, Settings.MenuFrameTweenInfo)
	MenuTween.Completed:Wait()
	OpenMenuFrameDB = false
end


function AddPlayer(Player : Player)
	if not PlayerFuncConnections[Player.Name] then PlayerFuncConnections[Player.Name] = {} end
end
function RemovePlayer(Player : Player)
	PlayerFuncConnections[Player.Name] = nil
end


function EnterMainMenu(Player : Player, Gui : ScreenGui, MenuFrames)
	
	if table.find(ActiveMenuPlayers, Player) then return end
	table.insert(ActiveMenuPlayers, Player)
	
	-- Player
	local Camera = workspace.CurrentCamera 
	
	LockCamera(Player, Camera, Gui)
	
	-- Open the menus
	task.spawn(function() OpenMenuFrame(MenuFrames.Home, MenuFrames) end)
	for name, Frame : Frame in MenuFrames do 
		Frame.Visible = true
	end
	
end
function ExitMainMenu(Player : Player, Gui : ScreenGui, MenuFrames)
	
	table.remove(ActiveMenuPlayers, table.find(ActiveMenuPlayers, Player))
	
	-- Player
	local Camera = workspace.CurrentCamera 
	
	-- Close the menus.
	for name, Frame : Frame in MenuFrames do 
		Frame.Visible = false
	end
	
	-- Unlock the camera.
	task.spawn(function() UnlockCamera(Player, Camera, Gui) end)
	
end



------------------------------ Stories and Queues

function SetUpStoryQueuesList(Player : Player, MenuFrames)
	local StoryQueues : Frame = MenuFrames.StoryQueues.Queues
	
	local function UpdateStoryQueuesList(QueuesFileLists)
		--print("Updating story queues list for player", Player.Name)
		
		-- Clear the story queues list.
		for i, Object in StoryQueues:GetChildren() do 
			if Object:IsA("Frame") then
				Object:Destroy()
			end
		end
		
		-- Create a new set of frames for each queue.
		for QueueId : number, Queue in QueuesFileLists do
			if not Queue.IsSolo then

				-- Get the story chapter info from the destination place id.
				local ChapterFileList
				for _, Story in StoryData do
					for i, Chapter in Story.Chapters do
						if Chapter.PlaceId == Queue.DestinationPlaceId then
							ChapterFileList = Chapter
							break
						end
					end
				end

				-- Create a UI for this queue.
				local QueueFrame = OriginalGuiItems.Queue:Clone()
				QueueFrame.Parent = StoryQueues
				QueueFrame.StoryName.Text = ChapterFileList.Name
				QueueFrame.StoryImage.Image = ChapterFileList.Image
				QueueFrame.QueueTime.Text = string.format("%d:%02d", math.floor(Queue.Time / 60), Queue.Time % 60)

				for i, Image : ImageLabel in QueueFrame.PlayerImages:GetChildren() do
					if Image:IsA("ImageLabel") then
						local QueuedPlayer : Player = Queue.Players[i]
						if QueuedPlayer then
							Image.Image = Players:GetUserThumbnailAsync(QueuedPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
						else
							Image.Image = ""
						end
					end
				end

				QueueFrame.Join.MouseButton1Click:Once(function()
					local AddSuccess = Queues:RequestAddToQueue(Player, QueueId)
					if AddSuccess then
						OpenQueueLobbyFrame(Player, MenuFrames, Queue, QueueId, ChapterFileList)
					end
				end)
			end
		end
	end
	
	PlayerFuncConnections[Player.Name]["UpdateStoryQueuesUi"] = Bindables.UpdateStoryQueuesUi.OnClientEvent:Connect(UpdateStoryQueuesList)
	
end


function OpenQueueLobbyFrame(Player : Player, MenuFrames, Queue, QueueId : number, ChapterFileList)

	OpenMenuFrame(MenuFrames.QueueLobby, MenuFrames)

	local StoryDetails : Frame = MenuFrames.QueueLobby.StoryDetails
	local PlayerList : Frame = MenuFrames.QueueLobby.PlayerList

	StoryDetails.StoryImage.Image = ChapterFileList.Image
	StoryDetails.StoryName.Text = ChapterFileList.Name
	StoryDetails.StoryDescription.Text = ChapterFileList.Description

	PlayerFuncConnections[Player.Name]["UpdateQueueLobbyUi"] = Bindables.UpdateQueueLobbyUi.OnClientEvent:Connect(function(Queue, SpecialMessage : string)
		if not Queue then return end

		-- Update the timer if not solo
		if SpecialMessage then
			MenuFrames.QueueLobby.StartTimer.Text = SpecialMessage
		elseif not Queue.IsSolo then
			MenuFrames.QueueLobby.StartTimer.Text = "Starting in "..string.format("%d:%02d", math.floor(Queue.Time / 60), Queue.Time % 60)
		end

		-- Update the player list
		for i, PlayerFrame : Frame in PlayerList:GetChildren() do
			if PlayerFrame:IsA("Frame") then
				local QueuedPlayer : Player = Queue.Players[i]
				if QueuedPlayer then
					PlayerFrame.DisplayName.Text = QueuedPlayer.DisplayName
					PlayerFrame.Username.Text = "@"..QueuedPlayer.Name
					PlayerFrame.PlayerImage.Image = Players:GetUserThumbnailAsync(QueuedPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
				else
					PlayerFrame.DisplayName.Text = ""
					PlayerFrame.Username.Text = ""
					PlayerFrame.PlayerImage.Image = ""
				end
			end
		end
	end)


	-- Set up the queue lobby UI
	if Queue.IsSolo then
		MenuFrames.QueueLobby.StartSolo.Visible = true
		MenuFrames.QueueLobby.StartTimer.Visible = false

		MenuFrames.QueueLobby.StartSolo.MouseButton1Click:Connect(function()
			GuiModule.PlayGuiSound(Player, "ButtonClick")
			Bindables.StartSolo:FireServer(QueueId)
		end)

	else
		MenuFrames.QueueLobby.StartTimer.Visible = true
		MenuFrames.QueueLobby.StartSolo.Visible = false

	end
end


function CreateQueue(Player : Player, MenuFrames, ChapterFileList, IsSolo : boolean)
	
	local Queue, QueueId = Queues:RequestCreateQueue(Player, ChapterFileList.PlaceId, IsSolo)

	OpenQueueLobbyFrame(Player, MenuFrames, Queue, QueueId, ChapterFileList)
	
end


function CreateStoryFrame(Player : Player, StoryName : string, FileList, MenuFrames)
	
	-- Menu Frame
	local StorySelector : Frame = MenuFrames.StorySelector
	local ChapterSelector : Frame = StorySelector.ChapterSelector
	local StoryViewer : Frame = StorySelector.StoryViewer
	
	
	-- Story
	local StoriesList : ScrollingFrame = MenuFrames.StorySelector:FindFirstChild("StoriesList")
	local StoryFrame : Frame = OriginalGuiItems.Story:Clone()
	StoryFrame.Parent = StoriesList
	StoryFrame.StoryName.Text = StoryName
	StoryFrame.StoryImage.Image = FileList.Chapters[1].Image
	
	PlayerFuncConnections[Player.Name][StoryName.."ViewButtonMouseButton1Click"] = StoryFrame.ViewButton.MouseButton1Click:Connect(function()
		GuiModule.PlayGuiSound(Player, "ButtonClick")
		
		-- Set up the chapter selector 
		local ChaptersList : ScrollingFrame = ChapterSelector.ChaptersList
		ChapterSelector.StoryName.Text = StoryName
		ChapterSelector.StoryImage.Image = FileList.Chapters[1].Image
		
		-- Remove all previous chapter frames
		for i, Frame in ChaptersList:GetChildren() do
			if Frame:IsA("GuiButton") then Frame:Destroy() end
		end
		
		-- Loop through all chapters and add them to the list
		for i, Chapter in FileList.Chapters do
			local ChapterButton : GuiButton = OriginalGuiItems.Chapter:Clone()
			ChapterButton.Parent = ChaptersList
			ChapterButton.Text = Chapter.Name
			ChapterButton.Name = Chapter.Name
			ChapterButton.LayoutOrder = i
			
			-- Set up the chapter button
			PlayerFuncConnections[Player.Name][ChapterButton.Name.."MouseButton1Click"] = ChapterButton.MouseButton1Click:Connect(function()
				GuiModule.PlayGuiSound(Player, "ButtonClick")
				-- Set up the chapter viewer
				StoryViewer.StoryName.Text = if StoryName ~= Chapter.Name then StoryName..": "..Chapter.Name else StoryName
				StoryViewer.StoryDescription.Text = Chapter.Description
				StoryViewer.Visible = true
				
				
				-- Disconnect previous connections
				if PlayerFuncConnections[Player.Name]["SoloMouseButton1Click"] then
					PlayerFuncConnections[Player.Name]["SoloMouseButton1Click"]:Disconnect()
				end
				if PlayerFuncConnections[Player.Name]["CoopMouseButton1Click"] then
					PlayerFuncConnections[Player.Name]["CoopMouseButton1Click"]:Disconnect()
				end
				
				-- Set up queue buttons
				PlayerFuncConnections[Player.Name]["SoloMouseButton1Click"] = StoryViewer.Solo.MouseButton1Click:Connect(function()
					GuiModule.PlayGuiSound(Player, "ButtonClick")
					StoryViewer.Visible = false
					CreateQueue(Player, MenuFrames, FileList.Chapters[i], true)
				end)
				PlayerFuncConnections[Player.Name]["CoopMouseButton1Click"] = StoryViewer.Coop.MouseButton1Click:Connect(function()
					GuiModule.PlayGuiSound(Player, "ButtonClick")
					StoryViewer.Visible = false
					CreateQueue(Player, MenuFrames, FileList.Chapters[i], false)
				end)

				
				
			end)
			
		end
		
	end)
	
	return StoryFrame
end


-- Loop through all stories and create a frame for each story
function GetStories(Player : Player, Gui : ScreenGui, MenuFrames)
	-- Loop through story data and create a frame for each story
	-- Put the frames into the story selector scrolling frame
	for name, Story in StoryData do
		local StoryFrame = CreateStoryFrame(Player, name, Story, MenuFrames)
	end
	
end



------------------------------ Set Up

-- Initialize all buttons in the menu.
function SetUpMenuNavigation(Player : Player, Gui : ScreenGui, MenuFrames)
	
	------------------------------ Buttons
	local Buttons = {
		Home = {
			Play = MenuFrames.Home.Play,
			TestArea = MenuFrames.Home.TestArea
		},
		StoryQueues = {
			CreateNew = MenuFrames.StoryQueues.CreateNewButton,
			Back = MenuFrames.StoryQueues.Back,
		},
		StorySelector = {
			Back = MenuFrames.StorySelector.Back,
		},
		QueueLobby = {
			LeaveQueue = MenuFrames.QueueLobby.LeaveQueue,
		},
		Other = {
			BackToMenu = Gui.BackToMenu
		}
	}
	
	
	-- Player
	local Character = Player.Character or Player.CharacterAdded:Wait()
	
	------------------------------ Logic
	----------- Other
	
	local function ReEnterMenu()
		Buttons.Other.BackToMenu.Visible = false
		if table.find(ActiveMenuPlayers, Player) then return end
		EnterMainMenu(Player, Gui, MenuFrames)
		Character:PivotTo(workspace.SpawnLocations.SpawnLocation.CFrame * CFrame.new(0, 3, 0))
	end
	Buttons.Other.BackToMenu.MouseButton1Click:Connect(function()
		GuiModule.PlayGuiSound(Player, "ButtonClick")
		ReEnterMenu()
	end)
	UserInputService.InputBegan:Connect(function(input : InputObject, GameProcessedEvent : boolean)
		if GameProcessedEvent then return end
		if input.KeyCode == Enum.KeyCode.M then
			ReEnterMenu()
		end
	end)
	
	----------- Home Buttons
	Buttons.Home.Play.MouseButton1Click:Connect(function()	
		GuiModule.PlayGuiSound(Player, "ButtonClick")
		OpenMenuFrame(MenuFrames.StoryQueues, MenuFrames)
	end)
	Buttons.Home.TestArea.MouseButton1Click:Connect(function()	
		GuiModule.PlayGuiSound(Player, "ButtonClick")
		Buttons.Other.BackToMenu.Visible = true
		ExitMainMenu(Player, Gui, MenuFrames)
		Character:PivotTo(workspace["Drabbed Enclosure"].Spawn.CFrame * CFrame.new(0, 3, 0))
	end)
	
	----------- Story Queues
	Buttons.StoryQueues.CreateNew.MouseButton1Click:Connect(function()
		GuiModule.PlayGuiSound(Player, "ButtonClick")
		OpenMenuFrame(MenuFrames.StorySelector, MenuFrames)
	end)
	Buttons.StoryQueues.Back.MouseButton1Click:Connect(function()
		GuiModule.PlayGuiSound(Player, "ButtonClick")
		OpenMenuFrame(MenuFrames.Home, MenuFrames)
	end)
	
	----------- Story Selector
	Buttons.StorySelector.Back.MouseButton1Click:Connect(function()
		GuiModule.PlayGuiSound(Player, "ButtonClick")
		if MenuFrames.StorySelector.StoryViewer.Visible then
			MenuFrames.StorySelector.StoryViewer.Visible = false
		else
			OpenMenuFrame(MenuFrames.StoryQueues, MenuFrames)
		end
	end)
	
	----------- Queue Lobby
	Buttons.QueueLobby.LeaveQueue.MouseButton1Click:Connect(function()
		GuiModule.PlayGuiSound(Player, "ButtonClick")
		
		-- Remove the player from the queue
		Queues:RequestRemoveFromQueue(Player)
		
		-- Reset ui
		if PlayerFuncConnections[Player.Name]["UpdateQueueLobbyUi"] then PlayerFuncConnections[Player.Name]["UpdateQueueLobbyUi"]:Disconnect() end
		OpenMenuFrame(MenuFrames.Home, MenuFrames)
	end)
	
	
end


-- Set up the menu frames and return them.
function MenuGuiModule.SetupClient(Player : Player, Gui : ScreenGui)
	
	------------------------------ Player
	local StatusValuesF = Player:WaitForChild("StatusValues")
	local StatusValues = {
		IsPlayerLocked = StatusValuesF.IsPlayerLocked
	}
	
	local Mouse = Player:GetMouse()
	local Camera = workspace.CurrentCamera 
	
	------------------------------ Gui
	local MenuFrames = { 
		Home = Gui.Home,
		StoryQueues = Gui.StoryQueues,
		StorySelector = Gui.StorySelector,
		QueueLobby = Gui.QueueLobby,
	}
	
	------------------------------ Set to initial state
	AddPlayer(Player)
	
	-- Frames
	for name, Frame : Frame in MenuFrames do
		Frame.Visible = true
		
		if name ~= "Home" then
			Frame.Position = GuiData[name].ClosedPos
		end
	end
	
	-- Camera
	LockCamera(Player, Camera, Gui)
	
	
	-- Menu Frame Setup
	for i, PlayerFrame in MenuFrames.QueueLobby.PlayerList:GetChildren() do
		if PlayerFrame:IsA("Frame") then
			PlayerFrame.DisplayName.Text = ""
			PlayerFrame.Username.Text = ""
			PlayerFrame.PlayerImage.Image = ""
		end
	end
	
	------------------------------ Functionality Setup
	SetUpMenuNavigation(Player, Gui, MenuFrames)
	SetUpStoryQueuesList(Player, MenuFrames)
	GetStories(Player, Gui, MenuFrames)
	
	
	
	
	
	return MenuFrames
end


------------------------------ Server-Sided
function MenuGuiModule.SetupServer()
	
	------------------------------ Setup gui items into default state
	OriginalGuiItems.Queue.StoryName.Text = ""
	OriginalGuiItems.Queue.StoryImage.Image = ""
	for i, Image : ImageLabel in OriginalGuiItems.Queue.PlayerImages:GetChildren() do
		Image.Image = ""
	end
	OriginalGuiItems.Story.StoryName.Text = ""
	OriginalGuiItems.Story.StoryImage.Image = ""
	
	
	
end



return MenuGuiModule
