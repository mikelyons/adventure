local NewGame = {}

function NewGame:load()
    self.characterName = ""
    self.maxNameLength = 20
    self.inputMode = true
    self.errorMessage = ""
    self.confirmCreate = false
end

function NewGame:update(dt)
end

function NewGame:draw()
    -- Title
    love.graphics.printf("Create New Game", 0, 100, 800, "center")
    
    -- Instructions
    love.graphics.printf("Enter your character name:", 0, 200, 800, "center")
    
    -- Name input box
    love.graphics.rectangle("line", 250, 250, 300, 40)
    love.graphics.print(self.characterName, 260, 260)
    
    -- Cursor blink when in input mode
    if self.inputMode and math.floor(love.timer.getTime() * 2) % 2 == 0 then
        local textWidth = love.graphics.getFont():getWidth(self.characterName)
        love.graphics.print("|", 260 + textWidth, 260)
    end
    
    -- Character count
    love.graphics.printf(string.len(self.characterName) .. "/" .. self.maxNameLength, 0, 300, 800, "center")
    
    -- Error message
    if self.errorMessage ~= "" then
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf(self.errorMessage, 0, 330, 800, "center")
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Instructions
    if not self.confirmCreate then
        love.graphics.printf("Press ENTER to create save file, ESC to go back", 0, 400, 800, "center")
    else
        love.graphics.printf("Are you sure? Y to confirm, N to cancel", 0, 400, 800, "center")
    end
end

function NewGame:keypressed(key)
    if self.confirmCreate then
        if key == "y" then
            self:createSaveFile()
        elseif key == "n" then
            self.confirmCreate = false
        end
        return
    end
    
    if key == "escape" then
        Gamestate:pop()
        return
    end
    
    if key == "return" or key == "kpenter" then
        if string.len(self.characterName) > 0 then
            self.confirmCreate = true
            self.errorMessage = ""
        else
            self.errorMessage = "Please enter a character name"
        end
        return
    end
    
    if key == "backspace" then
        self.characterName = string.sub(self.characterName, 1, -2)
        self.errorMessage = ""
        return
    end
    
    -- Handle text input
    if string.len(key) == 1 and string.len(self.characterName) < self.maxNameLength then
        -- Only allow alphanumeric characters and spaces
        if string.match(key, "[%w%s]") then
            self.characterName = self.characterName .. key
            self.errorMessage = ""
        end
    end
end

function NewGame:createSaveFile()
    -- Create save directory if it doesn't exist
    love.filesystem.createDirectory("saves")
    
    -- Create save file with character name and timestamp
    local saveData = {
        characterName = self.characterName,
        createdAt = os.time(),
        playTime = 0,
        level = 1,
        -- Add more game data as needed
    }
    
    -- Generate a safe filename from character name
    local safeFileName = string.gsub(self.characterName, "[^%w%s]", "")
    safeFileName = string.gsub(safeFileName, "%s+", "_")
    local fileName = "saves/" .. safeFileName .. "_" .. os.time() .. ".lua"
    
    -- Convert save data to Lua table format
    local saveString = "return {\n"
    for key, value in pairs(saveData) do
        if type(value) == "string" then
            saveString = saveString .. "  " .. key .. ' = "' .. value .. '",\n'
        else
            saveString = saveString .. "  " .. key .. " = " .. tostring(value) .. ",\n"
        end
    end
    saveString = saveString .. "}\n"
    
    -- Write save file
    local success, error = love.filesystem.write(fileName, saveString)
    
    if success then
        -- TODO: Start the actual game with this save data
        print("Save file created: " .. fileName)
        -- For now, go back to main menu
        Gamestate:pop()
    else
        self.errorMessage = "Failed to create save file: " .. (error or "Unknown error")
        self.confirmCreate = false
    end
end

return NewGame