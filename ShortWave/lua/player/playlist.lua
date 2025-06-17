local _, core = ...
core.Playlist = {}
local Playlist = core.Playlist

local ScrollView = nil

-- so the playlist function works as follows:
-- playlists are object in the ShortWaveVariables saved variable, so that they persist
-- playlist objects have a name & a list of sounds
-- sounds have a name, path, & id
-- to get a nice overview of the playlists in one scroll window
-- we flatten the playlists into a single array, rather than having a nested structure
-- this way we can easily display the playlists and their sounds in a single scroll view
local function FlattenPlaylists()
    local flattenedArray = {}
    if not ShortWaveVariables.Playlists[core.Channel.currentChannel] then
        return flattenedArray
    end
    for playlistIndex, playlist in ipairs(ShortWaveVariables.Playlists[core.Channel.currentChannel]) do
        local isPlaylistPlaying = core.Player.currentlyPlaying[core.Channel.currentChannel] and
            core.Player.currentPlaylist[core.Channel.currentChannel] and
            core.Player.currentPlaylist[core.Channel.currentChannel].name == playlist.name
        local playlistData = {
            name = playlist.name,
            type = "playlist",
            sounds = playlist.sounds,
            playing = isPlaylistPlaying,
            collapsed = playlist.collapsed
        }
        table.insert(flattenedArray, playlistData)
        if not playlist.collapsed then
            for index, sound in ipairs(playlist.sounds) do
                local soundData = {
                    name = sound.name,
                    path = sound.path,
                    id = sound.id,
                    index = index,
                    playing = isPlaylistPlaying and
                        core.Player.currentPlaylistIndex[core.Channel.currentChannel] == index,
                    soloPlaying = core.Player.currentlyPlaying[core.Channel.currentChannel]
                        and core.Player.currentSoloIndex and
                        core.Player.currentSoloIndex[core.Channel.currentChannel] and
                        core.Player.currentSoloIndex[core.Channel.currentChannel].soundIndex == index and
                        core.Player.currentSoloIndex[core.Channel.currentChannel].playlistIndex == playlistIndex,
                    playlistName = playlist.name,
                    type = "sound"
                }
                table.insert(flattenedArray, soundData)
            end
        end
    end
    return flattenedArray
end

-- create a new data provider for the scroll view
-- then set it
-- this is faster than directly manipulating the data or the scroll view
local function setDataProvider()
    local flattenedArray = FlattenPlaylists()
    local DataProvider = CreateDataProvider(flattenedArray)
    if not ScrollView then
        return;
    end
    ScrollView:SetDataProvider(DataProvider)
end

-- wipe the name then go agane, used by the channel to refresh the playlists
function Playlist:RefreshPlaylists()
    if not ScrollView then
        return;
    end
    -- this resets the playlist name input field specifically
    Playlist:WipePlaylistName()
    setDataProvider()
end

-- delete a specific sound from a playlist, this is also part of why playlist names have to be unique
local function deleteSoundFromPlaylist(playlistName, index)
    for i, playlist in ipairs(ShortWaveVariables.Playlists[core.Channel.currentChannel]) do
        if playlist.name == playlistName then
            for j, _ in ipairs(playlist.sounds) do
                if j == index then
                    table.remove(ShortWaveVariables.Playlists[core.Channel.currentChannel][i].sounds, j)
                    setDataProvider()
                    return
                end
            end
        end
    end
end

-- delete the entire playlist
local function deletePlaylist(playlistName)
    for i, playlist in ipairs(ShortWaveVariables.Playlists[core.Channel.currentChannel]) do
        if playlist.name == playlistName then
            table.remove(ShortWaveVariables.Playlists[core.Channel.currentChannel], i)
            setDataProvider()
            return
        end
    end
end

-- this sets the collapsed state of a playlist, meaning flattenPlaylists will ignore the sounds inside the playlist
local function collapsePlaylist(collapsed, playlistName)
    for _, playlist in ipairs(ShortWaveVariables.Playlists[core.Channel.currentChannel]) do
        if playlist.name == playlistName then
            playlist.collapsed = collapsed
            setDataProvider()
            return
        end
    end
end

