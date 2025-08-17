--[[
	ServiceManager.lua
	Módulo central para cargar, inicializar y gestionar todos los servicios del juego.
	Resuelve el problema de las dependencias circulares.
	Ubicación: ServerScriptService/core/
]]

local ServiceManager = {}
ServiceManager.Services = {} -- Directorio para almacenar todos los servicios cargados.

-- Función pública para obtener un servicio que ya ha sido iniciado.
function ServiceManager:GetService(serviceName)
	local service = self.Services[serviceName]
	if not service then
		warn("ServiceManager: Intento de obtener un servicio no existente o no cargado: " .. tostring(serviceName))
	end
	return service
end

-- El corazón del gestor. Carga e inicia todos los servicios en fases.
function ServiceManager:Start(servicesFolder)
	-- FASE 1: REQUERIR Y REGISTRAR TODOS LOS SERVICIOS
	-- Recorremos la carpeta de servicios y los cargamos en nuestro directorio.
	for _, serviceModule in ipairs(servicesFolder:GetChildren()) do
		if serviceModule:IsA("ModuleScript") then
			local success, service = pcall(require, serviceModule)
			if success then
				self.Services[serviceModule.Name] = service
				print(`[ServiceManager] Servicio cargado: {serviceModule.Name}`)
			else
				warn(`[ServiceManager] Fallo al cargar el servicio: {serviceModule.Name} | Error: {service}`)
			end
		end
	end

	-- FASE 2: INICIALIZAR TODOS LOS SERVICIOS
	-- Cada servicio puede preparar sus propias variables internas aquí, sin hablar con otros.
	for serviceName, service in pairs(self.Services) do
		if typeof(service.Init) == "function" then
			-- Usamos pcall para que un error en un servicio no detenga a los demás
			local success, err = pcall(function()
				service:Init()
			end)
			if not success then
				warn(`[ServiceManager] Error al inicializar el servicio {serviceName}: {err}`)
			end
		end
	end

	-- FASE 3: INICIAR TODOS LOS SERVICIOS
	-- Ahora que todos están cargados e inicializados, pueden empezar a comunicarse entre sí.
	for serviceName, service in pairs(self.Services) do
		if typeof(service.Start) == "function" then
			-- Le pasamos el propio ServiceManager por si lo necesitan para obtener otros servicios.
			local success, err = pcall(function()
				service:Start(self)
			end)
			if not success then
				warn(`[ServiceManager] Error al iniciar el servicio {serviceName}: {err}`)
			end
		end
	end
	
	print("[ServiceManager] Todos los servicios han sido iniciados correctamente.")
end

return ServiceManager
