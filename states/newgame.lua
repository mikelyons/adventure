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
    -- Generate a safe directory name from character name
    local safeDirName = string.gsub(self.characterName, "[^%w%s]", "")
    safeDirName = string.gsub(safeDirName, "%s+", "_")
    local saveDir = "saves/" .. safeDirName
    
    -- Create save directory
    local success = love.filesystem.createDirectory(saveDir)
    if not success then
        self.errorMessage = "Failed to create save directory"
        self.confirmCreate = false
        return
    end
    
    -- Create stats file
    local statsData = {
        characterName = self.characterName,
        createdAt = os.time(),
        lastPlayed = os.time(),
        playTime = 0,
        level = 1,
        experience = 0,
        pointsOfInterest = 0,
        totalSaves = 0
    }
    
    local statsSuccess = love.filesystem.write(saveDir .. "/stats.lua", self:serializeData(statsData))
    if not statsSuccess then
        self.errorMessage = "Failed to create stats file"
        self.confirmCreate = false
        return
    end
    
    -- Create options file
    local optionsData = {
        musicVolume = 0.7,
        soundVolume = 0.8,
        fullscreen = false,
        vsync = true,
        language = "en"
    }
    
    local optionsSuccess = love.filesystem.write(saveDir .. "/options.lua", self:serializeData(optionsData))
    if not optionsSuccess then
        self.errorMessage = "Failed to create options file"
        self.confirmCreate = false
        return
    end
    
    -- Create initial world data
    local worldData = self:generateWorldData()
    local worldSuccess = love.filesystem.write(saveDir .. "/world.lua", self:serializeData(worldData))
    if not worldSuccess then
        self.errorMessage = "Failed to create world file"
        self.confirmCreate = false
        return
    end
    
    -- Create initial town data
    local townData = self:generateTownData()
    local townSuccess = love.filesystem.write(saveDir .. "/town.lua", self:serializeData(townData))
    if not townSuccess then
        self.errorMessage = "Failed to create town file"
        self.confirmCreate = false
        return
    end
    
    print("Save directory created: " .. saveDir)
    
    -- Start the game with this save data
    local worldmap = require "states.worldmap"
    local newState = {}
    for k, v in pairs(worldmap) do newState[k] = v end
    newState.saveDir = saveDir
    newState.saveData = statsData
    newState.worldData = worldData
    newState.townData = townData
    newState.optionsData = optionsData
    Gamestate:push(newState)
end

function NewGame:serializeData(data)
    local result = "return {\n"
    
    for key, value in pairs(data) do
        if type(value) == "string" then
            result = result .. string.format("  %s = \"%s\",\n", key, value)
        elseif type(value) == "table" then
            result = result .. string.format("  %s = {\n", key)
            for i, v in ipairs(value) do
                if type(v) == "table" then
                    -- Handle nested tables (like color arrays)
                    result = result .. "    {\n"
                    for j, subV in ipairs(v) do
                        result = result .. string.format("      %s,\n", tostring(subV))
                    end
                    result = result .. "    },\n"
                else
                    result = result .. string.format("    %s,\n", tostring(v))
                end
            end
            result = result .. "  },\n"
        else
            result = result .. string.format("  %s = %s,\n", key, tostring(value))
        end
    end
    
    result = result .. "}\n"
    return result
end

function NewGame:generateWorldData()
    -- Generate a unique world seed based on character name and creation time
    local seed = 0
    for i = 1, #self.characterName do
        seed = seed + string.byte(self.characterName, i)
    end
    seed = seed + os.time()
    
    -- Set the random seed for this world
    love.math.setRandomSeed(seed)
    
    -- Generate world parameters
    local worldData = {
        seed = seed,
        tileSize = 32,
        cols = 100,
        rows = 100,
        scale = 0.08,
        playerStartX = 200,
        playerStartY = 200,
        pointsOfInterest = {
            {
                x = 400,
                y = 300,
                radius = 20,
                name = "Ancient Ruins",
                message = "You discover the remains of an ancient civilization. The weathered stones tell stories of a time long forgotten.",
                discovered = false,
                color = {0.8, 0.6, 0.2}
            },
            {
                x = 800,
                y = 150,
                radius = 18,
                name = "Crystal Cave",
                message = "A mysterious cave entrance glows with an ethereal light. Strange crystals line the walls.",
                discovered = false,
                color = {0.4, 0.8, 1.0}
            },
            {
                x = 1200,
                y = 600,
                radius = 25,
                name = "Sacred Grove",
                message = "A peaceful grove of ancient trees. The air here feels charged with magical energy.",
                discovered = false,
                color = {0.2, 0.8, 0.3}
            },
            {
                x = 600,
                y = 800,
                radius = 22,
                name = "Desert Oasis",
                message = "A rare oasis in the vast desert. Clear water flows from a hidden spring.",
                discovered = false,
                color = {0.9, 0.9, 0.5}
            },
            {
                x = 1000,
                y = 400,
                radius = 20,
                name = "Mystic Portal",
                message = "A swirling portal of unknown origin. It hums with arcane power.",
                discovered = false,
                color = {0.8, 0.2, 0.8}
            },
            {
                x = 100,
                y = 100,
                radius = 15,
                name = "Rivertown",
                message = "You see a bustling town to the north. It seems to be a good place to rest and gather supplies.",
                discovered = false,
                color = {0.4, 0.8, 1.0}
            }
        }
    }
    
    -- Randomize POI positions slightly for uniqueness
    for _, poi in ipairs(worldData.pointsOfInterest) do
        poi.x = poi.x + love.math.random(-100, 100)
        poi.y = poi.y + love.math.random(-100, 100)
    end
    
    return worldData
end

function NewGame:generateTownData()
    -- Generate a unique town seed based on character name and creation time
    local seed = 0
    for i = 1, #self.characterName do
        seed = seed + string.byte(self.characterName, i) * 2
    end
    seed = seed + os.time() * 3
    
    -- Set the random seed for this town
    love.math.setRandomSeed(seed)
    
    -- Generate town parameters
    local townData = {
        seed = seed,
        tileSize = 24,
        cols = 80,
        rows = 60,
        scale = 0.12,
        playerStartX = 400,
        playerStartY = 300,
        npcs = {
            {
                x = 500,
                y = 250,
                name = "Elder Marcus",
                size = 12,
                color = {0.7, 0.5, 0.3},
                dialogue = {
                    "Welcome to Rivertown, young adventurer!",
                    "The ancient ruins to the north hold many secrets...",
                    "Have you visited the market square yet?"
                },
                speed = 20
            },
            {
                x = 600,
                y = 400,
                name = "Merchant Sarah",
                size = 10,
                color = {0.9, 0.7, 0.5},
                dialogue = {
                    "Fine goods for sale! The best prices in town!",
                    "I've heard rumors of treasure in the crystal cave...",
                    "Come back when you have more gold!"
                },
                speed = 25
            },
            {
                x = 350,
                y = 350,
                name = "Guard Captain",
                size = 11,
                color = {0.6, 0.6, 0.8},
                dialogue = {
                    "Keep the peace, citizen. We've had trouble lately.",
                    "The mystic portal has been acting strangely...",
                    "Stay safe out there, adventurer."
                },
                speed = 30
            }
        },
        events = {
            -- Town events and cutscenes can be added here
        }
    }
    
    -- Randomize NPC positions slightly for uniqueness
    for _, npc in ipairs(townData.npcs) do
        npc.x = npc.x + love.math.random(-50, 50)
        npc.y = npc.y + love.math.random(-50, 50)
    end
    
    return townData
end

return NewGame