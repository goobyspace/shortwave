-------------------------------
-- Namespaces & Variables
-------------------------------
local _, core = ...
core.Player = {}
local Player = core.Player

local currentPlaylist = {}
local currentPlaylistIndex = { 1, 1, 1 }
local currentlyPlaying = {}
local currentId = {}
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
    if currentlyPlaying[core.Channel.currentChannel] then
        core.PlayerWindow.window.playPauseButton:SetChecked(true)
        core.PlayerWindow.window.playPauseButton:Enable()
    elseif currentId[core.Channel.currentChannel] and currentName[core.Channel.currentChannel] then
        core.PlayerWindow.window.playPauseButton:SetChecked(false)
        core.PlayerWindow.window.playPauseButton:Enable()
    else
        core.PlayerWindow.window.playPauseButton:SetChecked(false)
        core.PlayerWindow.window.playPauseButton:Disable()
    end
    if currentPlaylist[core.Channel.currentChannel] and #currentPlaylist[core.Channel.currentChannel].songs > 0 then
        core.PlayerWindow.window.previousButton:Enable()
        core.PlayerWindow.window.nextButton:Enable()
    else
        core.PlayerWindow.window.previousButton:Disable()
        core.PlayerWindow.window.nextButton:Disable()
    end
end

local function LoopCurrentlyPlaying(self)
    local localChannel
    for playerCore, frame in pairs(Player.UpdateFrame) do
        if frame == self then
            localChannel = playerCore
        end
    end
    if currentlyPlaying[localChannel] and currentPlaylist[localChannel] then
        local isPlaying = C_Sound.IsPlaying(currentlyPlaying[localChannel])
        if not isPlaying then
            currentPlaylistIndex[localChannel] = currentPlaylistIndex[localChannel] + 1
            if currentPlaylistIndex[localChannel] > #currentPlaylist[localChannel].songs then
                currentPlaylistIndex[localChannel] = 1
            end
            Player:PlayNextSongInPlaylist(localChannel)
        end
    elseif currentlyPlaying[localChannel] and core.Channel.LoopType[core.Channel.channelIndex[localChannel]] then
        local isPlaying = C_Sound.IsPlaying(currentlyPlaying[localChannel])
        if not isPlaying then
            if currentId[localChannel] and currentName[localChannel] then
                Player:PlaySongSingle(currentId[localChannel], currentName[localChannel], localChannel)
            end
        end
    elseif currentlyPlaying[localChannel] and not core.Channel.LoopType[core.Channel.channelIndex[localChannel]] then
        local isPlaying = C_Sound.IsPlaying(currentlyPlaying[localChannel])
        if not isPlaying then
            core.PlayerWindow.window.playPauseButton:SetChecked(false)
            core.PlayerWindow.window.playPauseButton:Disable()
            currentlyPlaying[localChannel] = nil
            currentId[localChannel] = nil
            currentName[localChannel] = nil
            currentText[localChannel] = core.Channel.defaultText
                [core.Channel.channelIndex[localChannel]] or "No sound playing"
            UpdateText()
            self:SetScript("OnUpdate", nil)
        end
    else
        self:SetScript("OnUpdate", nil)
    end
end

local function EmptyPlaylist()
    currentText[core.Channel.currentChannel] = "No playlist selected"
    UpdateText()
    core.PlayerWindow.window.previousButton:Disable()
    core.PlayerWindow.window.nextButton:Disable()
end

function Player:NextSongInPlaylist()
    if not currentPlaylist[core.Channel.currentChannel] or #currentPlaylist[core.Channel.currentChannel].songs == 0 then
        EmptyPlaylist()
        return
    end
    currentPlaylistIndex[core.Channel.currentChannel] = currentPlaylistIndex[core.Channel.currentChannel] + 1
    if currentPlaylistIndex[core.Channel.currentChannel] > #currentPlaylist[core.Channel.currentChannel].songs then
        currentPlaylistIndex[core.Channel.currentChannel] = 1
    end
    Player:PlayNextSongInPlaylist(core.Channel.currentChannel)
end

function Player:PreviousSongInPlaylist()
    if not currentPlaylist[core.Channel.currentChannel] or #currentPlaylist[core.Channel.currentChannel].songs == 0 then
        EmptyPlaylist()
        return
    end
    currentPlaylistIndex[core.Channel.currentChannel] = currentPlaylistIndex[core.Channel.currentChannel] - 1
    if currentPlaylistIndex[core.Channel.currentChannel] < 1 then
        currentPlaylistIndex[core.Channel.currentChannel] = #currentPlaylist[core.Channel.currentChannel].songs
    end
    Player:PlayNextSongInPlaylist(core.Channel.currentChannel)
