local _, core = ...
core.Search = {}
local Search = core.Search

local ScrollView = nil
local AddFrame
local AddFrameScrollView
local selectedSong = nil
local body

local searchTable = nil

local function OpenAddFrame()
    local uiScale, x, y = UIParent:GetEffectiveScale(), GetCursorPosition()
    AddFrame:ClearAllPoints()
    AddFrame:SetPoint("TOPLEFT", nil, "BOTTOMLEFT", x / uiScale - 20, y / uiScale + 10)
    local DataProvider = CreateDataProvider(ShortWaveVariables.Playlists[core.Channel.currentChannel])
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
        frame.ColorBackground:SetColorTexture(
            core.Channel.defaultColours[core.Channel.channelIndex[core.Channel.currentChannel]].r or 0.1,
            core.Channel.defaultColours[core.Channel.channelIndex[core.Channel.currentChannel]].g or 0.1,
            core.Channel.defaultColours[core.Channel.channelIndex[core.Channel.currentChannel]].b or 0.1, 0.050)
        if index % 2 == 0 then
            frame.ColorBackground:Hide()
            frame.BlackBackground:Show()
        else
            frame.ColorBackground:Show()
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

    local DataProvider = CreateDataProvider(ShortWaveVariables.Playlists[core.Channel.currentChannel])
    AddFrameScrollView:SetDataProvider(DataProvider)

    return body.ScrollBox, body.ScrollBar
end

local function GetSearchList()
    local searchList = core.DataLoader:GetData(ShortWaveVariables.selectedCore[core.Channel.currentChannel])
    return searchList or {}
end

local function SelectCore()
    if not ShortWaveVariables.selectedCore then
        ShortWaveVariables.selectedCore = {}
    end
    local coreList = core.Channel.searchData[core.Channel.currentChannel]
    if not coreList then
        return
    end
    if not ShortWaveVariables.selectedCore[core.Channel.currentChannel] then
        ShortWaveVariables.selectedCore[core.Channel.currentChannel] = coreList[1]
    else
        ShortWaveVariables.selectedCore[core.Channel.currentChannel] = ShortWaveVariables.selectedCore
            [core.Channel.currentChannel]
    end
end

local function SetCoreSwitchButtons()
    local searchData = core.Channel.searchData[core.Channel.currentChannel] or {}
    local expand = #searchData > 1

    if expand then
        body.ScrollBox:SetSize(body.ScrollBox:GetWidth(), body:GetHeight() - 64)
        body.ScrollBox:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -54)
        body.SearchBar:SetPoint("TOP", body, "TOP", 2, -26)
        body.CategoryButtons:Show()
    else
        body.ScrollBox:SetSize(body.ScrollBox:GetWidth(), body:GetHeight() - 34)
        body.ScrollBox:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -30)
        body.SearchBar:SetPoint("TOP", body, "TOP", 2, -2)
        body.CategoryButtons:Hide()
    end
end

function Search:RefreshSearchBody()
    if ScrollView then
        local DataProvider = CreateDataProvider(searchTable)
        ScrollView:SetDataProvider(DataProvider)
    end
end

function Search:ClearSearchBody()
    if AddFrame then
        AddFrame:Hide()
    end
    if not body or ShortWaveVariables.selectedTab ~= "search" then
        return
    end
    Search:WipeSearchbar()
    SelectCore()
    SetCoreSwitchButtons()
    searchTable = GetSearchList()
    Search:RefreshSearchBody()
end

function Search:SetErrorText(text)
    if not body or not body.ErrorText then
        return
    end
    if text and text ~= "" then
        body.ErrorText:SetText(text)
        body.ErrorText:Show()
    else
        body.ErrorText:Hide()
    end
end

