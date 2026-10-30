# Story-Main-Menu-System-Luau
This main menu system uses a simple luau module script hierarchy. Multiple stories can be added to this system.


# Placement in the game explorer goes as follows:

ReplicatedStorage
- MainMenu
    - Queues
    - Gui
    - Data 
    - [ModuleConfigs.rbxm]

ServerScriptService
- MainMenuServer

StarterGui
- [MainMenuScreenGui.rbxm]
    - MainMenuClient (May already be included in the model)

