local NewGame = {}

-- Compatibility color setter
local function setColor(r, g, b, a)
    a = a or 1
    local getVersion = love.getVersion
    if getVersion then
        local major = getVersion()
        if type(major) == "number" and major >= 11 then
            love.graphics.setColor(r, g, b, a)
            return
        end
    end
    love.graphics.setColor(r * 255, g * 255, b * 255, a * 255)
end

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
    local screenW, screenH = love.graphics.getDimensions()
    local time = love.timer.getTime()

    -- Animated background
    for y = 0, screenH, 32 do
        for x = 0, screenW, 32 do
            local wave = math.sin((x + y) * 0.01 + time * 0.5) * 0.02
            setColor(0.08 + wave, 0.10 + wave, 0.15 + wave)
            love.graphics.rectangle("fill", x, y, 32, 32)
        end
    end

    -- Main panel
    local panelW, panelH = 500, 380
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2 - 20

    -- Panel shadow
    setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", panelX + 6, panelY + 6, panelW, panelH, 10, 10)

    -- Panel background
    setColor(0.06, 0.10, 0.16, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 10, 10)

    -- Inner panel
    setColor(0.10, 0.14, 0.20, 0.9)
    love.graphics.rectangle("fill", panelX + 4, panelY + 4, panelW - 8, panelH - 8, 8, 8)

    -- Panel border
    love.graphics.setLineWidth(3)
    setColor(0.45, 0.55, 0.70)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 10, 10)

    -- Inner highlight
    love.graphics.setLineWidth(1)
    setColor(0.55, 0.65, 0.80, 0.4)
    love.graphics.rectangle("line", panelX + 3, panelY + 3, panelW - 6, panelH - 6, 8, 8)

    -- Corner decorations
    local cornerSize = 16
    setColor(0.55, 0.65, 0.80)
    love.graphics.rectangle("fill", panelX + 12, panelY + 12, cornerSize, 2)
    love.graphics.rectangle("fill", panelX + 12, panelY + 12, 2, cornerSize)
    love.graphics.rectangle("fill", panelX + panelW - 12 - cornerSize, panelY + 12, cornerSize, 2)
    love.graphics.rectangle("fill", panelX + panelW - 14, panelY + 12, 2, cornerSize)
    love.graphics.rectangle("fill", panelX + 12, panelY + panelH - 14, cornerSize, 2)
    love.graphics.rectangle("fill", panelX + 12, panelY + panelH - 12 - cornerSize, 2, cornerSize)
    love.graphics.rectangle("fill", panelX + panelW - 12 - cornerSize, panelY + panelH - 14, cornerSize, 2)
    love.graphics.rectangle("fill", panelX + panelW - 14, panelY + panelH - 12 - cornerSize, 2, cornerSize)

    -- Title with decorative line
    setColor(0.95, 0.90, 0.70)
    love.graphics.printf("CREATE NEW GAME", panelX, panelY + 35, panelW, "center")

    -- Decorative line under title
    local lineY = panelY + 60
    setColor(0.35, 0.45, 0.55)
    love.graphics.rectangle("fill", panelX + 60, lineY, panelW - 120, 2)
    setColor(0.55, 0.65, 0.80)
    love.graphics.rectangle("fill", panelX + 60, lineY, 20, 2)
    love.graphics.rectangle("fill", panelX + panelW - 80, lineY, 20, 2)

    -- Instructions
    setColor(0.70, 0.75, 0.85)
    love.graphics.printf("Enter your character name:", panelX, panelY + 90, panelW, "center")

    -- Name input box
    local inputW, inputH = 320, 45
    local inputX = panelX + (panelW - inputW) / 2
    local inputY = panelY + 125

    -- Input shadow
    setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", inputX + 3, inputY + 3, inputW, inputH, 6, 6)

    -- Input background
    setColor(0.12, 0.16, 0.22)
    love.graphics.rectangle("fill", inputX, inputY, inputW, inputH, 6, 6)

    -- Input border (glowing when active)
    local glow = self.inputMode and (math.sin(time * 3) * 0.2 + 0.8) or 0.6
    setColor(0.45 * glow, 0.65 * glow, 0.85 * glow)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", inputX, inputY, inputW, inputH, 6, 6)

    -- Character name text
    setColor(0.95, 0.95, 1)
    love.graphics.print(self.characterName, inputX + 15, inputY + 13)

    -- Cursor blink when in input mode
    if self.inputMode and math.floor(time * 2) % 2 == 0 then
        local textWidth = love.graphics.getFont():getWidth(self.characterName)
        setColor(0.85, 0.90, 1)
        love.graphics.rectangle("fill", inputX + 15 + textWidth + 2, inputY + 10, 2, 25)
    end

    -- Character count with progress bar
    local charCount = string.len(self.characterName)
    local countX = inputX
    local countY = inputY + inputH + 8

    -- Progress bar background
    setColor(0.15, 0.18, 0.22)
    love.graphics.rectangle("fill", countX, countY, inputW, 6, 2, 2)

    -- Progress bar fill
    local progress = charCount / self.maxNameLength
    local barColor = progress > 0.9 and {0.85, 0.55, 0.45} or {0.45, 0.65, 0.85}
    setColor(barColor[1], barColor[2], barColor[3])
    love.graphics.rectangle("fill", countX + 1, countY + 1, (inputW - 2) * progress, 4, 1, 1)

    -- Count text
    setColor(0.60, 0.65, 0.75)
    love.graphics.printf(charCount .. "/" .. self.maxNameLength, countX, countY + 12, inputW, "center")

    -- Error message
    if self.errorMessage ~= "" then
        -- Error background
        setColor(0.35, 0.15, 0.15, 0.8)
        love.graphics.rectangle("fill", panelX + 40, panelY + 230, panelW - 80, 30, 4, 4)
        setColor(0.85, 0.35, 0.35)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", panelX + 40, panelY + 230, panelW - 80, 30, 4, 4)
        setColor(1, 0.70, 0.70)
        love.graphics.printf(self.errorMessage, panelX, panelY + 237, panelW, "center")
    end

    -- Instructions/confirmation
    local instructY = panelY + 280
    if not self.confirmCreate then
        -- Button hints
        setColor(0.50, 0.60, 0.70)
        love.graphics.printf("Press", panelX, instructY, panelW, "center")

        -- ENTER button
        local enterX = panelX + panelW / 2 - 110
        setColor(0.25, 0.35, 0.45)
        love.graphics.rectangle("fill", enterX, instructY + 22, 60, 26, 4, 4)
        setColor(0.55, 0.70, 0.85)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", enterX, instructY + 22, 60, 26, 4, 4)
        setColor(0.90, 0.95, 1)
        love.graphics.print("ENTER", enterX + 8, instructY + 27)

        setColor(0.50, 0.60, 0.70)
        love.graphics.print("to create,", enterX + 68, instructY + 27)

        -- ESC button
        local escX = enterX + 145
        setColor(0.35, 0.25, 0.25)
        love.graphics.rectangle("fill", escX, instructY + 22, 45, 26, 4, 4)
        setColor(0.75, 0.55, 0.55)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", escX, instructY + 22, 45, 26, 4, 4)
        setColor(1, 0.85, 0.85)
        love.graphics.print("ESC", escX + 10, instructY + 27)

        setColor(0.50, 0.60, 0.70)
        love.graphics.print("to go back", escX + 52, instructY + 27)
    else
        -- Confirmation panel
        setColor(0.18, 0.22, 0.28, 0.9)
        love.graphics.rectangle("fill", panelX + 50, instructY - 5, panelW - 100, 65, 6, 6)
        setColor(0.55, 0.75, 0.55)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", panelX + 50, instructY - 5, panelW - 100, 65, 6, 6)

        setColor(0.85, 0.95, 0.85)
        love.graphics.printf("Create this character?", panelX, instructY + 5, panelW, "center")

        -- Y button
        local yX = panelX + panelW / 2 - 80
        setColor(0.25, 0.40, 0.30)
        love.graphics.rectangle("fill", yX, instructY + 28, 50, 26, 4, 4)
        setColor(0.55, 0.85, 0.60)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", yX, instructY + 28, 50, 26, 4, 4)
        setColor(0.85, 1, 0.85)
        love.graphics.print("Y", yX + 20, instructY + 33)

        setColor(0.65, 0.75, 0.65)
        love.graphics.print("Yes", yX + 55, instructY + 33)

        -- N button
        local nX = yX + 100
        setColor(0.40, 0.28, 0.28)
        love.graphics.rectangle("fill", nX, instructY + 28, 50, 26, 4, 4)
        setColor(0.85, 0.55, 0.55)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", nX, instructY + 28, 50, 26, 4, 4)
        setColor(1, 0.85, 0.85)
        love.graphics.print("N", nX + 20, instructY + 33)

        setColor(0.75, 0.60, 0.60)
        love.graphics.print("No", nX + 55, instructY + 33)
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
    
    local statsSuccess = love.filesystem.write(saveDir .. "/stats.lua", self:serializeDataToFile(statsData))
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
    
    local optionsSuccess = love.filesystem.write(saveDir .. "/options.lua", self:serializeDataToFile(optionsData))
    if not optionsSuccess then
        self.errorMessage = "Failed to create options file"
        self.confirmCreate = false
        return
    end
    
    -- Create initial world data
    local worldData = self:generateWorldData()
    local worldSuccess = love.filesystem.write(saveDir .. "/world.lua", self:serializeDataToFile(worldData))
    if not worldSuccess then
        self.errorMessage = "Failed to create world file"
        self.confirmCreate = false
        return
    end
    
    -- Create initial town data
    local townData = self:generateTownData()
    local townSuccess = love.filesystem.write(saveDir .. "/town.lua", self:serializeDataToFile(townData))
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

