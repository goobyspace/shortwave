local _, core = ...

if not ShortWaveGlobalData then
    -- this object is populated by the data addons
    -- it contains the filterable data for the search function
    -- but only if they get loaded
    ShortWaveGlobalData = {}
end

function core:OnLoadHandler(event, name)
    if name ~= "ShortWave" then return end;

    if ShortWaveVariables == nil then ShortWaveVariables = {} end
    core.Channel:OnLoad()
    core.PlayerWindow:Toggle()

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
