local _, core = ...
core.Channel = {}
local Channel = core.Channel

Channel.channels = {
    "Music",
    "Ambience",
    "SFX",
}

core.Channel.channelIndex = {
    [Channel.channels[1]] = 1,
    [Channel.channels[2]] = 2,
    [Channel.channels[3]] = 3,
}

core.Channel.colorMatch = {
    "blue",
    "green",
    "red",
}

core.Channel.LoopType = {
    true,
    true,
    false
}

core.Channel.defaultText = {
    "No music playing",
    "No ambience playing",
    "No SFX playing",
}

core.Channel.defaultColours = {
    { r = "0.1", g = "0.194", b = "0.941" },
    { b = "0.1", r = "0.194", g = "0.941" },
    { g = "0.1", b = "0.194", r = "0.941" }
}

core.Channel.searchCores = {
    [Channel.channels[1]] = { "music" },
    [Channel.channels[2]] = { "ambience" },
    [Channel.channels[3]] = { "items", "spells", "creature", "other" },
}

Channel.currentChannel = nil

function Channel:OnLoad()
    GroupMusicVariables.selectedChannel = GroupMusicVariables.selectedChannel or Channel.channels[1]
    Channel.currentChannel = GroupMusicVariables.selectedChannel
end

function Channel:ChangeChannel(channel)
    if channel == Channel.currentChannel then
        return
    end
    GroupMusicVariables.selectedChannel = channel
    Channel.currentChannel = channel
    core.PlayerWindow:SetColor(core.Channel.colorMatch[core.Channel.channelIndex[channel]] or "blue")
    core.PlayerWindow:SetDefaultText(core.Channel.defaultText[core.Channel.channelIndex[channel]] or "No sound playing")
    core.Playlist:RefreshPlaylists()
    core.Search:RefreshSearchBody()
    core.Player:UpdatePlayer()
end
