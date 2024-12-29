local function reverse(arr)
    for i = 1, math.floor(#arr / 2) do
        arr[i], arr[#arr - i + 1] = arr[#arr - i + 1], arr[i]
    end
end

local M = {}

M.list_contains = function(list, item)
    for _, x in ipairs(list) do
        if x == item then
            return true
        end
    end

    return false
end

M.capitalize = function(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

M.deduplicate = function(arr)
    local seen = {}
    local deduped = {}

    for i = #arr, 1, -1 do
        local item = arr[i]

        if not seen[item] then
            seen[item] = true
            table.insert(deduped, item)
        end
    end

    reverse(deduped)

    return deduped
end

return M
