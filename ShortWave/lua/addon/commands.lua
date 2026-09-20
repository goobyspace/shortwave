local _, core = ...
core.Commands = {}

-- opens a resizable, selectable text box so debug output can be copied out of the game
local function ShowCopyableText(title, text)
    if not core.Commands.copyFrame then
        local frame = CreateFrame("Frame", "ShortWaveCopyFrame", UIParent, "DefaultPanelTemplate")
        frame:SetSize(500, 400)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        frame.title = frame.TitleContainer:CreateFontString("TitleText")
        frame.title:SetFontObject("GameFontNormal")
        frame.title:SetPoint("CENTER")

        frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -2)
        frame.closeButton:SetSize(20, 20)
        frame.closeButton:SetScript("OnClick", function() frame:Hide() end)

        frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        frame.scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -30)
        frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 12)

        frame.editBox = CreateFrame("EditBox", nil, frame.scrollFrame)
        frame.editBox:SetMultiLine(true)
        frame.editBox:SetFontObject("ChatFontNormal")
        frame.editBox:SetWidth(440)
        frame.editBox:SetAutoFocus(false)
        frame.editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
        frame.scrollFrame:SetScrollChild(frame.editBox)

        core.Commands.copyFrame = frame
    end

    local frame = core.Commands.copyFrame
    frame.title:SetText(title)
    frame.editBox:SetText(text)
    frame.editBox:HighlightText()
    frame.editBox:SetFocus()
    frame:Show()
end

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
    ["settings"] = function()
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
    ["testfunc"] = function()
        for _, coreChannel in pairs(core.Channel.channels) do
            core.Player:StopSoundOnChannel(coreChannel)
        end
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
    ["bordercheck"] = function()
        local window = core.PlayerWindow.window
        if not window or not window.NineSlice then
            print("Shortwave: player window isn't created yet, open it first")
            return
        end
        local NineSlice = window.NineSlice
        local layout = NineSliceUtil.GetLayout(window.layoutType)
        local lines = { "Shortwave border check, frame height: " .. window:GetHeight() }
        for _, corner in ipairs({ "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner" }) do
            local piece = NineSlice[corner]
            local pieceLayout = layout and layout[corner]
            local info = pieceLayout and C_Texture.GetAtlasInfo(pieceLayout.atlas)
            if piece and info then
                table.insert(lines, string.format("%s: atlas=%s atlasSize=%dx%d pieceSize=%dx%d layoutOffset=%s,%s",
                    corner, pieceLayout.atlas, info.width, info.height, piece:GetWidth(), piece:GetHeight(),
                    tostring(pieceLayout.x), tostring(pieceLayout.y)))
            end
        end
        for _, edge in ipairs({ "TopEdge", "BottomEdge" }) do
            local piece = NineSlice[edge]
            if piece then
                table.insert(lines, string.format("%s: pieceSize=%dx%d", edge, piece:GetWidth(), piece:GetHeight()))
            end
        end
        ShowCopyableText("Shortwave Border Check", table.concat(lines, "\n"))
    end,
    ["help"] = function()
        print(" ")
        print("Shortwave Help")
        print("|cff647afa/shortwave player|r - toggle the player");
        print("|cff647afa/shortwave minimap|r - toggle the minimap icon");
        print("|cff647afa/shortwave settings|r - toggle the settings window");
        print("|cff647afa/shortwave reset|r - resets the player window position back to the center");
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
