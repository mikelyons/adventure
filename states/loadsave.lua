local LoadSave = {}
local Color = require("color")

function LoadSave:load()
    self.saveFiles = {}
    self.selected = 1
    self.selectionTime = 0
end

function LoadSave:enter()
    self:scanSaveFiles()
    self.selectionTime = 0
end

function LoadSave:scanSaveFiles()
    self.saveFiles = {}
    local items = love.filesystem.getDirectoryItems("saves")

    if items then
        for _, item in ipairs(items) do
            -- Check if it's a directory by trying to get items from it
            local subItems = love.filesystem.getDirectoryItems("saves/" .. item)
            if subItems then
                -- If we can get directory items, it's a directory
                local statsData = self:loadSaveData("saves/" .. item .. "/stats.lua")
                if statsData then
                    table.insert(self.saveFiles, {
                        dirname = item,
                        data = statsData
                    })
                end
            end
        end
    end

    -- Sort by last played time (newest first)
    table.sort(self.saveFiles, function(a, b)
        return (a.data.lastPlayed or 0) > (b.data.lastPlayed or 0)
    end)
end

function LoadSave:loadSaveData(filepath)
    local chunk = love.filesystem.load(filepath)
    if chunk then
        local success, data = pcall(chunk)
        if success and type(data) == "table" then
            return data
        end
    end
    return nil
end

function LoadSave:update(dt)
    self.selectionTime = self.selectionTime + dt
end

