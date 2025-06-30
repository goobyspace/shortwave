local _, core = ...
core.Player = {}
local Player = core.Player

-- some of these values are global, so that they can be checked in the search & playlist windows
-- to see if a sound that is on screen is currently playing
Player.currentPlaylist = {}
Player.currentPlaylistIndex = {}
Player.currentCosmeticIndex = {}
Player.currentlyPlaying = {}
Player.currentSoloIndex = {}
Player.currentId = {}
Player.currentDelay = {}
local firstFrame = {}
local currentName = {}
local currentText = {}

local cvarInitial

-- updatetext updates the text in the player window
local function UpdateText()
    core.PlayerWindow:SetText(currentText[core.Channel.currentChannel] or
        core.Channel.defaultText[core.Channel.channelIndex[core.Channel.currentChannel]])
end

-- UpdatePlayer updates the player window based on the current channel
function Player:UpdatePlayer()
    UpdateText()
    if ShortWaveVariables.selectedtab[core.Channel.currentChannel] == "playlist" then
        if (Player.currentlyPlaying[core.Channel.currentChannel] or Player.currentDelay[core.Channel.currentChannel]) and Player.currentPlaylist[core.Channel.currentChannel] then
            core.Playlist:RefreshPlaylists()
        elseif not Player.currentlyPlaying[core.Channel.currentChannel] and not Player.currentDelay[core.Channel.currentChannel] then
            core.Playlist:RefreshPlaylists()
        end
    elseif ShortWaveVariables.selectedtab[core.Channel.currentChannel] == "search" and ShortWaveVariables.selectedCore[core.Channel.currentChannel] ~= "creature" then
        if core.Player.currentlyPlaying[core.Channel.currentChannel] and core.Player.currentSoloIndex[core.Channel.currentChannel] == nil and core.Player.currentPlaylist[core.Channel.currentChannel] == nil then
            core.Search:RefreshSearchBody()
        elseif not Player.currentlyPlaying[core.Channel.currentChannel] and not Player.currentDelay[core.Channel.currentChannel] then
            core.Search:RefreshSearchBody()
        end
    end
    if Player.currentlyPlaying[core.Channel.currentChannel] or Player.currentDelay[core.Channel.currentChannel] then
        core.PlayerWindow.window.playPauseButton:SetChecked(true)
        core.PlayerWindow.window.playPauseButton:Enable()
    elseif Player.currentId[core.Channel.currentChannel] and currentName[core.Channel.currentChannel] then
        core.PlayerWindow.window.playPauseButton:SetChecked(false)
        core.PlayerWindow.window.playPauseButton:Enable()
    else
        core.PlayerWindow.window.playPauseButton:SetChecked(false)
        core.PlayerWindow.window.playPauseButton:Disable()
    end
    if Player.currentPlaylist[core.Channel.currentChannel] and #Player.currentPlaylist[core.Channel.currentChannel].sounds > 0 then
        core.PlayerWindow.window.previousButton:Enable()
        core.PlayerWindow.window.nextButton:Enable()
    else
        core.PlayerWindow.window.previousButton:Disable()
        core.PlayerWindow.window.nextButton:Disable()
    end
end

-- update frames check for each channel if a sound is still playing and what to do next
-- its because blizzard API doesnt have any kind of event for this, nor do we have a sound duration
-- so we kinda just have to check every frame whilst a sound is playing
Player.UpdateFrame = {}
for _, value in ipairs(core.Channel.channels) do
    Player.UpdateFrame[value] = CreateFrame("Frame", "ShortWavePlayerUpdateFrame" .. value)
    Player.UpdateFrame[value]:SetScript("OnUpdate", nil)
end

-- zeroframeaudio is called when a sound stops playing immediately on frame 0
-- blizzard API doesn't tell us when a sound won't play, or when an ID is invalid
-- and will instead just play it and instantly stop
-- this way we can detect that and give the user feedback
-- as well as stopping playlists with non-existant sounds and VOs
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
    core.PlayerWindow.window.playPauseButton:SetChecked(false)
    core.PlayerWindow.window.playPauseButton:Disable()
    core.PlayerWindow.window.previousButton:Disable()
    core.PlayerWindow.window.nextButton:Disable()
end

