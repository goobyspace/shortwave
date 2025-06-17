local _, core = ...

-- this object is populated by the data addons
-- it contains the filterable data for the search function
-- but only if they get loaded
ShortWaveGlobalData = {}

function core:OnLoadHandler(_, name)
    if name ~= "ShortWave" then return end;

    -- if this is a first launch create the saved variables
    if ShortWaveVariables == nil then ShortWaveVariables = {} end

    -- set all the initializations
    -- few order things are important:
    -- channel needs to go before everything else
    -- minimap needs to go before settings & commands
    core.Channel:Initialize()
    core.Broadcast:Initialize()
    core.Minimap:Initialize()
    core.Settings:Initialize()
    core.Commands.Initialize()

    if ShortWaveVariables.Debug then
        core.PlayerWindow:Toggle()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", core.OnLoadHandler);
