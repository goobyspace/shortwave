local _, core = ...

local shortwaveLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Shortwave", {
    type = "data source",
    text = "Shortwave",
    icon = "Interface\\Icons\\INV_111_StatSoundWaveEmitter_Blackwater",
    OnClick = function(_, e)
        if (e == "RightButton") then
            ShortWaveVariables.minimap.hide = true
            core.Icon:Hide("Shortwave")
        else
            core.PlayerWindow:Toggle()
        end
    end,
    OnEnter = function()
        GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
        GameTooltip:SetText(
            "|cffffd100Shortwave!|r\n|cff00cc66Left-Click|r to toggle the audio player. \n|cff00cc66Right-Click|r to hide the minimap icon.",
            1, 1, 1)
        GameTooltip:Show()
    end,
    OnLeave = function()
        GameTooltip:Hide()
    end
})

if not ShortWaveGlobalData then
    -- this object is populated by the data addons
    -- it contains the filterable data for the search function
    -- but only if they get loaded
    ShortWaveGlobalData = {}
end

function core:OnLoadHandler(_, name)
    if name ~= "ShortWave" then return end;

    if ShortWaveVariables == nil then ShortWaveVariables = {} end
    core.Channel:OnLoad()
    core.Broadcast:Setup()

    core.Debug = false

    if not ShortWaveVariables.minimap then
        ShortWaveVariables.minimap = { hide = false }
    end

    core.Icon = LibStub("LibDBIcon-1.0")
    core.Icon:Register("Shortwave", shortwaveLDB, ShortWaveVariables.minimap)

    SLASH_ShortWaveShort1 = "/SW"
    SlashCmdList.ShortWaveShort = core.SlashCommandHandler
    SLASH_ShortWave1 = "/ShortWave"
    SlashCmdList.ShortWave = core.SlashCommandHandler

    SLASH_RELOADUI1 = "/rl" -- For quicker reloading whilst debugging
    SlashCmdList.RELOADUI = ReloadUI
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", core.OnLoadHandler);
