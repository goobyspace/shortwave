-------------------------------
-- Namespaces & Variables
-------------------------------
local _, core = ...
core.PlayerWindow = {}
local PlayerWindow = core.PlayerWindow
local ShortWaveConfig
-------------------------------

function PlayerWindow:Toggle()
    local menu = ShortWaveConfig or PlayerWindow:CreateWindow()
    menu:SetShown(not menu:IsShown())
end

local SetMovable = function(f)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self, _)
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, xOfs, yOfs = f:GetPoint();
        ShortWaveVariables.point = point;
        ShortWaveVariables.xOfs = xOfs;
        ShortWaveVariables.yOfs = yOfs;
    end);
    f:SetUserPlaced(true);
end

local PlayerLeaderCheck = function()
    print("We've been called")
    local isLeader = core.Broadcast:IsLeader("player")
    if core.isLeader ~= isLeader then
        core.isLeader = isLeader
        if PlayerWindow.window then
            if not PlayerWindow.window.crown then
                PlayerWindow.window.crown = CreateFrame("Frame", "CrownContainer", PlayerWindow.window)
                PlayerWindow.window.crown:SetSize(24, 24)
                PlayerWindow.window.crown:SetFrameLevel(900)
                PlayerWindow.window.crown:SetPoint("TOPLEFT", PlayerWindow.window, "TOPLEFT", -4, 17)
                PlayerWindow.window.CrownTexture = PlayerWindow.window.crown:CreateTexture("CrownTexture")
                PlayerWindow.window.CrownTexture:SetAllPoints(PlayerWindow.window.crown)
                PlayerWindow.window.CrownTexture:SetRotation(math.pi / 5.5)
                PlayerWindow.window.CrownTexture:SetTexture("Interface/GroupFrame/UI-Group-LeaderIcon")
                PlayerWindow.window.crown:SetShown(isLeader)
            else
                PlayerWindow.window.crown:SetShown(isLeader)
            end
        end
    end
end

local groupFrame = CreateFrame("Frame")
groupFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
groupFrame:SetScript("OnEvent", PlayerLeaderCheck)

