local WorldMap = {}

-- Compatibility color setter for LÖVE 0.10.x (0-255) and 11.x+ (0-1)
local function setColor(r, g, b, a)
    a = a or 1
    local getVersion = love.getVersion
    if getVersion then
        local major = getVersion()
        if type(major) == "number" then
            if major >= 11 then
                love.graphics.setColor(r, g, b, a)
                return
            end
        end
    end
    -- Assume 0.10 style
    love.graphics.setColor(r * 255, g * 255, b * 255, a * 255)
end

function WorldMap:load()
    -- Player state
    self.player = {
        x = 200,  -- start somewhere near top-left
        y = 200,
        speed = 220,
        size = 14,
    }

    -- World and tiles
    self.world = {
        tileSize = 32,
        cols = 100,
        rows = 100,
        width = 0,   -- computed below
        height = 0,  -- computed below
    }
    self.world.width = self.world.cols * self.world.tileSize
    self.world.height = self.world.rows * self.world.tileSize

    -- Pre-generate a simple noise-based tilemap
    self.tiles = {}
    local scale = 0.08
    for row = 1, self.world.rows do
        self.tiles[row] = {}
        for col = 1, self.world.cols do
            local n = love.math.noise(col * scale, row * scale)
            local tile
            if n < 0.35 then
                tile = "water"
            elseif n < 0.45 then
                tile = "sand"
            else
                tile = "grass"
            end
            self.tiles[row][col] = tile
        end
    end

    -- Points of Interest (will be loaded from world data)
    self.pointsOfInterest = {}

    -- Message system
    self.messageSystem = {
        currentMessage = nil,
        messageTimer = 0,
        messageDuration = 4.0, -- seconds
        fadeInTime = 0.5,
        fadeOutTime = 0.5
    }

    -- Camera
    self.camera = { x = 0, y = 0 }

    -- HUD
    self.hud = {
        name = "",
        level = 1,
        playTime = 0,
    }
end

function WorldMap:enter()
    if self.saveData and self.worldData then
        self.hud.name = self.saveData.characterName or ""
        self.hud.level = self.saveData.level or 1
        self.hud.playTime = self.saveData.playTime or 0
        
        -- Load world data
        self:loadWorldFromData()
        
        -- Load player position if available
        if self.saveData.playerX and self.saveData.playerY then
            self.player.x = self.saveData.playerX
            self.player.y = self.saveData.playerY
        else
            -- Use world data start position
            self.player.x = self.worldData.playerStartX or 200
            self.player.y = self.worldData.playerStartY or 200
        end
    end
end

