-------------------------------
-- Namespaces & Variables
-------------------------------
local _, core = ...
core.Player = {}
local Player = core.Player

Player.currentPlaylist = {}
Player.currentPlaylistIndex = {}
Player.currentlyPlaying = {}
Player.currentSoloIndex = {}
Player.currentId = {}
local firstFrame = {}
local currentName = {}
local currentText = {}

local cvarInitial

Player.UpdateFrame = {}
for _, value in ipairs(core.Channel.channels) do
    Player.UpdateFrame[value] = CreateFrame("Frame", "ShortWavePlayerUpdateFrame" .. value)
    Player.UpdateFrame[value]:SetScript("OnUpdate", nil)
end

local function UpdateText()
    core.PlayerWindow:SetText(currentText[core.Channel.currentChannel] or
        core.Channel.defaultText[core.Channel.channelIndex[core.Channel.currentChannel]])
end

function Player:UpdatePlayer()
    UpdateText()
    if Player.currentlyPlaying[core.Channel.currentChannel] then
        core.PlayerWindow.window.playPauseButton:SetChecked(true)
        core.PlayerWindow.window.playPauseButton:Enable()
    elseif Player.currentId[core.Channel.currentChannel] and currentName[core.Channel.currentChannel] then
        core.PlayerWindow.window.playPauseButton:SetChecked(false)
        core.PlayerWindow.window.playPauseButton:Enable()
    else
        core.PlayerWindow.window.playPauseButton:SetChecked(false)
        core.PlayerWindow.window.playPauseButton:Disable()
    end
    if Player.currentPlaylist[core.Channel.currentChannel] and #Player.currentPlaylist[core.Channel.currentChannel].songs > 0 then
        core.PlayerWindow.window.previousButton:Enable()
        core.PlayerWindow.window.nextButton:Enable()
    else
        core.PlayerWindow.window.previousButton:Disable()
        core.PlayerWindow.window.nextButton:Disable()
    end
end

local function ZeroFrameAudio(localChannel)
    -- stop EVERYTHING on this channel
    Player.UpdateFrame[localChannel]:SetScript("OnUpdate", nil)
    Player.currentlyPlaying[localChannel] = nil
    Player.currentId[localChannel] = nil
    Player.currentPlaylist[localChannel] = nil
    Player.currentPlaylistIndex[localChannel] = 1
    Player.currentSoloIndex[localChannel] = nil
    currentName[localChannel] = nil
    currentText[localChannel] = "No audio for ID"
    UpdateText()
    core.PlayerWindow:RefreshTabs()
    core.PlayerWindow.window.playPauseButton:SetChecked(false)
    core.PlayerWindow.window.playPauseButton:Disable()
    core.PlayerWindow.window.previousButton:Disable()
    core.PlayerWindow.window.nextButton:Disable()
end


local function LoopCurrentlyPlaying(self)
    local localChannel
    for playerCore, frame in pairs(Player.UpdateFrame) do
        if frame == self then
            localChannel = playerCore
        end
    end
    if Player.currentlyPlaying[localChannel] and Player.currentPlaylist[localChannel] then
        local isPlaying = C_Sound.IsPlaying(Player.currentlyPlaying[localChannel])
        if not isPlaying then
            if firstFrame[localChannel] then
                ZeroFrameAudio(localChannel)
                return
            end
            Player.currentPlaylistIndex[localChannel] = Player.currentPlaylistIndex[localChannel] + 1
            if Player.currentPlaylistIndex[localChannel] > #Player.currentPlaylist[localChannel].songs then
                Player.currentPlaylistIndex[localChannel] = 1
            end
            Player:PlayNextSongInPlaylist(localChannel)
        end
    elseif Player.currentlyPlaying[localChannel] and core.Channel.LoopType[core.Channel.channelIndex[localChannel]] then
        local isPlaying = C_Sound.IsPlaying(Player.currentlyPlaying[localChannel])
        if not isPlaying then
            if firstFrame[localChannel] then
                ZeroFrameAudio(localChannel)
                return
            end
            if Player.currentId[localChannel] and currentName[localChannel] then
                Player:PlaySongSingle(Player.currentId[localChannel], currentName[localChannel], localChannel)
            end
        end
    elseif Player.currentlyPlaying[localChannel] and not core.Channel.LoopType[core.Channel.channelIndex[localChannel]] then
        local isPlaying = C_Sound.IsPlaying(Player.currentlyPlaying[localChannel])
        if not isPlaying then
            if firstFrame[localChannel] then
                ZeroFrameAudio(localChannel)
                return
            end
            Player:PauseSong()
            self:SetScript("OnUpdate", nil)
        end
    else
        self:SetScript("OnUpdate", nil)
    end
    firstFrame[localChannel] = false