function PlayerWindow:CreateWindow()
    local startingWidth = 310
    local startingHeight = 74
    local maxHeight = 380
    -- creating the main frame + its location
    core.PlayerWindow.window = CreateFrame("Frame", "ShortWaveUIFrame", UIParent, "PortraitFrameBaseTemplate")
    ShortWaveConfig = core.PlayerWindow.window
    ShortWaveConfig:SetSize(startingWidth, startingHeight)
    ShortWaveConfig:SetPoint("TOP", UIParent, ShortWaveVariables.xOfs or 50,
        ShortWaveVariables.yOfs or 120)
    SetMovable(ShortWaveConfig)

    -- title
    ShortWaveConfig.title = ShortWaveConfig.TitleContainer:CreateFontString("TitleText")
    ShortWaveConfig.title:SetFontObject("GameFontNormal")
    ShortWaveConfig.title:SetPoint("CENTER")
    ShortWaveConfig.title:SetText("Shortwave Player")

    ShortWaveConfig.closeButton = CreateFrame("Button", nil,
        ShortWaveConfig, "UIPanelCloseButton")
    ShortWaveConfig.closeButton:SetPoint("TOPRIGHT", ShortWaveConfig, "TOPRIGHT", -1, -2)
    ShortWaveConfig.closeButton:SetSize(20, 20)
    ShortWaveConfig.closeButton:SetScript("OnClick", function()
        ShortWaveConfig:Hide()
    end)

    -- portrait icon
    ShortWaveConfig.circularIcon = ShortWaveConfig.PortraitContainer:CreateTexture("PortraitTexture")
    ShortWaveConfig.circularIcon:SetSize(60, 60)
    ShortWaveConfig.circularIcon:SetPoint("CENTER", 24, -22)
    ShortWaveConfig.circularIcon:SetTexture("Interface/Icons/inv_gizmo_goblinboombox_01")

    ShortWaveConfig.circularIcon.mask = ShortWaveConfig:CreateMaskTexture()
    ShortWaveConfig.circularIcon.mask:SetAllPoints(ShortWaveConfig.circularIcon)
    ShortWaveConfig.circularIcon.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask",
        "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    ShortWaveConfig.circularIcon:AddMaskTexture(ShortWaveConfig.circularIcon.mask)

    local function createTopBar()
        local function playButton(self)
            if self:GetChecked() then
                core.Player:ResumeSong()
            else
                core.Player:PauseSong()
            end
        end

        function PlayerWindow:SetText(text)
            ShortWaveConfig.currentlyPlaying:SetText(text)
        end

        local function onPreviousClick(self)
            core.Player:PreviousSongInPlaylist()
        end

        local function onNextClick(self)
            core.Player:NextSongInPlaylist()
        end

        local topBarHeight = 48
        local topBarExpandedHeight = 74

        function PlayerWindow:ToggleExpand(expanded)
            if expanded then
                ShortWaveConfig:SetSize(startingWidth, maxHeight)
                ShortWaveConfig.topBar:SetSize(startingWidth, topBarExpandedHeight)
                ShortWaveConfig:AdjustPointsOffset(0, -((maxHeight - topBarExpandedHeight) / 2))
                ShortWaveConfig.tabBars:Show()
                ShortWaveConfig.body:Show()
                ShortWaveVariables.IsShown = true
            else
                ShortWaveConfig:SetSize(startingWidth, startingHeight)
                ShortWaveConfig.topBar:SetSize(startingWidth, topBarHeight)
                ShortWaveConfig:AdjustPointsOffset(0, (maxHeight - topBarExpandedHeight) / 2)
                ShortWaveConfig.tabBars:Hide()
                ShortWaveConfig.body:Hide()
                ShortWaveVariables.IsShown = false
            end
        end

        local function onMinMaxClick(self)
            PlayerWindow:ToggleExpand(self:GetChecked())
        end

        ShortWaveConfig.topBar = CreateFrame("Frame", nil, ShortWaveConfig)
        ShortWaveConfig.topBar:SetSize(startingWidth, topBarHeight)
        ShortWaveConfig.topBar:SetPoint("TOP", ShortWaveConfig, "TOP", 0, -22)
        ShortWaveConfig.topBar.texture = ShortWaveConfig.topBar:CreateTexture("TopBarTexture", "BACKGROUND")
        ShortWaveConfig.topBar.texture:SetAllPoints(ShortWaveConfig.topBar)
        ShortWaveConfig.topBar.texture:SetTexture("Interface/FrameGeneral/UI-Background-Rock")
        ShortWaveConfig.topBar.texture:SetHorizTile(true)
        ShortWaveConfig.topBar.texture:SetVertTile(true)

        ShortWaveConfig.previousButton = CreateFrame("Button", nil, ShortWaveConfig.topBar)
        ShortWaveConfig.previousButton:SetSize(30, 30)
        ShortWaveConfig.previousButton:SetPoint("TOPLEFT", ShortWaveConfig.topBar, 58, 2)
        ShortWaveConfig.previousButton:SetNormalTexture("Interface/Timemanager/RWButton")
        ShortWaveConfig.previousButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
        ShortWaveConfig.previousButton:SetScript("OnClick", onPreviousClick)
        ShortWaveConfig.previousButton.disabledTexture = ShortWaveConfig.previousButton:CreateTexture(
            "DisabledTexture")
        ShortWaveConfig.previousButton.disabledTexture:SetAllPoints(ShortWaveConfig.previousButton)
        ShortWaveConfig.previousButton.disabledTexture:SetTexture("Interface/Timemanager/RWButton")
        ShortWaveConfig.previousButton.disabledTexture:SetDesaturated(true)
        ShortWaveConfig.previousButton.disabledTexture:SetVertexColor(0.6, 0.6, 0.6, 1)
        ShortWaveConfig.previousButton:SetDisabledTexture(ShortWaveConfig.previousButton.disabledTexture)
        ShortWaveConfig.previousButton:Disable()

        ShortWaveConfig.playPauseButton = CreateFrame("CheckButton", nil, ShortWaveConfig.topBar)
        ShortWaveConfig.playPauseButton:SetSize(30, 30)
        ShortWaveConfig.playPauseButton:SetPoint("RIGHT", ShortWaveConfig.previousButton, 30, 0)
        ShortWaveConfig.playPauseButton:SetNormalTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Up")
        ShortWaveConfig.playPauseButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
        ShortWaveConfig.playPauseButton:SetCheckedTexture("Interface/Timemanager/PauseButton")
        ShortWaveConfig.playPauseButton:SetDisabledTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Disabled")
        ShortWaveConfig.playPauseButton:Disable()
        ShortWaveConfig.playPauseButton:SetScript("OnClick", playButton)

        ShortWaveConfig.nextButton = CreateFrame("Button", nil, ShortWaveConfig.topBar)
        ShortWaveConfig.nextButton:SetSize(30, 30)
        ShortWaveConfig.nextButton:SetPoint("TOPLEFT", ShortWaveConfig.playPauseButton, 30, 0)
        ShortWaveConfig.nextButton:SetNormalTexture("Interface/Timemanager/FFButton")
        ShortWaveConfig.nextButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
        ShortWaveConfig.nextButton:SetScript("OnClick", onNextClick)
        ShortWaveConfig.nextButton.disabledTexture = ShortWaveConfig.nextButton:CreateTexture(
            "DisabledTexture")
        ShortWaveConfig.nextButton.disabledTexture:SetAllPoints(ShortWaveConfig.nextButton)
        ShortWaveConfig.nextButton.disabledTexture:SetTexture("Interface/Timemanager/FFButton")
        ShortWaveConfig.nextButton.disabledTexture:SetDesaturated(true)
        ShortWaveConfig.nextButton.disabledTexture:SetVertexColor(0.6, 0.6, 0.6, 1)
        ShortWaveConfig.nextButton:SetDisabledTexture(ShortWaveConfig.nextButton.disabledTexture)
        ShortWaveConfig.nextButton:Disable()

        ShortWaveConfig.blueTexture = ShortWaveConfig.topBar:CreateTexture("BlueTexture")
        ShortWaveConfig.blueTexture:SetSize(startingWidth - 176, 30)
        ShortWaveConfig.blueTexture:SetPoint("TOPLEFT", ShortWaveConfig.nextButton, 30, 0)

        function PlayerWindow:SetColor(color)
            if color == "red" then
                ShortWaveConfig.blueTexture:SetTexture("interface/addons/ShortWave/assets/red.png")
            elseif color == "green" then
                ShortWaveConfig.blueTexture:SetTexture("interface/addons/ShortWave/assets/green.png")
            elseif color == "blue" then
                ShortWaveConfig.blueTexture:SetTexture("interface/addons/ShortWave/assets/blue.png")
            end
        end

        PlayerWindow:SetColor(core.Channel.colorMatch[core.Channel.channelIndex[core.Channel.currentChannel]] or "blue")

        ShortWaveConfig.currentlyPlaying = ShortWaveConfig.topBar:CreateFontString("CurrentlyPlayingText")
        ShortWaveConfig.currentlyPlaying:SetFontObject("GameFontHighlight")
        ShortWaveConfig.currentlyPlaying:SetPoint("LEFT", ShortWaveConfig.blueTexture, "LEFT", 4, 0)
        ShortWaveConfig.currentlyPlaying:SetPoint("RIGHT", ShortWaveConfig.blueTexture, "RIGHT", -4, 0)
        ShortWaveConfig.currentlyPlaying:SetText("No music playing")

        function PlayerWindow:SetDefaultText(text)
            local texts = core.Channel.defaultText;
            if not texts then
                return
            end
            local textAlreadySet = true
            for _, t in ipairs(texts) do
                if t == ShortWaveConfig.currentlyPlaying:GetText() then
                    textAlreadySet = false
                    break
                end
            end
            if textAlreadySet then
                return
            end
            ShortWaveConfig.currentlyPlaying:SetText(text)
        end

        core.PlayerWindow:SetDefaultText(core.Channel.defaultText
            [core.Channel.channelIndex[core.Channel.currentChannel]] or
            "No sound playing")

        ShortWaveConfig.blueTexture:SetScript("OnEnter", function()
            if ShortWaveConfig.currentlyPlaying:GetUnboundedStringWidth() > ShortWaveConfig.currentlyPlaying:GetWidth() then
                GameTooltip:SetOwner(ShortWaveConfig, "ANCHOR_CURSOR")
                GameTooltip:SetText(ShortWaveConfig.currentlyPlaying:GetText(), 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)

        ShortWaveConfig.blueTexture:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        ShortWaveConfig.minMax = CreateFrame("CheckButton", nil, ShortWaveConfig.topBar)
        ShortWaveConfig.minMax:SetSize(24, 24)
        ShortWaveConfig.minMax:SetPoint("RIGHT", ShortWaveConfig.blueTexture, 29, 0)
        ShortWaveConfig.minMax:SetScript("OnClick", onMinMaxClick)
        ShortWaveConfig.minMax:SetChecked(ShortWaveVariables.IsShown)

        ShortWaveConfig.minusTexture = ShortWaveConfig.minMax:CreateTexture("MinusTexture")
        ShortWaveConfig.minusTexture:SetSize(24, 24)
        ShortWaveConfig.minusTexture:SetPoint("CENTER", ShortWaveConfig.minMax, "CENTER", -2, 0)
        ShortWaveConfig.minusTexture:SetTexture("Interface/Options/OptionsExpandListButton")
        ShortWaveConfig.minusTexture:SetTexCoord(0.234375, 0.46875, 0.4296875, 0.6484375)
        ShortWaveConfig.minusTexture:SetRotation(math.pi)

        ShortWaveConfig.plusTexture = ShortWaveConfig.minMax:CreateTexture("PlusTexture")
        ShortWaveConfig.plusTexture:SetSize(24, 24)
        ShortWaveConfig.plusTexture:SetPoint("CENTER", ShortWaveConfig.minMax, "CENTER", -2, 0)
        ShortWaveConfig.plusTexture:SetTexture("Interface/Options/OptionsExpandListButton")
        ShortWaveConfig.plusTexture:SetTexCoord(0, 0.234375, 0.4296875, 0.6484375)
        ShortWaveConfig.plusTexture:SetRotation(math.pi)

        ShortWaveConfig.minMax:SetNormalTexture(ShortWaveConfig.plusTexture)
        ShortWaveConfig.minMax:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
        ShortWaveConfig.minMax:SetCheckedTexture(ShortWaveConfig.minusTexture)
    end

    if ShortWaveVariables.IsShown == nil then
        ShortWaveVariables.IsShown = true
    end

    createTopBar()

    local function createTopTabBars()
        ShortWaveConfig.tabBars = CreateFrame("Frame", nil, ShortWaveConfig)
        ShortWaveConfig.tabBars:SetSize(startingWidth - 20, 40)
        ShortWaveConfig.tabBars:SetPoint("TOPLEFT", ShortWaveConfig, 10, -51)

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

        local function selectTab(self)
            ShortWaveVariables.selectedTab = self:GetName()
            local otherTab
            if self == ShortWaveConfig.playlistTab then
                otherTab = ShortWaveConfig.searchTab
                if not ShortWaveConfig.playlistTab.body then
                    ShortWaveConfig.playlistTab.body = core.Playlist:CreateBody(startingWidth - 6, maxHeight - 102)
                    ShortWaveConfig.playlistTab.body:SetParent(ShortWaveConfig.body)
                    ShortWaveConfig.playlistTab.body:SetPoint("TOPLEFT", ShortWaveConfig, "TOPLEFT", 3, -96)
                end
            else
                otherTab = ShortWaveConfig.playlistTab
                if not ShortWaveConfig.searchTab.body then
                    ShortWaveConfig.searchTab.body = core.Search:CreateBody(startingWidth - 6, maxHeight - 102)
                    ShortWaveConfig.searchTab.body:SetParent(ShortWaveConfig.body)
                    ShortWaveConfig.searchTab.body:SetPoint("TOPLEFT", ShortWaveConfig, "TOPLEFT", 3, -96)
                end
                core.Search:RefreshSearchBody()
            end
            PanelTemplates_SelectTab(self)
            PanelTemplates_DeselectTab(otherTab)
            self.Text:SetHeight(20)
            otherTab.Text:SetHeight(1)
            if otherTab.body then
                otherTab.body:Hide()
            end
            self.body:Show()
        end

        ShortWaveConfig.playlistTab = CreateFrame("Button", "playlist", ShortWaveConfig.tabBars,
            "PanelTabButtonTemplate")
        ShortWaveConfig.playlistTab:SetPoint("BOTTOMLEFT", ShortWaveConfig.tabBars, "BOTTOMLEFT", 0, -6)
        ShortWaveConfig.playlistTab:SetSize(100, 26)
        ShortWaveConfig.playlistTab.Text:SetText("Playlists")
        ShortWaveConfig.playlistTab.Text:SetJustifyV("TOP")
        ShortWaveConfig.playlistTab:SetScript("OnClick", selectTab)
        setTabSizes(ShortWaveConfig.playlistTab)

        ShortWaveConfig.searchTab = CreateFrame("Button", "search", ShortWaveConfig.tabBars,
            "PanelTabButtonTemplate")
        ShortWaveConfig.searchTab:SetPoint("LEFT", ShortWaveConfig.playlistTab, "RIGHT", 10, 0)
        ShortWaveConfig.searchTab:SetSize(100, 26)
        ShortWaveConfig.searchTab.Text:SetText("Search")
        ShortWaveConfig.searchTab.Text:SetJustifyV("TOP")
        ShortWaveConfig.searchTab:SetScript("OnClick", selectTab)
        setTabSizes(ShortWaveConfig.searchTab)

        ShortWaveConfig.body = CreateFrame("Frame", nil, ShortWaveConfig)

        selectTab(ShortWaveVariables.selectedTab == ShortWaveConfig.searchTab:GetName() and ShortWaveConfig.searchTab or
            ShortWaveConfig.playlistTab)
    end

    createTopTabBars()

    local function createChannelTabs()
        ShortWaveConfig.channelTabs = CreateFrame("Frame", nil, ShortWaveConfig)
        ShortWaveConfig.channelTabs:SetSize(startingWidth - 20, 40)
        ShortWaveConfig.channelTabs:SetPoint("BOTTOMLEFT", ShortWaveConfig, 10, -20)

        local function setTabSizes(self)
            self.Middle:SetSize(26, 26)
            self.Left:SetSize(26, 26)
            self.Left:AdjustPointsOffset(0, 4)
            self.Right:SetSize(26, 26)
            self.Right:AdjustPointsOffset(0, 4)

            self.Text:SetHeight(16)

            self.MiddleHighlight:SetSize(26, 26)
            self.LeftHighlight:SetSize(26, 26)
            self.RightHighlight:SetSize(26, 26)

            self.MiddleActive:SetSize(26, 30)
            self.LeftActive:AdjustPointsOffset(0, 4)
            self.LeftActive:SetSize(26, 30)
            self.RightActive:AdjustPointsOffset(0, 4)
            self.RightActive:SetSize(26, 30)
        end

        local tabs = {}

        local function selectTab(tabName)
            for _, tab in ipairs(tabs) do
                if tab:GetName() == tabName then
                    PanelTemplates_SelectTab(tab)
                    core.Channel:ChangeChannel(tabName)
                else
                    PanelTemplates_DeselectTab(tab)
                end
            end
        end

        local lastFrame = nil
        for _, channel in ipairs(core.Channel.channels) do
            local tab = CreateFrame("Button", channel, ShortWaveConfig.channelTabs,
                "PanelTabButtonTemplate")
            tab:SetSize(100, 26)
            tab.Text:SetText(channel)
            tab.Text:SetJustifyV("TOP")
            tab:SetScript("OnClick", function()
                selectTab(tab:GetName())
            end)
            setTabSizes(tab)
            if lastFrame then
                tab:SetPoint("LEFT", lastFrame, "RIGHT", 10, 0)
            else
                tab:SetPoint("BOTTOMLEFT", ShortWaveConfig.channelTabs, "BOTTOMLEFT", 0, -6)
            end
            lastFrame = tab
            table.insert(tabs, tab)
        end

        selectTab(ShortWaveVariables.selectedChannel or tabs[1]:GetName())
    end

    createChannelTabs()

    PlayerWindow:ToggleExpand(ShortWaveVariables.IsShown)

    PlayerLeaderCheck()

    ShortWaveConfig:Hide()
    return ShortWaveConfig
end
