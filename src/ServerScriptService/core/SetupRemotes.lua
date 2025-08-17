local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
    remoteEventsFolder = Instance.new("Folder")
    remoteEventsFolder.Name = "RemoteEvents"
    remoteEventsFolder.Parent = ReplicatedStorage
end

local events = {
    "EquipItem",
    "UpdateInventory",
    "DropItemEvent",
    "UpdateStats"
}

for _, eventName in ipairs(events) do
    if not remoteEventsFolder:FindFirstChild(eventName) then
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = remoteEventsFolder
    end
end
