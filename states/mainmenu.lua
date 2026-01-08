local MainMenu = {}
local Color = require("color")

function MainMenu:load()
    self.options = {"New Game", "Continue", "Options", "Quit"}
    self.selected = 1
    self.selectionTime = 0
end

function MainMenu:update(dt)
    self.selectionTime = self.selectionTime + dt
end

function MainMenu:draw()
    local screenW, screenH = love.graphics.getDimensions()
    local time = love.timer.getTime()

    -- Animated background with stars
    Color.set(0.05, 0.07, 0.12)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Stars
    love.math.setRandomSeed(42)
    for i = 1, 100 do
        local sx = love.math.random(0, screenW)
        local sy = love.math.random(0, screenH)
        local twinkle = math.sin(time * 2 + i * 0.5) * 0.3 + 0.7
        local size = love.math.random() * 1.5 + 0.5
        Color.set(0.9, 0.9, 1, twinkle * 0.8)
        love.graphics.circle("fill", sx, sy, size)
    end

    -- Distant mountains silhouette
    for layer = 3, 1, -1 do
        local baseY = screenH - 80 - layer * 30
        local layerAlpha = 0.15 + layer * 0.08
        Color.set(0.08, 0.10, 0.18, layerAlpha)
        love.graphics.polygon("fill",
            0, screenH,
            0, baseY + 40,
            50 + layer * 20, baseY + 10,
            120 + layer * 15, baseY + 30,
            200 + layer * 25, baseY - 20 + layer * 5,
            280 + layer * 10, baseY + 25,
            350 + layer * 30, baseY - 10,
            420, baseY + 20,
            500 + layer * 20, baseY - 30 + layer * 10,
            580 + layer * 15, baseY + 15,
            650, baseY - 5,
            720 + layer * 25, baseY + 30,
            screenW, baseY + 20,
            screenW, screenH
        )
    end

    -- Title with glow effect
    local titleY = screenH * 0.18
    local titleText = "ADVENTURE"

    -- Title glow
    for i = 3, 1, -1 do
        local glowAlpha = 0.1 + (4 - i) * 0.05
        Color.set(0.45, 0.55, 0.85, glowAlpha)
        love.graphics.printf(titleText, -i, titleY - i, screenW, "center")
        love.graphics.printf(titleText, i, titleY - i, screenW, "center")
    end

    -- Title main
    Color.set(0.95, 0.92, 0.80)
    love.graphics.printf(titleText, 0, titleY, screenW, "center")

    -- Subtitle
    Color.set(0.55, 0.60, 0.75)
    love.graphics.printf("A Journey Awaits", 0, titleY + 30, screenW, "center")

    -- Decorative line
    local lineY = titleY + 60
    local lineW = 200
    local lineX = (screenW - lineW) / 2
    Color.set(0.35, 0.40, 0.55)
    love.graphics.rectangle("fill", lineX, lineY, lineW, 2)
    -- Endpoints
    Color.set(0.55, 0.60, 0.80)
    love.graphics.circle("fill", lineX, lineY + 1, 3)
    love.graphics.circle("fill", lineX + lineW, lineY + 1, 3)

    -- Menu options
    local menuStartY = screenH * 0.45
    local menuSpacing = 55

    for i, option in ipairs(self.options) do
        local optY = menuStartY + (i - 1) * menuSpacing
        local isSelected = (i == self.selected)

        -- Selection animation
        local selectPulse = isSelected and (math.sin(self.selectionTime * 4) * 0.1 + 0.9) or 0.6
        local xOffset = isSelected and (math.sin(self.selectionTime * 3) * 3) or 0

        -- Option background for selected
        if isSelected then
            local bgW = 220
            local bgX = (screenW - bgW) / 2

            -- Glow behind
            Color.set(0.35, 0.50, 0.75, 0.3)
            love.graphics.rectangle("fill", bgX - 10, optY - 8, bgW + 20, 42, 8, 8)

            -- Background
            Color.set(0.15, 0.20, 0.30, 0.9)
            love.graphics.rectangle("fill", bgX, optY - 5, bgW, 36, 6, 6)

            -- Border
            Color.set(0.50, 0.65, 0.90, selectPulse)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", bgX, optY - 5, bgW, 36, 6, 6)

            -- Arrow indicators
            Color.set(0.70, 0.80, 1, selectPulse)
            local arrowX = bgX - 20 + xOffset
            love.graphics.polygon("fill",
                arrowX, optY + 13,
                arrowX + 10, optY + 8,
                arrowX + 10, optY + 18
            )
            love.graphics.polygon("fill",
                bgX + bgW + 20 - xOffset, optY + 13,
                bgX + bgW + 10 - xOffset, optY + 8,
                bgX + bgW + 10 - xOffset, optY + 18
            )
        end

        -- Option text
        if isSelected then
            Color.set(0.95, 0.95, 1)
        else
            Color.set(0.55, 0.60, 0.70)
        end
        love.graphics.printf(option, xOffset, optY + 3, screenW, "center")
    end

    -- Controls hint at bottom
    local hintY = screenH - 50

    -- Background for hints
    Color.set(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, hintY - 10, screenW, 50)

    -- Hint text
    Color.set(0.45, 0.50, 0.60)
    love.graphics.printf("Use", screenW / 2 - 180, hintY, 40, "right")

    -- Arrow keys icon
    Color.set(0.25, 0.30, 0.40)
    love.graphics.rectangle("fill", screenW / 2 - 130, hintY - 3, 55, 22, 3, 3)
    Color.set(0.50, 0.60, 0.75)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", screenW / 2 - 130, hintY - 3, 55, 22, 3, 3)
    Color.set(0.80, 0.85, 0.95)
    love.graphics.print("UP/DN", screenW / 2 - 125, hintY)

    Color.set(0.45, 0.50, 0.60)
    love.graphics.print("to navigate,", screenW / 2 - 65, hintY)

    -- Enter key icon
    Color.set(0.25, 0.35, 0.30)
    love.graphics.rectangle("fill", screenW / 2 + 55, hintY - 3, 55, 22, 3, 3)
    Color.set(0.50, 0.70, 0.60)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", screenW / 2 + 55, hintY - 3, 55, 22, 3, 3)
    Color.set(0.80, 0.95, 0.85)
    love.graphics.print("ENTER", screenW / 2 + 60, hintY)

    Color.set(0.45, 0.50, 0.60)
    love.graphics.print("to select", screenW / 2 + 120, hintY)

    -- Version info
    Color.set(0.30, 0.35, 0.45)
    love.graphics.print("v0.1.0", 10, screenH - 25)
end

function MainMenu:keypressed(key)
    if key == "down" then
        self.selected = self.selected + 1
        if self.selected > #self.options then
            self.selected = 1
        end
        self.selectionTime = 0
    elseif key == "up" then
        self.selected = self.selected - 1
        if self.selected < 1 then
            self.selected = #self.options
        end
        self.selectionTime = 0
    elseif key == "return" or key == "kpenter" then
        if self.selected == 1 then
            -- Start new game
            Gamestate:push(require "states.newgame")
        elseif self.selected == 2 then
            Gamestate:push(require "states.loadsave")
        elseif self.selected == 3 then
            -- Go to options
        elseif self.selected == 4 then
            love.event.quit()
        end
    end
end

return MainMenu
