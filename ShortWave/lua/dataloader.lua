local _, core = ...
core.DataLoader = {}
local DataLoader = core.DataLoader

function DataLoader:GetData(dataToGet)
    local AddonToLoad = ""
    if core.utils.contains(core.Channel.searchData[core.Channel.channels[1]], dataToGet) then
        AddonToLoad = "ShortWave_MusicData"
    elseif core.utils.contains(core.Channel.searchData[core.Channel.channels[2]], dataToGet) then
        AddonToLoad = "ShortWave_AmbienceData"
    elseif core.utils.contains(core.Channel.searchData[core.Channel.channels[3]], dataToGet) then
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
    if dataToGet == "creature" then
        --creature is a special case, it is split into three files due to the sheer size of the data
        --wow starts hitting our addon with a stick if we put it all in one file
        --because of this filtering also takes forever and any extra loading is just felt immediately
        --for this reason most of the data is actually called directly in search.lua
        return ShortWaveGlobalData["creatureIndex"]
    elseif ShortWaveGlobalData then
        return ShortWaveGlobalData[dataToGet] or {}
    else
        return {}
    end
end
