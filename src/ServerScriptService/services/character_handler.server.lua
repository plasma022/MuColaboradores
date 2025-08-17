--[[
	Archivo: CharacterHandler.lua
	Tipo: Script
	Ubicacin: ServerScriptService/
	Descripcin: Gestiona la aparicin de los personajes personalizados.
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

	local function safeRequireServer(pathParts)
		local current = ServerScriptService
		for _, part in ipairs(pathParts) do
			current = current:FindFirstChild(part) or current:WaitForChild(part, 5)
			if not current then
				warn("[CharacterHandler] No se encontró: " .. table.concat(pathParts, "."))
				return nil
			end
		end
		-- Si lo encontrado no es un ModuleScript, buscar entre descendientes o en todo ServerScriptService
		if not current:IsA("ModuleScript") then
			local found = nil
			for _, d in ipairs(current:GetDescendants()) do
				if d:IsA("ModuleScript") and d.Name == pathParts[#pathParts] then
					found = d
					break
				end
			end
			if not found then
				for _, d in ipairs(ServerScriptService:GetDescendants()) do
					if d:IsA("ModuleScript") and d.Name == pathParts[#pathParts] then
						found = d
						break
					end
				end
			end
			if found then
				current = found
			else
				warn("[CharacterHandler] Objeto encontrado no es ModuleScript: " .. tostring(current.Name))
				return nil
			end
		end
		local ok, res = pcall(require, current)
		if not ok then warn("[CharacterHandler] Error al require: ", res) return nil end
		return res
	end

	local DataManager = safeRequireServer({"core", "player_data_manager"})

local function safeRequireShared(name)
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
	if not shared then warn("[CharacterHandler] ReplicatedStorage.Shared no disponible") return nil end
	local module = shared:FindFirstChild(name) or shared:WaitForChild(name, 5)
	if not module then warn("[CharacterHandler] Módulo '"..name.."' no encontrado en Shared") return nil end
	local ok, res = pcall(require, module)
	if not ok then warn("[CharacterHandler] Error al require: ", res) return nil end
	return res
end

	local Comm = safeRequireShared("comm")

	if not DataManager then warn("[CharacterHandler] player_data_manager no disponible, funciones dependientes quedaran inactivas.") end
	if not Comm or not Comm.Server then warn("[CharacterHandler] Comm no disponible; eventos no seran enviados.") end

local isLoadingCharacter = {}

local function onCharacterDied(player)
	print(player.Name, "ha muerto. Reaparecer en 5 segundos.")
	task.wait(5)
	if player and player:IsDescendantOf(Players) then
		isLoadingCharacter[player] = false -- Liberamos el cerrojo para permitir la reaparicin.
		player:LoadCharacter()
	end
end

local function onCharacterAdded(character, player)
	if isLoadingCharacter[player] then return end
	isLoadingCharacter[player] = true

	if not DataManager then
		warn("[CharacterHandler] onCharacterAdded: DataManager no disponible para " .. player.Name)
		isLoadingCharacter[player] = false
		return
	end

	local profile = DataManager:GetProfile(player)
	local wait_cycles = 0
	while not profile and wait_cycles < 20 do
		print("[CharacterHandler] El perfil de", player.Name, "an no est listo, esperando...")
		task.wait(0.5)
		profile = DataManager:GetProfile(player)
		wait_cycles = wait_cycles + 1
	end

	if not profile then
		warn("[CharacterHandler] No se pudo obtener el perfil de", player.Name, "despus de esperar.")
		isLoadingCharacter[player] = false
		return
	end

	if profile.Data.Clase == "Default" then
		print("[CharacterHandler] Jugador con clase 'Default'. Omitiendo carga de modelo personalizado.")
		isLoadingCharacter[player] = false
		return
	end

	print("[CharacterHandler] Perfil encontrado. Cargando modelo de clase:", profile.Data.Clase)

	character:Destroy()

	local characterModel = ServerStorage:FindFirstChild(profile.Data.Clase)
	if not characterModel then
		warn("[CharacterHandler] No se encontr el modelo para la clase:", profile.Data.Clase)
		isLoadingCharacter[player] = false
		return
	end

	local newCharacter = characterModel:Clone()
	newCharacter.Name = player.Name
	player.Character = newCharacter
	newCharacter.Parent = workspace -- Parentamos el personaje antes de configurar el Humanoide.

	local humanoid = newCharacter:WaitForChild("Humanoid", 5) -- Aadimos un tiempo de espera de 5s

	-- == CORRECCIN CLAVE ==
	-- Enviamos los datos al HUD INMEDIATAMENTE despus de cargar el personaje.
	-- Esto asegura que la UI se actualice incluso si hay problemas con el Humanoide.
	local derivedStats = profile.DerivedStats or {}
	if Comm and Comm.Server then
		Comm.Server:Fire(player, "InitialStatsUpdate", {
		Nivel = profile.Data.Nivel,
		Clase = profile.Data.Clase,
			MaxHP = derivedStats.MaxHP,
			CurrentHP = derivedStats.MaxHP,
			MaxMP = derivedStats.MaxMP,
			CurrentMP = derivedStats.MaxMP,
		Zen = profile.Data.Zen,
		Skills = profile.Data.Skills,
		CurrentEXP = profile.Data.Experiencia,
		MaxEXP = 1000 -- Placeholder: Deberas calcular esto basado en el nivel
	})
	else
		warn("[CharacterHandler] Comm.Server no disponible, no se pudo enviar InitialStatsUpdate para " .. player.Name)
	end

	if humanoid then
		-- Si el Humanoide se encontr, configuramos su vida y muerte.
		humanoid.MaxHealth = derivedStats.MaxHP
		humanoid.Health = derivedStats.MaxHP

		humanoid.Died:Connect(function()
			onCharacterDied(player)
		end)
	else
		warn("[CharacterHandler] No se encontr un Humanoide en el modelo", newCharacter.Name, "despus de 5 segundos.")
	end
end

Players.PlayerAdded:Connect(function(player)
	isLoadingCharacter[player] = false
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character, player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	isLoadingCharacter[player] = nil
end)
