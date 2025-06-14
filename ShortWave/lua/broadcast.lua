local _, core = ...
core.Broadcast = {}
local Broadcast = core.Broadcast

function Broadcast:IsLeader(unit)
    --there's probably a neater way to write this
    --but tldr if leader/assistant is from a different realm, we have to check with the realm name
    --if leader/assistant is from the same realm, we have to check *without* the realm name
    local isLeader = UnitIsGroupLeader(unit)
    if not isLeader then
        isLeader = UnitIsGroupAssistant(unit)
        if not isLeader then
            local realmLessName = strsplit("-", unit)
            isLeader = UnitIsGroupLeader(realmLessName)
            if not isLeader then
                isLeader = UnitIsGroupAssistant(realmLessName)
            end
        end
    end
    return isLeader
end

function Broadcast:Setup()
    core.prefix = "Shortwave"
    C_ChatInfo.RegisterAddonMessagePrefix(core.prefix)
end

function Broadcast:BroadcastAudio(type, id, name, channel)
    if not Broadcast:IsLeader("player") or not id or not name or not channel or not ShortWaveVariables.broadcasting[channel] or id == "" or name == "" or channel == "" then
        return
    end

    local message = type .. ":" .. id .. ":" .. name .. ":" .. channel

    local raidResult = C_ChatInfo.SendAddonMessage(core.prefix, message, "RAID")
    if raidResult == 3 then
        print(
            "|cff0070ddShortwave: You are sending too many broadcast requests and being rate-limited by the server. Please wait a moment or don't loop any very short sounds.")
        print(
            "|cff0070ddIf you have your master volume set to 0, the blizzard API tells the addon that the sound instantly finished, which will cause it to go through the playlist instantly and also overload the broadcast.")
    end
    if core.Debug then
        print("Broadcasting audio:")
        print("Message: " .. message)
        print("Channel: " .. channel)
        print("Raid result: " .. tostring(raidResult))
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(_, _, prefix, message, _, sender)
    local senderName = strsplit("-", sender)
    if senderName == UnitName("player") or not Broadcast:IsLeader(sender) then
        return
    end

    if core.Debug then
        print("Received addon message:")
        print("Prefix: " .. prefix)
        print("Message: " .. message)
        print("Sender: " .. sender)
    end

    if prefix == core.prefix then
        local type, id, name, channel = strsplit(":", message)
        if type and id and name and channel and ShortWaveVariables.listening[channel] then
            if type == "play" then
                core.Player:PlaySongSingle(id, name, channel)
            elseif type == "pause" then
                core.Player:StopMusicOnChannel(channel)
            end
        end
    end
end)
