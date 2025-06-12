local _, core = ...
core.Search = {}
local Search = core.Search

local ScrollView = nil
local AddFrame
local AddFrameScrollView
local selectedSong = nil

local function OpenAddFrame()
    local uiScale, x, y = UIParent:GetEffectiveScale(), GetCursorPosition()
    AddFrame:ClearAllPoints()
    AddFrame:SetPoint("TOPLEFT", nil, "BOTTOMLEFT", x / uiScale - 20, y / uiScale + 10)
    local DataProvider = CreateDataProvider(GroupMusicVariables.Playlists)
    AddFrameScrollView:SetDataProvider(DataProvider)

    AddFrame:Show()
end

local function CreateTooltipScrollView(body, width, height)
    body.ScrollBox = CreateFrame("Frame", nil, body, "WowScrollBoxList")
    body.ScrollBar = CreateFrame("EventFrame", nil, body, "MinimalScrollBar")
    body.ScrollBox:SetSize(width - 20, height - 34)
    body.ScrollBox:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -20)
    body.ScrollBar:SetPoint("TOPLEFT", body.ScrollBox, "TOPRIGHT")
    body.ScrollBar:SetPoint("BOTTOMLEFT", body.ScrollBox, "BOTTOMRIGHT")

    AddFrameScrollView = CreateScrollBoxListLinearView()
    ScrollUtil.InitScrollBoxListWithScrollBar(body.ScrollBox, body.ScrollBar, AddFrameScrollView)
    AddFrameScrollView:SetElementExtent(24)

    local function Initializer(frame, data)
        local index = frame:GetOrderIndex()
        if index % 2 == 0 then
            frame.BlueBackground:Hide()
            frame.BlackBackground:Show()
        else
            frame.BlueBackground:Show()
            frame.BlackBackground:Hide()
        end
        frame.Text:SetText(data.name)

        frame:SetScript("OnClick", function()
            if selectedSong then
                core.Playlist:AddSong(data.name, selectedSong)
                selectedSong = nil
                AddFrame:Hide()
            end
        end)
    end
    AddFrameScrollView:SetElementInitializer("TooltipPlaylistTemplate", Initializer)

    local DataProvider = CreateDataProvider(GroupMusicVariables.Playlists)
    AddFrameScrollView:SetDataProvider(DataProvider)

    return body.ScrollBox, body.ScrollBar
end

local function CreateScrollView(body, width, height)
    body.ScrollBox = CreateFrame("Frame", nil, body, "WowScrollBoxList")
    body.ScrollBar = CreateFrame("EventFrame", nil, body, "MinimalScrollBar")
    body.ScrollBox:SetSize(width - 20, height - 34)
    body.ScrollBox:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -30)
    body.ScrollBar:SetPoint("TOPLEFT", body.ScrollBox, "TOPRIGHT")
    body.ScrollBar:SetPoint("BOTTOMLEFT", body.ScrollBox, "BOTTOMRIGHT")

    ScrollView = CreateScrollBoxListLinearView()
    ScrollUtil.InitScrollBoxListWithScrollBar(body.ScrollBox, body.ScrollBar, ScrollView)
    ScrollView:SetElementExtent(24)

    local function Initializer(frame, data)
        local index = frame:GetOrderIndex()
        if index % 2 == 0 then
            frame.BlueBackground:Hide()
            frame.BlackBackground:Show()
        else
            frame.BlueBackground:Show()
            frame.BlackBackground:Hide()
        end
        frame.Text:SetText(data.name)
        frame.PlayButton:SetScript("OnClick", function()
            -- Play the sound when the frame is clicked
            if data.id then
                core.Player:PlaySongSingle(data.id, data.name)
            end
        end)
        frame.PlaylistButton:SetScript("OnClick", function()
            OpenAddFrame()
            selectedSong = data
        end)

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
    end
    ScrollView:SetElementInitializer("SongFrameTemplate", Initializer)

    local DataProvider = CreateDataProvider(core.music)
    ScrollView:SetDataProvider(DataProvider)

    return body.ScrollBox, body.ScrollBar
end

function Search:CreateBody(width, height)
    local body = CreateFrame("Frame", "SearchBody", nil, "InsetFrameTemplate");
    body:SetSize(width, height);

    CreateScrollView(body, width, height);

    body.SearchBar = CreateFrame("EditBox", "SearchBar", body, "SearchBoxTemplate")
    body.SearchBar:SetSize(width - 20, 30);
    body.SearchBar:SetPoint("TOP", body, "TOP", 2, -2)
    body.SearchBar:SetScript("OnEnterPressed", function()
        local searchText = body.SearchBar:GetText();
        if not ScrollView then
            return
        end
        if searchText and searchText ~= "" then
            local filteredData = core.utils.filter(core.music, function(file)
                return string.find(string.lower(file.path), string.lower(searchText), 1,
                    true) ~= nil or file.id == searchText;
            end);

            local DataProvider = CreateDataProvider(filteredData)
            ScrollView:SetDataProvider(DataProvider)
        elseif searchText == "" then
            local DataProvider = CreateDataProvider(core.music)
            ScrollView:SetDataProvider(DataProvider)
        end
        body.SearchBar:ClearFocus();
    end);

    AddFrame = CreateFrame("Frame", "AddFrame", body, "DefaultPanelTemplate")
    AddFrame:SetFrameStrata("TOOLTIP")
    AddFrame:SetSize(100, 180);
    AddFrame.title = AddFrame.TitleContainer:CreateFontString("TITLETEXT");
    AddFrame.title:SetFontObject("GameFontNormal")
    AddFrame.title:SetPoint("CENTER")
    AddFrame.title:SetText("Add to Playlist")
    CreateTooltipScrollView(AddFrame, 100, 180)
    OpenAddFrame();
    AddFrame:Hide()

    AddFrame:RegisterEvent("GLOBAL_MOUSE_DOWN")
    AddFrame:SetScript("OnEvent", function()
        if AddFrame:IsShown() and not AddFrame:IsMouseOver() then
            AddFrame:Hide()
        end
    end)
    return body;
end