local function CreateScrollView(width, height)
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
        if ShortWaveVariables.selectedCore[core.Channel.currentChannel] == "creature" then
            local creatureData = {
                name = ShortWaveGlobalData.creatureName[data] or "",
                id = ShortWaveGlobalData.creatureId[data] or "0",
                path = ShortWaveGlobalData.creaturePath[data] or ""
            }
            data = creatureData
        end
        frame.ColorBackground:SetColorTexture(
            core.Channel.defaultColours[core.Channel.channelIndex[core.Channel.currentChannel]].r or 0.1,
            core.Channel.defaultColours[core.Channel.channelIndex[core.Channel.currentChannel]].g or 0.1,
            core.Channel.defaultColours[core.Channel.channelIndex[core.Channel.currentChannel]].b or 0.1, 0.1)
        if index % 2 == 0 then
            frame.ColorBackground:Hide()
            frame.BlackBackground:Show()
        else
            frame.ColorBackground:Show()
            frame.BlackBackground:Hide()
        end

        frame.Text:SetText(data.name)

        if core.Player.currentlyPlaying[core.Channel.currentChannel] and core.Player.currentId[core.Channel.currentChannel] == data.id and core.Player.currentSoloIndex[core.Channel.currentChannel] == nil and core.Player.currentPlaylist[core.Channel.currentChannel] == nil then
            frame.PlayButton:Hide()
            frame.StopButton:Show()
        else
            frame.PlayButton:Show()
            frame.StopButton:Hide()
        end
        frame.PlayButton:SetScript("OnClick", function()
            -- Play the sound when the frame is clicked
            if data.id then
                core.Player:PlaySongSingle(data.id, data.name)
            end
        end)
        frame.StopButton:SetScript("OnClick", function()
            core.Player:PauseSong()
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

    return body.ScrollBox, body.ScrollBar
end

function Search:CreateBody(width, height)
    body = CreateFrame("Frame", "SearchBody", nil, "InsetFrameTemplate");
    body:SetSize(width, height);

    body.ErrorText = body:CreateFontString("ErrorText", "OVERLAY", "GameFontNormal")
    body.ErrorText:SetPoint("LEFT", 4, 0)
    body.ErrorText:SetPoint("RIGHT", -16, 0)
    body.ErrorText:SetJustifyV("MIDDLE")
    body.ErrorText:SetTextColor(1, 1, 0, 1)
    body.ErrorText:SetJustifyH("CENTER")

    body.SearchBar = CreateFrame("EditBox", "SearchBar", body, "SearchBoxTemplate")
    body.SearchBar:SetSize(width - 20, 30);
    body.SearchBar:SetPoint("TOP", body, "TOP", 2, -2)
    body.SearchBar:SetScript("OnEnterPressed", function()
        local searchText = body.SearchBar:GetText();
        if not ScrollView then
            return
        end
        if searchText and searchText ~= "" then
            local filteredData
            if ShortWaveVariables.selectedCore[core.Channel.currentChannel] == "creature" then
                filteredData = core.Utils.filter(GetSearchList(),
                    function(_, index)
                        return string.find(string.lower(ShortWaveGlobalData.creaturePath[index]),
                            string.lower(searchText), 1,
                            true) ~= nil or ShortWaveGlobalData.creatureId[index] == searchText;
                    end);
            else
                filteredData = core.Utils.filter(GetSearchList(),
                    function(file)
                        return string.find(string.lower(file.path), string.lower(searchText), 1,
                            true) ~= nil or file.id == searchText;
                    end);
            end

            searchTable = filteredData
            Search:RefreshSearchBody()
        elseif searchText == "" then
            Search:ClearSearchBody()
        end
        body.SearchBar:ClearFocus();
    end);

    function Search:WipeSearchbar()
        body.SearchBar:SetText("");
        body.SearchBar:ClearFocus();
    end

    body.CategoryButtons = CreateFrame("Frame", "CategoryButtons", body)
    body.CategoryButtons:SetPoint("TOPLEFT", body, "TOPLEFT", 12, -2)
    body.CategoryButtons:SetSize(body:GetWidth() - 8, 24)

    local function setTabSizes(self)
        self.Middle:SetTexCoord(0, 1, 1, 0)
        self.Middle:SetSize(26, 26)
        self.Left:SetTexCoord(0, 1, 1, 0)
        self.Left:SetSize(26, 26)
        self.Right:SetTexCoord(0, 1, 1, 0)
        self.Right:SetSize(26, 26)

        self.MiddleHighlight:SetTexCoord(0, 1, 1, 0)
        self.MiddleHighlight:SetSize(26, 26)
        self.LeftHighlight:SetTexCoord(0, 1, 1, 0)
        self.LeftHighlight:SetSize(26, 26)
        self.RightHighlight:SetTexCoord(0, 1, 1, 0)
        self.RightHighlight:SetSize(26, 26)

        self.MiddleActive:SetTexCoord(0, 1, 1, 0)
        self.MiddleActive:SetSize(26, 30)
        self.LeftActive:AdjustPointsOffset(0, 4)
        self.LeftActive:SetTexCoord(0, 1, 1, 0)
        self.LeftActive:SetSize(26, 30)
        self.RightActive:AdjustPointsOffset(0, 4)
        self.RightActive:SetTexCoord(0, 1, 1, 0)
        self.RightActive:SetSize(26, 30)
    end

    local tabs = {}

    local function selectTab(tabName)
        for _, tab in ipairs(tabs) do
            if tab:GetName() == tabName then
                PanelTemplates_SelectTab(tab)
                tab.Text:SetHeight(20)
                ShortWaveVariables.selectedCore[core.Channel.channels[3]] = tabName
                Search:ClearSearchBody()
            else
                PanelTemplates_DeselectTab(tab)
                tab.Text:SetHeight(1)
            end
        end
    end

    local lastFrame = nil
    for _, localCore in ipairs(core.Channel.searchData[core.Channel.channels[3]]) do
        local tab = CreateFrame("Button", localCore, body.CategoryButtons,
            "PanelTabButtonTemplate")
        tab:SetSize(100, 26)
        tab.Text:SetText(localCore)
        tab.Text:SetJustifyV("TOP")
        tab:SetScript("OnClick", function()
            selectTab(tab:GetName())
        end)
        setTabSizes(tab)
        if lastFrame then
            tab:SetPoint("LEFT", lastFrame, "RIGHT", 10, 0)
        else
            tab:SetPoint("BOTTOMLEFT", body.CategoryButtons, "BOTTOMLEFT", 0, -6)
        end
        lastFrame = tab
        table.insert(tabs, tab)
    end

    CreateScrollView(width, height);

    SelectCore()

    selectTab(ShortWaveVariables.selectedCore[core.Channel.channels[3]] or
        core.Channel.searchData[core.Channel.channels[3]][1])

    body.CategoryButtons:Hide()

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
