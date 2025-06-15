local _, core = ...
core.Minimap = {}

local shortwaveLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Shortwave", {
    type = "data source",
    text = "Shortwave",
    icon = "Interface\\Icons\\INV_111_StatSoundWaveEmitter_Blackwater",
    OnClick = function(_, e)
        if (e == "RightButton") then
            core.Settings:OpenSettings()
        else
            core.PlayerWindow:Toggle()
        end
    end,
    OnEnter = function()
        GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
        GameTooltip:SetText(
            "|cffffd100Shortwave!|r\n|cff00cc66Left-Click|r to toggle the audio player. \n|cff00cc66Right-Click|r to open Shortwave settings.",
            1, 1, 1)
        GameTooltip:Show()
    end,
    OnLeave = function()
        GameTooltip:Hide()
    end
})

function core.Minimap:CreatIcon()
    core.Minimap.Icon = LibStub("LibDBIcon-1.0")
    core.Minimap.Icon:Register("Shortwave", shortwaveLDB, ShortWaveVariables.minimap)
    if ShortWaveVariables.minimap.hide then
        core.Minimap.Icon:Hide("Shortwave")
    else
        core.Minimap.Icon:Show("Shortwave")
    end
end
