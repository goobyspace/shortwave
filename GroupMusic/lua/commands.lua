local _, core = ...

core.commands = {
    ["player"] = core.PlayerWindow.Toggle,
    ["vars"] = function()
        print(core.utils.dump(core));
    end,
    ["help"] = function()
        print(" ")
        print("Group Music Help")
        print("|cff00cc66/gm player|r - shows player menu");
        print("|cff00cc66/gm help|r - shows help info");
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