-- loopcurrentlyplaying is called every frame whenever a channel has audio playing
-- it checks if the audio is still playing, if yes, it does nothing
-- if not, it will check whether it has to stop and clear itself, play the next sound, etc
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
            if Player.currentPlaylistIndex[localChannel] > #Player.currentPlaylist[localChannel].sounds then
                Player.currentPlaylistIndex[localChannel] = 1
            end
            Player:PlayNextSoundInPlaylist(localChannel)
        end
    elseif Player.currentlyPlaying[localChannel] and core.Channel.LoopType[core.Channel.channelIndex[localChannel]] then
        local isPlaying = C_Sound.IsPlaying(Player.currentlyPlaying[localChannel])
        if not isPlaying then
            if firstFrame[localChannel] then
                ZeroFrameAudio(localChannel)
                return
            end
            if Player.currentId[localChannel] and currentName[localChannel] then
                Player:PlaySoundSingle(Player.currentId[localChannel], currentName[localChannel], localChannel)
            end
        end
    elseif Player.currentlyPlaying[localChannel] and not core.Channel.LoopType[core.Channel.channelIndex[localChannel]] then
        local isPlaying = C_Sound.IsPlaying(Player.currentlyPlaying[localChannel])
        if not isPlaying then
            if firstFrame[localChannel] then
                ZeroFrameAudio(localChannel)
                return
            end
            Player:PauseSound()
            self:SetScript("OnUpdate", nil)
        end
    else
        self:SetScript("OnUpdate", nil)
    end
    firstFrame[localChannel] = false
end

-- whenever something goes wrong with a playlist, this function is called
-- e.g. when a playlist is empty, or the index is out of bounds because the user deleted sounds in their currently playing playlist
local function EmptyPlaylist()
    currentText[core.Channel.currentChannel] = "Playlist is empty"
    UpdateText()
    core.PlayerWindow.window.previousButton:Disable()
    core.PlayerWindow.window.nextButton:Disable()
end

-- Set the index to be the next sound in the playlist and then play it
-- Used when the user clicks on the next button in the player window
-- And after a delay
function Player:NextSoundInPlaylist(localChannel)
    if not localChannel then
        localChannel = core.Channel.currentChannel
    end
    if not Player.currentPlaylist[localChannel] or #Player.currentPlaylist[localChannel].sounds == 0 then
        EmptyPlaylist()
        return
    end
    Player.currentPlaylistIndex[localChannel] = Player.currentPlaylistIndex[localChannel] +
        1
    if Player.currentPlaylistIndex[localChannel] > #Player.currentPlaylist[localChannel].sounds then
        Player.currentPlaylistIndex[localChannel] = 1
    end
    Player:PlayNextSoundInPlaylist(localChannel)
end

-- Set the index to be the previous sound in the playlist and then play it
-- Used when the user clicks on the previous button in the player window
function Player:PreviousSoundInPlaylist()
    if not Player.currentPlaylist[core.Channel.currentChannel] or #Player.currentPlaylist[core.Channel.currentChannel].sounds == 0 then
        EmptyPlaylist()
        return
    end
    Player.currentPlaylistIndex[core.Channel.currentChannel] = Player.currentPlaylistIndex[core.Channel.currentChannel] -
        1
    if Player.currentPlaylistIndex[core.Channel.currentChannel] < 1 then
        Player.currentPlaylistIndex[core.Channel.currentChannel] = #Player.currentPlaylist[core.Channel.currentChannel]
            .sounds
    end
    Player:PlayNextSoundInPlaylist(core.Channel.currentChannel)
end

-- Set the index to a specific sound in the playlist and then play it
-- Used when the user clicks on a sound in the playlist window
function Player:SetPlaylistIndex(index)
    if not Player.currentPlaylist[core.Channel.currentChannel] or #Player.currentPlaylist[core.Channel.currentChannel].sounds == 0 then
        EmptyPlaylist()
        return
    end
    if index < 1 or index > #Player.currentPlaylist[core.Channel.currentChannel].sounds then
        currentText[core.Channel.currentChannel] = "Invalid index"
        UpdateText()
        return
    end
    Player.currentPlaylistIndex[core.Channel.currentChannel] = index
    Player:PlayNextSoundInPlaylist(core.Channel.currentChannel)
end

-- Set a playlist for the current channel
-- Called when you press play in the playlist header
function Player:SetPlaylist(playlist)
    for index, _ in ipairs(playlist.sounds) do
        playlist.sounds[index].originalIndex = index
    end
    Player.currentPlaylist[core.Channel.currentChannel] = playlist
    Player.currentPlaylistIndex[core.Channel.currentChannel] = 1
