local _, core = ...

function core:OnLoadHandler(event, name)
    if name ~= "GroupMusic" then return end;

    if GroupMusicVariables == nil then GroupMusicVariables = {} end
    SLASH_RELOADUI1 = "/rl" -- For quicker reloading whilst debugging
    SlashCmdList.RELOADUI = ReloadUI

    core.PlayerWindow:Toggle()

    SLASH_GMusicShort1 = "/GM"
    SlashCmdList.GMusicShort = core.SlashCommandHandler
    SLASH_GMusic1 = "/GroupMusic"
    SlashCmdList.QMusic = core.SlashCommandHandler
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", core.OnLoadHandler);
