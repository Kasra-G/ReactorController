---@class Vector2
local Vector2 = {
    ---@type number
    x = nil,
    ---@type number
    y = nil,
}

---@param x number
---@param y number
---@return Vector2
local function new(x, y)
    return vector.new(x, y)
end

_G.Vector2 = {
    new = new,
    zero = new(0, 0),
    one = new(1, 1),
}
