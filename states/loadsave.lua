local LoadSave = {}
local Color = require("color")

function LoadSave:load()
    self.saveFiles = {}
    self.selected = 1
    self.selectionTime = 0
    self.deleteMode = false
    self.confirmDelete = false
    self.hoveredItem = nil
    self.hoveredDelete = nil
    self.clickableAreas = {}
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

    -- Clear clickable areas
    self.clickableAreas = {}

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
                local isHovered = (i == self.hoveredItem)
                local selectPulse = isSelected and (math.sin(self.selectionTime * 4) * 0.1 + 0.9) or 0.6

                -- Store clickable area for this save file
                local itemX = panelX + 25
                local itemW = panelW - 50 - 75  -- Exclude delete button area
                local itemH = itemHeight - 10
                table.insert(self.clickableAreas, {
                    type = "save",
                    index = i,
                    x = itemX,
                    y = itemY,
                    w = itemW,
                    h = itemH
                })

                -- Item background
                if isSelected or isHovered then
                    -- Selected/hovered glow
                    local glowColor = isSelected and {0.35, 0.50, 0.75} or {0.30, 0.45, 0.65}
                    Color.set(glowColor[1], glowColor[2], glowColor[3], 0.25)
                    love.graphics.rectangle("fill", panelX + 20, itemY - 5, panelW - 40, itemHeight - 5, 8, 8)
                end

                -- Item panel
                local bgColor = (isSelected or isHovered) and {0.15, 0.20, 0.30} or {0.12, 0.15, 0.20}
                Color.set(bgColor[1], bgColor[2], bgColor[3], 0.9)
                love.graphics.rectangle("fill", itemX, itemY, panelW - 50, itemH, 6, 6)

                -- Item border
                local borderColor = isSelected and {0.50, 0.65, 0.90} or (isHovered and {0.45, 0.60, 0.80} or {0.30, 0.35, 0.45})
                Color.set(borderColor[1], borderColor[2], borderColor[3], selectPulse)
                love.graphics.setLineWidth(isSelected and 2 or 1)
                love.graphics.rectangle("line", itemX, itemY, panelW - 50, itemH, 6, 6)

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

                -- Delete button
                local delBtnX = panelX + panelW - 100
                local delBtnY = itemY + 15
                local delBtnW = 70
                local delBtnH = 28
                local isDeleteHovered = (i == self.hoveredDelete)

                -- Store delete button clickable area
                table.insert(self.clickableAreas, {
                    type = "delete",
                    index = i,
                    x = delBtnX,
                    y = delBtnY,
                    w = delBtnW,
                    h = delBtnH
                })

                -- Delete button background
                local delBgColor = isDeleteHovered and {0.50, 0.20, 0.20} or {0.35, 0.18, 0.18}
                Color.set(delBgColor[1], delBgColor[2], delBgColor[3], 0.9)
                love.graphics.rectangle("fill", delBtnX, delBtnY, delBtnW, delBtnH, 4, 4)

                -- Delete button border
                local delBorderColor = isDeleteHovered and {0.90, 0.40, 0.40} or {0.70, 0.35, 0.35}
                Color.set(delBorderColor[1], delBorderColor[2], delBorderColor[3])
                love.graphics.setLineWidth(isDeleteHovered and 2 or 1)
                love.graphics.rectangle("line", delBtnX, delBtnY, delBtnW, delBtnH, 4, 4)

                -- Delete icon (X)
                Color.set(isDeleteHovered and 1 or 0.85, isDeleteHovered and 0.70 or 0.60, isDeleteHovered and 0.70 or 0.60)
                love.graphics.setLineWidth(2)
                local iconSize = 8
                local iconCenterX = delBtnX + 12
                local iconCenterY = delBtnY + delBtnH / 2
                love.graphics.line(iconCenterX - iconSize/2, iconCenterY - iconSize/2, iconCenterX + iconSize/2, iconCenterY + iconSize/2)
                love.graphics.line(iconCenterX + iconSize/2, iconCenterY - iconSize/2, iconCenterX - iconSize/2, iconCenterY + iconSize/2)

                -- Delete text
                love.graphics.print("Delete", delBtnX + 25, delBtnY + 7)
            end
        end

        -- Scroll indicator if more saves
        if #self.saveFiles > maxVisible then
            Color.set(0.50, 0.55, 0.65)
            love.graphics.printf("+ " .. (#self.saveFiles - maxVisible) .. " more saves...", panelX, startY + maxVisible * itemHeight, panelW, "center")
        end
    end

    -- Delete confirmation overlay
    if self.confirmDelete and #self.saveFiles > 0 then
        local confirmW, confirmH = 400, 120
        local confirmX = (screenW - confirmW) / 2
        local confirmY = (screenH - confirmH) / 2

        -- Overlay background
        Color.set(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)

        -- Confirmation panel shadow
        Color.set(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", confirmX + 5, confirmY + 5, confirmW, confirmH, 8, 8)

        -- Confirmation panel
        Color.set(0.12, 0.10, 0.10, 0.95)
        love.graphics.rectangle("fill", confirmX, confirmY, confirmW, confirmH, 8, 8)

        -- Border (red warning)
        Color.set(0.85, 0.35, 0.35)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", confirmX, confirmY, confirmW, confirmH, 8, 8)

        -- Warning message
        local selectedSave = self.saveFiles[self.selected]
        if selectedSave then
            Color.set(0.95, 0.85, 0.85)
            love.graphics.printf("Delete save file?", confirmX, confirmY + 20, confirmW, "center")
            Color.set(0.85, 0.75, 0.75)
            love.graphics.printf(selectedSave.data.characterName or "Unnamed", confirmX, confirmY + 42, confirmW, "center")
        end

        -- Y/N buttons
        local yX = confirmX + confirmW / 2 - 80
        local btnY = confirmY + 72

        -- Y button (Delete)
        Color.set(0.40, 0.20, 0.20)
        love.graphics.rectangle("fill", yX, btnY, 50, 26, 4, 4)
        Color.set(0.85, 0.45, 0.45)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", yX, btnY, 50, 26, 4, 4)
        Color.set(1, 0.75, 0.75)
        love.graphics.print("Y", yX + 20, btnY + 5)
        Color.set(0.75, 0.60, 0.60)
        love.graphics.print("Delete", yX + 55, btnY + 5)

        -- N button (Cancel)
        local nX = yX + 130
        Color.set(0.25, 0.30, 0.25)
        love.graphics.rectangle("fill", nX, btnY, 50, 26, 4, 4)
        Color.set(0.55, 0.70, 0.55)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", nX, btnY, 50, 26, 4, 4)
        Color.set(0.85, 1, 0.85)
        love.graphics.print("N", nX + 20, btnY + 5)
        Color.set(0.65, 0.75, 0.65)
        love.graphics.print("Cancel", nX + 55, btnY + 5)
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

        -- DELETE key
        Color.set(0.40, 0.25, 0.25)
        love.graphics.rectangle("fill", panelX + 270, hintY, 55, 22, 3, 3)
        Color.set(0.75, 0.50, 0.50)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", panelX + 270, hintY, 55, 22, 3, 3)
        Color.set(1, 0.75, 0.75)
        love.graphics.print("DEL", panelX + 280, hintY + 3)

        Color.set(0.60, 0.45, 0.45)
        love.graphics.print("Delete", panelX + 335, hintY + 3)
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
    -- Handle delete confirmation first
    if self.confirmDelete then
        if key == "y" then
            self:deleteSelectedSave()
            self.confirmDelete = false
        elseif key == "n" or key == "escape" then
            self.confirmDelete = false
        end
        return
    end

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
    elseif key == "delete" then
        -- Trigger delete confirmation
        self.confirmDelete = true
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

function LoadSave:deleteSelectedSave()
    if self.selected <= #self.saveFiles then
        local saveFile = self.saveFiles[self.selected]
        local saveDir = "saves/" .. saveFile.dirname

        -- Delete all save files in the directory
        local files = love.filesystem.getDirectoryItems(saveDir)
        for _, file in ipairs(files) do
            love.filesystem.remove(saveDir .. "/" .. file)
        end

        -- Remove the directory itself
        love.filesystem.remove(saveDir)

        print("Deleted save: " .. saveDir)

        -- Rescan save files
        self:scanSaveFiles()

        -- Adjust selection if needed
        if self.selected > #self.saveFiles then
            self.selected = math.max(1, #self.saveFiles)
        end
    end
end

function LoadSave:mousemoved(x, y)
    self.hoveredItem = nil
    self.hoveredDelete = nil

    -- Check if mouse is over any clickable area
    for _, area in ipairs(self.clickableAreas) do
        if x >= area.x and x <= area.x + area.w and y >= area.y and y <= area.y + area.h then
            if area.type == "save" then
                self.hoveredItem = area.index
            elseif area.type == "delete" then
                self.hoveredDelete = area.index
            end
        end
    end
end

function LoadSave:mousepressed(x, y, button)
    if button ~= 1 then return end  -- Only left click

    -- Handle delete confirmation first
    if self.confirmDelete then
        return
    end

    -- Check if mouse is over any clickable area
    for _, area in ipairs(self.clickableAreas) do
        if x >= area.x and x <= area.x + area.w and y >= area.y and y <= area.y + area.h then
            if area.type == "save" then
                -- Select and load this save
                self.selected = area.index
                self:loadSelectedSave()
            elseif area.type == "delete" then
                -- Trigger delete confirmation
                self.selected = area.index
                self.confirmDelete = true
            end
            return
        end
    end
end

return LoadSave
