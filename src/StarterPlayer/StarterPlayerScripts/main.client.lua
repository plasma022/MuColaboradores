--[[
	main.client.lua (Versión Actualizada)
	Punto de entrada del CLIENTE.
	Carga e inicia todos los controladores, permitiendo que se comuniquen entre sí.
	Ubicación: StarterPlayer/StarterPlayerScripts/
]]

print("Iniciando cliente...")

local controllersFolder = script.Parent.controllers
local controllers = {}

-- FASE 1: Cargar todos los controladores en una tabla
for _, controllerModule in ipairs(controllersFolder:GetChildren()) do
    if controllerModule:IsA("ModuleScript") then
        local success, controller = pcall(require, controllerModule)
        if success then
            controllers[controllerModule.Name] = controller
        else
            warn(`[Cliente] Fallo al cargar el controlador: {controllerModule.Name} | Error: {controller}`)
        end
    end
end

-- FASE 2: Iniciar todos los controladores, pasándoles la tabla completa
-- Esto permite que un controlador pueda acceder a otro (Inyección de Dependencias)
for name, controller in pairs(controllers) do
    if typeof(controller.Start) == "function" then
        controller:Start(controllers)
        print(`[Cliente] Controlador iniciado: {name}`)
    end
end

print("Cliente iniciado y todos los controladores están activos.")
