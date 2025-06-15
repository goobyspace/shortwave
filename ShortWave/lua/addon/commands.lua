local _, core = ...

core.commands = {
    ["player"] = core.PlayerWindow.Toggle,
    ["reset"] = function()
        core.PlayerWindow.window:ClearAllPoints()
        core.PlayerWindow.window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end,
    ["minimap"] = function()
        core.Settings.settingChangers["minimap"](ShortWaveVariables.minimap.hide)
    end,
    ["options"] = function()
        core.Settings:OpenSettings()
    end,
    ["debug"] = function()
        if not ShortWaveVariables.Debug then
            ShortWaveVariables.Debug = true
            print("Shortwave debug mode is now on")
            return
        end
        ShortWaveVariables.Debug = ShortWaveVariables.Debug == false
        print("Shortwave debug mode is now " .. (ShortWaveVariables.Debug and "on" or "off"))
    end,
    ["vars"] = function()
        print("Current variables:")
        DevTools_Dump(ShortWaveVariables)
        print("--------------------------")
    end,
    ["core"] = function()
        print("Current core:")
        DevTools_Dump(core)
        print("--------------------------")
    end,
    ["help"] = function()
        print(" ")
        print("Shortwave Help")
        print("|cff00cc66/shortwave player|r - toggle the player");
        print("|cff00cc66/shortwave minimap|r - toggle the minimap icon");

        print("|cff00cc66/shortwave reset|r - resets the player window position back to the center");
        print(" ")
    end
}

function core.SlashCommandHandler(str)
    if (#str == 0) then
        core.commands.help()
    end
    -- turn arguments after / command into table and then check if they match a function and what the other arguments are, if they dont match a function request help
    local args = {};
    for _, arg in ipairs({ string.split(' ', str) }) do
        if (#arg > 0) then
            table.insert(args, arg);
        end
    end

    local path = core.commands; -- required for updating found table.

    for id, arg in ipairs(args) do
        if (#arg > 0) then -- if string length is greater than 0.
            arg = arg:lower();
            if (path[arg]) then
                if (type(path[arg]) == "function") then
                    -- all remaining args passed to our function!
                    path[arg](select(id + 1, unpack(args)));
                    return;
                elseif (type(path[arg]) == "table") then
                    path = path[arg]; -- another sub-table found!
                end
            else
                -- does not exist!
                core.commands.help();
                return;
            end
        end
    end
end
