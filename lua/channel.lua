local _, core = ...
core.Channel = {}
local Channel = core.Channel

Channel.channels = {
    "Music",
    "Ambience",
    "SFX",
}

local channelIndex = {
    [Channel.channels[1]] = 1,
    [Channel.channels[2]] = 2,
    [Channel.channels[3]] = 3,
}

local colorMatch = {
    "blue",
    "green",
    "red",
}

core.Channel.defaultText = {
    "No music playing",
    "No ambience playing",
    "No SFX playing",
}

Channel.currentChannel = nil

function Channel:ChangeChannel(channel)
    if channel == Channel.currentChannel then
        return
    end
    GroupMusicVariables.selectedChannel = channel
    core.PlayerWindow:SetColor(colorMatch[channelIndex[channel]] or "blue")
    core.PlayerWindow:SetDefaultText(core.Channel.defaultText[channelIndex[channel]] or "No sound playing")
end
