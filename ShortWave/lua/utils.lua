local _, core = ...;
core.utils = {};

core.utils.filter = function(arr, func)
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

core.utils.contains = function(arr, value)
    for _, v in ipairs(arr) do
        if v == value then
            return true
        end
    end
    return false
end
