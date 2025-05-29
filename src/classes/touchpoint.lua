local version = "1.01"
--[[
The MIT License (MIT)
 
Copyright (c) 2013 Lyqyd
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Edited by DrunkenKas.
	See Github: https://github.com/Kasra-G/ReactorController/#readme
--]]

local function setupLabel(buttonLen, minY, maxY, name)
	local labelTable = {}
	if type(name) == "table" then
		for i = 1, #name do
			labelTable[i] = name[i]
		end
		name = name.label
	elseif type(name) == "string" then
		local buttonText = string.sub(name, 1, buttonLen - 2)
		if #buttonText < #name then
			buttonText = " "..buttonText.." "
		else
			local labelLine = string.rep(" ", math.floor((buttonLen - #buttonText) / 2))..buttonText
			buttonText = labelLine..string.rep(" ", buttonLen - #labelLine)
		end
		for i = 1, maxY - minY + 1 do
			if maxY == minY or i == math.floor((maxY - minY) / 2) + 1 then
				labelTable[i] = buttonText
			else
				labelTable[i] = string.rep(" ", buttonLen)
			end
		end
	end
	return labelTable, name
end

---@class Touchpoint
local Touchpoint = {
	drawButton = function(self, buttonName)
		self.mon.setTextColor(colors.white)
		self.mon.setBackgroundColor(colors.black)
		local buttonData = self.buttonList[buttonName]
		if buttonData == nil then
			error("button does not exist")
		end
		if buttonData.active then
			self.mon.setBackgroundColor(buttonData.activeColor)
			self.mon.setTextColor(buttonData.activeText)
		else
			self.mon.setBackgroundColor(buttonData.inactiveColor)
			self.mon.setTextColor(buttonData.inactiveText)
		end
		for i = buttonData.yMin, buttonData.yMax do
			self.mon.setCursorPos(buttonData.xMin, i)
			self.mon.write(buttonData.label[i - buttonData.yMin + 1])
		end
	end,
	drawAllButtons = function(self)
		for name, _ in pairs(self.buttonList) do
			self:drawButton(name)
		end
	end,
	add = function(self, name, func, xMin, yMin, xMax, yMax, inactiveColor, activeColor, inactiveText, activeText)
		local label, name = setupLabel(xMax - xMin + 1, yMin, yMax, name)
		if self.buttonList[name] then error("button already exists", 2) end
		local x, y = self.mon.getSize()
		if xMin < 1 or yMin < 1 or xMax > x or yMax > y then error("button out of bounds", 2) end
		self.buttonList[name] = {
			func = func,
			xMin = xMin,
			yMin = yMin,
			xMax = xMax,
			yMax = yMax,
			active = false,
			inactiveColor = inactiveColor or colors.red,
			activeColor = activeColor or colors.lime,
			inactiveText = inactiveText or colors.white,
			activeText = activeText or colors.white,
			label = label,
		}
		for i = xMin, xMax do
			for j = yMin, yMax do
				if self.clickMap[i][j] ~= nil then
					--undo changes
					for k = xMin, xMax do
						for l = yMin, yMax do
							if self.clickMap[k][l] == name then
								self.clickMap[k][l] = nil
							end
						end
					end
					self.buttonList[name] = nil
					error("overlapping button", 2)
				end
				self.clickMap[i][j] = name
			end
		end
	end,
	remove = function(self, name)
		if self.buttonList[name] then
			local button = self.buttonList[name]
			for i = button.xMin, button.xMax do
				for j = button.yMin, button.yMax do
					self.clickMap[i][j] = nil
				end
			end
			self.buttonList[name] = nil
		end
	end,
	run = function(self)
		while true do
			self:drawAllButtons()
			local event = {self:handleEvents(os.pullEvent(self.id == "term" and "mouse_click" or "monitor_touch"))}
			if event[1] == "button_click" then
				self.buttonList[event[2]].func()
			end
		end
	end,
	handleEvents = function(self, ...)
		local event = {...}
		if #event == 0 then event = {os.pullEvent()} end
		if (self.id == "term" and event[1] == "mouse_click") or (self.id ~= "term" and event[1] == "monitor_touch" and event[2] == self.id) then
			local clicked = self.clickMap[event[3]][event[4]]
			if clicked and self.buttonList[clicked] then
				return "button_click", self.id, clicked
			end
		end
		return unpack(event)
	end,
	setButton = function(self, name, state)
		self.buttonList[name].active = state
		self:drawButton(name)
	end,
	toggleButton = function(self, name)
		self.buttonList[name].active = not self.buttonList[name].active
		self:drawButton(name)
	end,
	flash = function(self, name, duration)
		self:toggleButton(name)
		sleep(tonumber(duration) or 0.15)
		self:toggleButton(name)
	end,
	rename = function(self, name, newName)
		self.buttonList[name].label, newName = setupLabel(self.buttonList[name].xMax - self.buttonList[name].xMin + 1, self.buttonList[name].yMin, self.buttonList[name].yMax, newName)
		if not self.buttonList[name] then error("no such button", 2) end
		if name ~= newName then
			self.buttonList[newName] = self.buttonList[name]
			self.buttonList[name] = nil
			for i = self.buttonList[newName].xMin, self.buttonList[newName].xMax do
				for j = self.buttonList[newName].yMin, self.buttonList[newName].yMax do
					self.clickMap[i][j] = newName
				end
			end
		end
		self:drawAllButtons()
	end,
}

local function new(id, mon)
	local touchpointInstance = {
		id = id,
		mon = mon,
		buttonList = {},
		clickMap = {},
	}
	local x, y = touchpointInstance.mon.getSize()
	for i = 1, x do
		touchpointInstance.clickMap[i] = {}
	end
	setmetatable(touchpointInstance, {__index = Touchpoint})
	return touchpointInstance
end

_G.Touchpoint = {new = new}
