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

function Broadcast:BroadcastAudio(message)
    if not message or message == "" then
        return
    end

    local partyResult = C_ChatInfo.SendAddonMessage("ShortWave", message, "PARTY")
    local raidResult = C_ChatInfo.SendAddonMessage("ShortWave", message, "RAID")
end