-- this swaps the position of a sound in the playlist with the one above or below it, depending on the direction
-- direction is true for up aka lowering the index, false for down aka increasing the index
local function ChangeDirection(direction, data)
    for _, playlist in ipairs(ShortWaveVariables.Playlists[core.Channel.currentChannel]) do
        if playlist.name == data.playlistName then
            local soundIndex = nil
            for j, sound in ipairs(playlist.sounds) do
                if sound.id == data.id then
                    soundIndex = j
                    break
                end
            end
            if soundIndex and #playlist.sounds > 1 then
                local directionNumber = direction and -1 or 1
                if soundIndex + directionNumber < 1 or soundIndex + directionNumber > #playlist.sounds then
                    return
                end
                local temp = playlist.sounds[soundIndex + directionNumber]
                playlist.sounds[soundIndex + directionNumber] = playlist.sounds[soundIndex]
                playlist.sounds[soundIndex] = temp
                break
            end
        end
    end

    setDataProvider()
end

-- Creates the entire scrollview
-- the initializer function inside does all the work
local function CreateScrollView(body, width, height)
    body.ScrollBox = CreateFrame("Frame", nil, body, "WowScrollBoxList")
    body.ScrollBar = CreateFrame("EventFrame", nil, body, "MinimalScrollBar")
    body.ScrollBox:SetSize(width - 20, height - 36)
    body.ScrollBox:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -32)
    body.ScrollBar:SetPoint("TOPLEFT", body.ScrollBox, "TOPRIGHT")
    body.ScrollBar:SetPoint("BOTTOMLEFT", body.ScrollBox, "BOTTOMRIGHT")

    ScrollView = CreateScrollBoxListLinearView()
    ScrollUtil.InitScrollBoxListWithScrollBar(body.ScrollBox, body.ScrollBar, ScrollView)
    ScrollView:SetElementExtent(24)

    function Playlist.Initializer(frame, data)
        local playlistIndex = 0
        local firstSound = false
        local lastSound = false
        for i = 1, #ShortWaveVariables.Playlists[core.Channel.currentChannel] do
            if data.type == "playlist" and data.name == ShortWaveVariables.Playlists[core.Channel.currentChannel][i].name then
                playlistIndex = i
                break
            elseif data.type == "sound" and data.playlistName == ShortWaveVariables.Playlists[core.Channel.currentChannel][i].name then
                playlistIndex = i
                for j = 1, #ShortWaveVariables.Playlists[core.Channel.currentChannel][i].sounds do
                    if ShortWaveVariables.Playlists[core.Channel.currentChannel][i].sounds[j].id == data.id then
                        if j == 1 then
                            firstSound = true
                        end
                        if j == #ShortWaveVariables.Playlists[core.Channel.currentChannel][i].sounds then
                            lastSound = true
                        end
                        break
                    end
                end
                break
            end
        end

        frame.ColorBackground:SetColorTexture(
            core.Channel.defaultColours[core.Channel.channelIndex[core.Channel.currentChannel]].r or 0.1,
            core.Channel.defaultColours[core.Channel.channelIndex[core.Channel.currentChannel]].g or 0.1,
            core.Channel.defaultColours[core.Channel.channelIndex[core.Channel.currentChannel]].b or 0.1, 0.050)
        frame.ColorHeaderBackground:SetColorTexture(
            core.Channel.defaultColours[core.Channel.channelIndex[core.Channel.currentChannel]].r or 0.1,
            core.Channel.defaultColours[core.Channel.channelIndex[core.Channel.currentChannel]].g or 0.1,
            core.Channel.defaultColours[core.Channel.channelIndex[core.Channel.currentChannel]].b or 0.1, 0.10)

        -- Set the frame's background color based on the playlist index so that we alternate color
        if playlistIndex % 2 == 0 then
            frame.ColorBackground:Hide()
            frame.ColorHeaderBackground:Hide()
            frame.BlackBackground:Show()
            frame.BlackHeaderBackground:Show()
        else
            frame.BlackBackground:Hide()
            frame.BlackHeaderBackground:Hide()
            frame.ColorBackground:Show()
            frame.ColorHeaderBackground:Show()
        end

        -- play/pause buttons so that we can see if a sound is playing from the playlist
        -- gives it a nice visual indicator
        if data.playing then
            frame.PlayButton:Hide()
            frame.StopButton:Show()
        else
            frame.PlayButton:Show()
            frame.StopButton:Hide()
        end

        frame.StopButton:SetScript("OnClick", function()
            core.Player:PauseSound()
        end)

        -- sets all the frame data depending on if its a sound or a playlist
        if data.type == "sound" then
            if playlistIndex % 2 == 0 then
                frame.BlackBackground:Show()
            else
                frame.ColorBackground:Show()
            end
            frame.ColorHeaderBackground:Hide()
            frame.BlackHeaderBackground:Hide()

            if data.soloPlaying then
                frame.SinglePlayButton:Hide()
                frame.LoopButton:Hide()
                frame.StopSpecialButton:Show()
            else
                if core.Channel.LoopType[core.Channel.channelIndex[core.Channel.currentChannel]] then
                    frame.LoopButton:Show()
                    core.Utils.createGameTooltip(frame.LoopButton, "Loop Sound")
                    frame.SinglePlayButton:Hide()
                else
                    frame.LoopButton:Hide()
                    core.Utils.createGameTooltip(frame.SinglePlayButton, "Play Sound Once")
                    frame.SinglePlayButton:Show()
                end
                frame.StopSpecialButton:Hide()
            end



            frame.MoveUpButton:Show()
            frame.MoveDownButton:Show()
            frame.MinMaxButton:Hide()
            if firstSound then
                frame.MoveUpButton:Disable()
                frame.MoveUpButton.ArrowTexture:SetDesaturated(true)
            else
                frame.MoveUpButton:Enable()
                frame.MoveUpButton.ArrowTexture:SetDesaturated(false)
            end

            if lastSound then
                frame.MoveDownButton:Disable()
                frame.MoveDownButton.ArrowTexture:SetDesaturated(true)
            else
                frame.MoveDownButton:Enable()
                frame.MoveDownButton.ArrowTexture:SetDesaturated(false)
            end

            frame.DeleteButton:SetScript("OnClick", function()
                deleteSoundFromPlaylist(data.playlistName, data.index)
            end)
            frame.PlayButton:SetScript("OnClick", function()
                local playlist = ShortWaveVariables.Playlists[core.Channel.currentChannel][playlistIndex]
                core.Player:SetPlaylist(playlist)
                core.Player:SetPlaylistIndex(data.index)
            end)
            frame.SinglePlayButton:SetScript("OnClick", function()
                core.Player:PlaySoundSingle(data.id, data.name, nil, playlistIndex, data.index)
            end)
            frame.LoopButton:SetScript("OnClick", function()
                core.Player:PlaySoundSingle(data.id, data.name, nil, playlistIndex, data.index)
            end)
            frame.StopSpecialButton:SetScript("OnClick", function()
                core.Player:PauseSound()
            end)
            frame.MoveUpButton:SetScript("OnClick", function()
                ChangeDirection(true, data)
            end)
            frame.MoveDownButton:SetScript("OnClick", function()
                ChangeDirection(false, data)
            end)
        else
            if playlistIndex % 2 == 0 then
                frame.BlackHeaderBackground:Show()
            else
                frame.ColorHeaderBackground:Show()
            end
            frame.ColorBackground:Hide()
            frame.BlackBackground:Hide()
            frame.LoopButton:Hide()
            frame.SinglePlayButton:Hide()
            frame.StopSpecialButton:Hide()
            frame.MoveUpButton:Hide()
            frame.MoveDownButton:Hide()
            frame.MinMaxButton:Show()
            frame.MinMaxButton:SetChecked(data.collapsed)

            frame.MinMaxButton:SetScript("OnClick", function()
                collapsePlaylist(not data.collapsed, data.name)
            end)

            frame.PlayButton:SetScript("OnClick", function()
                core.Player:SetPlaylist(data)
            end)
            frame.DeleteButton:SetScript("OnClick", function()
                deletePlaylist(data.name)
            end)
        end

        -- if the name is too long, we show a tooltip on hover
        frame:SetScript("OnEnter", function()
            if frame.Text:GetUnboundedStringWidth() > frame.Text:GetWidth() then
                GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
                GameTooltip:SetText(data.name, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)

        frame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        frame.Text:SetTextToFit(data.name)
    end

    ScrollView:SetElementInitializer("PlaylistTemplate", Playlist.Initializer)

    local DataProvider = CreateDataProvider({})
    ScrollView:SetDataProvider(DataProvider)

    return body.ScrollBox, body.ScrollBar
end

-- Make a new playlist and ensure the name is unique
function Playlist:NewPlaylist(name)
    if not ShortWaveVariables.Playlists[core.Channel.currentChannel] then
        ShortWaveVariables.Playlists[core.Channel.currentChannel] = {}
    end

    for _, playlist in ipairs(ShortWaveVariables.Playlists[core.Channel.currentChannel]) do
        if playlist.name == name then
            print("|cffff4a4aShortwave: Playlist with this name already exists")
            return
        end
    end

    local newPlaylist = {
        name = name,
        collapsed = false,
        sounds = {}
    }
    table.insert(ShortWaveVariables.Playlists[core.Channel.currentChannel], newPlaylist)
    setDataProvider()
end

-- insert a sound into a playlist
function Playlist:AddSound(playlistName, data)
    if not ShortWaveVariables.Playlists[core.Channel.currentChannel] then
        ShortWaveVariables.Playlists[core.Channel.currentChannel] = {}
    end

    for _, playlist in ipairs(ShortWaveVariables.Playlists[core.Channel.currentChannel]) do
        if playlist.name == playlistName then
            table.insert(playlist.sounds, {
                name = data.name,
                path = data.path,
                id = data.id,
            })
            setDataProvider()
            return
        end
    end
end

-- set all playlists to collapsed or expanded based on the checkbox state
local function minMaxAll(self)
    local isChecked = self:GetChecked()
    for _, playlist in ipairs(ShortWaveVariables.Playlists[core.Channel.currentChannel]) do
        playlist.collapsed = not isChecked
    end
    setDataProvider()
end

-- create the playlist body, including the scrollview
function Playlist:CreateBody(width, height)
    if not ShortWaveVariables.Playlists then
        ShortWaveVariables.Playlists = {}
        for _, channel in ipairs(core.Channel.channels) do
            ShortWaveVariables.Playlists[channel] = {}
        end
    end


    local body = CreateFrame("Frame", "PlaylistBody", nil, "InsetFrameTemplate");
    body:SetSize(width, height);

    body.minMax = CreateFrame("CheckButton", nil, body)
    body.minMax:SetSize(24, 24)
    body.minMax:SetPoint("TOPLEFT", body, "TOPLEFT", 6, -4);
    body.minMax:SetScript("OnClick", minMaxAll)
    body.minMax:SetChecked(false)

    body.minusTexture = body.minMax:CreateTexture("MinusTexture")
    body.minusTexture:SetSize(24, 24)
    body.minusTexture:SetPoint("CENTER", body.minMax, "CENTER", -2, 0)
    body.minusTexture:SetTexture("Interface/Options/OptionsExpandListButton")
    body.minusTexture:SetTexCoord(0.234375, 0.46875, 0.4296875, 0.6484375)

    body.plusTexture = body.minMax:CreateTexture("PlusTexture")
    body.plusTexture:SetSize(24, 24)
    body.plusTexture:SetPoint("CENTER", body.minMax, "CENTER", -2, 0)
    body.plusTexture:SetTexture("Interface/Options/OptionsExpandListButton")
    body.plusTexture:SetTexCoord(0, 0.234375, 0.4296875, 0.6484375)

    body.minMax:SetNormalTexture(body.plusTexture)
    body.minMax:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
    body.minMax:SetCheckedTexture(body.minusTexture)

    body.PlaylistName = CreateFrame("EditBox", "PlaylistName", body, "SearchBoxTemplate");
    body.PlaylistName:SetSize(width - 100, 30);
    body.PlaylistName:SetPoint("LEFT", body.minMax, "RIGHT", 6, 0);
    body.PlaylistName:SetMaxLetters(28);
    body.PlaylistName.Instructions:SetText("Enter playlist name");
    body.PlaylistName.searchIcon:SetTexture("Interface/BUTTONS/UI-GuildButton-PublicNote-Up")
    body.PlaylistName.searchIcon:SetDesaturated(true)
    body.PlaylistName.searchIcon:SetVertexColor(1, 1, 1, 1)

    function Playlist:WipePlaylistName()
        body.PlaylistName:ClearFocus();
        body.PlaylistName:SetText("");
    end

    body.PlaylistAddButton = CreateFrame("Button", "PlaylistAddButton", body.PlaylistName,
        "SharedButtonTemplate");
    body.PlaylistAddButton:SetSize(58, 24);
    body.PlaylistAddButton:SetPoint("LEFT", body.PlaylistName, "RIGHT", 1, 0);
    body.PlaylistAddButton:SetText("Create");

    body.PlaylistAddButton:SetScript("OnClick", function()
        local playlistName = body.PlaylistName:GetText();
        if playlistName and playlistName ~= "" then
            Playlist:NewPlaylist(playlistName);
            body.PlaylistName:ClearFocus();
            body.PlaylistName:SetText("");
        end
    end);

    CreateScrollView(body, width, height);

    setDataProvider()

    return body;
end
