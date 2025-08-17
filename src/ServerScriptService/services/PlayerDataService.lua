--[[
    Archivo: PlayerDataManager.lua
    Tipo: ModuleScript
    Ubicacion: ServerScriptService/
    Descripcion: Maneja el guardado y carga de datos de jugadores, y calcula sus stats totales.
--]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()

-- Modulos requeridos
local ProfileService = require(game:GetService("ServerScriptService").lib.profile_service)
local InventoryManager = require(ServerScriptService.Modules.inventory_manager) -- Required InventoryManager here

local DataManager = {} -- Define the DataManager table
DataManager.Profiles = {} -- Initialize Profiles table within DataManager

local function safeRequireShared(name)
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
	if not shared then warn("[PlayerDataManager] ReplicatedStorage.Shared no disponible") return nil end
	local module = shared:FindFirstChild(name) or shared:WaitForChild(name, 5)
	if not module then warn("[PlayerDataManager] Módulo '"..name.."' no encontrado en Shared") return nil end
	local ok, res = pcall(require, module)
	if not ok then warn("[PlayerDataManager] Error al require: ", res) return nil end
	return res
end

local PlayerConfig = safeRequireShared("player_config")
if not PlayerConfig then warn("[PlayerDataManager] PlayerConfig no disponible. Abortando.") return nil end
local Formulas = safeRequireShared("character_formulas")
if not Formulas then warn("[PlayerDataManager] Formulas no disponible. Abortando.") return nil end
local Comm = safeRequireShared("comm")
if not Comm then warn("[PlayerDataManager] Comm no disponible. Abortando.") return nil end

-- Mover safeRequireServer aquí, fuera de la función onPlayerAdded
local function safeRequireServer(pathParts)
	local current = ServerScriptService
	for _, part in ipairs(pathParts) do
		current = current:FindFirstChild(part) or current:WaitForChild(part, 5)
		if not current then
			warn("[PlayerDataManager] No se encontró: " .. table.concat(pathParts, "."))
			return nil
		end
		end
	local ok, res = pcall(require, current)
	if not ok then warn("[PlayerDataManager] Error al require: ", res) return nil end
	return res
end

function DataManager:onPlayerAdded(player) -- Make onPlayerAdded a method of DataManager
    if not player or not player:IsA("Player") then -- Añadir esta verificación
        warn("[PlayerDataManager] onPlayerAdded llamado con un objeto 'player' inválido o nulo. Abortando.")
        return
    end
	local profile

	if IS_STUDIO then
		-- MockData está en ServerScriptService.core.mock_data
		local MockData = safeRequireServer({"core", "mock_data"})
		profile = MockData.LoadProfileAsync(player)
	else
        -- ... (codigo de carga de ProfileService sin cambios) ...
	end

	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			DataManager.Profiles[player] = nil -- Use DataManager.Profiles
			player:Kick("Tu perfil ha sido liberado. Por favor, unete de nuevo.")
		end)

		if player:IsDescendantOf(Players) then
			DataManager.Profiles[player] = profile -- Use DataManager.Profiles
            
			-- --- INICIALIZACION DE MODULOS ---
			-- Se asegura que el inventario del jugador este inicializado.
			if InventoryManager then
				InventoryManager.InitializeInventory(profile)
				-- Se inicializan los bonus de items en una tabla vacia.
				profile.ItemBonuses = InventoryManager.GetTotalEquippedStats(profile) or {}
			else
				profile.ItemBonuses = {}
				warn("[PlayerDataManager] InventoryManager no disponible para inicializar inventario de " .. player.Name)
			end

			DataManager:CalculateDerivedStats(profile) -- Call as method
			print("Perfil cargado para", player.Name)
		else
			profile:Release()
		end
	else
		warn("No se pudo cargar el perfil para " .. player.Name .. ". Causa probable: Throttling de DataStore.")
		player:Kick("No se pudo cargar tu perfil (servidor ocupado). Intenta de nuevo en unos minutos.")
	end
end

function DataManager:onPlayerRemoving(player) -- Make onPlayerRemoving a method of DataManager
	local profile = DataManager.Profiles[player] -- Use DataManager.Profiles
	if profile then
		profile:Release()
	end
end

function DataManager:CalculateDerivedStats(profile)
    if not profile or not profile.Player then -- Añadir esta verificación
        warn("[PlayerDataManager] CalculateDerivedStats llamado con un perfil o jugador inválido.")
        return
    end
    -- Implement calculation of derived stats here
    -- For now, it's a placeholder to prevent errors.
    print("[PlayerDataManager] Calculando stats derivados para", profile.Player.Name)
end

function DataManager:GetProfile(player)
    -- Placeholder for GetProfile implementation
    -- This function should return the player's profile from DataManager.Profiles
    return DataManager.Profiles[player]
end

function DataManager:sendFullStatsToClient(player)
    -- Placeholder for sendFullStatsToClient implementation
    -- This function should send the player's stats to the client using Comm
    print("[PlayerDataManager] Enviando stats completos al cliente para", player.Name)
    if Comm and Comm.Client and DataManager.Profiles[player] then
        Comm.Client:Fire(player, "UpdateStats", DataManager.Profiles[player].Data.EstadisticasTotales)
    end
end

return PlayerDataService
