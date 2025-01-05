
---comment Draws a rectangle with a border
---@param mon table
---@param color any
---@param offset Vector2
---@param size Vector2
local function drawFilledRectangle(mon, color, offset, size)
    if size.x <= 0 or size.y <= 0 then
        return
    end
    local old = term.redirect(mon)
    local endCoord = offset + size - 1
    paintutils.drawFilledBox(offset.x, offset.y, endCoord.x, endCoord.y, color)
    term.redirect(old)
end

---comment Draws a rectangle with a fill color and border
---@param mon table
---@param innerColor any
---@param outerColor any
---@param offset Vector2
---@param size Vector2
local function drawFilledBoxWithBorder(mon, innerColor, outerColor, offset, size)
    if size.x <= 0 or size.y <= 0 then
        return
    end
    local old = term.redirect(mon)
    local endCoord = offset + size - 1
    paintutils.drawBox(offset.x, offset.y, endCoord.x, endCoord.y, outerColor)

    if size.x > 2 and size.y > 2 then
        paintutils.drawFilledBox(offset.x + 1, offset.y + 1, endCoord.x - 1, endCoord.y - 1, innerColor)
    end
    term.redirect(old)
end

---comment Draws text on the screen
---@param mon table
---@param text string
---@param pos Vector2
---@param backgroundColor any
---@param textColor any
local function drawText(mon, text, pos, backgroundColor, textColor)
    mon.setCursorPos(pos.x, pos.y)
    local len = #text
    mon.blit(text, string.rep(colors.toBlit(textColor), len), string.rep(colors.toBlit(backgroundColor), len))
end

_G.DrawUtil = {
    drawFilledBoxWithBorder = drawFilledBoxWithBorder,
    drawFilledRectangle = drawFilledRectangle,
    drawText = drawText,
}
