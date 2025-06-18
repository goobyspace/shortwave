local _, core = ...
core.Broadcast = {}
local Broadcast = core.Broadcast

-- check if unit is the leader or assistant of the group
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

-- initialize broadcast by setting our prefix and registering it
-- this means the addon can listen to messages with this prefix
function Broadcast:Initialize()
    core.prefix = "Shortwave"
    C_ChatInfo.RegisterAddonMessagePrefix(core.prefix)
end

-- this function is called when we receive a version check from the addon
local function versionCheck(version, message)
    local version, beta = strsplit("-", version)
    if beta then
        -- if the version is an alpha or a beta version we don't wanna warn people about it
        return
    end
    -- x y z = x.y.z = 1.1.1 or 1.6.3 or 19.5.3 etc
    local x, y, z = strsplit(".", version)
    if not x or not y or not z then
        -- either i misspelled the release tag or its me :3c since the pre-release version is like, @project-version@ so y/z would be nil
        return
    end
    local lX, lY, lZ = strsplit(".", core.Version)
    if not lX or not lY or not lZ then
        -- if the current version is not set, we set it to the version we received
        core.Version = version
        print("|cff647afaShortwave:|r |cff86ff6e" .. message)
        return
    end
    -- if the version is higher than the current one, we set the version check
    if x > lX or y > lY or z > lZ then
        core.Version = version
        core.VersionMessage = message
        print("|cff647afaShortwave:|r |cff86ff6e" .. message)
    end
end

-- we send a version check to the group incase anyone has an older version of the addon
function Broadcast:SetVersionCheck(version, message)
    if message == nil or message == "" then
        message =
        "Newer version of Shortwave detected! Please update to get the latest features and bug fixes."
    end

    local groupFrame = CreateFrame("Frame")
    groupFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    groupFrame:SetScript("OnEvent", function()
        -- raid messages are sent to the party if you're not in a raid
        C_ChatInfo.SendAddonMessage(core.prefix, "version" .. ":" .. version .. ":" .. message, "RAID")
    end)
end

-- broadcast an audio to the group to either play or pause
function Broadcast:BroadcastAudio(type, id, name, channel)
    if not Broadcast:IsLeader("player") or not id or not name or not channel or not ShortWaveVariables.broadcasting[channel] or id == "" or name == "" or channel == "" then
        return
    end

    local message = type .. ":" .. id .. ":" .. name .. ":" .. channel

    -- raid messages are sent to the party if you're not in a raid
    local raidResult = C_ChatInfo.SendAddonMessage(core.prefix, message, "RAID")
    if raidResult == 3 then
        core.Player:StopSoundOnChannel(channel)
        print(
            "|cffff4a4aShortwave: You are sending too many broadcast requests and being rate-limited by the server. Please wait a moment or don't loop any very short sounds.")
        print(
            "|cffff4a4aIf you have your master volume set to 0, the blizzard API tells the addon that the sound instantly finished, which will cause it to go through the playlist instantly and also overload the broadcast.")
    end
    if ShortWaveVariables.Debug then
        print("Broadcasting audio:")
        print("Message: " .. message)
        print("Channel: " .. channel)
        print("Raid result: " .. tostring(raidResult))
    end
end

-- we use this frame to listen for addon messages that we registered for earlier
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(_, _, prefix, message, _, sender)
    if prefix == core.prefix then
        local senderName = strsplit("-", sender)
        if senderName == UnitName("player") then
            return
        end

        -- a message looks like this: play:12345:stormwind01:music
        -- this would play the sound 12345 with the name stormwind01 on the music channel
        -- then if the user is listenign to the music channel, we will send the sound to be played on that channel
        if ShortWaveVariables.Debug then
            print("Received addon message:")
            print("Prefix: " .. prefix)
            print("Message: " .. message)
            print("Sender: " .. sender)
        end
        local type, id, name, channel = strsplit(":", message)
        if type == "version" then
            local version = tonumber(id)
            if version then
                -- the version message goes type/version/message/nil
                -- so we use the equivelant of the id & name
                versionCheck(version, name)
            end
            return
        end
        if Broadcast:IsLeader(sender) and type and id and name and channel and ShortWaveVariables.listening[channel] then
            if type == "play" then
                core.Player:PlaySoundFromBroadcast(id, name, channel)
            elseif type == "pause" then
                core.Player:StopSoundOnChannel(channel)
            end
        end
    end
end)
