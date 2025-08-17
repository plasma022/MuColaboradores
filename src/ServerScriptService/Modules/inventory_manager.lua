--[[
    Archivo: InventoryManager.lua
    Tipo: ModuleScript
    Ubicacion: ServerScriptService/Modules/
    Descripcion: Contiene la logica pura para manipular los datos del inventario de un jugador.
                 No se comunica con el cliente, solo manipula datos del perfil.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local function safeRequireShared(name)
    local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
    if not shared then warn("[InventoryManager] ReplicatedStorage.Shared no disponible") return {} end
    local module = shared:FindFirstChild(name) or shared:WaitForChild(name, 5)
    if not module then warn("[InventoryManager] Módulo '"..name.."' no encontrado en Shared") return {} end
    local ok, res = pcall(require, module)
    if not ok then warn("[InventoryManager] Error al require: ", res) return {} end
    return res
end

local ItemConfig = safeRequireShared("item_config")

local InventoryManager = {}

-- Mapa de traduccion para los requisitos de stats
local statNameMap = {
	Strength = "STR", Agility = "AGI", Vitality = "VIT", Energy = "ENE"
}

-- Inicializa la seccion de inventario en el perfil de un jugador si no existe.
function InventoryManager.InitializeInventory(profile)
    local data = profile.Data
    if not data.Inventory then
        data.Inventory = {
            Items = {},
            Equipped = {}
        }
    end
    -- Asegura que las tablas internas existan
    if not data.Inventory.Items then data.Inventory.Items = {} end
    if not data.Inventory.Equipped then data.Inventory.Equipped = {} end
end

-- Añade un nuevo item al inventario del jugador.
function InventoryManager.AddItem(profile, itemID)
    if not ItemConfig[itemID] then
        warn("[InventoryManager] Se intento agregar un item invalido: " .. tostring(itemID))
        return
    end

    local itemData = ItemConfig[itemID]
    
    -- Creamos una instancia unica del item para el jugador
    local newItemInstance = {
        ID = itemID, -- El ID base del ItemConfig
        UniqueID = HttpService:GenerateGUID(false), -- Un identificador unico para esta instancia especifica
        Level = itemData.Level or 0,
        -- Se podrian añadir mas propiedades unicas aqui en el futuro (ej. stats aleatorios)
    }

    table.insert(profile.Data.Inventory.Items, newItemInstance)
    return newItemInstance
end

-- Valida si un jugador cumple con los requisitos para usar un item.
function InventoryManager.CanEquip(playerStats, itemData)
    if not playerStats or not itemData then return false end

    -- 1. Validar Clase
    if itemData.ReqClass and itemData.ReqClass ~= playerStats.ClassName then
        return false
    end

    -- 2. Validar Stats
    if itemData.ReqStats then
        for stat, requiredValue in pairs(itemData.ReqStats) do
            local statAbbreviation = statNameMap[stat]
            if not statAbbreviation or (playerStats[statAbbreviation] or 0) < requiredValue then
                return false
            end
        end
    end

    return true
end

-- Equipa o desequipa un item.
function InventoryManager.ToggleEquipItem(profile, playerStats, itemUniqueID)
    local inventory = profile.Data.Inventory
    local itemInstance
    local itemIndex

    for i, item in ipairs(inventory.Items) do
        if item.UniqueID == itemUniqueID then
            itemInstance = item
            itemIndex = i
            break
        end
    end

    if not itemInstance then 
        warn("[InventoryManager] El jugador intento equipar un item que no posee: " .. tostring(itemUniqueID))
        return false 
    end

    local itemData = ItemConfig[itemInstance.ID]
    if not itemData or not itemData.Type then return false end

    local itemType = itemData.Type

    -- Comprobar si ya esta equipado
    local isCurrentlyEquipped = false
    for slot, equippedUniqueID in pairs(inventory.Equipped) do
        if equippedUniqueID == itemUniqueID then
            isCurrentlyEquipped = true
            break
        end
    end

    if isCurrentlyEquipped then
        -- Desequiparlo
        inventory.Equipped[itemType] = nil
    else
        -- Validar si se puede equipar
        if not InventoryManager.CanEquip(playerStats, itemData) then
            -- El jugador no cumple los requisitos
            return false
        end
        -- Equiparlo
        inventory.Equipped[itemType] = itemInstance.UniqueID
    end
    
    return true -- Hubo un cambio en el equipo
end


-- Calcula la suma de todos los stats proporcionados por los items equipados.
function InventoryManager.GetTotalEquippedStats(profile)
    local inventory = profile.Data.Inventory
    local totalStats = {
        -- Inicializar todos los posibles stats de items en 0
        MinDmg = 0, MaxDmg = 0, Defense = 0, AttackSpeed = 0, MovementSpeed = 0
    }

    if not inventory or not inventory.Equipped then return totalStats end

    for slot, uniqueID in pairs(inventory.Equipped) do
        local itemInstance = nil
        for _, inst in ipairs(inventory.Items) do
            if inst.UniqueID == uniqueID then
                itemInstance = inst
                break
            end
        end

        if itemInstance then
            local itemData = ItemConfig[itemInstance.ID]
            if itemData then
                -- Sumar los stats del item a los totales
                for statName, statValue in pairs(itemData) do
                    if totalStats[statName] then
                        totalStats[statName] = totalStats[statName] + statValue
                    end
                end
            end
        end
    end

    return totalStats
end

return InventoryManager
