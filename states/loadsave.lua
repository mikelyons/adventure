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
end

function LoadSave:draw()
    love.graphics.printf("Load Game", 0, 80, 800, "center")

    if #self.saveFiles == 0 then
        love.graphics.printf("No save files found. Press ESC to go back.", 0, 280, 800, "center")
        return
    end

    local startY = 180
    local lineHeight = 36
    for i, entry in ipairs(self.saveFiles) do
        local prefix = (i == self.selected) and "> " or "  "
        local lastPlayed = os.date("%Y-%m-%d %H:%M", entry.data.lastPlayed or 0)
        local label = string.format("%s%s (Lv.%d) - %s", prefix, entry.data.characterName or "Unnamed", entry.data.level or 1, lastPlayed)
        love.graphics.print(label, 260, startY + (i - 1) * lineHeight)
    end

    love.graphics.printf("Up/Down to select, Enter to load, Esc to back", 0, 520, 800, "center")
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
        local saveDir = "saves/" .. saveFile.dirname
        
        -- Load all save data
        local statsData = self:loadSaveData(saveDir .. "/stats.lua")
        local worldData = self:loadSaveData(saveDir .. "/world.lua")
        local optionsData = self:loadSaveData(saveDir .. "/options.lua")
        
        if statsData and worldData and optionsData then
            local worldmap = require "states.worldmap"
            -- Create a new table instance so state isn't shared across calls
            local newState = {}
            for k, v in pairs(worldmap) do newState[k] = v end
            newState.saveDir = saveDir
            newState.saveData = statsData
            newState.worldData = worldData
            newState.optionsData = optionsData
            Gamestate:push(newState)
        else
            print("Failed to load save data from: " .. saveDir)
        end
    end
end

return LoadSave
