-------------------------------
-- Namespaces & Variables
-------------------------------
local _, core = ...
core.Player = {}
local Player = core.Player

local currentlyPlaying = nil
local currentId = nil
local currentName = nil

local cvarInitial

Player.UpdateFrame = CreateFrame("Frame")
Player.UpdateFrame:SetScript("OnUpdate", function()
    if currentlyPlaying then
        local isPlaying = C_Sound.IsPlaying(currentlyPlaying)
        if not isPlaying then
            --either we go next in playlist *or*
            if currentId and currentName then
                Player:PlaySong(currentId, currentName)
            end
        end
    end
end)

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
    if currentId and currentName then
        Player:PlaySong(currentId, currentName)
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
    local willPlay, soundHandle = PlaySoundFile(id, "Master")
    core.PlayerWindow.window.playPauseButton:SetChecked(willPlay)
    currentlyPlaying = soundHandle
    core.PlayerWindow:SetText(name)
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
