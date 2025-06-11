-------------------------------
-- Namespaces & Variables
-------------------------------
local _, core = ...
core.PlayerWindow = {}
local PlayerWindow = core.PlayerWindow
local groupMusicConfig
-------------------------------
function PlayerWindow:Toggle()
    local menu = groupMusicConfig or PlayerWindow:CreateWindow()
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
        GroupMusicVariables.point = point;
        GroupMusicVariables.xOfs = xOfs;
        GroupMusicVariables.yOfs = yOfs;
    end);
    f:SetUserPlaced(true);
end

function PlayerWindow:CreateWindow()
    local startingWidth = 310
    local startingHeight = 74
    local maxHeight = 380
    -- creating the main frame + its location
    core.PlayerWindow.window = CreateFrame("Frame", "groupMusicUIFrame", UIParent, "PortraitFrameBaseTemplate")
    groupMusicConfig = core.PlayerWindow.window
    groupMusicConfig:SetSize(startingWidth, startingHeight)
    groupMusicConfig:SetPoint("TOPLEFT", UIParent, GroupMusicVariables.xOfs or 50,
        GroupMusicVariables.yOfs or 120)
    SetMovable(groupMusicConfig)

    -- title
    groupMusicConfig.title = groupMusicConfig.TitleContainer:CreateFontString("TitleText")
    groupMusicConfig.title:SetFontObject("GameFontNormal")
    groupMusicConfig.title:SetPoint("CENTER")
    groupMusicConfig.title:SetText("Group Music Player")

    -- portrait icon
    groupMusicConfig.circularIcon = groupMusicConfig.PortraitContainer:CreateTexture("PortraitTexture")
    groupMusicConfig.circularIcon:SetSize(60, 60)
    groupMusicConfig.circularIcon:SetPoint("CENTER", 24, -22)
    groupMusicConfig.circularIcon:SetTexture("Interface/Icons/inv_gizmo_goblinboombox_01")

    groupMusicConfig.circularIcon.mask = groupMusicConfig:CreateMaskTexture()
    groupMusicConfig.circularIcon.mask:SetAllPoints(groupMusicConfig.circularIcon)
    groupMusicConfig.circularIcon.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask",
        "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    groupMusicConfig.circularIcon:AddMaskTexture(groupMusicConfig.circularIcon.mask)

    local function createTopBar()
        local function playButton(self)
            if self:GetChecked() then
                core.Player:ResumeSong()
            else
                core.Player:PauseSong()
            end
        end

        function PlayerWindow:SetText(text)
            groupMusicConfig.currentlyPlaying:SetText(text)
        end

        local function onPreviousClick(self)
            groupMusicConfig.currentlyPlaying:SetText("Previous track")
            --add logic here
        end

        local function onNextClick(self)
            groupMusicConfig.currentlyPlaying:SetText("Next track")
            --add logic here
        end

        local topBarHeight = 48
        local topBarExpandedHeight = 74

        function PlayerWindow:ToggleExpand(expanded)
            if expanded then
                groupMusicConfig:SetSize(startingWidth, maxHeight)
                groupMusicConfig.topBar:SetSize(startingWidth, topBarExpandedHeight)
                groupMusicConfig:AdjustPointsOffset(0, -((maxHeight - topBarExpandedHeight) / 2))
                groupMusicConfig.tabBars:Show()
                groupMusicConfig.body:Show()
                GroupMusicVariables.IsShown = true
            else
                groupMusicConfig:SetSize(startingWidth, startingHeight)
                groupMusicConfig.topBar:SetSize(startingWidth, topBarHeight)
                groupMusicConfig:AdjustPointsOffset(0, (maxHeight - topBarExpandedHeight) / 2)
                groupMusicConfig.tabBars:Hide()
                groupMusicConfig.body:Hide()
                GroupMusicVariables.IsShown = false
            end
        end

        local function onMinMaxClick(self)
            PlayerWindow:ToggleExpand(self:GetChecked())
        end

        groupMusicConfig.topBar = CreateFrame("Frame", nil, groupMusicConfig)
        groupMusicConfig.topBar:SetSize(startingWidth, topBarHeight)
        groupMusicConfig.topBar:SetPoint("TOP", groupMusicConfig, "TOP", 0, -22)
        groupMusicConfig.topBar.texture = groupMusicConfig.topBar:CreateTexture("TopBarTexture", "BACKGROUND")
        groupMusicConfig.topBar.texture:SetAllPoints(groupMusicConfig.topBar)
        groupMusicConfig.topBar.texture:SetTexture("Interface/FrameGeneral/UI-Background-Rock")
        groupMusicConfig.topBar.texture:SetHorizTile(true)
        groupMusicConfig.topBar.texture:SetVertTile(true)

        groupMusicConfig.previousButton = CreateFrame("Button", nil, groupMusicConfig.topBar)
        groupMusicConfig.previousButton:SetSize(30, 30)
        groupMusicConfig.previousButton:SetPoint("TOPLEFT", groupMusicConfig.topBar, 58, 2)
        groupMusicConfig.previousButton:SetNormalTexture("Interface/Timemanager/RWButton")
        groupMusicConfig.previousButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
        groupMusicConfig.previousButton:SetScript("OnClick", onPreviousClick)
        groupMusicConfig.previousButton.disabledTexture = groupMusicConfig.previousButton:CreateTexture(
            "DisabledTexture")
        groupMusicConfig.previousButton.disabledTexture:SetAllPoints(groupMusicConfig.previousButton)
        groupMusicConfig.previousButton.disabledTexture:SetTexture("Interface/Timemanager/RWButton")
        groupMusicConfig.previousButton.disabledTexture:SetDesaturated(true)
        groupMusicConfig.previousButton.disabledTexture:SetVertexColor(0.6, 0.6, 0.6, 1)
        groupMusicConfig.previousButton:SetDisabledTexture(groupMusicConfig.previousButton.disabledTexture)
        groupMusicConfig.previousButton:Disable()

        groupMusicConfig.playPauseButton = CreateFrame("CheckButton", nil, groupMusicConfig.topBar)
        groupMusicConfig.playPauseButton:SetSize(30, 30)
        groupMusicConfig.playPauseButton:SetPoint("RIGHT", groupMusicConfig.previousButton, 30, 0)
        groupMusicConfig.playPauseButton:SetNormalTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Up")
        groupMusicConfig.playPauseButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
        groupMusicConfig.playPauseButton:SetCheckedTexture("Interface/Timemanager/PauseButton")
        groupMusicConfig.playPauseButton:SetDisabledTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Disabled")
        groupMusicConfig.playPauseButton:Disable()
        groupMusicConfig.playPauseButton:SetScript("OnClick", playButton)

        groupMusicConfig.nextButton = CreateFrame("Button", nil, groupMusicConfig.topBar)
        groupMusicConfig.nextButton:SetSize(30, 30)
        groupMusicConfig.nextButton:SetPoint("TOPLEFT", groupMusicConfig.playPauseButton, 30, 0)
        groupMusicConfig.nextButton:SetNormalTexture("Interface/Timemanager/FFButton")
        groupMusicConfig.nextButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
        groupMusicConfig.nextButton:SetScript("OnClick", onNextClick)
        groupMusicConfig.nextButton.disabledTexture = groupMusicConfig.nextButton:CreateTexture(
            "DisabledTexture")
        groupMusicConfig.nextButton.disabledTexture:SetAllPoints(groupMusicConfig.nextButton)
        groupMusicConfig.nextButton.disabledTexture:SetTexture("Interface/Timemanager/FFButton")
        groupMusicConfig.nextButton.disabledTexture:SetDesaturated(true)
        groupMusicConfig.nextButton.disabledTexture:SetVertexColor(0.6, 0.6, 0.6, 1)
        groupMusicConfig.nextButton:SetDisabledTexture(groupMusicConfig.nextButton.disabledTexture)
        groupMusicConfig.nextButton:Disable()

        groupMusicConfig.blueTexture = groupMusicConfig.topBar:CreateTexture("BlueTexture")
        groupMusicConfig.blueTexture:SetSize(startingWidth - 176, 30)
        groupMusicConfig.blueTexture:SetPoint("TOPLEFT", groupMusicConfig.nextButton, 30, 0)
        groupMusicConfig.blueTexture:SetTexture("Interface/FriendsFrame/battlenet-friends-main")
        groupMusicConfig.blueTexture:SetTexCoord(0.00390625, 0.74609375, 0.00195313, 0.05859375)

        groupMusicConfig.currentlyPlaying = groupMusicConfig.topBar:CreateFontString("CurrentlyPlayingText")
        groupMusicConfig.currentlyPlaying:SetFontObject("GameFontHighlight")
        groupMusicConfig.currentlyPlaying:SetPoint("LEFT", groupMusicConfig.blueTexture, "LEFT", 4, 0)
        groupMusicConfig.currentlyPlaying:SetPoint("RIGHT", groupMusicConfig.blueTexture, "RIGHT", -4, 0)
        groupMusicConfig.currentlyPlaying:SetText("No music playing")

        groupMusicConfig.minMax = CreateFrame("CheckButton", nil, groupMusicConfig.topBar)
        groupMusicConfig.minMax:SetSize(24, 24)
        groupMusicConfig.minMax:SetPoint("RIGHT", groupMusicConfig.blueTexture, 29, 0)
        groupMusicConfig.minMax:SetScript("OnClick", onMinMaxClick)
        groupMusicConfig.minMax:SetChecked(GroupMusicVariables.IsShown)

        groupMusicConfig.minusTexture = groupMusicConfig.minMax:CreateTexture("MinusTexture")
        groupMusicConfig.minusTexture:SetSize(24, 24)
        groupMusicConfig.minusTexture:SetPoint("CENTER", groupMusicConfig.minMax, "CENTER", -2, 0)
        groupMusicConfig.minusTexture:SetTexture("Interface/Options/OptionsExpandListButton")
        groupMusicConfig.minusTexture:SetTexCoord(0.234375, 0.46875, 0.4296875, 0.6484375)
        groupMusicConfig.minusTexture:SetRotation(math.pi)

        groupMusicConfig.plusTexture = groupMusicConfig.minMax:CreateTexture("PlusTexture")
        groupMusicConfig.plusTexture:SetSize(24, 24)
        groupMusicConfig.plusTexture:SetPoint("CENTER", groupMusicConfig.minMax, "CENTER", -2, 0)
        groupMusicConfig.plusTexture:SetTexture("Interface/Options/OptionsExpandListButton")
        groupMusicConfig.plusTexture:SetTexCoord(0, 0.234375, 0.4296875, 0.6484375)
        groupMusicConfig.plusTexture:SetRotation(math.pi)

        groupMusicConfig.minMax:SetNormalTexture(groupMusicConfig.plusTexture)
        groupMusicConfig.minMax:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
        groupMusicConfig.minMax:SetCheckedTexture(groupMusicConfig.minusTexture)
    end

    if GroupMusicVariables.IsShown == nil then
        GroupMusicVariables.IsShown = true
    end

    createTopBar()

    local function createTabBars()
        groupMusicConfig.tabBars = CreateFrame("Frame", nil, groupMusicConfig)
        groupMusicConfig.tabBars:SetSize(startingWidth - 20, 40)
        groupMusicConfig.tabBars:SetPoint("TOPLEFT", groupMusicConfig, 10, -51)

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
            local otherTab = self == groupMusicConfig.playlistTab and groupMusicConfig.searchTab or
                groupMusicConfig.playlistTab
            PanelTemplates_SelectTab(self)
            PanelTemplates_DeselectTab(otherTab)
            self.Text:SetHeight(20)
            otherTab.Text:SetHeight(1)
            self.body:Show()
            otherTab.body:Hide()
            GroupMusicVariables.selectedTab = self:GetName()
        end

        groupMusicConfig.playlistTab = CreateFrame("Button", "musicTabOne", groupMusicConfig.tabBars,
            "PanelTabButtonTemplate")
        groupMusicConfig.playlistTab:SetPoint("BOTTOMLEFT", groupMusicConfig.tabBars, "BOTTOMLEFT", 0, -6)
        groupMusicConfig.playlistTab:SetSize(100, 26)
        groupMusicConfig.playlistTab.Text:SetText("Playlists")
        groupMusicConfig.playlistTab.Text:SetJustifyV("TOP")
        groupMusicConfig.playlistTab:SetScript("OnClick", selectTab)
        setTabSizes(groupMusicConfig.playlistTab)

        groupMusicConfig.searchTab = CreateFrame("Button", "musicTabTwo", groupMusicConfig.tabBars,
            "PanelTabButtonTemplate")
        groupMusicConfig.searchTab:SetPoint("LEFT", groupMusicConfig.playlistTab, "RIGHT", 10, 0)
        groupMusicConfig.searchTab:SetSize(100, 26)
        groupMusicConfig.searchTab.Text:SetText("Search")
        groupMusicConfig.searchTab.Text:SetJustifyV("TOP")
        groupMusicConfig.searchTab:SetScript("OnClick", selectTab)
        setTabSizes(groupMusicConfig.searchTab)

        groupMusicConfig.body = CreateFrame("Frame", nil, groupMusicConfig)

        groupMusicConfig.playlistTab.body = core.Playlist:CreateBody(startingWidth - 6, maxHeight - 102)
        groupMusicConfig.playlistTab.body:SetParent(groupMusicConfig.body)
        groupMusicConfig.playlistTab.body:SetPoint("TOPLEFT", groupMusicConfig, "TOPLEFT", 3, -96)

        groupMusicConfig.searchTab.body = core.Search:CreateBody(startingWidth - 6, maxHeight - 102)
        groupMusicConfig.searchTab.body:SetParent(groupMusicConfig.body)
        groupMusicConfig.searchTab.body:SetPoint("TOPLEFT", groupMusicConfig, "TOPLEFT", 3, -96)

        selectTab(GroupMusicVariables.selectedTab == groupMusicConfig.searchTab:GetName() and groupMusicConfig.searchTab or
            groupMusicConfig.playlistTab)
    end

    createTabBars()

    PlayerWindow:ToggleExpand(GroupMusicVariables.IsShown)

    groupMusicConfig:Hide()
    return groupMusicConfig
end