function WorldMap:loadWorldFromData()
    if not self.worldData then return end
    
    -- Set the world seed to regenerate the same world
    love.math.setRandomSeed(self.worldData.seed)
    
    -- Update world parameters
    self.world.tileSize = self.worldData.tileSize or 32
    self.world.cols = self.worldData.cols or 100
    self.world.rows = self.worldData.rows or 100
    self.world.width = self.world.cols * self.world.tileSize
    self.world.height = self.world.rows * self.world.tileSize
    
    -- Regenerate tiles with the same seed
    self.tiles = {}
    local scale = self.worldData.scale or 0.08
    for row = 1, self.world.rows do
        self.tiles[row] = {}
        for col = 1, self.world.cols do
            local n = love.math.noise(col * scale, row * scale)
            local tile
            if n < 0.35 then
                tile = "water"
            elseif n < 0.45 then
                tile = "sand"
            else
                tile = "grass"
            end
            self.tiles[row][col] = tile
        end
    end
    
    -- Load points of interest with safety checks
    self.pointsOfInterest = {}
    if self.worldData.pointsOfInterest then
        for _, poi in ipairs(self.worldData.pointsOfInterest) do
            -- Safety check: ensure all required fields exist
            if poi and poi.x and poi.y and poi.radius and poi.name and poi.message and poi.color then
                table.insert(self.pointsOfInterest, {
                    x = poi.x,
                    y = poi.y,
                    radius = poi.radius,
                    name = poi.name,
                    message = poi.message,
                    discovered = poi.discovered or false,
                    color = poi.color
                })
            else
                print("Warning: Skipping malformed POI data")
            end
        end
    end
    
    -- If no POIs were loaded, create default ones
    if #self.pointsOfInterest == 0 then
        print("No POIs loaded, creating default ones")
        self.pointsOfInterest = {
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
            }
        }
    end
    
    print("Loaded " .. #self.pointsOfInterest .. " points of interest")
end

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function WorldMap:update(dt)
    local moveX, moveY = 0, 0
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        moveX = moveX - 1
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        moveX = moveX + 1
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        moveY = moveY - 1
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        moveY = moveY + 1
    end

    if moveX ~= 0 or moveY ~= 0 then
        local length = math.sqrt(moveX * moveX + moveY * moveY)
        moveX, moveY = moveX / length, moveY / length
        self.player.x = self.player.x + moveX * self.player.speed * dt
        self.player.y = self.player.y + moveY * self.player.speed * dt
    end

    local half = self.player.size / 2
    self.player.x = clamp(self.player.x, half, self.world.width - half)
    self.player.y = clamp(self.player.y, half, self.world.height - half)

    -- Check for collisions with points of interest
    self:checkPointOfInterestCollisions()

    -- Update message system
    if self.messageSystem.currentMessage then
        self.messageSystem.messageTimer = self.messageSystem.messageTimer + dt
        if self.messageSystem.messageTimer >= self.messageSystem.messageDuration then
            self.messageSystem.currentMessage = nil
            self.messageSystem.messageTimer = 0
        end
    end

    -- Camera follows player, clamped to world bounds
    local screenW, screenH = love.graphics.getDimensions()
    self.camera.x = clamp(self.player.x - screenW / 2, 0, self.world.width - screenW)
    self.camera.y = clamp(self.player.y - screenH / 2, 0, self.world.height - screenH)
end

function WorldMap:checkPointOfInterestCollisions()
    for _, poi in ipairs(self.pointsOfInterest) do
        local distance = math.sqrt((self.player.x - poi.x)^2 + (self.player.y - poi.y)^2)
        local collisionDistance = self.player.size + poi.radius
        
        if distance <= collisionDistance and not poi.discovered then
            poi.discovered = true
            self:showMessage(poi.name, poi.message)
        end
    end
end

function WorldMap:showMessage(title, message)
    self.messageSystem.currentMessage = {
        title = title,
        message = message
    }
    self.messageSystem.messageTimer = 0
end

function WorldMap:draw()
    local screenW, screenH = love.graphics.getDimensions()
    local ts = self.world.tileSize

    love.graphics.push()
    love.graphics.translate(-self.camera.x, -self.camera.y)

    -- Draw visible tiles only
    local startCol = math.max(1, math.floor(self.camera.x / ts) + 1)
    local endCol = math.min(self.world.cols, math.floor((self.camera.x + screenW) / ts) + 1)
    local startRow = math.max(1, math.floor(self.camera.y / ts) + 1)
    local endRow = math.min(self.world.rows, math.floor((self.camera.y + screenH) / ts) + 1)

    for row = startRow, endRow do
        for col = startCol, endCol do
            local tile = self.tiles[row][col]
            if tile == "water" then
                setColor(0.17, 0.35, 0.60)
            elseif tile == "sand" then
                setColor(0.82, 0.74, 0.49)
            else -- grass
                setColor(0.23, 0.50, 0.28)
            end
            love.graphics.rectangle("fill", (col - 1) * ts, (row - 1) * ts, ts, ts)
        end
    end

    -- Optional: subtle grid
    setColor(0, 0, 0, 0.05)
    for row = startRow, endRow do
        love.graphics.line((startCol - 1) * ts, (row - 1) * ts, endCol * ts, (row - 1) * ts)
    end
    for col = startCol, endCol do
        love.graphics.line((col - 1) * ts, (startRow - 1) * ts, (col - 1) * ts, endRow * ts)
    end

    -- Draw Points of Interest
    for _, poi in ipairs(self.pointsOfInterest) do
        -- Check if POI is visible on screen
        if poi.x >= self.camera.x - poi.radius and poi.x <= self.camera.x + screenW + poi.radius and
           poi.y >= self.camera.y - poi.radius and poi.y <= self.camera.y + screenH + poi.radius then
            
            -- Draw POI with pulsing effect
            local pulse = math.sin(love.timer.getTime() * 3) * 0.2 + 0.8
            setColor(poi.color[1] * pulse, poi.color[2] * pulse, poi.color[3] * pulse, 0.8)
            love.graphics.circle("fill", poi.x, poi.y, poi.radius)
            
            -- Draw outline
            setColor(poi.color[1], poi.color[2], poi.color[3], 1)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", poi.x, poi.y, poi.radius)
            
            -- Draw name if discovered
            if poi.discovered then
                setColor(1, 1, 1, 0.9)
                love.graphics.print(poi.name, poi.x - love.graphics.getFont():getWidth(poi.name) / 2, poi.y - poi.radius - 25)
            end
        end
    end

    -- Player icon (circle with outline)
    setColor(1, 1, 1)
    love.graphics.circle("fill", self.player.x, self.player.y, self.player.size)
    setColor(0.1, 0.1, 0.2)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.player.x, self.player.y, self.player.size)

    love.graphics.pop()

    -- HUD
    setColor(1, 1, 1)
    local hudText = string.format("World Map  |  %s  Lv.%d  |  (%.0f, %.0f)", self.hud.name, self.hud.level, self.player.x, self.player.y)
    love.graphics.print(hudText, 10, 10)
    love.graphics.print("Arrows/WASD to move, ESC to go back, F5 to save", 10, 30)
    
    -- Draw discovered POI count
    local discoveredCount = 0
    for _, poi in ipairs(self.pointsOfInterest) do
        if poi.discovered then
            discoveredCount = discoveredCount + 1
        end
    end
    love.graphics.print(string.format("Points of Interest: %d/%d", discoveredCount, #self.pointsOfInterest), 10, 50)

    -- Draw message overlay
    if self.messageSystem.currentMessage then
        self:drawMessageOverlay()
    end
end

function WorldMap:drawMessageOverlay()
    local screenW, screenH = love.graphics.getDimensions()
    local msg = self.messageSystem.currentMessage
    local timer = self.messageSystem.messageTimer
    local duration = self.messageSystem.messageDuration
    local fadeIn = self.messageSystem.fadeInTime
    local fadeOut = self.messageSystem.fadeOutTime
    
    -- Calculate alpha based on fade in/out
    local alpha = 1.0
    if timer < fadeIn then
        alpha = timer / fadeIn
    elseif timer > duration - fadeOut then
        alpha = (duration - timer) / fadeOut
    end
    
    -- Semi-transparent background
    setColor(0, 0, 0, 0.7 * alpha)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    
    -- Message box
    local boxWidth = 600
    local boxHeight = 200
    local boxX = (screenW - boxWidth) / 2
    local boxY = (screenH - boxHeight) / 2
    
    setColor(0.1, 0.1, 0.2, 0.9 * alpha)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)
    setColor(0.8, 0.8, 0.8, alpha)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight)
    
    -- Title
    setColor(1, 1, 0.8, alpha)
    love.graphics.printf(msg.title, boxX + 20, boxY + 20, boxWidth - 40, "center")
    
    -- Message text
    setColor(1, 1, 1, alpha)
    love.graphics.printf(msg.message, boxX + 20, boxY + 60, boxWidth - 40, "left")
    
    -- Progress bar
    local progressWidth = boxWidth - 40
    local progressHeight = 4
    local progressX = boxX + 20
    local progressY = boxY + boxHeight - 30
    
    setColor(0.3, 0.3, 0.3, alpha)
    love.graphics.rectangle("fill", progressX, progressY, progressWidth, progressHeight)
    
    local progress = timer / duration
    setColor(0.8, 0.8, 0.2, alpha)
    love.graphics.rectangle("fill", progressX, progressY, progressWidth * progress, progressHeight)
