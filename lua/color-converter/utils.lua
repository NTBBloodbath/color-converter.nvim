local M = {}

M.round_float = function(num, decimal_points)
    local decimal = math.pow(10, decimal_points)
    return math.floor(num * decimal + 0.5) / decimal
end

return M
