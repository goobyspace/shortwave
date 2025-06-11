local _, core = ...
core.Search = {}
local Search = core.Search

local ScrollView = nil

local function CreateScrollView(body, width, height)
    body.ScrollBox = CreateFrame("Frame", nil, body, "WowScrollBoxList")
    body.ScrollBar = CreateFrame("EventFrame", nil, body, "MinimalScrollBar")
    body.ScrollBox:SetSize(width - 20, height - 34)
    body.ScrollBox:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -30)
    body.ScrollBar:SetPoint("TOPLEFT", body.ScrollBox, "TOPRIGHT")
    body.ScrollBar:SetPoint("BOTTOMLEFT", body.ScrollBox, "BOTTOMRIGHT")

    ScrollView = CreateScrollBoxListLinearView()
    ScrollUtil.InitScrollBoxListWithScrollBar(body.ScrollBox, body.ScrollBar, ScrollView)
    ScrollView:SetElementExtent(24)

    local function Initializer(frame, data)
        local index = frame:GetOrderIndex()
        if index % 2 == 0 then
            frame.BlueBackground:Hide()
            frame.BlackBackground:Show()
        else
            frame.BlueBackground:Show()
            frame.BlackBackground:Hide()
        end
        frame.Text:SetText(data.name)
        frame.PlayButton:SetScript("OnClick", function()
            -- Play the sound when the frame is clicked
            if data.id then
                core.Player:PlaySong(data.id, data.name)
            end
        end)
        frame.PlaylistButton:SetScript("OnClick", function()
            print("Heyyyy, you clicked the playlist button for " .. data.name .. "idk go open a dropdown or something")
        end)
    end
    ScrollView:SetElementInitializer("SongFrameTemplate", Initializer)

    local DataProvider = CreateDataProvider(core.music)
    ScrollView:SetDataProvider(DataProvider)

    return body.ScrollBox, body.ScrollBar
end

function Search:CreateBody(width, height)
    local body = CreateFrame("Frame", "SearchBody", nil, "InsetFrameTemplate");
    body:SetSize(width, height);

    CreateScrollView(body, width, height);

    body.SearchBar = CreateFrame("EditBox", "SearchBar", body, "SearchBoxTemplate");
    body.SearchBar:SetSize(width - 20, 30);
    body.SearchBar:SetPoint("TOP", body, "TOP", 2, -2);
    body.SearchBar:SetScript("OnEnterPressed", function()
        local searchText = body.SearchBar:GetText();
        if not ScrollView then
            return
        end
        if searchText and searchText ~= "" then
            local filteredData = core.utils.filter(core.music, function(file)
                return string.find(string.lower(file.path), string.lower(searchText), 1,
                    true) ~= nil;
            end);

            local DataProvider = CreateDataProvider(filteredData)
            ScrollView:SetDataProvider(DataProvider)
        elseif searchText == "" then
            local DataProvider = CreateDataProvider(core.music)
            ScrollView:SetDataProvider(DataProvider)
        end
        body.SearchBar:ClearFocus();
    end);

    return body;
end
