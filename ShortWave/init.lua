local _, core = ...

if not ShortWaveGlobalData then
    ShortWaveGlobalData = {}
end

function core:OnLoadHandler(event, name)
    if name ~= "ShortWave" then return end;

    if ShortWaveVariables == nil then ShortWaveVariables = {} end
    ShortWaveVariables = {}
    SLASH_RELOADUI1 = "/rl" -- For quicker reloading whilst debugging
    SlashCmdList.RELOADUI = ReloadUI
    core.Channel:OnLoad()
    core.PlayerWindow:Toggle()
    SLASH_ShortWaveShort1 = "/SW"
    SlashCmdList.ShortWaveShort = core.SlashCommandHandler
    SLASH_ShortWave1 = "/ShortWave"
    SlashCmdList.ShortWave = core.SlashCommandHandler
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", core.OnLoadHandler);