end

-- implements the fisher-yates shuffle algorithm to shuffle a playlist
-- then we set the new shuffled playlist as the playlist data
function Player:SetPlaylistShuffled(playlist)
    local shuffleSounds = {}
    local shuffleDelays = {}
    for index, _ in ipairs(playlist.sounds) do
        playlist.sounds[index].originalIndex = index
    end

    for _, sound in ipairs(playlist.sounds) do
        if sound.delay then
            table.insert(shuffleDelays, sound)
        else
            table.insert(shuffleSounds, sound)
        end
    end



    local shuffledPlaylist = {
        name = playlist.name,
        sounds = core.Utils.shuffle(shuffleSounds)
    }

    -- tldr
    -- if user wants to keep the delays, we need to insert them back into the shuffled playlist
    -- ideally in the same place they were before shuffling
    -- we have a setting to check if the user wants them before or after the sound
    if ShortWaveVariables.keepDelay then
        for newIndex, sound in ipairs(shuffledPlaylist.sounds) do
            for _, delay in ipairs(shuffleDelays) do
                local delayDirection = ShortWaveVariables.delayFirst and -1 or 1

                if sound.originalIndex + delayDirection == delay.originalIndex and ((ShortWaveVariables.delayFirst and (not shuffledPlaylist.sounds[newIndex + delayDirection] or not shuffledPlaylist.sounds[newIndex + delayDirection].delay)) or (not ShortWaveVariables.delayFirst and not shuffledPlaylist.sounds[newIndex].delay)) then
                    local insertIndex = ShortWaveVariables.delayFirst and newIndex or newIndex + 1
                    table.insert(shuffledPlaylist.sounds, insertIndex, delay)
                end
            end
        end
    end

    Player.currentPlaylist[core.Channel.currentChannel] = shuffledPlaylist
    Player.currentPlaylistIndex[core.Channel.currentChannel] = 1
end

-- Stops the music on a specific channel or the current channel if no channel is specified
-- Called directly from the broadcast window, or via the PauseSound function
function Player:StopSoundOnChannel(localChannel)
    if Player.currentlyPlaying[localChannel] then
        StopSound(Player.currentlyPlaying[localChannel])
        Player.currentlyPlaying[localChannel] = nil

        Player:UpdatePlayer()
    end
end

-- Pause the current sound on the current channel
-- Called by the various stop buttons in the player window
function Player:PauseSound()
    if Player.currentlyPlaying[core.Channel.currentChannel] then
        core.Broadcast:BroadcastAudio("pause", Player.currentlyPlaying[core.Channel.currentChannel],
            currentName[core.Channel.currentChannel], core.Channel.currentChannel)
        Player:StopSoundOnChannel(core.Channel.currentChannel)
    end
    if Player.currentDelay[core.Channel.currentChannel] then
        Player.currentDelay[core.Channel.currentChannel]:Cancel()
        Player.currentDelay[core.Channel.currentChannel] = nil
        Player:UpdatePlayer()
    end
    SetCVar("Sound_EnableMusic", cvarInitial)
    cvarInitial = nil
end

-- If a sound was selected then stopped, this function restarts it
-- We can't do actual resuming, because the Blizzard API can only play sounds from the start
function Player:ResumeSound()
    if Player.currentPlaylist[core.Channel.currentChannel] then
        Player:PlayNextSoundInPlaylist(core.Channel.currentChannel)
    elseif Player.currentId[core.Channel.currentChannel] and currentName[core.Channel.currentChannel] then
        local playlistIndex = Player.currentSoloIndex[core.Channel.currentChannel] and
            Player.currentSoloIndex[core.Channel.currentChannel].playlistIndex
        local soundIndex = Player.currentSoloIndex[core.Channel.currentChannel] and
            Player.currentSoloIndex[core.Channel.currentChannel].soundIndex
        Player:PlaySoundSingle(Player.currentId[core.Channel.currentChannel], currentName[core.Channel.currentChannel],
            core.Channel.currentChannel, playlistIndex, soundIndex)
    end
end

