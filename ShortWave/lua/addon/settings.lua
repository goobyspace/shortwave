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
    ["broadcastMusic"] = function(value)
        if core.Channel.currentChannel == "Music" then
            core.PlayerWindow.window.broadcastingToggle:SetChecked(value)
        end
    end,
    ["broadcastAmbience"] = function(value)
        if core.Channel.currentChannel == "Ambience" then
            core.PlayerWindow.window.broadcastingToggle:SetChecked(value)
        end
    end,
    ["broadcastSFX"] = function(value)
        if core.Channel.currentChannel == "SFX" then
            core.PlayerWindow.window.broadcastingToggle:SetChecked(value)
        end
    end,
    ["listenMusic"] = function(value)
        if core.Channel.currentChannel == "Music" then
            core.PlayerWindow.window.listeningToggle:SetChecked(value)
        end
    end,
    ["listenAmbience"] = function(value)
        if core.Channel.currentChannel == "Ambience" then
            core.PlayerWindow.window.listeningToggle:SetChecked(value)
        end
    end,
    ["listenSFX"] = function(value)
        if core.Channel.currentChannel == "SFX" then
            core.PlayerWindow.window.listeningToggle:SetChecked(value)
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
        local defaultValue = true

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, ShortWaveVariables.minimap,
            type(defaultValue),
            name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)

        Settings.CreateCheckbox(category, setting, nil)
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Shuffle"));

    do
        local name = "Keep Delay in Shuffle"
        local variable = "keepDelay"
        local variableKey = "keepDelay"
        local defaultValue = true

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, ShortWaveVariables,
            type(defaultValue),
            name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)

        local tooltip =
        "When this toggle is ticked, a shuffled playlist will try to keep the delay between songs in the same place it was before shuffling. \nToggling it off will ignore the delays entirely when shuffling."
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    do
        local name = "Keep Delay Before Sound"
        local variable = "delayFirst"
        local variableKey = "delayFirst"
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, ShortWaveVariables,
            type(defaultValue),
            name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)

        local tooltip =
        "When this toggle is ticked, delays will attempt to stay before their original next sound when shuffling a playlist. \nToggling it off will attempt to keep delays intact after their original sound instead."
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Broadcasting"));
    do
        if not ShortWaveVariables.broadcasting then
            ShortWaveVariables.broadcasting = {}
        end
        local name = "Music"
        local variable = "broadcastMusic"
        local variableKey = "Music"
        local defaultValue = true

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey,
            ShortWaveVariables.broadcasting,
            type(defaultValue),
            name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)

        local tooltip =
        "When this toggle is ticked, any audio you play in the music channel will be broadcasted to your group if you are the leader. \nToggling it off will mean any audio you play will only be heard by you no matter if you are the leader or not."
        Settings.CreateCheckbox(category, setting, tooltip)
    end
    do
        local name = "Ambience"
        local variable = "broadcastAmbience"
        local variableKey = "Ambience"
        local defaultValue = true

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey,
            ShortWaveVariables.broadcasting,
            type(defaultValue),
            name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)

        local tooltip =
        "When this toggle is ticked, any audio you play in the ambience channel will be broadcasted to your group if you are the leader. \nToggling it off will mean any audio you play will only be heard by you no matter if you are the leader or not."
        Settings.CreateCheckbox(category, setting, tooltip)
    end
    do
        local name = "SFX"
        local variable = "broadcastSFX"
        local variableKey = "SFX"
        local defaultValue = true

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey,
            ShortWaveVariables.broadcasting,
            type(defaultValue),
            name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)

        local tooltip =
        "When this toggle is ticked, any audio you play in the SFX channel will be broadcasted to your group if you are the leader. \nToggling it off will mean any audio you play will only be heard by you no matter if you are the leader or not."
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Listening"));
    do
        if not ShortWaveVariables.listening then
            ShortWaveVariables.listening = {}
        end
        local name = "Music"
        local variable = "listenMusic"
        local variableKey = "Music"
        local defaultValue = true

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey,
            ShortWaveVariables.listening,
            type(defaultValue),
            name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)

        local tooltip =
        "When this toggle is ticked, any audio your group leader (or assist) plays in their music channel will be played back to you.\nToggling it off mean you will not hear any music played by your group."
        Settings.CreateCheckbox(category, setting, tooltip)
    end
    do
        local name = "Ambience"
        local variable = "listenAmbience"
        local variableKey = "Ambience"
        local defaultValue = true

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey,
            ShortWaveVariables.listening,
            type(defaultValue),
            name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)

        local tooltip =
        "When this toggle is ticked, any audio your group leader (or assist) plays in their ambience channel will be played back to you.\nToggling it off mean you will not hear any ambience played by your group."
        Settings.CreateCheckbox(category, setting, tooltip)
    end
    do
        local name = "SFX"
        local variable = "listenSFX"
        local variableKey = "SFX"
        local defaultValue = true

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey,
            ShortWaveVariables.listening,
            type(defaultValue),
            name, defaultValue)
        setting:SetValueChangedCallback(OnSettingChanged)

        local tooltip =
        "When this toggle is ticked, any audio your group leader (or assist) plays in their SFX channel will be played back to you.\nToggling it off mean you will not hear any SFX played by your group."
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    Settings.RegisterAddOnCategory(category)

    -- call this fucntion to open the settings page to our addon settings
    function core.Settings:OpenSettings()
        Settings.OpenToCategory(category.ID)
    end
end