end

function Player:SetPlaylistIndex(index)
    if not currentPlaylist[core.Channel.currentChannel] or #currentPlaylist[core.Channel.currentChannel].songs == 0 then
        EmptyPlaylist()
        return
    end
    if index < 1 or index > #currentPlaylist[core.Channel.currentChannel].songs then
        currentText[core.Channel.currentChannel] = "Invalid index"
        UpdateText()
        return
    end
    currentPlaylistIndex[core.Channel.currentChannel] = index
    Player:PlayNextSongInPlaylist(core.Channel.currentChannel)
end

function Player:StopMusicOnChannel(localChannel)
    if currentlyPlaying[localChannel] then
        StopSound(currentlyPlaying[localChannel])
        currentlyPlaying[localChannel] = nil

        if localChannel == core.Channel.currentChannel then
            core.PlayerWindow.window.playPauseButton:SetChecked(false)
        end
    end
end

function Player:PauseSong()
    if currentlyPlaying[core.Channel.currentChannel] then
        core.Broadcast:BroadcastAudio("pause", currentlyPlaying[core.Channel.currentChannel],
            currentName[core.Channel.currentChannel], core.Channel.currentChannel)
        Player:StopMusicOnChannel(core.Channel.currentChannel)
    end
    SetCVar("Sound_EnableMusic", cvarInitial)
    cvarInitial = nil
end

function Player:ResumeSong()
    if currentPlaylist[core.Channel.currentChannel] then
        Player:PlayNextSongInPlaylist(core.Channel.currentChannel)
    elseif currentId[core.Channel.currentChannel] and currentName[core.Channel.currentChannel] then
        Player:PlaySongSingle(currentId[core.Channel.currentChannel], currentName[core.Channel.currentChannel],
            core.Channel.currentChannel)
    end
end

function Player:PlaySong(id, name, localChannel)
    if currentlyPlaying[localChannel] then
        StopSound(currentlyPlaying[localChannel])
    end

    currentId[localChannel] = id
    currentName[localChannel] = name

    if cvarInitial == nil then
        cvarInitial = GetCVar("Sound_EnableMusic")
    end
    SetCVar("Sound_EnableMusic", "0")

    Player.UpdateFrame[localChannel]:SetScript("OnUpdate", LoopCurrentlyPlaying)
    local willPlay, soundHandle = PlaySoundFile(id, "Master")
    currentlyPlaying[localChannel] = soundHandle
    currentText[localChannel] = name

    core.Broadcast:BroadcastAudio("play", id, name, localChannel)

    if localChannel == core.Channel.currentChannel then
        core.PlayerWindow.window.playPauseButton:Enable()
        core.PlayerWindow.window.playPauseButton:SetChecked(willPlay)
        UpdateText()
    end
end

function Player:PlaySongSingle(id, name, localChannel)
    if not localChannel then
        localChannel = core.Channel.currentChannel
    end
    core.PlayerWindow.window.previousButton:Disable()
    core.PlayerWindow.window.nextButton:Disable()
    currentPlaylist[localChannel] = nil
    currentPlaylistIndex[localChannel] = 1

    Player:PlaySong(id, name, localChannel)
end

function Player:PlayNextSongInPlaylist(localChannel)
    if not currentPlaylist[localChannel] or #currentPlaylist[localChannel].songs == 0 then
        EmptyPlaylist()
        return
    end
    core.PlayerWindow.window.previousButton:Enable()
    core.PlayerWindow.window.nextButton:Enable()
    local currentSong = currentPlaylist[localChannel].songs
        [currentPlaylistIndex[localChannel]]

    Player:PlaySong(currentSong.id, currentSong.name, localChannel)
end

function Player:StopCurrentSong()
    if currentlyPlaying[core.Channel.currentChannel] then
        StopSound(currentlyPlaying[core.Channel.currentChannel])
    end
    currentlyPlaying[core.Channel.currentChannel] = nil
    currentId[core.Channel.currentChannel] = nil
    currentName[core.Channel.currentChannel] = nil
    core.PlayerWindow.window.playPauseButton:Disable()
    currentText[core.Channel.currentChannel] = "No track selected"
    UpdateText()
end

function Player:SetPlaylist(playlist)
    currentPlaylist[core.Channel.currentChannel] = playlist
    currentPlaylistIndex[core.Channel.currentChannel] = 1
    Player:PlayNextSongInPlaylist(core.Channel.currentChannel)
end
