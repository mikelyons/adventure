-- Debug UI Module
-- Shows FPS and other debug info, toggleable from pause menu

local Color = require("color")

local DebugUI = {
    visible = false,
    fps = 0,
    fpsUpdateTimer = 0,
    fpsUpdateInterval = 0.5,  -- Update FPS reading every 0.5 seconds
    frameTime = 0,
    buttonHovered = false,
    buttonArea = {x = 0, y = 0, w = 0, h = 0}
}

function DebugUI:update(dt)
    if not self.visible then return end

    self.frameTime = dt
    self.fpsUpdateTimer = self.fpsUpdateTimer + dt

    if self.fpsUpdateTimer >= self.fpsUpdateInterval then
        self.fps = love.timer.getFPS()
        self.fpsUpdateTimer = 0
    end
end

function DebugUI:draw()
    if not self.visible then return end

    local screenW = love.graphics.getDimensions()

    -- Position in upper right corner
    local boxW = 100
    local boxH = 45
    local boxX = screenW - boxW - 10
    local boxY = 10

    -- Background
    Color.set(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 4, 4)

    -- Border
    Color.set(0.4, 0.4, 0.4, 0.9)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 4, 4)

    -- FPS text
    local fpsColor = self.fps >= 55 and {0.4, 0.9, 0.4} or (self.fps >= 30 and {0.9, 0.9, 0.4} or {0.9, 0.4, 0.4})
    Color.set(fpsColor[1], fpsColor[2], fpsColor[3], 1)
    love.graphics.print("FPS: " .. self.fps, boxX + 8, boxY + 5)

    -- Log button
    local btnX = boxX + 8
    local btnY = boxY + 22
    local btnW = boxW - 16
    local btnH = 18

    self.buttonArea = {x = btnX, y = btnY, w = btnW, h = btnH}

    -- Button background
    if self.buttonHovered then
        Color.set(0.3, 0.5, 0.7, 0.9)
    else
        Color.set(0.2, 0.3, 0.4, 0.9)
    end
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 3, 3)

    -- Button border
    Color.set(0.5, 0.6, 0.7, 0.9)
    love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 3, 3)

    -- Button text
    Color.set(0.9, 0.9, 0.9, 1)
    love.graphics.printf("Log FPS", btnX, btnY + 3, btnW, "center")
end

function DebugUI:mousemoved(x, y)
    if not self.visible then return end

    local btn = self.buttonArea
    self.buttonHovered = x >= btn.x and x <= btn.x + btn.w and
                         y >= btn.y and y <= btn.y + btn.h
end

function DebugUI:mousepressed(x, y, button)
    if not self.visible then return false end
    if button ~= 1 then return false end

    local btn = self.buttonArea
    if x >= btn.x and x <= btn.x + btn.w and
       y >= btn.y and y <= btn.y + btn.h then
        self:logFPS()
        return true
    end

    return false
end

function DebugUI:logFPS()
    local frameMs = self.frameTime * 1000
    print(string.format("[DEBUG] FPS: %d | Frame time: %.2f ms", self.fps, frameMs))
end

function DebugUI:toggle()
    self.visible = not self.visible
    print("[DEBUG] Debug UI " .. (self.visible and "enabled" or "disabled"))
end

function DebugUI:isVisible()
    return self.visible
end

function DebugUI:setVisible(visible)
    self.visible = visible
end

return DebugUI
