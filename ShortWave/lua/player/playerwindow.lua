local _, core = ...
core.PlayerWindow = {}
local PlayerWindow = core.PlayerWindow
local ShortWavePlayer
-------------------------------

-- If the window isn't already created, create it
-- Else, show it
function PlayerWindow:Toggle()
    local menu = ShortWavePlayer or PlayerWindow:CreateWindow()
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

-- Check if the player is the leader and updates a lil cosmetic crown icon
-- This is seperate so that it can be called on event updates
local PlayerLeaderCheck = function()
    local isLeader = core.Broadcast:IsLeader("player")
    if core.isLeader ~= isLeader then -- only update if the leader status has changed
        core.isLeader = isLeader
        if PlayerWindow.window then
            -- create the crown icon if it doesnt already exist
            if not PlayerWindow.window.crown then
                PlayerWindow.window.crown = CreateFrame("Frame", "CrownContainer", PlayerWindow.window)
                PlayerWindow.window.crown:SetSize(24, 24)
                PlayerWindow.window.crown:SetFrameLevel(900)
                PlayerWindow.window.crown:SetPoint("TOPLEFT", PlayerWindow.window, "TOPLEFT", -4, 17)
                PlayerWindow.window.CrownTexture = PlayerWindow.window.crown:CreateTexture("CrownTexture")
                PlayerWindow.window.CrownTexture:SetAllPoints(PlayerWindow.window.crown)
                PlayerWindow.window.CrownTexture:SetRotation(math.pi / 5.5)
                PlayerWindow.window.CrownTexture:SetTexture("Interface/GroupFrame/UI-Group-LeaderIcon")
            end
            -- then toggle it
            PlayerWindow.window.crown:SetShown(isLeader)
        end
    end
end

local groupFrame = CreateFrame("Frame")
groupFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
groupFrame:SetScript("OnEvent", PlayerLeaderCheck)

-- this function refreshes the tabs based on the currently selected channel
-- so that when you switch channels, the tabs are updated to the correct state
-- this is mostly done so you can avoid loading the creatures
function PlayerWindow:RefreshTabs()
    PlayerWindow:SelectTabByName(ShortWaveVariables.selectedtab[core.Channel.currentChannel])
    if ShortWaveVariables.selectedtab[core.Channel.currentChannel] == "playlist" then
        core.Playlist:RefreshPlaylists()
    elseif ShortWaveVariables.selectedtab[core.Channel.currentChannel] == "search" then
        core.Search:ClearSearchBody()
    end
end

