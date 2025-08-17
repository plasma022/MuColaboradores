--[[
    Archivo: MockData.lua
    Tipo: ModuleScript
    Ubicacion: ServerScriptService/
    Descripcion: Simula la carga de datos para pruebas ropidas en Roblox Studio.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local function safeRequireShared(name)
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
	if not shared then warn("[MockData] ReplicatedStorage.Shared no disponible") return nil end
	local module = shared:FindFirstChild(name) or shared:WaitForChild(name, 5)
	if not module then warn("[MockData] Módulo '"..name.."' no encontrado en Shared") return nil end
	local ok, res = pcall(require, module)
	if not ok then warn("[MockData] Error al require: ", res) return nil end
	return res
end

local PlayerConfig = safeRequireShared("player_config")

local function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else
		copy = orig
	end
	return copy
end

local MockData = {}

function MockData.LoadProfileAsync(player)
    if not player or not player:IsA("Player") then
        warn("[MockData] LoadProfileAsync llamado con un objeto 'player' inválido o nulo.")
        return nil -- O un perfil vacío si es preferible
    end
	print("--- USANDO DATOS SIMULADOS (MOCK DATA) PARA " .. player.Name .. " ---")

	local fakeProfile = {}
	fakeProfile.Data = deepcopy(PlayerConfig)

	function fakeProfile:ListenToRelease(callback) end
	function fakeProfile:Reconcile() end
	function fakeProfile:AddUserId(id) end
	function fakeProfile:Release()
		print("--- DATOS SIMULADOS LIBERADOS PARA " .. player.Name .. " ---")
	end

	return fakeProfile
end

return MockData