end

local function EmptyPlaylist()
    currentText[core.Channel.currentChannel] = "No playlist selected"
    UpdateText()
    core.PlayerWindow.window.previousButton:Disable()
    core.PlayerWindow.window.nextButton:Disable()
end

function Player:NextSongInPlaylist()
    if not Player.currentPlaylist[core.Channel.currentChannel] or #Player.currentPlaylist[core.Channel.currentChannel].songs == 0 then
        EmptyPlaylist()
        return
    end
    Player.currentPlaylistIndex[core.Channel.currentChannel] = Player.currentPlaylistIndex[core.Channel.currentChannel] +
        1
    if Player.currentPlaylistIndex[core.Channel.currentChannel] > #Player.currentPlaylist[core.Channel.currentChannel].songs then
        Player.currentPlaylistIndex[core.Channel.currentChannel] = 1
    end
    Player:PlayNextSongInPlaylist(core.Channel.currentChannel)
end

function Player:PreviousSongInPlaylist()
    if not Player.currentPlaylist[core.Channel.currentChannel] or #Player.currentPlaylist[core.Channel.currentChannel].songs == 0 then
        EmptyPlaylist()
        return
    end
    Player.currentPlaylistIndex[core.Channel.currentChannel] = Player.currentPlaylistIndex[core.Channel.currentChannel] -
        1
    if Player.currentPlaylistIndex[core.Channel.currentChannel] < 1 then
        Player.currentPlaylistIndex[core.Channel.currentChannel] = #Player.currentPlaylist[core.Channel.currentChannel]
            .songs
    end
    Player:PlayNextSongInPlaylist(core.Channel.currentChannel)
end

function Player:SetPlaylistIndex(index)
    if not Player.currentPlaylist[core.Channel.currentChannel] or #Player.currentPlaylist[core.Channel.currentChannel].songs == 0 then
        EmptyPlaylist()
        return
    end
    if index < 1 or index > #Player.currentPlaylist[core.Channel.currentChannel].songs then
        currentText[core.Channel.currentChannel] = "Invalid index"
        UpdateText()
        return
    end
    Player.currentPlaylistIndex[core.Channel.currentChannel] = index
    Player:PlayNextSongInPlaylist(core.Channel.currentChannel)
end

function Player:StopMusicOnChannel(localChannel)
    Player.currentSoloIndex[localChannel] = nil
    if Player.currentlyPlaying[localChannel] then
        StopSound(Player.currentlyPlaying[localChannel])
        Player.currentlyPlaying[localChannel] = nil

        if localChannel == core.Channel.currentChannel then
            core.PlayerWindow.window.playPauseButton:SetChecked(false)
            core.PlayerWindow:RefreshTabs()
        end
    end
end

function Player:PauseSong()
    if Player.currentlyPlaying[core.Channel.currentChannel] then
        core.Broadcast:BroadcastAudio("pause", Player.currentlyPlaying[core.Channel.currentChannel],
            currentName[core.Channel.currentChannel], core.Channel.currentChannel)
        Player:StopMusicOnChannel(core.Channel.currentChannel)
    end
    SetCVar("Sound_EnableMusic", cvarInitial)
    cvarInitial = nil
end

function Player:ResumeSong()
    if Player.currentPlaylist[core.Channel.currentChannel] then
        Player:PlayNextSongInPlaylist(core.Channel.currentChannel)
    elseif Player.currentId[core.Channel.currentChannel] and currentName[core.Channel.currentChannel] then
        Player:PlaySongSingle(Player.currentId[core.Channel.currentChannel], currentName[core.Channel.currentChannel],
            core.Channel.currentChannel)
    end
end

