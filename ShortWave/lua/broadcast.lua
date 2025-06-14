local _, core = ...
core.Broadcast = {}
local Broadcast = core.Broadcast

function Broadcast:IsLeader(unit)
    local isLeader = UnitIsGroupLeader(unit)
    if not isLeader then
        isLeader = UnitIsGroupAssistant(unit)
    end
    return isLeader
end

function Broadcast:BroadcastAudio(id, name, channel)
    if not Broadcast:IsLeader("player") or not id or not name or not channel or id == "" or name == "" or channel == "" then
        return
    end

    local message = id .. ":" .. name .. ":" .. channel

    local raidResult = C_ChatInfo.SendAddonMessage("ShortWave", message, "RAID")
    if core.Debug then
        print("Broadcasting audio:")
        print("Message: " .. message)
        print("Channel: " .. channel)
        print("Raid result: " .. tostring(raidResult))
    end
end
