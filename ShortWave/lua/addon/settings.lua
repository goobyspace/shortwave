local _, core = ...
core.Settings = {}

-- call this on any setting changers if they need special functions to update other frames
core.Settings.settingChangers = {
    ["minimap"] = function(value)
        if value then
            -- for some reason the minimap icon library uses an object with a 'hide' value
            -- so the value is opposite of whatever our saved variable or the checkbox is
            ShortWaveVariables.minimap.hide = false
            ShortWaveVariables.minimap.toggle = true
            core.Minimap.Icon:Show("Shortwave")
        else
            ShortWaveVariables.minimap.hide = true
            ShortWaveVariables.minimap.toggle = false
            core.Minimap.Icon:Hide("Shortwave")
        end
    end,
}

-- just a wrapper for settingChangers
local function OnSettingChanged(setting, value)
    if core.Settings.settingChangers[setting:GetVariable()] then
        core.Settings.settingChangers[setting:GetVariable()](value)
    end
end

-- create the vertical layout category and add the settings to it
function core.Settings:Initialize()
    MyAddOn_SavedVars = {}

    -- there's practically 0 documentation on this, but you can find some stuff by searching through the wow UI source
    -- https://github.com/Gethe/wow-ui-source
    local category, layout = Settings.RegisterVerticalLayoutCategory("Shortwave")

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("General"));

    do
        -- this creates a slightly inset button
        layout:AddInitializer(CreateSettingsButtonInitializer("Reset Shortwave Player", "Reset Position", function()
            core.PlayerWindow.window:ClearAllPoints()
            core.PlayerWindow.window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end, nil, true))
    end

    do
        -- this creates a checkbox for the minimap icon
        -- by default it already changes the value in the saved variables
        -- but we still need to call the onSettingChanged function to actually update the minimap icon
        local name = "Show Minimap Icon"
        local variable = "minimap"
        local variableKey = "toggle"
        local defaultValue = not ShortWaveVariables.minimap.hide

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, ShortWaveVariables.minimap,
            type(defaultValue),
            name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)

        Settings.CreateCheckbox(category, setting, nil)
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Shuffle"));

    do
        local name = "Keep Delay in Shuffle"
        local variable = "ShortWaveVariables"
        local variableKey = "keepDelay"
        local defaultValue = ShortWaveVariables.keepDelay or true

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, ShortWaveVariables,
            type(defaultValue),
            name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)

        local tooltip =
        "When this toggle is ticked, a shuffled playlist will try to keep the delay between songs in the same place it was before shuffling. \nToggling it off will ignore the delays entirely when shuffling."
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    Settings.RegisterAddOnCategory(category)

    -- call this fucntion to open the settings page to our addon settings
    function core.Settings:OpenSettings()
        Settings.OpenToCategory(category.ID)
    end
end
