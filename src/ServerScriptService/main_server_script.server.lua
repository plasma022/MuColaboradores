local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataManager = require(ServerScriptService.core.player_data_manager)

local function onPlayerAdded(player)
    print("DEBUG: onPlayerAdded en main_server_script. Player object:", player, "Name:", player and player.Name) -- Línea de depuración
    PlayerDataManager.onPlayerAdded(player)
end

local function onPlayerRemoving(player)
    PlayerDataManager.onPlayerRemoving(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("Main Server Script Initialized.")