function PlayerWindow:CreateWindow()
    local startingWidth = 334
    local startingHeight = 74
    local maxHeight = 380

    -- slightly misleading name, this checks if the player is expanded or not
    if ShortWaveVariables.IsShown == nil then
        ShortWaveVariables.IsShown = true
    end

    do
        -- creating the main frame + its location
        core.PlayerWindow.window = CreateFrame("Frame", "ShortWaveUIFrame", UIParent, "PortraitFrameBaseTemplate")
        ShortWavePlayer = core.PlayerWindow.window
        ShortWavePlayer:SetSize(startingWidth, startingHeight)
        -- if it has not yet been created, put it in the center of the screen
        ShortWavePlayer:SetPoint("TOPLEFT", UIParent, ShortWaveVariables.point or "CENTER",
            ShortWaveVariables.xOfs or 0,
            ShortWaveVariables.yOfs or 0)
        SetMovable(ShortWavePlayer)

        -- title
        ShortWavePlayer.title = ShortWavePlayer.TitleContainer:CreateFontString("TitleText")
        ShortWavePlayer.title:SetFontObject("GameFontNormal")
        ShortWavePlayer.title:SetPoint("CENTER")
        ShortWavePlayer.title:SetText("Shortwave Player")

        -- close button
        ShortWavePlayer.closeButton = CreateFrame("Button", nil,
            ShortWavePlayer, "UIPanelCloseButton")
        ShortWavePlayer.closeButton:SetPoint("TOPRIGHT", ShortWavePlayer, "TOPRIGHT", -1, -2)
        ShortWavePlayer.closeButton:SetSize(20, 20)
        ShortWavePlayer.closeButton:SetScript("OnClick", function()
            ShortWavePlayer:Hide()
        end)

        -- portrait icon
        ShortWavePlayer.circularIcon = ShortWavePlayer.PortraitContainer:CreateTexture("PortraitTexture")
        ShortWavePlayer.circularIcon:SetSize(60, 60)
        ShortWavePlayer.circularIcon:SetPoint("CENTER", 24, -22)
        ShortWavePlayer.circularIcon:SetTexture("Interface/Icons/INV_111_StatSoundWaveEmitter_VentureCo")

        -- this function sets the icon based on the current channel
        -- its also called in set channel
        function core.PlayerWindow:SetIcon()
            if core.Channel.channels[3] == core.Channel.currentChannel then
                ShortWavePlayer.circularIcon:SetTexture("Interface/Icons/INV_111_StatSoundWaveEmitter_VentureCo")
            elseif core.Channel.channels[2] == core.Channel.currentChannel then
                ShortWavePlayer.circularIcon:SetTexture("Interface/Icons/INV_111_StatSoundWaveEmitter_Bilgewater")
            else
                ShortWavePlayer.circularIcon:SetTexture("Interface/Icons/INV_111_StatSoundWaveEmitter_Blackwater")
            end
        end

        core.PlayerWindow:SetIcon()

        -- mask to turn the icon into a circle
        ShortWavePlayer.circularIcon.mask = ShortWavePlayer:CreateMaskTexture()
        ShortWavePlayer.circularIcon.mask:SetAllPoints(ShortWavePlayer.circularIcon)
        ShortWavePlayer.circularIcon.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask",
            "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        ShortWavePlayer.circularIcon:AddMaskTexture(ShortWavePlayer.circularIcon.mask)
    end

    -- the top player bar
    do
        -- the play button is a check button
        local function playButton(self)
            if self:GetChecked() then
                core.Player:ResumeSound()
            else
                core.Player:PauseSound()
            end
        end

        -- this function is called in other files to set the text of the currently playing sound, or any error messages
        function PlayerWindow:SetText(text)
            ShortWavePlayer.currentlyPlaying:SetText(text)
        end

        -- go back in playlist
        local function onPreviousClick()
            core.Player:PreviousSoundInPlaylist()
        end

        -- go forward in playlist
        local function onNextClick()
            core.Player:NextSoundInPlaylist()
        end

        local topBarHeight = 48
        local topBarExpandedHeight = 74

        -- expand the player window, the topbar height here is the texture behind the top bar
        function PlayerWindow:ToggleExpand(expanded)
            if expanded then
                ShortWavePlayer:SetSize(startingWidth, maxHeight)
                ShortWavePlayer.topBar:SetSize(startingWidth, topBarExpandedHeight)
                ShortWavePlayer.tabBars:Show()
                ShortWavePlayer.body:Show()
                ShortWaveVariables.IsShown = true
            else
                ShortWavePlayer:SetSize(startingWidth, startingHeight)
                ShortWavePlayer.topBar:SetSize(startingWidth, topBarHeight)
                ShortWavePlayer.tabBars:Hide()
                ShortWavePlayer.body:Hide()
                ShortWaveVariables.IsShown = false
            end
        end

        local function onMinMaxClick(self)
            PlayerWindow:ToggleExpand(self:GetChecked())
        end

        -- all the frame & button creations
        ShortWavePlayer.topBar = CreateFrame("Frame", nil, ShortWavePlayer)
        ShortWavePlayer.topBar:SetSize(startingWidth, topBarHeight)
        ShortWavePlayer.topBar:SetPoint("TOP", ShortWavePlayer, "TOP", 0, -22)
        ShortWavePlayer.topBar.texture = ShortWavePlayer.topBar:CreateTexture("TopBarTexture", "BACKGROUND")
        ShortWavePlayer.topBar.texture:SetAllPoints(ShortWavePlayer.topBar)
        ShortWavePlayer.topBar.texture:SetTexture("Interface/FrameGeneral/UI-Background-Rock")
        ShortWavePlayer.topBar.texture:SetHorizTile(true)
        ShortWavePlayer.topBar.texture:SetVertTile(true)

        ShortWavePlayer.previousButton = CreateFrame("Button", nil, ShortWavePlayer.topBar)
        ShortWavePlayer.previousButton:SetSize(30, 30)
        ShortWavePlayer.previousButton:SetPoint("TOPLEFT", ShortWavePlayer.topBar, 58, 2)
        ShortWavePlayer.previousButton:SetNormalTexture("Interface/Timemanager/RWButton")
        ShortWavePlayer.previousButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
        ShortWavePlayer.previousButton:SetScript("OnClick", onPreviousClick)
        ShortWavePlayer.previousButton.disabledTexture = ShortWavePlayer.previousButton:CreateTexture(
            "DisabledTexture")
        ShortWavePlayer.previousButton.disabledTexture:SetAllPoints(ShortWavePlayer.previousButton)
        ShortWavePlayer.previousButton.disabledTexture:SetTexture("Interface/Timemanager/RWButton")
        ShortWavePlayer.previousButton.disabledTexture:SetDesaturated(true)
        ShortWavePlayer.previousButton.disabledTexture:SetVertexColor(0.6, 0.6, 0.6, 1)
        ShortWavePlayer.previousButton:SetDisabledTexture(ShortWavePlayer.previousButton.disabledTexture)
        ShortWavePlayer.previousButton:Disable()

        ShortWavePlayer.playPauseButton = CreateFrame("CheckButton", nil, ShortWavePlayer.topBar)
        ShortWavePlayer.playPauseButton:SetSize(30, 30)
        ShortWavePlayer.playPauseButton:SetPoint("RIGHT", ShortWavePlayer.previousButton, 30, 0)
        ShortWavePlayer.playPauseButton:SetNormalTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Up")
        ShortWavePlayer.playPauseButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
        ShortWavePlayer.playPauseButton:SetCheckedTexture("interface/addons/ShortWave/assets/stopbutton-up.png")
        ShortWavePlayer.playPauseButton:SetDisabledTexture("Interface/Buttons/UI-SpellbookIcon-NextPage-Disabled")
        ShortWavePlayer.playPauseButton:Disable()
        ShortWavePlayer.playPauseButton:SetScript("OnClick", playButton)

        ShortWavePlayer.nextButton = CreateFrame("Button", nil, ShortWavePlayer.topBar)
        ShortWavePlayer.nextButton:SetSize(30, 30)
        ShortWavePlayer.nextButton:SetPoint("TOPLEFT", ShortWavePlayer.playPauseButton, 30, 0)
        ShortWavePlayer.nextButton:SetNormalTexture("Interface/Timemanager/FFButton")
        ShortWavePlayer.nextButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
        ShortWavePlayer.nextButton:SetScript("OnClick", onNextClick)
        ShortWavePlayer.nextButton.disabledTexture = ShortWavePlayer.nextButton:CreateTexture(
            "DisabledTexture")
        ShortWavePlayer.nextButton.disabledTexture:SetAllPoints(ShortWavePlayer.nextButton)
        ShortWavePlayer.nextButton.disabledTexture:SetTexture("Interface/Timemanager/FFButton")
        ShortWavePlayer.nextButton.disabledTexture:SetDesaturated(true)
        ShortWavePlayer.nextButton.disabledTexture:SetVertexColor(0.6, 0.6, 0.6, 1)
        ShortWavePlayer.nextButton:SetDisabledTexture(ShortWavePlayer.nextButton.disabledTexture)
        ShortWavePlayer.nextButton:Disable()

        ShortWavePlayer.playerTexture = ShortWavePlayer.topBar:CreateTexture("playerTexture")
        ShortWavePlayer.playerTexture:SetSize(startingWidth - 176, 30)
        ShortWavePlayer.playerTexture:SetPoint("TOPLEFT", ShortWavePlayer.nextButton, 30, 0)

        -- this function sets the icon to different coloured versions based on the channel
        function PlayerWindow:SetColor(color)
            if color == "red" then
                ShortWavePlayer.playerTexture:SetTexture("interface/addons/ShortWave/assets/red.png")
            elseif color == "green" then
                ShortWavePlayer.playerTexture:SetTexture("interface/addons/ShortWave/assets/green.png")
            elseif color == "blue" then
                ShortWavePlayer.playerTexture:SetTexture("interface/addons/ShortWave/assets/blue.png")
            end
        end

        PlayerWindow:SetColor(core.Channel.colorMatch[core.Channel.channelIndex[core.Channel.currentChannel]] or "blue")

        ShortWavePlayer.currentlyPlaying = ShortWavePlayer.topBar:CreateFontString("CurrentlyPlayingText")
        ShortWavePlayer.currentlyPlaying:SetFontObject("GameFontHighlight")
        ShortWavePlayer.currentlyPlaying:SetPoint("TOPLEFT", ShortWavePlayer.playerTexture, "LEFT", 4, 4)
        ShortWavePlayer.currentlyPlaying:SetPoint("BOTTOMRIGHT", ShortWavePlayer.playerTexture, "RIGHT", -4, -4)
        ShortWavePlayer.currentlyPlaying:SetText("No music playing")

        -- this function makes sure the text is set to the default text whenever you switch channel
        function PlayerWindow:SetDefaultText(text)
            local texts = core.Channel.defaultText;
            if not texts then
                return
            end
            local textAlreadySet = true
            for _, t in ipairs(texts) do
                if t == ShortWavePlayer.currentlyPlaying:GetText() then
                    textAlreadySet = false
                    break
                end
            end
            if textAlreadySet then
                return
            end
            ShortWavePlayer.currentlyPlaying:SetText(text)
        end

        core.PlayerWindow:SetDefaultText(core.Channel.defaultText
            [core.Channel.channelIndex[core.Channel.currentChannel]] or
            "No sound playing")

        -- if a sound name is too long, we show a fooltip with the full name on mouseover
        ShortWavePlayer.playerTexture:SetScript("OnEnter", function()
            if ShortWavePlayer.currentlyPlaying:GetUnboundedStringWidth() > ShortWavePlayer.currentlyPlaying:GetWidth() then
                GameTooltip:SetOwner(ShortWavePlayer, "ANCHOR_CURSOR")
                GameTooltip:SetText(ShortWavePlayer.currentlyPlaying:GetText(), 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)

        ShortWavePlayer.playerTexture:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        ShortWavePlayer.minMax = CreateFrame("CheckButton", nil, ShortWavePlayer.topBar)
        ShortWavePlayer.minMax:SetSize(24, 24)
        ShortWavePlayer.minMax:SetPoint("RIGHT", ShortWavePlayer.playerTexture, 29, 0)
        ShortWavePlayer.minMax:SetScript("OnClick", onMinMaxClick)
        ShortWavePlayer.minMax:SetChecked(ShortWaveVariables.IsShown)

        ShortWavePlayer.minusTexture = ShortWavePlayer.minMax:CreateTexture("MinusTexture")
        ShortWavePlayer.minusTexture:SetSize(24, 24)
        ShortWavePlayer.minusTexture:SetPoint("CENTER", ShortWavePlayer.minMax, "CENTER", -2, 0)
        ShortWavePlayer.minusTexture:SetTexture("Interface/Options/OptionsExpandListButton")
        ShortWavePlayer.minusTexture:SetTexCoord(0.234375, 0.46875, 0.4296875, 0.6484375)
        ShortWavePlayer.minusTexture:SetRotation(math.pi)

        ShortWavePlayer.plusTexture = ShortWavePlayer.minMax:CreateTexture("PlusTexture")
        ShortWavePlayer.plusTexture:SetSize(24, 24)
        ShortWavePlayer.plusTexture:SetPoint("CENTER", ShortWavePlayer.minMax, "CENTER", -2, 0)
        ShortWavePlayer.plusTexture:SetTexture("Interface/Options/OptionsExpandListButton")
        ShortWavePlayer.plusTexture:SetTexCoord(0, 0.234375, 0.4296875, 0.6484375)
        ShortWavePlayer.plusTexture:SetRotation(math.pi)

        ShortWavePlayer.minMax:SetNormalTexture(ShortWavePlayer.plusTexture)
        ShortWavePlayer.minMax:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
        ShortWavePlayer.minMax:SetCheckedTexture(ShortWavePlayer.minusTexture)

        ShortWavePlayer.broadcastingToggle = CreateFrame("CheckButton", "broadcasting", ShortWavePlayer.topBar,
            "SettingsCheckboxTemplate")
        ShortWavePlayer.broadcastingToggle:SetSize(18, 18)
        ShortWavePlayer.broadcastingToggle:SetPoint("TOPLEFT", ShortWavePlayer.topBar, 4, -29)

        ShortWavePlayer.broadcastingToggle.text = ShortWavePlayer.broadcastingToggle:CreateFontString("BroadcastingText")
        ShortWavePlayer.broadcastingToggle.text:SetPoint("LEFT", ShortWavePlayer.broadcastingToggle, "RIGHT", 4, 0)
        ShortWavePlayer.broadcastingToggle.text:SetFontObject("GameFontNormal")
        ShortWavePlayer.broadcastingToggle.text:SetText("Broadcasting")
        core.Utils.createGameTooltip(ShortWavePlayer.broadcastingToggle,
            "Toggle to broadcast current channel to\nyour group if you are the party leader.")
        ShortWavePlayer.broadcastingToggle.HoverBackground = nil

        -- broadcasting toggle, per channel basis
        function PlayerWindow:SetBroadcasting(isBroadcasting)
            if not ShortWaveVariables.broadcasting then
                ShortWaveVariables.broadcasting = {}
            end

            local check
            if isBroadcasting ~= nil then
                check = isBroadcasting
            elseif ShortWaveVariables.broadcasting[core.Channel.currentChannel] ~= nil then
                check = ShortWaveVariables.broadcasting[core.Channel.currentChannel]
            else
                check = true
            end

            ShortWavePlayer.broadcastingToggle:SetChecked(check)
            ShortWaveVariables.broadcasting[core.Channel.currentChannel] = check
        end

        ShortWavePlayer.broadcastingToggle:SetScript("OnClick", function(self)
            PlayerWindow:SetBroadcasting(self:GetChecked())
        end)

        PlayerWindow:SetBroadcasting()

        ShortWavePlayer.listeningToggle = CreateFrame("CheckButton", "broadcasting", ShortWavePlayer.topBar,
            "SettingsCheckboxTemplate")
        ShortWavePlayer.listeningToggle:SetSize(18, 18)
        ShortWavePlayer.listeningToggle:SetPoint("LEFT", ShortWavePlayer.broadcastingToggle, "RIGHT", 88, 0)

        ShortWavePlayer.listeningToggle.text = ShortWavePlayer.listeningToggle:CreateFontString("ListeningText")
        ShortWavePlayer.listeningToggle.text:SetPoint("LEFT", ShortWavePlayer.listeningToggle, "RIGHT", 4, 0)
        ShortWavePlayer.listeningToggle.text:SetFontObject("GameFontNormal")
        ShortWavePlayer.listeningToggle.text:SetText("Listening")
        ShortWavePlayer.listeningToggle.HoverBackground = nil
        core.Utils.createGameTooltip(ShortWavePlayer.listeningToggle,
            "Toggle to listen to audio played on current\nchannel by your group leader.")

        -- listening toggle, per channel basis
        function PlayerWindow:SetListening(isListening)
            if not ShortWaveVariables.listening then
                ShortWaveVariables.listening = {}
            end

            local check
            if isListening ~= nil then
                check = isListening
            elseif ShortWaveVariables.listening[core.Channel.currentChannel] ~= nil then
                check = ShortWaveVariables.listening[core.Channel.currentChannel]
            else
                check = true
            end

            ShortWavePlayer.listeningToggle:SetChecked(check)
            ShortWaveVariables.listening[core.Channel.currentChannel] = check
        end

        ShortWavePlayer.listeningToggle:SetScript("OnClick", function(self)
            PlayerWindow:SetListening(self:GetChecked())
        end)

        PlayerWindow:SetListening()
    end

    -- the tab bars for the playlist/search tabs
    do
        ShortWavePlayer.tabBars = CreateFrame("Frame", nil, ShortWavePlayer)
        ShortWavePlayer.tabBars:SetSize(startingWidth - 20, 40)
        ShortWavePlayer.tabBars:SetPoint("TOPLEFT", ShortWavePlayer, 6, -51)

        if not ShortWaveVariables.selectedtab then
            ShortWaveVariables.selectedtab = {}
        end

        -- we're flipping the tab texture upside down
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

        -- this is just hard coded since there's only two tabs
        local function selectTab(self)
            ShortWaveVariables.selectedtab[core.Channel.currentChannel] = self:GetName()
            local otherTab
            if self == ShortWavePlayer.playlistTab then
                otherTab = ShortWavePlayer.searchTab
                if not ShortWavePlayer.playlistTab.body then
                    ShortWavePlayer.playlistTab.body = core.Playlist:CreateBody(startingWidth, maxHeight - 96)
                    ShortWavePlayer.playlistTab.body:SetParent(ShortWavePlayer.body)
                    ShortWavePlayer.playlistTab.body:SetPoint("TOPLEFT", ShortWavePlayer, "TOPLEFT", 0, -96)
                else
                    core.Playlist:RefreshPlaylists()
                end
            else
                otherTab = ShortWavePlayer.playlistTab
                if not ShortWavePlayer.searchTab.body then
                    ShortWavePlayer.searchTab.body = core.Search:CreateBody(startingWidth, maxHeight - 96)
                    ShortWavePlayer.searchTab.body:SetParent(ShortWavePlayer.body)
                    ShortWavePlayer.searchTab.body:SetPoint("TOPLEFT", ShortWavePlayer, "TOPLEFT", 0, -96)
                else
                    core.Search:ClearSearchBody()
                end
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

        -- alternative to the above that gets the tab by name instead of by reference
        function PlayerWindow:SelectTabByName(name)
            if ShortWavePlayer.searchTab:GetName() == name then
                selectTab(ShortWavePlayer.searchTab)
            else
                selectTab(ShortWavePlayer.playlistTab)
            end
        end

        ShortWavePlayer.playlistTab = CreateFrame("Button", "playlist", ShortWavePlayer.tabBars,
            "PanelTabButtonTemplate")
        ShortWavePlayer.playlistTab:SetPoint("BOTTOMLEFT", ShortWavePlayer.tabBars, "BOTTOMLEFT", 0, -6)
        ShortWavePlayer.playlistTab:SetSize(100, 26)
        ShortWavePlayer.playlistTab.Text:SetText("Playlists")
        ShortWavePlayer.playlistTab.Text:SetJustifyV("TOP")
        ShortWavePlayer.playlistTab:SetScript("OnClick", selectTab)
        setTabSizes(ShortWavePlayer.playlistTab)

        ShortWavePlayer.searchTab = CreateFrame("Button", "search", ShortWavePlayer.tabBars,
            "PanelTabButtonTemplate")
        ShortWavePlayer.searchTab:SetPoint("LEFT", ShortWavePlayer.playlistTab, "RIGHT", 10, 0)
        ShortWavePlayer.searchTab:SetSize(100, 26)
        ShortWavePlayer.searchTab.Text:SetText("Search")
        ShortWavePlayer.searchTab.Text:SetJustifyV("TOP")
        ShortWavePlayer.searchTab:SetScript("OnClick", selectTab)
        setTabSizes(ShortWavePlayer.searchTab)

        ShortWavePlayer.settingsTab = CreateFrame("Button", "search", ShortWavePlayer.tabBars,
            "PanelTabButtonTemplate")
        ShortWavePlayer.settingsTab:SetPoint("BOTTOMRIGHT", ShortWavePlayer.tabBars, "BOTTOMRIGHT", 0, -6)
        ShortWavePlayer.settingsTab:SetSize(100, 26)
        ShortWavePlayer.settingsTab.Text:SetText("Settings")
        ShortWavePlayer.settingsTab.Text:SetHeight(1)
        ShortWavePlayer.settingsTab.Text:SetJustifyV("TOP")
        ShortWavePlayer.settingsTab:SetScript("OnClick", function() core.Settings:OpenSettings() end)
        setTabSizes(ShortWavePlayer.settingsTab)
        PanelTemplates_DeselectTab(ShortWavePlayer.settingsTab)

        ShortWavePlayer.body = CreateFrame("Frame", nil, ShortWavePlayer)

        selectTab(ShortWaveVariables.selectedtab[core.Channel.currentChannel] == ShortWavePlayer.searchTab:GetName() and
            ShortWavePlayer.searchTab or
            ShortWavePlayer.playlistTab)
    end

    -- the channel tabs at the bottom of the screen
    -- unlike the body tabs, these are automatically generated based on the channels
    do
        ShortWavePlayer.channelTabs = CreateFrame("Frame", nil, ShortWavePlayer)
        ShortWavePlayer.channelTabs:SetSize(startingWidth - 20, 40)
        ShortWavePlayer.channelTabs:SetPoint("BOTTOMLEFT", ShortWavePlayer, 10, -20)

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
            local tab = CreateFrame("Button", channel, ShortWavePlayer.channelTabs,
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
                tab:SetPoint("BOTTOMLEFT", ShortWavePlayer.channelTabs, "BOTTOMLEFT", 0, -6)
            end
            lastFrame = tab
            table.insert(tabs, tab)
        end

        selectTab(ShortWaveVariables.selectedChannel or tabs[1]:GetName())
    end

    PlayerWindow:ToggleExpand(ShortWaveVariables.IsShown)

    -- call this on creation incase you were already a party leader
    PlayerLeaderCheck()

    ShortWavePlayer:Hide()
    return ShortWavePlayer
end
