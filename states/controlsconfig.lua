local ControlsConfig = {}
local Controls = require("controls")
local Color = require("color")

function ControlsConfig:load()
    self.mode = self.mode or "worldmap"
    self.actions = Controls:getActions(self.mode)
    self.selected = 1
    self.selectionTime = 0
    self.waitingForKey = false
    self.waitingSlot = 1
    self.scrollOffset = 0
    self.maxVisible = 6
end

function ControlsConfig:enter(mode)
    self.mode = mode or "worldmap"
    self.actions = Controls:getActions(self.mode)
    self.selected = 1
    self.waitingForKey = false
end

function ControlsConfig:update(dt)
    self.selectionTime = self.selectionTime + dt
end

function ControlsConfig:draw()
    local screenW, screenH = love.graphics.getDimensions()

    -- Semi-transparent overlay
    Color.set(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Panel background
    local panelW = 450
    local panelH = 400
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Panel shadow
    Color.set(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", panelX + 5, panelY + 5, panelW, panelH, 8, 8)

    -- Panel background
    Color.set(0.10, 0.12, 0.18, 0.98)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)

    -- Panel border
    Color.set(0.40, 0.50, 0.70, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)

    -- Title
    local modeName = Controls.modeNames[self.mode] or self.mode
    Color.set(0.90, 0.88, 0.78)
    love.graphics.printf("CONTROLS: " .. string.upper(modeName), panelX, panelY + 20, panelW, "center")

    -- Decorative line under title
    local lineY = panelY + 50
    local lineW = 200
    local lineX = panelX + (panelW - lineW) / 2
    Color.set(0.35, 0.40, 0.55)
    love.graphics.rectangle("fill", lineX, lineY, lineW, 2)

    -- Waiting for key overlay
    if self.waitingForKey then
        -- Darken background more
        Color.set(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)

        -- Prompt
        Color.set(0.95, 0.85, 0.40)
        love.graphics.printf("Press a key to bind...", panelX, screenH / 2 - 20, panelW, "center")
        Color.set(0.60, 0.65, 0.75)
        love.graphics.printf("(ESC to cancel)", panelX, screenH / 2 + 10, panelW, "center")
        return
    end

    -- Actions list
    local listY = panelY + 70
    local itemHeight = 42
    local listPadding = 20

    -- Calculate visible range
    local visibleStart = self.scrollOffset + 1
    local visibleEnd = math.min(self.scrollOffset + self.maxVisible, #self.actions + 1) -- +1 for Back option

    for displayIdx = 1, self.maxVisible do
        local idx = self.scrollOffset + displayIdx
        if idx > #self.actions + 1 then break end -- +1 for Back option

        local itemY = listY + (displayIdx - 1) * itemHeight
        local isSelected = (idx == self.selected)
        local isBackOption = (idx == #self.actions + 1)

        -- Selection animation
        local selectPulse = isSelected and (math.sin(self.selectionTime * 4) * 0.1 + 0.9) or 0.6

        -- Item background
        if isSelected then
            Color.set(0.25, 0.35, 0.55, 0.7)
            love.graphics.rectangle("fill", panelX + listPadding - 5, itemY - 3, panelW - listPadding * 2 + 10, itemHeight - 6, 4, 4)
            Color.set(0.50, 0.65, 0.90, selectPulse)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", panelX + listPadding - 5, itemY - 3, panelW - listPadding * 2 + 10, itemHeight - 6, 4, 4)
        end

        if isBackOption then
            -- Back option
            if isSelected then
                Color.set(0.95, 0.95, 1)
            else
                Color.set(0.55, 0.60, 0.70)
            end
            love.graphics.printf("< Back", panelX, itemY + 8, panelW, "center")
        else
            -- Action name and keys
            local action = self.actions[idx]
            local actionName = Controls.actionNames[action] or action
            local keys = Controls:formatKeys(self.mode, action)

            -- Action name (left side)
            if isSelected then
                Color.set(0.95, 0.95, 1)
            else
                Color.set(0.70, 0.75, 0.85)
            end
            love.graphics.print(actionName, panelX + listPadding, itemY + 8)

            -- Keys (right side)
            if isSelected then
                Color.set(0.70, 0.85, 1)
            else
                Color.set(0.50, 0.55, 0.65)
            end
            local keysWidth = love.graphics.getFont():getWidth(keys)
            love.graphics.print(keys, panelX + panelW - listPadding - keysWidth, itemY + 8)
        end
    end

    -- Scroll indicators
    if self.scrollOffset > 0 then
        Color.set(0.60, 0.70, 0.90, 0.8)
        love.graphics.printf("^ more ^", panelX, listY - 18, panelW, "center")
    end
    if self.scrollOffset + self.maxVisible < #self.actions + 1 then
        Color.set(0.60, 0.70, 0.90, 0.8)
        love.graphics.printf("v more v", panelX, listY + self.maxVisible * itemHeight - 5, panelW, "center")
    end

    -- Controls hint at bottom of panel
    local hintY = panelY + panelH - 55
    Color.set(0.30, 0.32, 0.38)
    love.graphics.rectangle("fill", panelX + 10, hintY - 5, panelW - 20, 45, 4, 4)

    Color.set(0.50, 0.55, 0.65)
    love.graphics.printf("UP/DOWN: Navigate  |  ENTER: Rebind Key 1  |  TAB: Rebind Key 2", panelX, hintY + 3, panelW, "center")
    love.graphics.printf("R: Reset to Defaults  |  ESC: Back", panelX, hintY + 20, panelW, "center")
end

function ControlsConfig:keypressed(key)
    if self.waitingForKey then
        if key == "escape" then
            -- Cancel rebind
            self.waitingForKey = false
        else
            -- Bind the new key
            local action = self.actions[self.selected]
            if action then
                Controls:setKey(self.mode, action, key, self.waitingSlot)
            end
            self.waitingForKey = false
        end
        return
    end

    if key == "escape" then
        Gamestate:pop()
    elseif key == "down" then
        self.selected = self.selected + 1
        if self.selected > #self.actions + 1 then
            self.selected = 1
            self.scrollOffset = 0
        elseif self.selected > self.scrollOffset + self.maxVisible then
            self.scrollOffset = self.selected - self.maxVisible
        end
        self.selectionTime = 0
    elseif key == "up" then
        self.selected = self.selected - 1
        if self.selected < 1 then
            self.selected = #self.actions + 1
            self.scrollOffset = math.max(0, #self.actions + 1 - self.maxVisible)
        elseif self.selected <= self.scrollOffset then
            self.scrollOffset = self.selected - 1
        end
        self.selectionTime = 0
    elseif key == "return" or key == "kpenter" then
        if self.selected == #self.actions + 1 then
            -- Back option
            Gamestate:pop()
        else
            -- Start rebinding key slot 1
            self.waitingForKey = true
            self.waitingSlot = 1
        end
    elseif key == "tab" then
        if self.selected <= #self.actions then
            -- Start rebinding key slot 2
            self.waitingForKey = true
            self.waitingSlot = 2
        end
    elseif key == "r" then
        -- Reset this mode to defaults
        Controls:resetMode(self.mode)
        self.actions = Controls:getActions(self.mode)
    end
end

return ControlsConfig
