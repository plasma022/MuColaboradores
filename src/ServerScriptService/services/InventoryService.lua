--[[
	InventoryService.lua
	Servicio para gestionar el inventario y el equipamiento de los jugadores.
	Maneja la adición, eliminación y equipamiento de ítems.
	Ubicación: ServerScriptService/services/
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- <-- LÍNEA AÑADIDA

-- Módulos
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ItemConfig = require(ReplicatedStorage.Shared.config.ItemConfig)

local InventoryService = {}

-- ATRIBUTOS DEL SERVICIO
InventoryService.PlayerDataService = nil
InventoryService.StatsService = nil

-- MÉTODOS
function InventoryService:Init()
	-- No se necesita nada en la inicialización
end

function InventoryService:Start(ServiceManager)
	-- Obtenemos referencias a otros servicios
	self.PlayerDataService = ServiceManager:GetService("PlayerDataService")
	self.StatsService = ServiceManager:GetService("StatsService")

	-- Conectamos el RemoteEvent para que el cliente pueda solicitar equipar un ítem
	Remotes.EquipItem.OnServerEvent:Connect(function(player, itemInstanceId)
		self:_onEquipItem(player, itemInstanceId)
	end)

	print("[InventoryService] Listo y escuchando peticiones de inventario.")
end

-- Función privada que se ejecuta cuando un jugador intenta equipar un ítem
function InventoryService:_onEquipItem(player, itemInstanceId)
	local playerData = self.PlayerDataService:GetData(player)
	if not playerData then return end

	local itemToEquip = self:FindItemInInventory(playerData, itemInstanceId)
	if not itemToEquip then
		warn(`[InventoryService] El jugador {player.Name} intentó equipar un ítem que no posee: {itemInstanceId}`)
		return
	end

	local itemBaseData = ItemConfig[itemToEquip.itemId]
	if not itemBaseData or not itemBaseData.Slot then
		warn(`[InventoryService] El ítem {itemToEquip.itemId} no tiene datos de configuración o slot de equipo.`)
		return
	end

	local equipmentSlot = itemBaseData.Slot -- Ej: "Weapon", "Helmet", etc.

	-- Desequipamos el ítem que estaba en ese slot, si había uno
	local previouslyEquippedItem = playerData.Equipment[equipmentSlot]
	if previouslyEquippedItem then
		table.insert(playerData.Inventory, previouslyEquippedItem)
	end

	-- Movemos el nuevo ítem del inventario al equipamiento
	playerData.Equipment[equipmentSlot] = itemToEquip
	self:RemoveItemByInstanceId(playerData, itemInstanceId)

	-- Recalculamos los stats del jugador para aplicar los bonus del nuevo ítem
	self.StatsService:RecalculateDerivedStats(player)

	-- Notificamos al cliente que los datos han cambiado para que actualice la UI
	Remotes.PlayerStatUpdate:FireClient(player, playerData)
	Remotes.InventoryUpdated:FireClient(player, {
		Inventory = playerData.Inventory,
		Equipment = playerData.Equipment
	})

	print(`[InventoryService] El jugador {player.Name} equipó el ítem {itemToEquip.itemId}`)
end

-- Función pública para añadir un ítem al inventario de un jugador
function InventoryService:AddItem(player, itemId, quantity)
	local playerData = self.PlayerDataService:GetData(player)
	if not playerData then return false end

	local itemBaseData = ItemConfig[itemId]
	if not itemBaseData then
		warn(`[InventoryService] Se intentó añadir un ítem inexistente: {itemId}`)
		return false
	end

	-- Aquí iría la lógica para apilar ítems si son apilables (stackable)
	-- Por ahora, creamos una nueva instancia única para cada ítem
	local newItem = {
		itemId = itemId,
		instanceId = HttpService:GenerateGUID(false), -- Creamos un ID único para esta instancia del ítem
		quantity = quantity or 1,
		-- Aquí podrían ir otras propiedades como durabilidad, nivel del ítem (+X), etc.
	}

	table.insert(playerData.Inventory, newItem)
	
	-- Notificamos al cliente sobre la actualización
	Remotes.InventoryUpdated:FireClient(player, {
		Inventory = playerData.Inventory,
		Equipment = playerData.Equipment
	})

	return true
end

-- Helper para encontrar un ítem en el inventario por su ID de instancia
function InventoryService:FindItemInInventory(playerData, itemInstanceId)
	for _, item in ipairs(playerData.Inventory) do
		if item.instanceId == itemInstanceId then
			return item
		end
	end
	return nil
end

-- Helper para eliminar un ítem del inventario por su ID de instancia
function InventoryService:RemoveItemByInstanceId(playerData, itemInstanceId)
	for i, item in ipairs(playerData.Inventory) do
		if item.instanceId == itemInstanceId then
			table.remove(playerData.Inventory, i)
			return true
		end
	end
	return false
end

return InventoryService