function LoadSave:draw()
    local screenW, screenH = love.graphics.getDimensions()
    local time = love.timer.getTime()

    -- Animated background
    for y = 0, screenH, 32 do
        for x = 0, screenW, 32 do
            local wave = math.sin((x - y) * 0.01 + time * 0.3) * 0.015
            Color.set(0.06 + wave, 0.08 + wave, 0.12 + wave)
            love.graphics.rectangle("fill", x, y, 32, 32)
        end
    end

    -- Main panel
    local panelW, panelH = 600, 450
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2 - 20

    -- Panel shadow
    Color.set(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", panelX + 6, panelY + 6, panelW, panelH, 10, 10)

    -- Panel background
    Color.set(0.06, 0.10, 0.16, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 10, 10)

    -- Inner panel
    Color.set(0.10, 0.14, 0.20, 0.9)
    love.graphics.rectangle("fill", panelX + 4, panelY + 4, panelW - 8, panelH - 8, 8, 8)

    -- Panel border
    love.graphics.setLineWidth(3)
    Color.set(0.45, 0.55, 0.70)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 10, 10)

    -- Inner highlight
    love.graphics.setLineWidth(1)
    Color.set(0.55, 0.65, 0.80, 0.4)
    love.graphics.rectangle("line", panelX + 3, panelY + 3, panelW - 6, panelH - 6, 8, 8)

    -- Corner decorations
    local cornerSize = 16
    Color.set(0.55, 0.65, 0.80)
    love.graphics.rectangle("fill", panelX + 12, panelY + 12, cornerSize, 2)
    love.graphics.rectangle("fill", panelX + 12, panelY + 12, 2, cornerSize)
    love.graphics.rectangle("fill", panelX + panelW - 12 - cornerSize, panelY + 12, cornerSize, 2)
    love.graphics.rectangle("fill", panelX + panelW - 14, panelY + 12, 2, cornerSize)
    love.graphics.rectangle("fill", panelX + 12, panelY + panelH - 14, cornerSize, 2)
    love.graphics.rectangle("fill", panelX + 12, panelY + panelH - 12 - cornerSize, 2, cornerSize)
    love.graphics.rectangle("fill", panelX + panelW - 12 - cornerSize, panelY + panelH - 14, cornerSize, 2)
    love.graphics.rectangle("fill", panelX + panelW - 14, panelY + panelH - 12 - cornerSize, 2, cornerSize)

    -- Title
    Color.set(0.95, 0.90, 0.70)
    love.graphics.printf("LOAD GAME", panelX, panelY + 30, panelW, "center")

    -- Decorative line under title
    local lineY = panelY + 55
    Color.set(0.35, 0.45, 0.55)
    love.graphics.rectangle("fill", panelX + 80, lineY, panelW - 160, 2)
    Color.set(0.55, 0.65, 0.80)
    love.graphics.rectangle("fill", panelX + 80, lineY, 20, 2)
    love.graphics.rectangle("fill", panelX + panelW - 100, lineY, 20, 2)

    if #self.saveFiles == 0 then
        -- No saves message
        Color.set(0.55, 0.55, 0.65)
        love.graphics.printf("No save files found.", panelX, panelY + 180, panelW, "center")
        love.graphics.printf("Start a New Game to create your first save.", panelX, panelY + 210, panelW, "center")
    else
        -- Save file list
        local startY = panelY + 80
        local itemHeight = 65
        local maxVisible = 5

        for i, entry in ipairs(self.saveFiles) do
            if i <= maxVisible then
                local itemY = startY + (i - 1) * itemHeight
                local isSelected = (i == self.selected)
                local selectPulse = isSelected and (math.sin(self.selectionTime * 4) * 0.1 + 0.9) or 0.6

                -- Item background
                if isSelected then
                    -- Selected glow
                    Color.set(0.35, 0.50, 0.75, 0.25)
                    love.graphics.rectangle("fill", panelX + 20, itemY - 5, panelW - 40, itemHeight - 5, 8, 8)
                end

                -- Item panel
                local bgColor = isSelected and {0.15, 0.20, 0.30} or {0.12, 0.15, 0.20}
                Color.set(bgColor[1], bgColor[2], bgColor[3], 0.9)
                love.graphics.rectangle("fill", panelX + 25, itemY, panelW - 50, itemHeight - 10, 6, 6)

                -- Item border
                local borderColor = isSelected and {0.50, 0.65, 0.90} or {0.30, 0.35, 0.45}
                Color.set(borderColor[1], borderColor[2], borderColor[3], selectPulse)
                love.graphics.setLineWidth(isSelected and 2 or 1)
                love.graphics.rectangle("line", panelX + 25, itemY, panelW - 50, itemHeight - 10, 6, 6)

                -- Selection indicator
                if isSelected then
                    Color.set(0.70, 0.80, 1, selectPulse)
                    local arrowX = panelX + 35 + math.sin(self.selectionTime * 3) * 3
                    love.graphics.polygon("fill",
                        arrowX, itemY + 22,
                        arrowX + 8, itemY + 17,
                        arrowX + 8, itemY + 27
                    )
                end

                -- Character name
                local nameX = panelX + 55
                Color.set(isSelected and 0.95 or 0.75, isSelected and 0.95 or 0.75, isSelected and 1 or 0.80)
                love.graphics.print(entry.data.characterName or "Unnamed", nameX, itemY + 8)

                -- Level badge
                local lvlText = "Lv." .. (entry.data.level or 1)
                Color.set(0.30, 0.40, 0.50)
                love.graphics.rectangle("fill", nameX + 150, itemY + 8, 50, 18, 3, 3)
                Color.set(0.95, 0.85, 0.55)
                love.graphics.print(lvlText, nameX + 160, itemY + 10)

                -- Last played date
                local lastPlayed = os.date("%Y-%m-%d %H:%M", entry.data.lastPlayed or 0)
                Color.set(0.50, 0.55, 0.65)
                love.graphics.print("Last played: " .. lastPlayed, nameX, itemY + 32)

                -- POI count
                local poiText = (entry.data.pointsOfInterest or 0) .. " POI discovered"
                Color.set(0.45, 0.60, 0.55)
                love.graphics.print(poiText, nameX + 250, itemY + 32)
            end
        end

        -- Scroll indicator if more saves
        if #self.saveFiles > maxVisible then
            Color.set(0.50, 0.55, 0.65)
            love.graphics.printf("+ " .. (#self.saveFiles - maxVisible) .. " more saves...", panelX, startY + maxVisible * itemHeight, panelW, "center")
        end
    end

    -- Controls hint
    local hintY = panelY + panelH - 50

    -- Background strip
    Color.set(0.08, 0.10, 0.14, 0.8)
    love.graphics.rectangle("fill", panelX + 20, hintY - 5, panelW - 40, 35, 4, 4)

    if #self.saveFiles > 0 then
        -- UP/DOWN keys
        Color.set(0.25, 0.30, 0.40)
        love.graphics.rectangle("fill", panelX + 35, hintY, 55, 22, 3, 3)
        Color.set(0.50, 0.60, 0.75)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", panelX + 35, hintY, 55, 22, 3, 3)
        Color.set(0.80, 0.85, 0.95)
        love.graphics.print("UP/DN", panelX + 40, hintY + 3)

        Color.set(0.45, 0.50, 0.60)
        love.graphics.print("Select", panelX + 100, hintY + 3)

        -- ENTER key
        Color.set(0.25, 0.35, 0.30)
        love.graphics.rectangle("fill", panelX + 160, hintY, 55, 22, 3, 3)
        Color.set(0.50, 0.70, 0.60)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", panelX + 160, hintY, 55, 22, 3, 3)
        Color.set(0.80, 0.95, 0.85)
        love.graphics.print("ENTER", panelX + 165, hintY + 3)

        Color.set(0.45, 0.50, 0.60)
        love.graphics.print("Load", panelX + 225, hintY + 3)
    end

    -- ESC key
    Color.set(0.35, 0.25, 0.25)
    love.graphics.rectangle("fill", panelX + panelW - 130, hintY, 45, 22, 3, 3)
    Color.set(0.75, 0.55, 0.55)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", panelX + panelW - 130, hintY, 45, 22, 3, 3)
    Color.set(1, 0.85, 0.85)
    love.graphics.print("ESC", panelX + panelW - 120, hintY + 3)

    Color.set(0.45, 0.50, 0.60)
    love.graphics.print("Back", panelX + panelW - 75, hintY + 3)
end

function LoadSave:keypressed(key)
    if key == "escape" then
        Gamestate:pop()
        return
    end

    if key == "f5" then
        self:scanSaveFiles()
        return
    end

    if #self.saveFiles == 0 then
        return
    end

    if key == "down" then
        self.selected = self.selected + 1
        if self.selected > #self.saveFiles then
            self.selected = 1
        end
        self.selectionTime = 0
    elseif key == "up" then
        self.selected = self.selected - 1
        if self.selected < 1 then
            self.selected = #self.saveFiles
        end
        self.selectionTime = 0
    elseif key == "return" or key == "kpenter" then
        self:loadSelectedSave()
    end
end

function LoadSave:loadSelectedSave()
    if self.selected <= #self.saveFiles then
        local saveFile = self.saveFiles[self.selected]
        local saveDir = "saves/" .. saveFile.dirname

        -- Load all save data
        local statsData = self:loadSaveData(saveDir .. "/stats.lua")
        local worldData = self:loadSaveData(saveDir .. "/world.lua")
        local townData = self:loadSaveData(saveDir .. "/town.lua")
        local optionsData = self:loadSaveData(saveDir .. "/options.lua")

        if statsData and worldData and townData and optionsData then
            local worldmap = require "states.worldmap"
            -- Create a new table instance so state isn't shared across calls
            local newState = {}
            for k, v in pairs(worldmap) do newState[k] = v end
            newState.saveDir = saveDir
            newState.saveData = statsData
            newState.worldData = worldData
            newState.townData = townData
            newState.optionsData = optionsData
            Gamestate:push(newState)
        else
            print("Failed to load save data from: " .. saveDir)
        end
    end
end

return LoadSave
