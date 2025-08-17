--[[
    Archivo: InventoryService.server.lua
    Tipo: Script
    Ubicacion: ServerScriptService/
    Descripcion: Orquesta la logica del inventario, conectando la comunicacion del cliente
                 con los modulos de logica del servidor.
--]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modulos requeridos
local Comm = require(ReplicatedStorage.Shared.comm)
local DataManager = require(ServerScriptService.core.player_data_manager)
local InventoryManager = require(ServerScriptService.Modules.inventory_manager)

local RemoteEvents = Comm and Comm.RemotesFolder or nil

-- ---
-- Funcion para enviar el estado completo del inventario a un jugador
-- ---
local function sendInventoryToClient(player)
    local profile = DataManager:GetProfile(player)
    if not profile or not profile.Data.Inventory then return end

    -- Para que el cliente pueda ver los detalles, necesita los datos completos de cada item, no solo el ID.
    local detailedInventory = {
        Items = {},
        Equipped = profile.Data.Inventory.Equipped
    }

    local ItemConfig = require(ReplicatedStorage.Shared.item_config) -- Se requiere aqui para no mantenerlo en memoria siempre

    for _, itemInstance in ipairs(profile.Data.Inventory.Items) do
        local itemData = ItemConfig[itemInstance.ID]
        if itemData then
            -- Se crea una tabla nueva con los datos base y los datos de la instancia
            local fullItemData = {}
            for k, v in pairs(itemData) do fullItemData[k] = v end
            fullItemData.UniqueID = itemInstance.UniqueID
            fullItemData.Level = itemInstance.Level
            table.insert(detailedInventory.Items, fullItemData)
        end
    end

    if RemoteEvents and RemoteEvents.UpdateInventory then
        RemoteEvents.UpdateInventory:FireClient(player, detailedInventory)
    end
end

-- ---
-- Manejadores de Eventos Remotos
-- ---

-- Se ejecuta cuando un jugador intenta equipar o desequipar un item
local function onEquipItem(player, itemUniqueID)
    local profile = DataManager:GetProfile(player)
    if not profile then return end

    local currentStats = DataManager:GetFullStats(profile)

    local success = InventoryManager.ToggleEquipItem(profile, currentStats, itemUniqueID)

    if success then
        -- Si el equipo cambio, hay que recalcular todo y notificar al cliente
        local itemBonuses = InventoryManager.GetTotalEquippedStats(profile)
        DataManager:UpdateItemBonuses(profile, itemBonuses)
        DataManager:sendFullStatsToClient(player)
        sendInventoryToClient(player)
    end
end

-- Se ejecuta cuando un jugador arrastra un item fuera de la ventana
local function onDropItem(player, itemUniqueID)
    local profile = DataManager:GetProfile(player)
    if not profile then return end

    -- TODO: Implementar la logica para dropear items
    -- 1. Encontrar el item en profile.Data.Inventory.Items y removerlo.
    -- 2. Si estaba equipado, asegurarse de desequiparlo (inventory.Equipped[type] = nil)
    -- 3. Recalcular stats y actualizar al cliente (similar a onEquipItem)

    print("[InventoryService] El jugador " .. player.Name .. " dropeo el item " .. tostring(itemUniqueID))
end


-- ---
-- Manejo de Jugadores
-- ---

local function onPlayerAdded(player)
    -- El perfil puede tardar un poco en cargar, asi que esperamos.
    -- Una mejor solucion a futuro seria un evento desde PlayerDataManager cuando el perfil este listo.
    task.wait(2) 

    local dm = DataManager
    local im = InventoryManager
    if not dm then
        warn("[InventoryService] DataManager no disponible en onPlayerAdded para " .. player.Name)
        return
    end

    local profile = dm:GetProfile(player)
    if not profile then return end

    -- TEMPORAL: Dar items iniciales para testing
    if im and #profile.Data.Inventory.Items == 0 then
        print("[InventoryService] Dando items iniciales a " .. player.Name)
        im.AddItem(profile, "SWORD_01")
        im.AddItem(profile, "HELMET_01")
    end

    sendInventoryToClient(player)
end

-- Conectar todos los eventos
if RemoteEvents and RemoteEvents.EquipItem then
    RemoteEvents.EquipItem.OnServerEvent:Connect(onEquipItem)
end
if RemoteEvents and RemoteEvents.DropItemEvent then
    RemoteEvents.DropItemEvent.OnServerEvent:Connect(onDropItem)
end
Players.PlayerAdded:Connect(onPlayerAdded)

print("Servicio de Inventario iniciado.")