function Player:PlaySong(id, name, localChannel)
    if Player.currentlyPlaying[localChannel] then
        StopSound(Player.currentlyPlaying[localChannel])
    end

    Player.currentId[localChannel] = id
    currentName[localChannel] = name

    if cvarInitial == nil then
        cvarInitial = GetCVar("Sound_EnableMusic")
    end
    SetCVar("Sound_EnableMusic", "0")

    Player.UpdateFrame[localChannel]:SetScript("OnUpdate", LoopCurrentlyPlaying)
    firstFrame[localChannel] = true
    local willPlay, soundHandle = PlaySoundFile(id, "Master")
    Player.currentlyPlaying[localChannel] = soundHandle
    currentText[localChannel] = name

    --i dont think willplay actually works but justincase it does i guess
    if not willPlay then
        Player:PauseSong()
        currentText[localChannel] = "Failed to play sound: " .. name
        UpdateText()
        core.Broadcast:BroadcastAudio("pause", id, name, localChannel)
        if localChannel == core.Channel.currentChannel then
            core.PlayerWindow.window.playPauseButton:Disable()
            core.PlayerWindow.window.playPauseButton:SetChecked(false)
            UpdateText()
        end
        return
    end

    if localChannel == core.Channel.currentChannel then
        core.PlayerWindow:RefreshTabs()
        core.PlayerWindow.window.playPauseButton:Enable()
        core.PlayerWindow.window.playPauseButton:SetChecked(willPlay)
        UpdateText()
    end
end

function Player:PlaySongFromBroadcast(id, name, localChannel)
    -- this is essentially just PlaySongSingle, but done so that a broadcast doesnt trigger another broadcast
    core.PlayerWindow.window.previousButton:Disable()
    core.PlayerWindow.window.nextButton:Disable()
    Player.currentPlaylist[localChannel] = nil
    Player.currentPlaylistIndex[localChannel] = 1

    Player:PlaySong(id, name, localChannel)
end

function Player:PlaySongSingle(id, name, localChannel, playlistIndex, songIndex)
    if not localChannel then
        localChannel = core.Channel.currentChannel
    end

    if playlistIndex and songIndex then
        Player.currentSoloIndex[localChannel] = {
            playlistIndex = playlistIndex,
            songIndex = songIndex
        }
    end

    if core.Channel.currentChannel == localChannel then
        core.PlayerWindow.window.previousButton:Disable()
        core.PlayerWindow.window.nextButton:Disable()
    end

    Player.currentPlaylist[localChannel] = nil
    Player.currentPlaylistIndex[localChannel] = 1

    -- They have to be here rather than in playsong to ensure that the broadcast doesnt trigger another broadcast
    core.Broadcast:BroadcastAudio("play", id, name, localChannel)
    Player:PlaySong(id, name, localChannel)
end

function Player:PlayNextSongInPlaylist(localChannel)
    Player.currentSoloIndex[localChannel] = nil
    if not Player.currentPlaylist[localChannel] or #Player.currentPlaylist[localChannel].songs == 0 then
        EmptyPlaylist()
        return
    end

    local currentSong = Player.currentPlaylist[localChannel].songs
        [Player.currentPlaylistIndex[localChannel]]

    -- They have to be here rather than in playsong to ensure that the broadcast doesnt trigger another broadcast
    core.Broadcast:BroadcastAudio("play", currentSong.id, currentSong.name, localChannel)
    Player:PlaySong(currentSong.id, currentSong.name, localChannel)

    if core.Channel.currentChannel == localChannel then
        core.PlayerWindow.window.previousButton:Enable()
        core.PlayerWindow.window.nextButton:Enable()
    end
end

function Player:StopCurrentSong()
    if Player.currentlyPlaying[core.Channel.currentChannel] then
        StopSound(Player.currentlyPlaying[core.Channel.currentChannel])
    end
    Player.currentlyPlaying[core.Channel.currentChannel] = nil
    Player.currentId[core.Channel.currentChannel] = nil
    currentName[core.Channel.currentChannel] = nil
    core.PlayerWindow.window.playPauseButton:Disable()
    currentText[core.Channel.currentChannel] = "No track selected"
    UpdateText()
end

function Player:SetPlaylist(playlist)
    Player.currentPlaylist[core.Channel.currentChannel] = playlist
    Player.currentPlaylistIndex[core.Channel.currentChannel] = 1
    Player:PlayNextSongInPlaylist(core.Channel.currentChannel)
end