end

function WorldMap:keypressed(key)
    if key == "escape" then
        -- Auto-save before exiting
        if self.saveDir then
            self:saveGame()
        end
        Gamestate:pop()
    elseif key == "f5" then
        self:saveGame()
    end
end

function WorldMap:saveGame()
    if not self.saveDir then
        print("No save directory set")
        return
    end
    
    -- Update stats data
    local discoveredCount = 0
    for _, poi in ipairs(self.pointsOfInterest) do
        if poi.discovered then
            discoveredCount = discoveredCount + 1
        end
    end
    
    local statsData = {
        characterName = self.hud.name,
        createdAt = self.saveData.createdAt,
        lastPlayed = os.time(),
        playTime = self.hud.playTime,
        level = self.hud.level,
        experience = self.saveData.experience or 0,
        pointsOfInterest = discoveredCount,
        totalSaves = (self.saveData.totalSaves or 0) + 1,
        playerX = self.player.x,
        playerY = self.player.y
    }
    
    -- Update world data with current POI states
    local worldData = {
        seed = self.worldData.seed,
        tileSize = self.world.tileSize,
        cols = self.world.cols,
        rows = self.world.rows,
        scale = self.worldData.scale,
        playerStartX = self.worldData.playerStartX,
        playerStartY = self.worldData.playerStartY,
        pointsOfInterest = {}
    }
    
    for _, poi in ipairs(self.pointsOfInterest) do
        table.insert(worldData.pointsOfInterest, {
            x = poi.x,
            y = poi.y,
            radius = poi.radius,
            name = poi.name,
            message = poi.message,
            discovered = poi.discovered,
            color = poi.color
        })
    end
    
    -- Save all files
    local statsSuccess = love.filesystem.write(self.saveDir .. "/stats.lua", self:serializeSaveData(statsData))
    local worldSuccess = love.filesystem.write(self.saveDir .. "/world.lua", self:serializeSaveData(worldData))
    
    if statsSuccess and worldSuccess then
        print("Game saved to: " .. self.saveDir)
        -- Update local data
        self.saveData = statsData
        self.worldData = worldData
    else
        print("Failed to save game")
    end
end

function WorldMap:serializeSaveData(data)
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

return WorldMap


