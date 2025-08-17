--[[
	CharacterHandler.lua
	Gestiona la carga de modelos de personaje personalizados, la muerte y la reaparición.
	Ahora escucha la señal "PlayerDataLoaded" para actuar en el momento preciso.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Módulos
local Signals = require(ReplicatedStorage.Shared.util.Signal)
local ItemConfig = require(ReplicatedStorage.Shared.config.ItemConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes) -- AÑADIDO

local CharacterHandler = {}

-- ATRIBUTOS DEL SERVICIO
CharacterHandler.connections = {}
CharacterHandler.isLoadingCharacter = {}
CharacterHandler.StatsService = nil -- AÑADIDO
CharacterHandler.PlayerDataService = nil -- AÑADIDO

-- MÉTODOS
function CharacterHandler:Init()
	-- No se necesita nada
end

function CharacterHandler:Start(ServiceManager)
    -- OBTENEMOS OTROS SERVICIOS
    self.StatsService = ServiceManager:GetService("StatsService")
    self.PlayerDataService = ServiceManager:GetService("PlayerDataService")

	Players.PlayerAdded:Connect(function(player)
		self.isLoadingCharacter[player] = false
		player.CharacterAdded:Connect(function(character)
			self:_onCharacterAdded(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.isLoadingCharacter[player] = nil
		if self.connections[player] then
			for _, connection in ipairs(self.connections[player]) do
				connection:Disconnect()
			end
			self.connections[player] = nil
		end
	end)
	
	-- Nos conectamos a la señal para saber cuándo cargar el personaje.
	Signals:Connect(function(eventName, player, playerData)
		if eventName == "PlayerDataLoaded" then
			self:_onPlayerDataLoaded(player, playerData)
		end
	end)

	print("[CharacterHandler] Listo y escuchando apariciones de personajes.")
end

-- Esta función ahora es llamada por la señal
function CharacterHandler:_onPlayerDataLoaded(player, playerData)
	if not player.Character then return end
	
	if not playerData or not playerData.Clase or playerData.Clase == "Default" then
		print(`[CharacterHandler] Jugador {player.Name} con clase Default. Usando personaje estándar.`)
		return
	end
	
	self:_loadCustomCharacter(player, player.Character, playerData)
end

-- Se ejecuta cada vez que un personaje (re)aparece en el juego
function CharacterHandler:_onCharacterAdded(player, character)
	print(`[CharacterHandler] Personaje añadido para {player.Name}`)
	self:_setupCharacterConnections(player, character)
end

-- Carga el modelo de personaje personalizado
function CharacterHandler:_loadCustomCharacter(player, oldCharacter, playerData)
	if self.isLoadingCharacter[player] then return end
	self.isLoadingCharacter[player] = true

	print(`[CharacterHandler] Perfil encontrado para {player.Name}. Cargando modelo de clase: {playerData.Clase}`)
	
	local characterModel = ServerStorage:FindFirstChild(playerData.Clase)
	if not characterModel then
		warn(`[CharacterHandler] No se encontró el modelo para la clase: {playerData.Clase}`)
		self.isLoadingCharacter[player] = false
		return
	end

	oldCharacter:Destroy()
	local newCharacter = characterModel:Clone()
	newCharacter.Name = player.Name
	player.Character = newCharacter
	
	local humanoid = newCharacter:WaitForChild("Humanoid")
	humanoid.DisplayName = player.DisplayName
	
	self:_setupCharacterConnections(player, newCharacter)
	self:UpdateCharacterAppearance(player, newCharacter, playerData)
	
	newCharacter.Parent = workspace
	
    -- CORRECCIÓN: Forzamos la actualización de stats DESPUÉS de cargar el nuevo personaje
    self.StatsService:RecalculateDerivedStats(player)
    local freshPlayerData = self.PlayerDataService:GetData(player)
    if freshPlayerData then
        humanoid.Health = freshPlayerData.MaxHP -- Seteamos la vida al máximo
        Remotes.PlayerStatUpdate:FireClient(player, freshPlayerData) -- Enviamos los datos actualizados al cliente
    end

	self.isLoadingCharacter[player] = false
end

-- Configura las conexiones para un personaje recién creado
function CharacterHandler:_setupCharacterConnections(player, character)
	if self.connections[player] then
		for _, connection in ipairs(self.connections[player]) do
			connection:Disconnect()
		end
	end
	self.connections[player] = {}

	local humanoid = character:WaitForChild("Humanoid")
	local diedConnection = humanoid.Died:Connect(function()
		self:_onCharacterDied(player)
	end)
	table.insert(self.connections[player], diedConnection)
end

-- Se ejecuta cuando el humanoide del personaje muere
function CharacterHandler:_onCharacterDied(player)
	print(`[CharacterHandler] El personaje de {player.Name} ha muerto.`)
	task.wait(5)
	if player and player:IsDescendantOf(Players) then
		self.isLoadingCharacter[player] = false
		player:LoadCharacter()
	end
end

-- Función pública para actualizar la apariencia del personaje
function CharacterHandler:UpdateCharacterAppearance(player, character, playerData)
	if not playerData or not playerData.Equipment then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	for slot, itemInstance in pairs(playerData.Equipment) do
		local itemData = ItemConfig[itemInstance.itemId]
		if itemData and itemData.AccessoryId then
			-- Lógica para añadir accesorios
		end
	end
end

return CharacterHandler
