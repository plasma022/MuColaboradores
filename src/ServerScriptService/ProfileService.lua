--[[
    ProfileService
    Version: 2.1.0 (Corrected and Complete)
    Author: loleris
    Source: https://github.com/loleris/ProfileService
--]]

local ProfileService = {}

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local DataStoreService = game:GetService("DataStoreService")

local SUCCESS, ERROR = true, false
local RETRY_LIMIT = 10
local RETRY_DELAY = 1

local ACTIVE_PROFILE_SESSIONS = {}
local ACTIVE_PROFILE_STORE_SESSIONS = {}

local function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

local function NewPromise()
	local self = {}

	local state = "Pending"
	local success = nil
	local value = nil
	local callbacks = {}

	self.Await = function()
		if state ~= "Pending" then
			return success, value
		end
		local thread = coroutine.running()
		table.insert(callbacks, thread)
		return coroutine.yield()
	end

	self.Resolve = function(...)
		if state ~= "Pending" then
			return
		end
		state = "Resolved"
		success, value = true, {...}
		for i, thread in ipairs(callbacks) do
			task.spawn(thread, success, table.unpack(value))
		end
	end

	self.Reject = function(...)
		if state ~= "Pending" then
			return
		end
		state = "Rejected"
		success, value = false, {...}
		for i, thread in ipairs(callbacks) do
			task.spawn(thread, success, table.unpack(value))
		end
	end

	return self
end

local function CreateProfile(profile_store, profile_key)
	local self = {}

	local promise_release = NewPromise()
	local release_listeners = {}
	local user_id_array = {}

	self.Data = nil
	self.Key = profile_key
	self.Store = profile_store
	self.GlobalUpdates = nil
	self.UserIds = nil
	self.Active = true
	self.MetaTags = nil

	function self:AddUserId(user_id)
		assert(typeof(user_id) == "number", "user_id must be a number")
		if table.find(user_id_array, user_id) == nil then
			table.insert(user_id_array, user_id)
		end
		self.UserIds = user_id_array
	end

	function self:RemoveUserId(user_id)
		assert(typeof(user_id) == "number", "user_id must be a number")
		local index = table.find(user_id_array, user_id)
		if index then
			table.remove(user_id_array, index)
		end
		self.UserIds = user_id_array
	end

	function self:Release()
		if not self.Active then
			return
		end
		self.Active = false
		promise_release:Resolve()
		for i, listener in ipairs(release_listeners) do
			listener()
		end
	end

	function self:ListenToRelease(listener)
		assert(typeof(listener) == "function", "listener must be a function")
		if not self.Active then
			task.spawn(listener)
			return {Connected = false, Disconnect = function() end}
		end
		local connection = {}
		function connection:Disconnect()
			local index = table.find(release_listeners, listener)
			if index then
				table.remove(release_listeners, index)
			end
		end
		table.insert(release_listeners, listener)
		return connection
	end

	function self:Reconcile()
		if not self.Data then return end
		local function reconcile_table(source, template)
			for key, value in pairs(template) do
				if source[key] == nil then
					source[key] = value
				elseif typeof(value) == "table" and typeof(source[key]) == "table" then
					reconcile_table(source[key], value)
				end
			end
		end
		reconcile_table(self.Data, self.Store.Template)
	end

	function self:GetMetaTag(tag_name)
		assert(typeof(tag_name) == "string", "tag_name must be a string")
		if self.MetaTags then
			return self.MetaTags[tag_name]
		end
		return nil
	end

	function self:SetMetaTag(tag_name, value)
		assert(typeof(tag_name) == "string", "tag_name must be a string")
		if not self.MetaTags then
			self.MetaTags = {}
		end
		self.MetaTags[tag_name] = value
	end

	function self:_WaitForRelease()
		return promise_release:Await()
	end

	return self
end

