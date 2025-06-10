-------------------------------
-- Namespaces & Variables
-------------------------------
local _, core = ...
core.Player = {}
local Player = core.Player
local groupMusicConfig
-------------------------------
-- Config
-- in config we 1: Create the actual configuration window
-- 2: Set our global bools depending on the toggles in the menu
-------------------------------
function Player:Toggle()
    local menu = groupMusicConfig or Player:CreateMenu()
    menu:SetShown(not menu:IsShown())
end

function Player:CreateToggle(point, relativeFrame, relativePoint, text, toggleVar, bgType)
    local toggle = CreateFrame("CheckButton", nil, groupMusicConfig, "UicheckButtonTemplate")
    toggle:SetPoint(point, relativeFrame, relativePoint)
    toggle.text:SetText(text)
    toggle:SetChecked(toggleVar)
    toggle:SetScript("OnClick", function() core.Config:VarStates(bgType) end)
    return toggle;
end

Player.SetMovable = function(f)
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

function Player:CreateMenu()
    -- creating the main frame + its location
    groupMusicConfig = CreateFrame("Frame", "arenaSoundUIFrame", UIParent, "BasicFrameTemplateWithInset")
    groupMusicConfig:SetSize(200, 230)
    groupMusicConfig:SetPoint("CENTER", UIParent, GroupMusicVariables.point or "CENTER", GroupMusicVariables.xOfs or 0,
        GroupMusicVariables.yOfs or 120)

    -- title
    groupMusicConfig.title = groupMusicConfig:CreateFontString(nil, "OVERLAY")
    groupMusicConfig.title:SetFontObject("GameFontHighlight")
    groupMusicConfig.title:SetPoint("CENTER", groupMusicConfig.TitleBg, "CENTER")
    groupMusicConfig.title:SetText("Group Music Player")
    self.SetMovable(groupMusicConfig)

    -- mainFrame
    groupMusicConfig.mainArea = CreateFrame("Frame", nil, groupMusicConfig)
    groupMusicConfig.mainArea:SetSize(20, 190)
    groupMusicConfig.mainArea:SetPoint("BOTTOM", groupMusicConfig, "BOTTOM", 0, 10)

    groupMusicConfig:Hide()
    return groupMusicConfig
end
