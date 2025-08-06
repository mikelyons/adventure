local LoadSave = {}

function LoadSave:load()
    self.saveFiles = {}
    self.selected = 1
    self:scanSaveFiles()
end

function LoadSave:scanSaveFiles()
    self.saveFiles = {}
    local items = love.filesystem.getDirectoryItems("saves")
    
    if items then
        for _, item in ipairs(items) do
            if string.match(item, "%.lua$") then
                local saveData = self:loadSaveData("saves/" .. item)
                if saveData then
                    table.insert(self.saveFiles, {
                        filename = item,
                        data = saveData
                    })
                end
            end
        end
    end
    
    -- Sort by creation time (newest first)
    table.sort(self.saveFiles, function(a, b)
        return (a.data.createdAt or 0) > (b.data.createdAt or 0)
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
end

function LoadSave:draw()
    -- Title
    love.graphics.printf("Load Game", 0, 50, 800, "center")
    
    if #self.saveFiles == 0 then
        love.graphics.printf("No save files found", 0, 200, 800, "center")
        love.graphics.printf("Press ESC to go back", 0, 250, 800, "center")
        return
    end
    
    -- Save file list
    for i, saveFile in ipairs(self.saveFiles) do
        local y = 120 + i * 80
        local data = saveFile.data
        
        -- Highlight selected save
        if i == self.selected then
            love.graphics.setColor(0.3, 0.3, 0.7)
            love.graphics.rectangle("fill", 100, y - 5, 600, 70)
            love.graphics.setColor(1, 1, 1)
        end
        
        -- Character name
        local nameText = data.characterName or "Unknown"
        love.graphics.print(nameText, 120, y)
        
        -- Level and play time
        local level = data.level or 1
        local playTime = data.playTime or 0
        local hours = math.floor(playTime / 3600)
        local minutes = math.floor((playTime % 3600) / 60)
        local timeText = string.format("Level %d - %02d:%02d", level, hours, minutes)
        love.graphics.print(timeText, 120, y + 20)
        
        -- Creation date
        local createdAt = data.createdAt or 0
        local dateText = os.date("%Y-%m-%d %H:%M", createdAt)
        love.graphics.print("Created: " .. dateText, 120, y + 40)
    end
    
    -- Instructions
    love.graphics.printf("Use UP/DOWN to select, ENTER to load, ESC to go back", 0, 500, 800, "center")
end

function LoadSave:keypressed(key)
    if key == "escape" then
        Gamestate:pop()
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
    elseif key == "up" then
        self.selected = self.selected - 1
        if self.selected < 1 then
            self.selected = #self.saveFiles
        end
    elseif key == "return" or key == "kpenter" then
        self:loadSelectedSave()
    end
end

function LoadSave:loadSelectedSave()
    if self.selected <= #self.saveFiles then
        local saveFile = self.saveFiles[self.selected]
        -- TODO: Start game with loaded save data
        print("Loading save: " .. saveFile.data.characterName)
        -- For now, just go back to main menu
        Gamestate:pop()
    end
end

return LoadSave