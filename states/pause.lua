local Pause = {}
local Color = require("color")

function Pause:load()
    self.selected = 1
    self.selectionTime = 0

    -- Check if we're in a sub-state (not directly on world map)
    -- The state below pause is at stack position #stack - 1
    local stackSize = #Gamestate.stack
    local parentState = stackSize > 1 and Gamestate.stack[stackSize - 1] or nil
    local worldMapState = nil

    -- Detect which game mode we're in
    self.gameMode = "worldmap" -- default
    if parentState then
        if parentState.pointsOfInterest then
            self.gameMode = "worldmap"
        elseif parentState.npcs and parentState.buildings then
            self.gameMode = "town"
        elseif parentState.bullets and parentState.enemies then
            self.gameMode = "contra"
        elseif parentState.buildMode ~= nil and parentState.showWardrobe ~= nil then
            self.gameMode = "basebuilding"
        elseif parentState.tiles or parentState.npcs then
            self.gameMode = "level"
        end
    end

    -- Find if WorldMap is in the stack (but not the immediate parent)
    for i = stackSize - 1, 1, -1 do
        local state = Gamestate.stack[i]
        if state.saveGame and state.pointsOfInterest then -- WorldMap has these
            worldMapState = state
            break
        end
    end

    self.canReturnToWorldMap = parentState and worldMapState and parentState ~= worldMapState

    -- Build options list
    self.options = {"Resume"}
    if self.canReturnToWorldMap then
        table.insert(self.options, "Return to World Map")
    end
    table.insert(self.options, "Configure Controls")
    table.insert(self.options, "Save & Exit to Menu")
end

function Pause:update(dt)
    self.selectionTime = self.selectionTime + dt
end

function Pause:draw()
    local screenW, screenH = love.graphics.getDimensions()

    -- Semi-transparent overlay
    Color.set(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Panel background
    local panelW = 320
    local panelH = 170 + (#self.options * 45)
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Panel shadow
    Color.set(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", panelX + 5, panelY + 5, panelW, panelH, 8, 8)

    -- Panel background
    Color.set(0.12, 0.15, 0.22, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)

    -- Panel border
    Color.set(0.40, 0.50, 0.70, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)

    -- Title
    Color.set(0.90, 0.88, 0.78)
    love.graphics.printf("PAUSED", panelX, panelY + 25, panelW, "center")

    -- Decorative line under title
    local lineY = panelY + 55
    local lineW = 120
    local lineX = panelX + (panelW - lineW) / 2
    Color.set(0.35, 0.40, 0.55)
    love.graphics.rectangle("fill", lineX, lineY, lineW, 2)

    -- Menu options
    local menuStartY = panelY + 80
    local menuSpacing = 45

    for i, option in ipairs(self.options) do
        local optY = menuStartY + (i - 1) * menuSpacing
        local isSelected = (i == self.selected)

        -- Selection animation
        local selectPulse = isSelected and (math.sin(self.selectionTime * 4) * 0.1 + 0.9) or 0.6
        local xOffset = isSelected and (math.sin(self.selectionTime * 3) * 2) or 0

        -- Option background for selected
        if isSelected then
            local bgW = 240
            local bgX = panelX + (panelW - bgW) / 2

            -- Glow behind
            Color.set(0.35, 0.50, 0.75, 0.3)
            love.graphics.rectangle("fill", bgX - 8, optY - 6, bgW + 16, 36, 6, 6)

            -- Background
            Color.set(0.18, 0.22, 0.32, 0.9)
            love.graphics.rectangle("fill", bgX, optY - 3, bgW, 30, 5, 5)

            -- Border
            Color.set(0.50, 0.65, 0.90, selectPulse)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", bgX, optY - 3, bgW, 30, 5, 5)

            -- Arrow indicators
            Color.set(0.70, 0.80, 1, selectPulse)
            local arrowX = bgX - 15 + xOffset
            love.graphics.polygon("fill",
                arrowX, optY + 12,
                arrowX + 8, optY + 7,
                arrowX + 8, optY + 17
            )
        end

        -- Option text
        if isSelected then
            Color.set(0.95, 0.95, 1)
        else
            Color.set(0.55, 0.60, 0.70)
        end
        love.graphics.printf(option, panelX + xOffset, optY + 3, panelW, "center")
    end

    -- Controls hint at bottom of panel
    local hintY = panelY + panelH - 35
    Color.set(0.40, 0.45, 0.55)
    love.graphics.printf("UP/DOWN to navigate, ENTER to select", panelX, hintY, panelW, "center")
end

function Pause:keypressed(key)
    if key == "escape" then
        -- Resume game
        Gamestate:pop()
    elseif key == "down" then
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
        local option = self.options[self.selected]

        if option == "Resume" then
            Gamestate:pop()
        elseif option == "Return to World Map" then
            -- Pop pause and current game mode to return to world map
            Gamestate:pop() -- pop pause
            -- Save current state if it has a save method
            local current = Gamestate:current()
            if current.saveTownState then
                current:saveTownState()
            end
            Gamestate:pop() -- pop the game mode (Town, Level, etc.)
        elseif option == "Configure Controls" then
            local controlsConfig = require("states.controlsconfig")
            controlsConfig:enter(self.gameMode)
            Gamestate:push(controlsConfig)
        elseif option == "Save & Exit to Menu" then
            -- Pop back to main menu (pop pause, then pop all gameplay states)
            Gamestate:pop() -- pop pause
            while Gamestate:current() and Gamestate:current() ~= require("states.mainmenu") do
                -- Save if the state has a save method
                local current = Gamestate:current()
                if current.saveGame then
                    current:saveGame()
                elseif current.saveTownState then
                    current:saveTownState()
                end
                Gamestate:pop()
            end
        end
    end
end

return Pause
