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
    Player.UpdateFrame[value] = CreateFrame("Frame", "GroupMusicPlayerUpdateFrame" .. value)
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
    local loopingCore
    for playerCore, frame in pairs(Player.UpdateFrame) do
        if frame == self then
            loopingCore = playerCore
        end
    end
    if currentlyPlaying[loopingCore] and currentPlaylist[loopingCore] then
        local isPlaying = C_Sound.IsPlaying(currentlyPlaying[loopingCore])
        if not isPlaying then
            currentPlaylistIndex[loopingCore] = currentPlaylistIndex[loopingCore] + 1
            if currentPlaylistIndex[loopingCore] > #currentPlaylist[loopingCore].songs then
                currentPlaylistIndex[loopingCore] = 1
            end
            Player:PlayNextSongInPlaylist()
        end
    elseif currentlyPlaying[loopingCore] and core.Channel.LoopType[core.Channel.channelIndex[loopingCore]] then
        local isPlaying = C_Sound.IsPlaying(currentlyPlaying[loopingCore])
        if not isPlaying then
            if currentId[loopingCore] and currentName[loopingCore] then
                Player:PlaySongSingle(currentId[loopingCore], currentName[loopingCore])
            end
        end
    elseif currentlyPlaying[loopingCore] and not core.Channel.LoopType[core.Channel.channelIndex[loopingCore]] then
        local isPlaying = C_Sound.IsPlaying(currentlyPlaying[loopingCore])
        if not isPlaying then
            core.PlayerWindow.window.playPauseButton:SetChecked(false)
            core.PlayerWindow.window.playPauseButton:Disable()
            currentlyPlaying[loopingCore] = nil
            currentId[loopingCore] = nil
            currentName[loopingCore] = nil
            currentText[loopingCore] = core.Channel.defaultText
                [core.Channel.channelIndex[loopingCore]] or "No sound playing"
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
    Player:PlayNextSongInPlaylist()
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
    Player:PlayNextSongInPlaylist()
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
    Player:PlayNextSongInPlaylist()
end

function Player:PauseSong()
    if currentlyPlaying[core.Channel.currentChannel] then
        StopSound(currentlyPlaying[core.Channel.currentChannel])
        currentlyPlaying[core.Channel.currentChannel] = nil
    end
    core.PlayerWindow.window.playPauseButton:SetChecked(false)
    SetCVar("Sound_EnableMusic", cvarInitial)
    cvarInitial = nil
end

function Player:ResumeSong()
    if currentPlaylist[core.Channel.currentChannel] then
        Player:PlayNextSongInPlaylist()
    elseif currentId[core.Channel.currentChannel] and currentName[core.Channel.currentChannel] then
        Player:PlaySongSingle(currentId[core.Channel.currentChannel], currentName[core.Channel.currentChannel])
    end
end

function Player:PlaySong(id, name)
    if currentlyPlaying[core.Channel.currentChannel] then
        StopSound(currentlyPlaying[core.Channel.currentChannel])
        currentlyPlaying[core.Channel.currentChannel] = nil
        currentId[core.Channel.currentChannel] = nil
        currentName[core.Channel.currentChannel] = nil
        core.PlayerWindow.window.playPauseButton:Disable()
        currentText[core.Channel.currentChannel] = "No track selected"
        UpdateText()
    end

    currentId[core.Channel.currentChannel] = id
    currentName[core.Channel.currentChannel] = name
    core.PlayerWindow.window.playPauseButton:Enable()
    if cvarInitial == nil then
        cvarInitial = GetCVar("Sound_EnableMusic")
    end
    SetCVar("Sound_EnableMusic", "0")
    Player.UpdateFrame[core.Channel.currentChannel]:SetScript("OnUpdate", LoopCurrentlyPlaying)
    local willPlay, soundHandle = PlaySoundFile(id, "Master")
    core.PlayerWindow.window.playPauseButton:SetChecked(willPlay)
    currentlyPlaying[core.Channel.currentChannel] = soundHandle
    currentText[core.Channel.currentChannel] = name
    UpdateText()
end

function Player:PlaySongSingle(id, name)
    core.PlayerWindow.window.previousButton:Disable()
    core.PlayerWindow.window.nextButton:Disable()
    currentPlaylist[core.Channel.currentChannel] = nil
    currentPlaylistIndex[core.Channel.currentChannel] = 1

    Player:PlaySong(id, name)
end

function Player:PlayNextSongInPlaylist()
    if not currentPlaylist[core.Channel.currentChannel] or #currentPlaylist[core.Channel.currentChannel].songs == 0 then
        EmptyPlaylist()
        return
    end
    core.PlayerWindow.window.previousButton:Enable()
    core.PlayerWindow.window.nextButton:Enable()
    local currentSong = currentPlaylist[core.Channel.currentChannel].songs
        [currentPlaylistIndex[core.Channel.currentChannel]]

    Player:PlaySong(currentSong.id, currentSong.name)
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
    Player:PlayNextSongInPlaylist()
end
