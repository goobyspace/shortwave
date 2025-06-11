local _, core = ...;
core.utils = {};

core.utils.dump = function(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. core.utils.dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

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
