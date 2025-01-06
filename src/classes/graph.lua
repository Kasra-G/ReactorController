---@class Graph
local Graph = {
    ---@type string
    id = nil,
    ---@type string
    name = nil,
    ---@type Vector2
    offset = nil,
    ---@type Vector2
    size = nil,
    ---@type function
    drawCallback = nil,
    ---@param self Graph
    ---@param mon table
    ---@param statistics ReactorStatistics
    draw = function(self, mon, statistics)
        self.drawCallback(mon, self.offset, self.size, statistics)
    end,
}

---comment
---@param id string
---@param name string
---@param offset Vector2
---@param size Vector2
---@param drawCallback function
---@return Graph
local function newGraph(id, name, offset, size, drawCallback)

    local graphInstance = {
        id = id,
        name = name,
        offset = offset,
        size = size,
        drawCallback = drawCallback,
    }
	setmetatable(graphInstance, {__index = Graph})
    return graphInstance
end

_G.Graph = {
    new = newGraph
}

---@param mon table
---@param offset Vector2
---@param size Vector2
local function drawControlGraph(mon, offset, size, averageRod)
    local controlRodLength0To1 = averageRod / 100
    local controlRodMaxLengthOnScreen = size.y - 2
    local controlRodLengthOnScreen = math.ceil(controlRodLength0To1 * (controlRodMaxLengthOnScreen))


    DrawUtil.drawText(
        mon,
        "Control Level",
        offset + Vector2.new(1, 0),
        colors.black,
        colors.orange

    )
    DrawUtil.drawFilledBoxWithBorder(
        mon,
        colors.yellow,
        colors.gray,
        offset + Vector2.new(0, 1),
        size
    )
    DrawUtil.drawFilledBox(
        mon,
        colors.white,
        offset + Vector2.new(3, 2),
        Vector2.new(9, controlRodLengthOnScreen)
    )

    local controlRodPercentTextPosition, color
    if controlRodLengthOnScreen > 0 then
        color = colors.white
        controlRodPercentTextPosition = offset + Vector2.new(4, 1 + controlRodLengthOnScreen)
    else
        color = colors.yellow
        controlRodPercentTextPosition = offset + Vector2.new(4, 2)
    end

    DrawUtil.drawText(
        mon,
        string.format("%6.2f%%", averageRod),
        controlRodPercentTextPosition,
        color,
        colors.black
    )
end
local sizey = 1
local controlGraph = _G.Graph.new(
    "Control Level",
    "Control Level",
    Vector2.new(27, 4),
    Vector2.new(15, sizey - 7),
    drawControlGraph
)