local _, core = ...;
core.Utils = {};

core.Utils.filter = function(arr, func)
    local new_index = 1
    local newArray = {}
    for old_index, v in ipairs(arr) do
        if func(v, old_index) then
            newArray[new_index] = v
            new_index = new_index + 1
        end
    end
    return newArray
end

core.Utils.contains = function(arr, value)
    for _, v in ipairs(arr) do
        if v == value then
            return true
        end
    end
    return false
end

core.Utils.createGameTooltip = function(frame, text)
    if not frame then
        return
    end
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, 1, 1, 1)
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end
