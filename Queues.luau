------------------------------ Services
local Players = game:GetService("Players")

local TeleportService = game:GetService("TeleportService")


--[[

Queue = {
	DestinationPlaceId = 0,
	Players = {Player, Player, Player},
	Time = 0,
	IsSolo = true/false,
}

]]

local Queues = {}

------------------------------ Module
local MainMenuModuleScript = script.Parent

-- Bindables
local MenuBindables = MainMenuModuleScript.Bindables
local Bindables = {
	-- Server to Client
	CreateQueueUi = MenuBindables.CreateQueueUi,
	UpdateQueueLobbyUi = MenuBindables.UpdateQueueLobbyUi,
	UpdateStoryQueuesUi = MenuBindables.UpdateStoryQueuesUi,
	
	-- Client to Server
	CreateQueue = MenuBindables.CreateQueue,
	QueuePlayer = MenuBindables.QueuePlayer,
	StartSolo = MenuBindables.StartSolo,
}

-- Other Modules
local Data = require(MainMenuModuleScript.Data)
local Settings = Data.Settings

local MenuQueuesModule = {}


------------------------------ Server-Sided

function CreateQueue(InitialPlayer : Player, IsSolo : boolean, DestinationPlaceId : number)
	if not InitialPlayer then warn("Cannot create queue without player.") return end
	
	-- Create Queue
	local QueueId
	repeat
		QueueId = math.random(0, 99999)
	until not Queues[QueueId]
	Queues[QueueId] = {
		DestinationPlaceId = DestinationPlaceId,
		Players = {InitialPlayer},
		Time = Settings.CoopStartTime,
		IsSolo = IsSolo or false,
	}
	
	print("New queue has been created.", QueueId, Queues[QueueId].DestinationPlaceId)
	
	Bindables.UpdateStoryQueuesUi:FireAllClients(Queues)
	
	local function UpdateQueuedPlayerUi(SpecialMessage : string)
		for i, Player : Player in Queues[QueueId].Players do
			Bindables.UpdateQueueLobbyUi:FireClient(Player, Queues[QueueId], SpecialMessage)
		end
	end
	task.spawn(UpdateQueuedPlayerUi)
	
	task.spawn(function()
		if Queues[QueueId].IsSolo then
			local StartedSolo = false
			local StartSoloConnection = Bindables.StartSolo.OnServerEvent:Connect(function(StartPlayer : Player, StartQueueId : number)
				if QueueId == StartQueueId then
					StartedSolo = true
				end
			end)
			
			repeat 
				task.wait(0.1) 
				task.spawn(UpdateQueuedPlayerUi)
				
			until StartedSolo or (not Queues[QueueId] or #Queues[QueueId].Players <= 0)
			StartSoloConnection:Disconnect()
			
		else
			while Queues[QueueId] and #Queues[QueueId].Players > 0 and Queues[QueueId].Time > 0 do
				if #Queues[QueueId].Players < Data.Settings.CoopMinimumPlayers then
					UpdateQueuedPlayerUi("Waiting for more players...")
					repeat task.wait() until #Queues[QueueId].Players >= Data.Settings.CoopMinimumPlayers
						or not Queues[QueueId] or #Queues[QueueId].Players <= 0
				end
				
				Queues[QueueId].Time -= 1

				task.spawn(UpdateQueuedPlayerUi)
				Bindables.UpdateStoryQueuesUi:FireAllClients(Queues)
				task.wait(0.5)
				
				task.spawn(UpdateQueuedPlayerUi)
				Bindables.UpdateStoryQueuesUi:FireAllClients(Queues)
				task.wait(0.5)
			end
		end
		
		if not Queues[QueueId] or #Queues[QueueId].Players <= 0 then
			print("Queue has been deleted or all players have left the queue. "..QueueId, Queues[QueueId].DestinationPlaceId)
			
		else
			-- Reserve a server in the queue destination place and teleport the players.
			local TeleportOptions = Instance.new("TeleportOptions")
			TeleportOptions.ShouldReserveServer = true

			local success, result = pcall(function()
				return TeleportService:TeleportAsync(Queues[QueueId].DestinationPlaceId, Queues[QueueId].Players, TeleportOptions)
			end)

			if success then
				local AccessCode = result.ReservedServerAccessCode
				local ServerId = result.PrivateServerId
				print("Successfully sent to reserved server: ", ServerId)
			else
				warn("Teleport failed: " .. tostring(result))
			end
		end
		
		-- Delete the queue.
		Queues[QueueId] = nil

		Bindables.UpdateStoryQueuesUi:FireAllClients(Queues)
		
	end)
	
	return Queues[QueueId], QueueId
end


-- Run an action to a queue of the player, e.g. add or remove the player from the queue. Server-sided.
function QueuePlayer(Player : Player, Action : string, QueueId : number)
	if not Player then warn("Cannot queue player without player.") return end
	
	-- Type check
	if QueueId then QueueId = tonumber(QueueId) end
	
	-- Add or remove the player from the queue.
	if Action == "Add" then
		local Queue = Queues[QueueId]
		if Queue then
			--print("Adding player", Player.Name, "to QueueId", QueueId)
			table.insert(Queue.Players, Player)
			Queue.Time += Settings.CoopAddTime
			return true
		else
			warn("Queue does not exist from QueueId", QueueId, "; found", Queue)
		end
		
	elseif Action == "Remove" then
		for QueueId, Queue in Queues do
			if table.find(Queue.Players, Player) then
				--print("Removing", Player.Name, "from QueueId", QueueId)
				table.remove(Queue.Players, table.find(Queue.Players, Player))
				Queue.Time -= Settings.CoopAddTime
				return true
			else	
				warn("Player", Player.Name, "is not in any queue.")
			end
		end
		
	end
	
end

-- Queue Handler. Server-sided.
function MenuQueuesModule.QueueHandlerServer()
	
	------------------------------ Event Connections
	
	-- Bindables
	Bindables.CreateQueue.OnServerInvoke = function(Player : Player, IsSolo : boolean, PlaceId : number)
		return CreateQueue(Player, IsSolo, PlaceId)
	end
	Bindables.QueuePlayer.OnServerInvoke = function(Player : Player, Action : string, QueueId : number)
		return QueuePlayer(Player, Action, QueueId)
	end
	
	-- Players
	Players.PlayerAdded:Connect(function(Player : Player)
		Bindables.UpdateStoryQueuesUi:FireAllClients(Queues)
	end)

	Players.PlayerRemoving:Connect(function(Player : Player)
		QueuePlayer(Player, "Remove")
	end)

end


------------------------------ Client-Sided

-- Create a queue that goes to the placeid, start the time, and automatically add the player to the queue. Client-sided.
function MenuQueuesModule:RequestCreateQueue(Player : Player, PlaceId : number, IsSolo : boolean)
	if not PlaceId then warn("Cannot create queue without a PlaceId.") return end
	-- Request the server to create a queue.
	return Bindables.CreateQueue:InvokeServer(IsSolo, PlaceId)
end

-- Add a player to a current queue. Client-sided.
function MenuQueuesModule:RequestAddToQueue(Player : Player, QueueId : number)
	-- Request the server to add the player to a queue.
	return Bindables.QueuePlayer:InvokeServer("Add", QueueId)
end

-- Remove a player from their current queue. Client-sided.
function MenuQueuesModule:RequestRemoveFromQueue(Player : Player)
	-- Request the server to remove the player frome their queue.
	return Bindables.QueuePlayer:InvokeServer("Remove", nil)
end






return MenuQueuesModule
