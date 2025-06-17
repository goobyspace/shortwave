local _, core = ...
core.Commands = {}
-- list of commands, structure goes like "/sw [command]" or "/shortwave [command]"
-- debug, vars & core are for debugging purposes only
core.Commands.commands = {
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

-- slash command handler, this is called when the user types /sw or /shortwave and then checks the next word
function core.Commands.SlashCommandHandler(str)
    if (#str == 0) then
        core.Commands.commands.help()
    end
    -- turn arguments after / command into table and then check if they match a function and what the other arguments are, if they dont match a function request help
    local args = {};
    for _, arg in ipairs({ string.split(' ', str) }) do
        if (#arg > 0) then
            table.insert(args, arg);
        end
    end

    local path = core.Commands.commands;

    for id, arg in ipairs(args) do
        if (#arg > 0) then
            arg = arg:lower();
            if (path[arg]) then
                if (type(path[arg]) == "function") then
                    path[arg](select(id + 1, unpack(args)));
                    return;
                elseif (type(path[arg]) == "table") then
                    path = path[arg];
                end
            else
                -- do the help command if the command is not found
                core.Commands.commands.help();
                return;
            end
        end
    end
end

function core.Commands.Initialize()
    SLASH_ShortWaveShort1 = "/SW"
    SlashCmdList.ShortWaveShort = core.Commands.SlashCommandHandler
    SLASH_ShortWave1 = "/ShortWave"
    SlashCmdList.ShortWave = core.Commands.SlashCommandHandler

    if core.Debug then
        SLASH_RELOADUI1 = "/rl"
        SlashCmdList.RELOADUI = ReloadUI
    end
end
