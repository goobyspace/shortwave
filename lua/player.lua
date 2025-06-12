-------------------------------
-- Namespaces & Variables
-------------------------------
local _, core = ...
core.Player = {}
local Player = core.Player

local currentPlaylist = nil
local currentPlaylistIndex = 1
local currentlyPlaying = nil
local currentId = nil
local currentName = nil

local cvarInitial

local function LoopCurrentlyPlaying()
    if currentlyPlaying and currentPlaylist then
        local isPlaying = C_Sound.IsPlaying(currentlyPlaying)
        if not isPlaying then
            currentPlaylistIndex = currentPlaylistIndex + 1
            if currentPlaylistIndex > #currentPlaylist.songs then
                currentPlaylistIndex = 1
            end
            Player:PlayNextSongInPlaylist()
        end
    elseif currentlyPlaying then
        local isPlaying = C_Sound.IsPlaying(currentlyPlaying)
        if not isPlaying then
            if currentId and currentName then
                Player:PlaySongSingle(currentId, currentName)
            end
        end
    else
        Player.UpdateFrame:SetScript("OnUpdate", nil)
    end
end

Player.UpdateFrame = CreateFrame("Frame")
Player.UpdateFrame:SetScript("OnUpdate", nil)

local function EmptyPlaylist()
    core.PlayerWindow:SetText("No playlist selected")
    core.PlayerWindow.window.previousButton:Disable()
    core.PlayerWindow.window.nextButton:Disable()
end

function Player:NextSongInPlaylist()
    if not currentPlaylist or #currentPlaylist.songs == 0 then
        EmptyPlaylist()
        return
    end
    currentPlaylistIndex = currentPlaylistIndex + 1
    if currentPlaylistIndex > #currentPlaylist.songs then
        currentPlaylistIndex = 1
    end
    Player:PlayNextSongInPlaylist()
end

function Player:PreviousSongInPlaylist()
    if not currentPlaylist or #currentPlaylist.songs == 0 then
        EmptyPlaylist()
        return
    end
    currentPlaylistIndex = currentPlaylistIndex - 1
    if currentPlaylistIndex < 1 then
        currentPlaylistIndex = #currentPlaylist.songs
    end
    Player:PlayNextSongInPlaylist()
end

function Player:SetPlaylistIndex(index)
    if not currentPlaylist or #currentPlaylist.songs == 0 then
        EmptyPlaylist()
        return
    end
    if index < 1 or index > #currentPlaylist.songs then
        core.PlayerWindow:SetText("Invalid index")
        return
    end
    currentPlaylistIndex = index
    Player:PlayNextSongInPlaylist()
end

function Player:PauseSong()
    if currentlyPlaying then
        StopSound(currentlyPlaying)
        currentlyPlaying = nil
    end
    core.PlayerWindow.window.playPauseButton:SetChecked(false)
    SetCVar("Sound_EnableMusic", cvarInitial)
    cvarInitial = nil
end

function Player:ResumeSong()
    if currentPlaylist then
        Player:PlayNextSongInPlaylist()
    end
    if currentId and currentName then
        Player:PlaySongSingle(currentId, currentName)
    end
end

function Player:PlaySong(id, name)
    if currentlyPlaying then
        StopSound(currentlyPlaying)
        currentlyPlaying = nil
        currentId = nil
        currentName = nil
        core.PlayerWindow.window.playPauseButton:Disable()
        core.PlayerWindow:SetText("No track selected")
    end

    currentId = id
    currentName = name
    core.PlayerWindow.window.playPauseButton:Enable()
    if cvarInitial == nil then
        cvarInitial = GetCVar("Sound_EnableMusic")
    end
    SetCVar("Sound_EnableMusic", "0")
    Player.UpdateFrame:SetScript("OnUpdate", LoopCurrentlyPlaying)
    local willPlay, soundHandle = PlaySoundFile(id, "Master")
    core.PlayerWindow.window.playPauseButton:SetChecked(willPlay)
    currentlyPlaying = soundHandle
    core.PlayerWindow:SetText(name)
end

function Player:PlaySongSingle(id, name)
    core.PlayerWindow.window.previousButton:Disable()
    core.PlayerWindow.window.nextButton:Disable()

    Player:PlaySong(id, name)
end

function Player:PlayNextSongInPlaylist()
    if not currentPlaylist or #currentPlaylist.songs == 0 then
        EmptyPlaylist()
        return
    end
    core.PlayerWindow.window.previousButton:Enable()
    core.PlayerWindow.window.nextButton:Enable()
    local currentSong = currentPlaylist.songs[currentPlaylistIndex]

    Player:PlaySong(currentSong.id, currentSong.name)
end

function Player:StopCurrentSong()
    if currentlyPlaying then
        StopSound(currentlyPlaying)
    end
    currentlyPlaying = nil
    currentId = nil
    currentName = nil
    core.PlayerWindow.window.playPauseButton:Disable()
    core.PlayerWindow:SetText("No track selected")
end

function Player:SetPlaylist(playlist)
    currentPlaylist = playlist
    currentPlaylistIndex = 1
    Player:PlayNextSongInPlaylist()
end