-- This function actually plays a sound file
-- It is only called by wrapper functions like PlaySoundSingle, PlaySoundFromBroadcast, or PlayNextSoundInPlaylist
-- If a sound is currently playing, stop it
-- Then, get all the details, pause any music currently playing by the game
-- Play the sound file and set all the various values, including the LoopCurrentlyPlaying function
-- Set the frame appropriately
function Player:PlaySound(id, name, localChannel)
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
    local willPlay, soundHandle = PlaySoundFile(id, ShortWaveVariables.channel or "SFX")
    Player.currentlyPlaying[localChannel] = soundHandle
    currentText[localChannel] = name

    --i dont think willplay actually works but just incase it does
    if not willPlay then
        Player:PauseSound()
        Player.currentlyPlaying[localChannel] = nil;
        currentText[localChannel] = "Failed to play sound: " .. name
        UpdateText()
        core.Broadcast:BroadcastAudio("pause", id, name, localChannel)
        Player:UpdatePlayer()
        return
    end

    Player:UpdatePlayer()
end

-- Pretty simple, play the sound from a broadcast
-- This is a seperate function specifically so that it doesn't trigger another broadcast
-- Whilst PlaySoundSingle & PlayNextSoundInPlaylist will trigger a broadcast
function Player:PlaySoundFromBroadcast(id, name, localChannel)
    Player.currentPlaylist[localChannel] = nil
    Player.currentPlaylistIndex[localChannel] = 1
    Player.currentSoloIndex[localChannel] = nil

    Player:PlaySound(id, name, localChannel)
end

-- Does what it says on the tin, plays this one sound file whilst removing any playlist values
-- Any potential looping of this one sound file is handled by LoopCurrentlyPlaying
function Player:PlaySoundSingle(id, name, localChannel, playlistIndex, soundIndex)
    if not localChannel then
        localChannel = core.Channel.currentChannel
    end

    if playlistIndex and soundIndex then
        Player.currentSoloIndex[localChannel] = {
            playlistIndex = playlistIndex,
            soundIndex = soundIndex
        }
    else
        Player.currentSoloIndex[localChannel] = nil
    end

    Player.currentPlaylist[localChannel] = nil
    Player.currentPlaylistIndex[localChannel] = 1

    -- They have to be here rather than in playsound to ensure that the broadcast doesnt trigger another broadcast
    core.Broadcast:BroadcastAudio("play", id, name, localChannel)
    Player:PlaySound(id, name, localChannel)
end

-- Plays the next sound in the playlist
-- LoopCurrentlyPlaying or the previous/next buttons should have already updated the index to actually be the next sound
-- So this just has to play it, and set the playlist values
-- The only reason this is a seperate function from PlaySoundSingle is so that PlaySoundSingle can remove the playlist values
-- and this can remove the solo values
function Player:PlayNextSoundInPlaylist(localChannel)
    Player.currentSoloIndex[localChannel] = nil
    if not Player.currentPlaylist[localChannel] or #Player.currentPlaylist[localChannel].sounds == 0 then
        EmptyPlaylist()
        return
    end

    local currentSound = Player.currentPlaylist[localChannel].sounds
        [Player.currentPlaylistIndex[localChannel]]

    if currentSound.originalIndex then
        Player.currentCosmeticIndex[localChannel] = currentSound.originalIndex
    end

    if currentSound.delay then
        if Player.currentDelay[localChannel] then
            Player.currentDelay[localChannel]:Cancel()
        end
        Player:StopSoundOnChannel(localChannel)
        Player.UpdateFrame[localChannel]:SetScript("OnUpdate", nil)
        Player.currentId[core.Channel.currentChannel] = currentSound.id
        currentName[core.Channel.currentChannel] = currentSound.name
        currentText[localChannel] = "Delaying for " .. currentSound.time .. " seconds"
        Player.currentDelay[localChannel] = currentSound.delay
        Player.currentDelay[localChannel] = C_Timer.NewTimer(currentSound.time, function()
            if not Player.currentPlaylist[localChannel] then
                return
            end
            Player:NextSoundInPlaylist(localChannel)
        end)
        Player:UpdatePlayer()
        return
    end

    if Player.currentDelay[localChannel] then
        Player.currentDelay[localChannel]:Cancel()
        Player.currentDelay[localChannel] = nil
    end

    -- They have to be here rather than in playsound to ensure that the broadcast doesnt trigger another broadcast
    core.Broadcast:BroadcastAudio("play", currentSound.id, currentSound.name, localChannel)
    Player:PlaySound(currentSound.id, currentSound.name, localChannel)
end