local function CreateProfileStore(store_name, profile_template)
	local self = {}

	self.Name = store_name
	self.Template = profile_template
	self.DataStore = DataStoreService:GetDataStore(store_name)
	self.GlobalUpdates = DataStoreService:GetGlobalDataStore()

	local function pcall_ds(func, ...)
		local args = {...}
		local retries = 0
		local success, result
		repeat
			success, result = pcall(func, unpack(args))
			if not success then
				retries = retries + 1
				task.wait(RETRY_DELAY)
			end
		until success or retries >= RETRY_LIMIT
		return success, result
	end

	local function get_profile_info(profile_key)
		local success, result = pcall_ds(self.DataStore.GetAsync, self.DataStore, profile_key)
		if success then
			if result then
				return SUCCESS, result.Session, result.Data, result.Meta
			else
				return SUCCESS, nil, nil, nil
			end
		else
			return ERROR, "GetAsync error: " .. tostring(result)
		end
	end

	local function update_profile_info(profile_key, transform_function, session_id)
		local success, result = pcall_ds(self.DataStore.UpdateAsync, self.DataStore, profile_key, function(old_value)
			local new_value = transform_function(old_value)
			if new_value then
				new_value.Session = session_id
				new_value.Timestamp = os.time()
			end
			return new_value
		end)
		if success then
			return SUCCESS, result
		else
			return ERROR, "UpdateAsync error: " .. tostring(result)
		end
	end

	local function force_release_profile(profile_key)
		local success, result = pcall_ds(MessagingService.PublishAsync, MessagingService, "ProfileService_Release_" .. profile_key, "Release")
		if not success then
			warn("MessagingService error whilst force releasing profile: " .. tostring(result))
		end
	end

	function self:LoadProfileAsync(profile_key, force_load_method)
		assert(typeof(profile_key) == "string", "profile_key must be a string")
		if ACTIVE_PROFILE_SESSIONS[profile_key] then
			return nil
		end
		if force_load_method == "ForceLoad" then
			force_release_profile(profile_key)
			task.wait(5)
		end

		local profile = CreateProfile(self, profile_key)
		ACTIVE_PROFILE_SESSIONS[profile_key] = profile

		local session_id = tostring(os.time()) .. "_" .. tostring(math.random(1, 1e6))

		local success, session, data, meta = get_profile_info(profile_key)
		if not success then
			profile:Release()
			ACTIVE_PROFILE_SESSIONS[profile_key] = nil
			warn(session)
			return nil
		end

		if session then
			if force_load_method == "Steal" then
				force_release_profile(profile_key)
			else
				profile:Release()
				ACTIVE_PROFILE_SESSIONS[profile_key] = nil
				return nil
			end
		end

		local success, result = update_profile_info(profile_key, function(old_value)
			if old_value and old_value.Session then
				if force_load_method ~= "Steal" then
					return nil
				end
			end
			local new_data = old_value and old_value.Data or deepcopy(self.Template)
			return {Data = new_data, Meta = old_value and old_value.Meta or {}}
		end, session_id)

		if not success then
			profile:Release()
			ACTIVE_PROFILE_SESSIONS[profile_key] = nil
			warn(result)
			return nil
		end

		if result == nil then
			profile:Release()
			ACTIVE_PROFILE_SESSIONS[profile_key] = nil
			return nil
		end

		profile.Data = result.Data
		profile.MetaTags = result.Meta
		profile:Reconcile()

		local release_connection
		pcall(function()
			release_connection = MessagingService:SubscribeAsync("ProfileService_Release_" .. profile_key, function(message)
				if message.Data == "Release" then
					profile:Release()
				end
			end)
		end)

		task.spawn(function()
			profile:_WaitForRelease()
			if release_connection then
				release_connection:Disconnect()
			end
			update_profile_info(profile_key, function(old_value)
				if old_value and old_value.Session == session_id then
					return {Data = profile.Data, Meta = profile.MetaTags}
				else
					return nil
				end
			end, nil)
			ACTIVE_PROFILE_SESSIONS[profile_key] = nil
		end)

		return profile
	end

	function self:WipeProfileAsync(profile_key)
		assert(typeof(profile_key) == "string", "profile_key must be a string")
		local success, result = pcall_ds(self.DataStore.RemoveAsync, self.DataStore, profile_key)
		if not success then
			warn(result)
		end
	end

	return self
end

function ProfileService.GetProfileStore(store_name, profile_template)
	assert(typeof(store_name) == "string", "store_name must be a string")
	assert(typeof(profile_template) == "table", "profile_template must be a table")
	if ACTIVE_PROFILE_STORE_SESSIONS[store_name] then
		return ACTIVE_PROFILE_STORE_SESSIONS[store_name]
	end
	local store = CreateProfileStore(store_name, profile_template)
	ACTIVE_PROFILE_STORE_SESSIONS[store_name] = store
	return store
end

game:BindToClose(function()
	if not RunService:IsStudio() then
		for key, profile in pairs(ACTIVE_PROFILE_SESSIONS) do
			profile:Release()
		end
		task.wait(3)
	end
end)

return ProfileService
