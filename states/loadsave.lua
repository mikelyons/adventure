local LoadSave = {}

function LoadSave:load()
    self.saveFiles = {}
    self.selected = 1
end

function LoadSave:enter()
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
    love.graphics.printf("Load Game", 0, 50, 800, "center")
    love.graphics.printf("This is a test", 0, 200, 800, "center")
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
