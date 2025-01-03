
---comment
---@param mon table
---@param drawFunction function
local function executeAndRestoreMonitorSettings(mon, drawFunction)
    if (mon == nil) then
        error("Error! Mon is nil")
        return
    end

    local originalCursorPos = Vector2.new(mon.getCursorPos())
    local originalBackgroundColor = mon.getBackgroundColor()
    local originalTextColor = mon.getTextColor()

    drawFunction()

    mon.setCursorPos(originalCursorPos.x, originalCursorPos.y)
    mon.setBackgroundColor(originalBackgroundColor)
    mon.setTextColor(originalTextColor)
end

---comment Draws a filled rectangle
---@param mon table
---@param color any
---@param offset Vector2
---@param size Vector2
local function drawFilledRectangle(mon, color, offset, size)
    executeAndRestoreMonitorSettings(
        mon,
        function ()
            local horizLine = string.rep(" ", size.x)
            mon.setBackgroundColor(color)
            for i=0, size.y - 1 do
                mon.setCursorPos(offset.x, offset.y + i)
                mon.write(horizLine)
            end
        end
    )
end

---comment Draws a rectangle with a fill color and border
---@param mon table
---@param innerColor any
---@param outerColor any
---@param offset Vector2
---@param size Vector2
local function drawRectangle(mon, innerColor, outerColor, offset, size)
    drawFilledRectangle(mon, outerColor, offset, size)
    drawFilledRectangle(mon, innerColor, offset + 1, size - 2)
end

---comment Draws text on the screen
---@param mon table
---@param text string
---@param pos Vector2
---@param backgroundColor any
---@param textColor any
local function drawText(mon, text, pos, backgroundColor, textColor)
    executeAndRestoreMonitorSettings(
        mon,
        function ()
            mon.setCursorPos(pos.x, pos.y)
            mon.setBackgroundColor(backgroundColor)
            mon.setTextColor(textColor)
            mon.write(text)
        end
    )
end

_G.DrawUtil = {
    drawRectangle = drawRectangle,
    drawFilledRectangle = drawFilledRectangle,
    drawText = drawText,
}
