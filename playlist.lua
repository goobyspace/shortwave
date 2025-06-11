local _, core = ...
core.Playlist = {}
local Playlist = core.Playlist

local ScrollView = nil

local function FlattenPlaylists()
    local flattenedArray = {}
    for _, playlist in ipairs(GroupMusicVariables.Playlists) do
        local playlistData = {
            name = playlist.name,
            songs = playlist.songs,
            type = "playlist"
        }
        table.insert(flattenedArray, playlistData)
        for _, song in ipairs(playlist.songs) do
            local songData = {
                name = song.name,
                path = song.path,
                id = song.id,
                looping = song.looping,
                playlistName = playlist.name,
                type = "song"
            }
            table.insert(flattenedArray, songData)
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

local function deleteSongFromPlaylist(playlistName, songId)
    for i, playlist in ipairs(GroupMusicVariables.Playlists) do
        if playlist.name == playlistName then
            for j, song in ipairs(playlist.songs) do
                if song.id == songId then
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
    body.ScrollBox:SetSize(width - 20, height - 4)
    body.ScrollBox:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -4)
    body.ScrollBar:SetPoint("TOPLEFT", body.ScrollBox, "TOPRIGHT")
    body.ScrollBar:SetPoint("BOTTOMLEFT", body.ScrollBox, "BOTTOMRIGHT")

    ScrollView = CreateScrollBoxListLinearView()
    ScrollUtil.InitScrollBoxListWithScrollBar(body.ScrollBox, body.ScrollBar, ScrollView)
    ScrollView:SetElementExtent(24)

    local function Initializer(frame, data)
        local index = 0
        for i = 1, #GroupMusicVariables.Playlists do
            if data.type == "playlist" and data.name == GroupMusicVariables.Playlists[i].name then
                index = i
                break
            elseif data.type == "song" and data.playlistName == GroupMusicVariables.Playlists[i].name then
                index = i
                break
            end
        end
        if index % 2 == 0 then
            frame.BlueBackground:Hide()
            frame.BlackBackground:Show()
        else
            frame.BlueBackground:Show()
            frame.BlackBackground:Hide()
        end

        if data.type == "song" then
            frame.DeleteButton:SetScript("OnClick", function()
                deleteSongFromPlaylist(data.playlistName, data.id)
            end)
            frame.PlayButton:SetScript("OnClick", function()
                print("Playing playlist from this song")
            end)
            frame.LoopButton:SetScript("OnClick", function()
                core.Player:PlaySong(data.id, data.name)
            end)
            frame.MoveUpButton:SetScript("OnClick", function()
                ChangeDirection(true, data)
            end)
            frame.MoveDownButton:SetScript("OnClick", function()
                ChangeDirection(false, data)
            end)
        else
            frame.LoopButton:Hide()
            frame.PlayButton:SetScript("OnClick", function()
                print("Playing entire playlist from start")
            end)
            frame.DeleteButton:SetScript("OnClick", function()
                deletePlaylist(data.name)
            end)
            frame.MoveUpButton:Hide()
            frame.MoveDownButton:Hide()
        end

        frame.Text:SetText(data.name)
    end
    ScrollView:SetElementInitializer("PlaylistTemplate", Initializer)

    local DataProvider = CreateDataProvider({})
    ScrollView:SetDataProvider(DataProvider)

    return body.ScrollBox, body.ScrollBar
end

function Playlist:CreateBody(width, height)
    GroupMusicVariables.Playlists = {
        {
            name = "Default Playlist",
            songs = {
                {
                    name = "Song 1",
                    path = "Interface\\AddOns\\MyAddon\\Sounds\\song1.mp3",
                    id = 123,
                    looping = false
                },
                {
                    name = "Song 2",
                    path = "Interface\\AddOns\\MyAddon\\Sounds\\song1.mp3",
                    id = 456,
                    looping = false
                },
                {
                    name = "Song 17",
                    path = "Interface\\AddOns\\MyAddon\\Sounds\\song1.mp3",
                    id = 7778,
                    looping = false
                }
            }
        },
        {
            name = "Second Playlist",
            songs = {
                {
                    name = "Song 1",
                    path = "Interface\\AddOns\\MyAddon\\Sounds\\song1.mp3",
                    id = 123,
                    looping = false
                },
                {
                    name = "Song 3",
                    path = "Interface\\AddOns\\MyAddon\\Sounds\\song1.mp3",
                    id = 1555,
                    looping = false
                }
            }
        }
    }
    local body = CreateFrame("Frame", "PlaylistBody", nil, "InsetFrameTemplate");
    body:SetSize(width, height);

    CreateScrollView(body, width, height);

    setDataProvider()

    return body;
end
