local _, core = ...
core.Playlist = {}
local Playlist = core.Playlist

local ScrollView = nil

local function FlattenPlaylists()
    local flattenedArray = {}
    for _, playlist in ipairs(GroupMusicVariables.Playlists) do
        local playlistData = {
            name = playlist.name,
            type = "playlist",
            songs = playlist.songs,
            collapsed = playlist.collapsed
        }
        table.insert(flattenedArray, playlistData)
        if not playlist.collapsed then
            for index, song in ipairs(playlist.songs) do
                local songData = {
                    name = song.name,
                    path = song.path,
                    id = song.id,
                    index = index,
                    playlistName = playlist.name,
                    type = "song"
                }
                table.insert(flattenedArray, songData)
            end
        end
    end
    return flattenedArray
end

local function setDataProvider()
    local flattenedArray = FlattenPlaylists()
    local DataProvider = CreateDataProvider(flattenedArray)
    if not ScrollView then
        return;
    end
    ScrollView:SetDataProvider(DataProvider)
end

local function deleteSongFromPlaylist(playlistName, index)
    for i, playlist in ipairs(GroupMusicVariables.Playlists) do
        if playlist.name == playlistName then
            for j, _ in ipairs(playlist.songs) do
                if j == index then
                    table.remove(GroupMusicVariables.Playlists[i].songs, j)
                    setDataProvider()
                    return
                end
            end
        end
    end
end

local function deletePlaylist(playlistName)
    for i, playlist in ipairs(GroupMusicVariables.Playlists) do
        if playlist.name == playlistName then
            table.remove(GroupMusicVariables.Playlists, i)
            setDataProvider()
            return
        end
    end
end

local function collapsePlaylist(collapsed, playlistName)
    for _, playlist in ipairs(GroupMusicVariables.Playlists) do
        if playlist.name == playlistName then
            playlist.collapsed = collapsed
            setDataProvider()
            return
        end
    end
end

local function ChangeDirection(direction, data)
    for _, playlist in ipairs(GroupMusicVariables.Playlists) do
        if playlist.name == data.playlistName then
            local songIndex = nil
            for j, song in ipairs(playlist.songs) do
                if song.id == data.id then
                    songIndex = j
                    break
                end
            end
            if songIndex and #playlist.songs > 1 then
                local directionNumber = direction and -1 or 1
                if songIndex + directionNumber < 1 or songIndex + directionNumber > #playlist.songs then
                    return
                end
                local temp = playlist.songs[songIndex + directionNumber]
                playlist.songs[songIndex + directionNumber] = playlist.songs[songIndex]
                playlist.songs[songIndex] = temp
                break
            end
        end
    end

    setDataProvider()
end

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
        local firstSong = false
        local lastSong = false
        for i = 1, #GroupMusicVariables.Playlists do
            if data.type == "playlist" and data.name == GroupMusicVariables.Playlists[i].name then
                playlistIndex = i
                break
            elseif data.type == "song" and data.playlistName == GroupMusicVariables.Playlists[i].name then
                playlistIndex = i
                for j = 1, #GroupMusicVariables.Playlists[i].songs do
                    if GroupMusicVariables.Playlists[i].songs[j].id == data.id then
                        if j == 1 then
                            firstSong = true
                        end
                        if j == #GroupMusicVariables.Playlists[i].songs then
                            lastSong = true
                        end
                        break
                    end
                end
                break
            end
        end

        if playlistIndex % 2 == 0 then
            frame.BlueBackground:Hide()
            frame.BlueHeaderBackground:Hide()
            frame.BlackBackground:Show()
            frame.BlackHeaderBackground:Show()
        else
            frame.BlackBackground:Hide()
            frame.BlackHeaderBackground:Hide()
            frame.BlueBackground:Show()
            frame.BlueHeaderBackground:Show()
        end

        if data.type == "song" then
            if playlistIndex % 2 == 0 then
                frame.BlackBackground:Show()
            else
                frame.BlueBackground:Show()
            end
            frame.BlueHeaderBackground:Hide()
            frame.BlackHeaderBackground:Hide()
            frame.LoopButton:Show()
            frame.MoveUpButton:Show()
            frame.MoveDownButton:Show()
            frame.MinMaxButton:Hide()
            if firstSong then
                frame.MoveUpButton:Disable()
                frame.MoveUpButton.ArrowTexture:SetDesaturated(true)
            else
                frame.MoveUpButton:Enable()
                frame.MoveUpButton.ArrowTexture:SetDesaturated(false)
            end

            if lastSong then
                frame.MoveDownButton:Disable()
                frame.MoveDownButton.ArrowTexture:SetDesaturated(true)
            else
                frame.MoveDownButton:Enable()
                frame.MoveDownButton.ArrowTexture:SetDesaturated(false)
            end

            frame.DeleteButton:SetScript("OnClick", function()
                deleteSongFromPlaylist(data.playlistName, data.index)
            end)
            frame.PlayButton:SetScript("OnClick", function()
                local playlist = GroupMusicVariables.Playlists[playlistIndex]
                core.Player:SetPlaylist(playlist)
                core.Player:SetPlaylistIndex(data.index)
            end)
            frame.LoopButton:SetScript("OnClick", function()
                core.Player:PlaySongSingle(data.id, data.name)
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
                frame.BlueHeaderBackground:Show()
            end
            frame.BlueBackground:Hide()
            frame.BlackBackground:Hide()
            frame.LoopButton:Hide()
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

function Playlist:NewPlaylist(name)
    if not GroupMusicVariables.Playlists then
        GroupMusicVariables.Playlists = {}
    end

    for _, playlist in ipairs(GroupMusicVariables.Playlists) do
        if playlist.name == name then
            print("Playlist with this name already exists")
            return
        end
    end

    local newPlaylist = {
        name = name,
        collapsed = false,
        songs = {}
    }
    table.insert(GroupMusicVariables.Playlists, newPlaylist)
    setDataProvider()
end

function Playlist:AddSong(playlistName, data)
    if not GroupMusicVariables.Playlists then
        GroupMusicVariables.Playlists = {}
    end

    for _, playlist in ipairs(GroupMusicVariables.Playlists) do
        if playlist.name == playlistName then
            table.insert(playlist.songs, {
                name = data.name,
                path = data.path,
                id = data.id,
            })
            setDataProvider()
            return
        end
    end
end

local function minMaxAll(self)
    local isChecked = self:GetChecked()
    for _, playlist in ipairs(GroupMusicVariables.Playlists) do
        playlist.collapsed = not isChecked
    end
    setDataProvider()
end

function Playlist:CreateBody(width, height)
    if not GroupMusicVariables.Playlists then
        GroupMusicVariables.Playlists = {}
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
    body.PlaylistName.Instructions:SetText("Enter playlist name");
    body.PlaylistName.searchIcon:SetTexture("Interface/BUTTONS/UI-GuildButton-PublicNote-Up")
    body.PlaylistName.searchIcon:SetDesaturated(true)
    body.PlaylistName.searchIcon:SetVertexColor(1, 1, 1, 1)

    body.PlaylistAddButton = CreateFrame("Button", "PlaylistAddButton", body.PlaylistName,
        "SharedButtonTemplate");
    body.PlaylistAddButton:SetSize(60, 24);
    body.PlaylistAddButton:SetPoint("LEFT", body.PlaylistName, "RIGHT", 0, 0);
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
