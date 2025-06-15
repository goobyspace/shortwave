local _, core = ...
core.Settings = {}

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

local function OnSettingChanged(setting, value)
    if core.Settings.settingChangers[setting:GetVariable()] then
        core.Settings.settingChangers[setting:GetVariable()](value)
    end
end

function core.Settings:Initialize()
    MyAddOn_SavedVars = {}

    local category, layout = Settings.RegisterVerticalLayoutCategory("Shortwave")

    do
        local initializer = CreateSettingsButtonInitializer("Reset Shortwave Player", "Reset Position", function()
            core.PlayerWindow.window:ClearAllPoints()
            core.PlayerWindow.window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end, nil, true)
        layout:AddInitializer(initializer)
    end

    do
        local name = "Show Minimap Icon"
        local variable = "minimap"
        local variableKey = "toggle"
        local defaultValue = not ShortWaveVariables.minimap.hide

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, ShortWaveVariables.minimap,
            type(defaultValue),
            name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)

        local tooltip = "This is a tooltip for the checkbox."
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    Settings.RegisterAddOnCategory(category)

    function core.Settings:OpenSettings()
        Settings.OpenToCategory(category.ID)
    end
end
