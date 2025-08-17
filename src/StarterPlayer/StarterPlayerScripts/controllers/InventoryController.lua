--[[ 
    ARCHIVO: InventoryController.lua
    UBICACIÓN: StarterPlayer/StarterPlayerScripts/controllers/
    DESCRIPCION: Controla toda la logica de la interfaz de usuario del inventario.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Módulos y Eventos
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ItemConfig = require(ReplicatedStorage.Shared.config.ItemConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Referencias a la UI (usando WaitForChild para seguridad)
local inventoryGui = playerGui:WaitForChild("InventoryGui")
local mainFrame = inventoryGui:WaitForChild("MainFrame")
local itemsGrid = mainFrame:WaitForChild("ItemsGrid")
local itemSlotTemplate = itemsGrid:WaitForChild("ItemSlotTemplate")
local equipmentFrame = mainFrame:WaitForChild("EquipmentFrame")
local tooltipFrame = mainFrame:WaitForChild("TooltipFrame")

-- CORRECCIÓN: La ruta ahora apunta al Frame correcto ("StatusUI") según tus archivos .rbxmx
local mainHudGui = playerGui:WaitForChild("MainHudGui")
local statusUIFrame = mainHudGui:FindFirstChild("StatusUI") -- El Frame se llama StatusUI, no HudFrame.

local InventoryController = {}

-- Variables de estado
local slotConnections = {}
local currentPlayerStats = {}

-- ---
-- FUNCIONES DE UI
-- ---

local function showTooltip(itemData)
    -- Lógica para mostrar el tooltip (sin cambios)
end

local function resetSlot(slot)
    slot.Image = ""
    if slotConnections[slot] then
        for _, c in ipairs(slotConnections[slot]) do c:Disconnect() end
        slotConnections[slot] = nil
    end
end

local function populateSlot(slot, itemData)
    resetSlot(slot)
    slot.Image = ItemConfig[itemData.itemId].IconId or ""

    slotConnections[slot] = {}

    table.insert(slotConnections[slot], slot.MouseButton1Click:Connect(function()
        Remotes.EquipItem:FireServer(itemData.instanceId)
    end))

    table.insert(slotConnections[slot], slot.MouseEnter:Connect(function()
        showTooltip(itemData)
    end))
    table.insert(slotConnections[slot], slot.MouseLeave:Connect(function()
        tooltipFrame.Visible = false
    end))
end

local function updateInventoryUI(data)
    if not data or not data.Inventory or not data.Equipment then return end

    for _, child in ipairs(itemsGrid:GetChildren()) do
        if child:IsA("ImageButton") and child.Name ~= "ItemSlotTemplate" then
            child:Destroy()
        end
    end

    for _, slot in ipairs(equipmentFrame:GetChildren()) do
        if slot:IsA("ImageButton") then resetSlot(slot) end
    end
    
    for slotType, itemData in pairs(data.Equipment) do
        local equipmentSlot = equipmentFrame:FindFirstChild(slotType)
        if equipmentSlot then populateSlot(equipmentSlot, itemData) end
    end
    
    for _, itemData in ipairs(data.Inventory) do
        local newSlot = itemSlotTemplate:Clone()
        newSlot.Name = itemData.instanceId
        newSlot.Visible = true
        populateSlot(newSlot, itemData)
        newSlot.Parent = itemsGrid
    end
end

-- ---
-- INICIALIZACIÓN
-- ---

function InventoryController:Start()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.B then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)

    Remotes.InventoryUpdated.OnClientEvent:Connect(updateInventoryUI)
    Remotes.PlayerStatUpdate.OnClientEvent:Connect(function(stats)
        currentPlayerStats = stats
    end)

    inventoryGui.Enabled = true
    mainFrame.Visible = false
    tooltipFrame.Visible = false

    print("[InventoryController] Iniciado.")
end

return InventoryController
