local _, core = ...
core.Channel = {}
local Channel = core.Channel

-- these channels identify a bunch of things, including the visual of the player depending on what channel is selected
-- the player function has a soundhandle it can track per channel
-- this means that the player can play multiple sounds at once, one per channel
-- the search function has different data per channel
-- and the playlists are unique per channel too
-- this means that each channel can only play their own kind of sound
Channel.channels = {
    "Music",
    "Ambience",
    "SFX",
}

-- index of each channel
core.Channel.channelIndex = {
    [Channel.channels[1]] = 1,
    [Channel.channels[2]] = 2,
    [Channel.channels[3]] = 3,
}

-- the colours of each channel
core.Channel.colorMatch = {
    "blue",
    "green",
    "red",
}

-- the loop type of each channel
core.Channel.LoopType = {
    true,
    true,
    false
}

-- the default text for each channel
core.Channel.defaultText = {
    "No music playing",
    "No ambience playing",
    "No SFX playing",
}

-- the default colors for each channel's background textures
core.Channel.defaultColours = {
    { r = "0.1", g = "0.194", b = "0.941" },
    { b = "0.1", r = "0.194", g = "0.941" },
    { g = "0.1", b = "0.194", r = "0.941" }
}

-- the search data for each channel
-- the third channel is SFX which is split into multiple categories due to the fact that there's 160k creature SFX
-- and world of warcraft doesn't like it when we put all of those IDs/paths/names in one file
core.Channel.searchData = {
    [Channel.channels[1]] = { "music" },
    [Channel.channels[2]] = { "ambience" },
    [Channel.channels[3]] = { "character", "spells", "creature", "other" },
}

-- the currently selected channel
Channel.currentChannel = nil

-- set the currently selected channel to the saved channel or the first channel on first launch
function Channel:Initialize()
    ShortWaveVariables.selectedChannel = ShortWaveVariables.selectedChannel or Channel.channels[1]
    Channel.currentChannel = ShortWaveVariables.selectedChannel
end

-- Sets a new channel and (re)sets all the windows and tabs to the appropriate value for the new channel.
-- E.G. If you had playlist selected on the music channel, but then switched to ambience where you had search selected,
-- it will switch to the search tab and refresh the search body with the ambience search data.
function Channel:ChangeChannel(channel)
    if channel == Channel.currentChannel then
        return
    end
    ShortWaveVariables.selectedChannel = channel
    Channel.currentChannel = channel
    core.PlayerWindow:SetColor(core.Channel.colorMatch[core.Channel.channelIndex[channel]] or "blue")
    core.PlayerWindow:SetDefaultText(core.Channel.defaultText[core.Channel.channelIndex[channel]] or "No sound playing")
    core.PlayerWindow:SetIcon()
    core.PlayerWindow:SetBroadcasting()
    core.PlayerWindow:SetListening()
    core.PlayerWindow:RefreshTabs()
    core.Player:UpdatePlayer()
end
