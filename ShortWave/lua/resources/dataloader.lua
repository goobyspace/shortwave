local _, core = ...
core.DataLoader = {}
local DataLoader = core.DataLoader

-- pretty simple function but really cool
-- when asking for data, it will load the relevant addon
-- and the data will be added to the global ShortWaveGlobalData table within the respective addon
-- but if this is not called, it will not load any of the addons
-- which makes a huge difference, especially the SFX data which can be like 100MB in memory
-- and will then just stay in your game until a reload or restart only when you actually ask for it
-- instead of being there all the time
function DataLoader:GetData(dataToGet)
    local AddonToLoad = ""
    if core.Utils.contains(core.Channel.searchData[core.Channel.channels[1]], dataToGet) then
        AddonToLoad = "ShortWave_MusicData"
    elseif core.Utils.contains(core.Channel.searchData[core.Channel.channels[2]], dataToGet) then
        AddonToLoad = "ShortWave_AmbienceData"
    elseif core.Utils.contains(core.Channel.searchData[core.Channel.channels[3]], dataToGet) then
        AddonToLoad = "ShortWave_SFXData"
    else
        return {}
    end

    local loaded, error = C_AddOns.LoadAddOn(AddonToLoad)
    if not loaded or error then
        core.Search:SetErrorText(AddonToLoad ..
            " is disabled or missing, please ensure it is installed and enabled in the AddOns menu.")
        return {}
    end

    core.Search:SetErrorText()

    if ShortWaveGlobalData then
        return ShortWaveGlobalData[dataToGet] or {}
    else
        return {}
    end
end