function NewGame:serializeData(data, indent)
    indent = indent or ""
    local result = "{\n"
    local nextIndent = indent .. "  "

    for key, value in pairs(data) do
        local keyStr
        if type(key) == "number" then
            keyStr = ""  -- Array index, no key needed
        else
            keyStr = key .. " = "
        end

        if type(value) == "string" then
            result = result .. nextIndent .. keyStr .. "\"" .. value .. "\",\n"
        elseif type(value) == "boolean" then
            result = result .. nextIndent .. keyStr .. tostring(value) .. ",\n"
        elseif type(value) == "table" then
            result = result .. nextIndent .. keyStr .. self:serializeData(value, nextIndent) .. ",\n"
        else
            result = result .. nextIndent .. keyStr .. tostring(value) .. ",\n"
        end
    end

    result = result .. indent .. "}"
    return result
end

function NewGame:serializeDataToFile(data)
    return "return " .. self:serializeData(data) .. "\n"
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
                color = {0.8, 0.6, 0.2},
                levelType = "ruins",
                levelSeed = seed + 1,
                visited = false
            },
            {
                x = 800,
                y = 150,
                radius = 18,
                name = "Crystal Cave",
                message = "A mysterious cave entrance glows with an ethereal light. Strange crystals line the walls.",
                discovered = false,
                color = {0.4, 0.8, 1.0},
                levelType = "cave",
                levelSeed = seed + 2,
                visited = false
            },
            {
                x = 1200,
                y = 600,
                radius = 25,
                name = "Sacred Grove",
                message = "A peaceful grove of ancient trees. The air here feels charged with magical energy.",
                discovered = false,
                color = {0.2, 0.8, 0.3},
                levelType = "forest",
                levelSeed = seed + 3,
                visited = false
            },
            {
                x = 600,
                y = 800,
                radius = 22,
                name = "Desert Oasis",
                message = "A rare oasis in the vast desert. Clear water flows from a hidden spring.",
                discovered = false,
                color = {0.9, 0.9, 0.5},
                levelType = "oasis",
                levelSeed = seed + 4,
                visited = false
            },
            {
                x = 1000,
                y = 400,
                radius = 20,
                name = "Mystic Portal",
                message = "A swirling portal of unknown origin. It hums with arcane power.",
                discovered = false,
                color = {0.8, 0.2, 0.8},
                levelType = "portal",
                levelSeed = seed + 5,
                visited = false
            },
            {
                x = 100,
                y = 100,
                radius = 15,
                name = "Rivertown",
                message = "You see a bustling town to the north. It seems to be a good place to rest and gather supplies.",
                discovered = false,
                color = {0.4, 0.8, 1.0},
                levelType = "town",
                levelSeed = seed + 6,
                visited = false
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