--[[ 
    ARCHIVO: InventoryController.lua
    UBICACIÓN: StarterPlayer/StarterPlayerScripts/controllers/
    DESCRIPCION: Controla toda la logica de la interfaz de usuario del inventario.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Modulos y Eventos
local function safeRequireShared(moduleName)
	local shared = ReplicatedStorage:WaitForChild("Shared", 5)
	if not shared then
		warn("[InventoryController] ReplicatedStorage.Shared no disponible (timeout)")
		return nil
	end
	local module = shared:FindFirstChild(moduleName)
	if not module then
		warn("[InventoryController] Módulo '"..moduleName.."' no encontrado en ReplicatedStorage.Shared")
		return nil
	end
	local ok, res = pcall(require, module)
	if not ok then
		warn("[InventoryController] Error al require de ", moduleName, res)
		return nil
	end
	return res
end

local Comm = safeRequireShared("comm")
local RemoteEvents = Comm and Comm.RemotesFolder

local player = Players.LocalPlayer
local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)

-- Referencias a la UI
local mainHud = playerGui and (playerGui:FindFirstChild("MainHudGui") or playerGui:WaitForChild("MainHudGui",5))
local openInventoryButton = mainHud and mainHud:FindFirstChild("HudFrame") and mainHud.HudFrame:FindFirstChild("OpenInventoryButton")
local inventoryGui = playerGui and (playerGui:FindFirstChild("InventoryGui") or playerGui:WaitForChild("InventoryGui",5))
local mainFrame = inventoryGui and (inventoryGui:FindFirstChild("MainFrame") or inventoryGui:WaitForChild("MainFrame",5))
local itemsGrid = mainFrame and mainFrame:FindFirstChild("ItemsGrid")
local itemSlotTemplate = itemsGrid and itemsGrid:FindFirstChild("ItemSlotTemplate")
local equipmentFrame = mainFrame and mainFrame:FindFirstChild("EquipmentFrame")
local tooltipFrame = mainFrame and mainFrame:FindFirstChild("TooltipFrame")

-- Variables de estado
local slotConnections = {}
local isTooltipHovered = false
local hideTooltipThread = nil
local currentPlayerStats = {} -- Se actualizara via el evento Comm "UpdateStats"

-- Tabla para traducir los nombres de los requisitos
local statNameMap = {
	Strength = "STR", Agility = "AGI", Vitality = "VIT", Energy = "ENE"
}

-- ---
-- FUNCIONES DE UI
-- ---

-- Muestra los detalles de un item
local function showTooltip(itemData)
	if hideTooltipThread then task.cancel(hideTooltipThread); hideTooltipThread = nil end

	if not tooltipFrame then return end
	tooltipFrame.ItemNameLabel.Text = itemData.Name .. " +" .. tostring(itemData.Level or 0)
	tooltipFrame.ItemTypeLabel.Text = itemData.Type or "Ítem"
	tooltipFrame.ItemDescriptionLabel.Text = itemData.Description or ""
	tooltipFrame.ItemStatsLabel.RichText = true

	local statsText = ""

	if itemData.MinDmg and itemData.MaxDmg then statsText = statsText .. string.format("Daño: %d ~ %d\n", itemData.MinDmg, itemData.MaxDmg) end
	if itemData.Defense then statsText = statsText .. "Defensa: " .. tostring(itemData.Defense) .. "\n" end
	if itemData.AttackSpeed then statsText = statsText .. "Velocidad de Ataque: " .. tostring(itemData.AttackSpeed) .. "\n" end
	if itemData.MovementSpeed then statsText = statsText .. "Velocidad de Movimiento: " .. tostring(itemData.MovementSpeed) .. "\n" end
	if itemData.Luck == true then statsText = statsText .. "\n+ Suerte (+5% prob. crítica)\n(+25% prob. de exito)" end

	if itemData.ReqStats or itemData.ReqClass then
		statsText = statsText .. "\nRequisitos:\n"
		if itemData.ReqClass then
			if currentPlayerStats and currentPlayerStats.ClassName and currentPlayerStats.ClassName == itemData.ReqClass then
				statsText = statsText .. string.format("  Clase: %s\n", itemData.ReqClass)
			else
				statsText = statsText .. string.format('<font color="rgb(255, 80, 80)">  Clase: %s</font>\n', itemData.ReqClass)
			end
		end
		if itemData.ReqStats then
			for stat, requiredValue in pairs(itemData.ReqStats) do
				local statAbbreviation = statNameMap[stat]
				if statAbbreviation and (currentPlayerStats[statAbbreviation] or 0) >= requiredValue then
					statsText = statsText .. string.format("  %s: %d\n", stat, requiredValue)
				else
					statsText = statsText .. string.format('<font color="rgb(255, 80, 80)">  %s: %d</font>\n', stat, requiredValue)
				end
			end
		end
	end

	tooltipFrame.ItemStatsLabel.Text = statsText
	tooltipFrame.Visible = true
end

-- Resetea un slot a su estado vacio
local function resetSlot(slot)
	slot.Image = ""
	local nameLabel = slot:FindFirstChild("ItemName")
	if nameLabel then nameLabel.Text = "" end
	local levelLabel = slot:FindFirstChild("ItemLevel")
	if levelLabel then levelLabel.Text = "" end
	if slotConnections[slot] then
		for _, c in ipairs(slotConnections[slot]) do c:Disconnect() end
		slotConnections[slot] = nil
	end
end

-- Rellena un slot con los datos de un item
local function populateSlot(slot, itemData)
	resetSlot(slot)
	slot.Image = itemData.ImageId or ""
	local nameLabel = slot:FindFirstChild("ItemName")
	if nameLabel then nameLabel.Text = itemData.Name end
	local levelLabel = slot:FindFirstChild("ItemLevel")
	if levelLabel then levelLabel.Text = "+" .. tostring(itemData.Level or 0) end

	slotConnections[slot] = {}

	-- Click para equipar/desequipar
	table.insert(slotConnections[slot], slot.MouseButton1Click:Connect(function()
		RemoteEvents.EquipItem:FireServer(itemData.UniqueID)
	end))

	-- Tooltip
	table.insert(slotConnections[slot], slot.MouseEnter:Connect(function()
		showTooltip(itemData)
	end))
	table.insert(slotConnections[slot], slot.MouseLeave:Connect(function()
		hideTooltipThread = task.delay(0.1, function()
			if not isTooltipHovered then
				tooltipFrame.Visible = false
			end
		end)
	end))
end

-- Dibuja toda la UI del inventario desde cero
local function updateInventoryUI(inventoryData)
	if not inventoryData then return end

	-- Limpiar slots de la grilla
	for _, child in ipairs(itemsGrid:GetChildren()) do
		if child:IsA("ImageButton") and child.Name ~= "ItemSlotTemplate" then
			child:Destroy()
		end
	end

	-- Limpiar slots de equipo
	for _, slot in pairs(equipmentFrame:GetChildren()) do
		if slot:IsA("ImageButton") then resetSlot(slot) end
	end

	-- Crear lookup para items equipados
	local equippedItemsLookup = {}
	if inventoryData.Equipped then
		for slotType, uniqueId in pairs(inventoryData.Equipped) do
			equippedItemsLookup[uniqueId] = true
		end
	end

	-- Poblar la UI
	if inventoryData.Items then
		for _, itemData in ipairs(inventoryData.Items) do
			local isEquipped = equippedItemsLookup[itemData.UniqueID] or false
			if isEquipped then
				local equipmentSlot = equipmentFrame:FindFirstChild(itemData.Type)
				if equipmentSlot then populateSlot(equipmentSlot, itemData) end
			else
				local newSlot = itemSlotTemplate:Clone()
				newSlot.Name = itemData.UniqueID
				newSlot.Visible = true
				populateSlot(newSlot, itemData)
				newSlot.Parent = itemsGrid
			end
		end
	end
end

-- ---
-- MANEJADORES DE EVENTOS
-- ---

local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.B then
		mainFrame.Visible = not mainFrame.Visible
	end
end

local function onInputEnded(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Logica de dropear item (simplificada)
        -- Si el mouse se suelta fuera del frame principal, se intenta dropear.
        -- Una implementacion mas robusta usaria un estado de "dragging".
        local mousePos = UserInputService:GetMouseLocation()
        local framePos = mainFrame.AbsolutePosition
        local frameSize = mainFrame.AbsoluteSize

        if not (mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and
                mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y) then
            
            -- TODO: Implementar la logica de arrastrar y soltar para saber que item se dropea.
            -- print("Intento de drop fuera de la ventana")
        end
    end
end

-- ---
-- CONEXIONES E INICIALIZACION
-- ---

-- Conectar el boton del HUD
openInventoryButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-- Conectar inputs de teclado
UserInputService.InputBegan:Connect(onInputBegan)
-- UserInputService.InputEnded:Connect(onInputEnded) -- Deshabilitado hasta implementar drag & drop

-- Conectar eventos del servidor
RemoteEvents.UpdateInventory.OnClientEvent:Connect(updateInventoryUI)

-- Escuchar el MISMO evento que el StatsController para mantener los datos sincronizados
Comm.Client:On("UpdateStats", function(stats)
    print("[InventoryController] Stats recibidos y actualizados.")
    currentPlayerStats = stats
end)

-- Conectar eventos del tooltip
tooltipFrame.MouseEnter:Connect(function() isTooltipHovered = true; if hideTooltipThread then task.cancel(hideTooltipThread); hideTooltipThread = nil end end)
tooltipFrame.MouseLeave:Connect(function() isTooltipHovered = false; tooltipFrame.Visible = false end)

-- Estado inicial de la UI
inventoryGui.Enabled = true
mainFrame.Visible = false
tooltipFrame.Visible = false

print("Controlador de Inventario (Cliente) iniciado.")