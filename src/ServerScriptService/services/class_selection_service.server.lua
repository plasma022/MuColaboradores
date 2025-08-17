--[[
    Archivo: ClassSelectionService.lua
    Tipo: Script
    Ubicacin: ServerScriptService/
    Descripcin: Maneja la lgica del servidor para la seleccin de clases.
--]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local function safeRequireShared(name)
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
	if not shared then warn("[ClassSelection] ReplicatedStorage.Shared no disponible") return nil end
	local module = shared:FindFirstChild(name) or shared:WaitForChild(name, 5)
	if not module then warn("[ClassSelection] Módulo '"..name.."' no encontrado en Shared") return nil end
	local ok, res = pcall(require, module)
	if not ok then warn("[ClassSelection] Error al require: ", res) return nil end
	return res
end

local function safeRequireServer(folderName, moduleName)
	local folder = ServerScriptService:FindFirstChild(folderName) or ServerScriptService:WaitForChild(folderName, 5)
	if not folder then warn("[ClassSelection] Carpeta '"..folderName.."' no encontrada en ServerScriptService") return nil end
	local module = folder:FindFirstChild(moduleName) or folder:FindFirstChildWhichIsA("ModuleScript") or folder:WaitForChild(moduleName, 5)
	if not module then warn("[ClassSelection] Módulo '"..moduleName.."' no encontrado en "..folderName) return nil end
	if not module:IsA("ModuleScript") then
		-- Intentar encontrar un ModuleScript dentro
		local childModule = module:FindFirstChildWhichIsA("ModuleScript") or folder:FindFirstChild(moduleName)
		if childModule and childModule:IsA("ModuleScript") then
			module = childModule
		else
			warn("[ClassSelection] Objeto encontrado no es ModuleScript: " .. tostring(module.Name))
			return nil
		end
	end
	local ok, res = pcall(require, module)
	if not ok then warn("[ClassSelection] Error al require server: ", res) return nil end
	return res
end

local DataManager = safeRequireServer("core", "player_data_manager")
local Comm = safeRequireShared("comm")
local CharacterFormulas = safeRequireShared("character_formulas")

if not DataManager then
	warn("[ClassSelection] Objeto encontrado no es ModuleScript: player_data_manager or failed to require it. Operaciones dependientes quedaran inactivas.")
end
if not Comm then
	warn("[ClassSelection] Comm no disponible; operaciones de GUI no se podrán disparar.")
end

-- Diccionario con los datos iniciales de cada clase para una transicin fcil.
local CLASS_STARTING_DATA = {
	["DarkKnight"] = {
		-- == CORRECCIN CLAVE: Ahora se asignan los stats con los nombres correctos ==
		EstadisticasBase = {
			Fuerza = CharacterFormulas.CLASS_BASE_STATS["DarkKnight"].Fuerza,
			Agilidad = CharacterFormulas.CLASS_BASE_STATS["DarkKnight"].Agilidad,
			Vitalidad = CharacterFormulas.CLASS_BASE_STATS["DarkKnight"].Vitalidad,
			Energia = CharacterFormulas.CLASS_BASE_STATS["DarkKnight"].Energia,
		},
		Skills = {"Cyclone", "TwistingSlash", "Inner", "DeathStab"}
	},
	["DarkWizard"] = {
		EstadisticasBase = {
			Fuerza = CharacterFormulas.CLASS_BASE_STATS["DarkWizard"].Fuerza,
			Agilidad = CharacterFormulas.CLASS_BASE_STATS["DarkWizard"].Agilidad,
			Vitalidad = CharacterFormulas.CLASS_BASE_STATS["DarkWizard"].Vitalidad,
			Energia = CharacterFormulas.CLASS_BASE_STATS["DarkWizard"].Energia,
		},
		Skills = {"EnergyBall", "EvilSpirit", "ManaShield", "IceStorm"}
	},
	["FairyElf"] = {
		EstadisticasBase = {
			Fuerza = CharacterFormulas.CLASS_BASE_STATS["FairyElf"].Fuerza,
			Agilidad = CharacterFormulas.CLASS_BASE_STATS["FairyElf"].Agilidad,
			Vitalidad = CharacterFormulas.CLASS_BASE_STATS["FairyElf"].Vitalidad,
			Energia = CharacterFormulas.CLASS_BASE_STATS["FairyElf"].Energia,
		},
		Skills = {"TripleShot", "GreaterDefense", "GreaterDamage", "IceShot"}
	}
}

-- Escuchamos el evento que enva el cliente desde la GUI de seleccin.
if Comm and Comm.Server and DataManager then
	Comm.Server:On("SelectClass", function(player, selectedClass)
		local profile = DataManager:GetProfile(player)
		if not profile or profile.Data.Clase ~= "Default" then
			return
		end

	local classData = CLASS_STARTING_DATA[selectedClass]
	if not classData then
		warn("El jugador", player.Name, "intent seleccionar una clase invlida:", selectedClass)
		return
	end

	-- Actualizamos el perfil del jugador con los datos de la nueva clase.
	profile.Data.Clase = selectedClass
	profile.Data.EstadisticasBase = classData.EstadisticasBase
	profile.Data.Skills = classData.Skills
	profile.Data.PuntosDeStatsDisponibles = 0

	DataManager:CalculateDerivedStats(profile)
    DataManager:sendFullStatsToClient(player)

	print("[ClassSelection] El jugador", player.Name, "ha seleccionado la clase:", selectedClass)

	player:LoadCharacter()
	end)
else
	warn("[ClassSelection] No se registró SelectClass porque Comm o DataManager no están disponibles.")
end

-- Esta funcin revisa si el jugador necesita elegir una clase al entrar.
local function checkPlayerClass(player)
	print("[ClassSelection] Revisando la clase para el jugador:", player.Name)
	if not DataManager then
		warn("[ClassSelection] checkPlayerClass: DataManager no disponible; omitiendo comprobacion para " .. player.Name)
		return
	end

	local profile = DataManager:GetProfile(player)
	local wait_cycles = 0

	while not profile and wait_cycles < 10 do
		print("[ClassSelection] El perfil de", player.Name, "no est listo, esperando...")
		task.wait(0.5)
		profile = DataManager:GetProfile(player)
		wait_cycles = wait_cycles + 1
	end

	if not profile then
		warn("[ClassSelection] Tiempo de espera agotado para el perfil de:", player.Name)
		return
	end

	print("[ClassSelection] Perfil encontrado. La clase actual es:", profile.Data.Clase)

	if profile.Data.Clase == "Default" then
		print("[ClassSelection] La clase es 'Default'. Mostrando la GUI de seleccin.")
		Comm.Server:Fire(player, "ShowClassSelection")
	else
		print("[ClassSelection] El jugador ya tiene una clase. Omitiendo GUI.")
	end
end

Players.PlayerAdded:Connect(checkPlayerClass)