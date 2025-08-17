--[[
	CharacterHandler.lua
	Servicio que maneja eventos y lógica directamente relacionados con el modelo del personaje.
	Gestiona la carga de modelos de personaje personalizados, la muerte y la reaparición.
	Ubicación: ServerScriptService/services/
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Módulos
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ItemConfig = require(ReplicatedStorage.Shared.config.ItemConfig)

local CharacterHandler = {}

-- ATRIBUTOS DEL SERVICIO
CharacterHandler.PlayerDataService = nil
CharacterHandler.connections = {} -- Para guardar las conexiones de cada personaje
CharacterHandler.isLoadingCharacter = {} -- Cerrojo para evitar cargas múltiples

-- MÉTODOS
function CharacterHandler:Init()
	-- No se necesita nada en la inicialización
end

function CharacterHandler:Start(ServiceManager)
	-- Obtenemos referencias a otros servicios
	self.PlayerDataService = ServiceManager:GetService("PlayerDataService")

	Players.PlayerAdded:Connect(function(player)
		self.isLoadingCharacter[player] = false
		-- Conectamos una función que se ejecutará CADA VEZ que el personaje del jugador aparezca
		player.CharacterAdded:Connect(function(character)
			self:_onCharacterAdded(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		-- Limpiamos las conexiones y el cerrojo cuando el jugador se va
		self.isLoadingCharacter[player] = nil
		if self.connections[player] then
			for _, connection in ipairs(self.connections[player]) do
				connection:Disconnect()
			end
			self.connections[player] = nil
		end
	end)

	print("[CharacterHandler] Listo y escuchando apariciones de personajes.")
end

-- Se ejecuta cada vez que un personaje (re)aparece en el juego
function CharacterHandler:_onCharacterAdded(player, character)
	if self.isLoadingCharacter[player] then return end
	self.isLoadingCharacter[player] = true

	-- Esperamos un momento para que PlayerDataService cargue el perfil
	task.wait(0.5)
	local playerData = self.PlayerDataService:GetData(player)

	if not playerData or not playerData.PlayerClass or playerData.PlayerClass == "Default" then
		print(`[CharacterHandler] Jugador {player.Name} con clase Default. Usando personaje estándar.`)
		self.isLoadingCharacter[player] = false
		return
	end

	print(`[CharacterHandler] Perfil encontrado para {player.Name}. Cargando modelo de clase: {playerData.PlayerClass}`)
	
	local characterModel = ServerStorage:FindFirstChild(playerData.PlayerClass)
	if not characterModel then
		warn(`[CharacterHandler] No se encontró el modelo para la clase: {playerData.PlayerClass}`)
		self.isLoadingCharacter[player] = false
		return
	end

	-- Destruimos el personaje anterior y lo reemplazamos con el modelo de clase
	character:Destroy()
	local newCharacter = characterModel:Clone()
	newCharacter.Name = player.Name
	player.Character = newCharacter
	
	local humanoid = newCharacter:WaitForChild("Humanoid")
	humanoid.DisplayName = player.DisplayName
	
	-- Conectamos el evento de muerte del nuevo personaje
	self:_setupCharacterConnections(player, newCharacter)
	
	-- Equipamos los accesorios visuales al nuevo modelo
	self:UpdateCharacterAppearance(player, newCharacter)
	
	newCharacter.Parent = workspace
	self.isLoadingCharacter[player] = false
end

-- Configura las conexiones para un personaje recién creado
function CharacterHandler:_setupCharacterConnections(player, character)
	-- Limpiamos conexiones antiguas para este jugador
	if self.connections[player] then
		for _, connection in ipairs(self.connections[player]) do
			connection:Disconnect()
		end
	end
	self.connections[player] = {}

	local humanoid = character:WaitForChild("Humanoid")

	-- Conectamos el evento de muerte
	local diedConnection = humanoid.Died:Connect(function()
		self:_onCharacterDied(player)
	end)
	table.insert(self.connections[player], diedConnection)
end

-- Se ejecuta cuando el humanoide del personaje muere
function CharacterHandler:_onCharacterDied(player)
	print(`[CharacterHandler] El personaje de {player.Name} ha muerto.`)
	
	-- Aquí iría la lógica de penalización por muerte
	
	task.wait(5)
	if player and player:IsDescendantOf(Players) then
		self.isLoadingCharacter[player] = false -- Liberamos el cerrojo para permitir reaparición
		player:LoadCharacter()
	end
end

-- Función pública para actualizar la apariencia del personaje (añadir accesorios)
function CharacterHandler:UpdateCharacterAppearance(player, character)
	local playerData = self.PlayerDataService:GetData(player)
	if not playerData or not playerData.Equipment then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Lógica para añadir/quitar accesorios (armadura, cascos, etc.)
	for slot, itemInstance in pairs(playerData.Equipment) do
		local itemData = ItemConfig[itemInstance.itemId]
		if itemData and itemData.AccessoryId then
			-- Lógica para encontrar el accesorio y clonarlo
			-- Ejemplo: humanoid:AddAccessory(accessoryClone)
		end
	end
end

return CharacterHandler
