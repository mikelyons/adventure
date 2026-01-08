local WorldMap = {}
local Sprites = require "sprites"

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

    -- Nearby POI for interaction
    self.nearbyPOI = nil
    self.interactionPrompt = nil

    -- Initialize sprites
    Sprites:init()
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
                    color = poi.color,
                    levelType = poi.levelType or "town",
                    levelSeed = poi.levelSeed or 12345,
                    visited = poi.visited or false
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
                color = {0.8, 0.6, 0.2},
                levelType = "ruins",
                levelSeed = 1001,
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
                levelSeed = 1002,
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
                levelSeed = 1003,
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
                levelSeed = 1004,
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
                levelSeed = 1005,
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
                levelSeed = 1006,
                visited = false
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
    self.nearbyPOI = nil
    self.interactionPrompt = nil

    for _, poi in ipairs(self.pointsOfInterest) do
        local distance = math.sqrt((self.player.x - poi.x)^2 + (self.player.y - poi.y)^2)
        local collisionDistance = self.player.size + poi.radius

        if distance <= collisionDistance and not poi.discovered then
            poi.discovered = true
            self:showMessage(poi.name, poi.message)
        end

        -- Track nearby POI for interaction
        if distance <= collisionDistance then
            self.nearbyPOI = poi
            self.interactionPrompt = "Press SPACE to enter " .. poi.name
        end
    end
end

function WorldMap:enterTown()
    local town = require "states.town"
    local newState = {}
    for k, v in pairs(town) do newState[k] = v end
    newState.saveDir = self.saveDir
    newState.saveData = self.saveData
    newState.worldData = self.worldData
    newState.townData = self.townData
    newState.optionsData = self.optionsData
    Gamestate:push(newState)
end

function WorldMap:enterLevel(poi)
    local stateModule
    -- Use Contra-style shooter for the portal
    if poi.levelType == "portal" then
        stateModule = require "states.contra"
    -- Use base building for exploration areas
    elseif poi.levelType == "ruins" or poi.levelType == "cave" or
           poi.levelType == "forest" or poi.levelType == "oasis" then
        stateModule = require "states.basebuilding"
    else
        stateModule = require "states.level"
    end

    local newState = {}
    for k, v in pairs(stateModule) do newState[k] = v end
    newState.saveDir = self.saveDir
    newState.saveData = self.saveData
    newState.worldData = self.worldData
    newState.townData = self.townData
    newState.optionsData = self.optionsData
    newState.poiData = poi
    Gamestate:push(newState)
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

    -- Draw visible tiles only using sprites
    local startCol = math.max(1, math.floor(self.camera.x / ts) + 1)
    local endCol = math.min(self.world.cols, math.floor((self.camera.x + screenW) / ts) + 1)
    local startRow = math.max(1, math.floor(self.camera.y / ts) + 1)
    local endRow = math.min(self.world.rows, math.floor((self.camera.y + screenH) / ts) + 1)

    setColor(1, 1, 1, 1)
    for row = startRow, endRow do
        for col = startCol, endCol do
            local tile = self.tiles[row][col]
            local sprite = Sprites:getTile(tile, col, row)
            if sprite then
                love.graphics.draw(sprite, (col - 1) * ts, (row - 1) * ts, 0, Sprites.scale, Sprites.scale)
            end
        end
    end

    -- Draw Points of Interest using sprite markers
    for _, poi in ipairs(self.pointsOfInterest) do
        -- Check if POI is visible on screen
        if poi.x >= self.camera.x - poi.radius and poi.x <= self.camera.x + screenW + poi.radius and
           poi.y >= self.camera.y - poi.radius and poi.y <= self.camera.y + screenH + poi.radius then

            -- Get POI marker sprite
            local markerSprite = Sprites:getPOIMarker(poi.levelType)

            -- Draw with pulsing effect
            local pulse = math.sin(love.timer.getTime() * 3) * 0.15 + 0.85
            local markerScale = (poi.radius / 8) * pulse

            setColor(1, 1, 1, 1)
            if markerSprite then
                love.graphics.draw(markerSprite,
                    poi.x, poi.y,
                    0,
                    markerScale, markerScale,
                    8, 8)  -- Center origin
            else
                -- Fallback to circle
                setColor(poi.color[1] * pulse, poi.color[2] * pulse, poi.color[3] * pulse, 0.8)
                love.graphics.circle("fill", poi.x, poi.y, poi.radius)
            end

            -- Draw name if discovered
            if poi.discovered then
                setColor(1, 1, 1, 0.9)
                love.graphics.print(poi.name, poi.x - love.graphics.getFont():getWidth(poi.name) / 2, poi.y - poi.radius - 25)
            end
        end
    end

    -- Player sprite
    setColor(1, 1, 1, 1)
    local playerSprite = Sprites.images.player
    if playerSprite then
        local playerScale = self.player.size / 6
        love.graphics.draw(playerSprite,
            self.player.x, self.player.y,
            0,
            playerScale, playerScale,
            8, 8)  -- Center origin
    else
        -- Fallback to circle
        love.graphics.circle("fill", self.player.x, self.player.y, self.player.size)
        setColor(0.1, 0.1, 0.2)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", self.player.x, self.player.y, self.player.size)
    end

    love.graphics.pop()

    -- Enhanced HUD
    self:drawHUD()

    -- Draw interaction prompt
    if self.interactionPrompt then
        self:drawInteractionPrompt()
    end

    -- Draw message overlay
    if self.messageSystem.currentMessage then
        self:drawMessageOverlay()
    end
end

function WorldMap:drawHUD()
    local screenW = love.graphics.getDimensions()

    -- HUD background panel
    setColor(0.05, 0.08, 0.12, 0.9)
    love.graphics.rectangle("fill", 5, 5, 450, 70, 6, 6)

    -- Panel border
    setColor(0.30, 0.45, 0.55)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 5, 5, 450, 70, 6, 6)

    -- Inner highlight
    setColor(0.40, 0.55, 0.65, 0.3)
    love.graphics.rectangle("line", 7, 7, 446, 66, 5, 5)

    -- World map title with globe icon hint
    setColor(0.55, 0.75, 0.90)
    love.graphics.print("WORLD MAP", 15, 12)

    -- Separator
    setColor(0.30, 0.45, 0.55)
    love.graphics.rectangle("fill", 105, 10, 2, 20)

    -- Player name and level
    setColor(0.65, 0.95, 0.75)
    love.graphics.print(self.hud.name, 120, 12)
    setColor(0.95, 0.85, 0.55)
    love.graphics.print("Lv." .. self.hud.level, 240, 12)

    -- Separator
    setColor(0.30, 0.45, 0.55)
    love.graphics.rectangle("fill", 290, 10, 2, 20)

    -- Coordinates
    setColor(0.6, 0.7, 0.8)
    love.graphics.print(string.format("(%.0f, %.0f)", self.player.x, self.player.y), 305, 12)

    -- POI progress bar
    local discoveredCount = 0
    for _, poi in ipairs(self.pointsOfInterest) do
        if poi.discovered then
            discoveredCount = discoveredCount + 1
        end
    end

    -- POI label
    setColor(0.55, 0.75, 0.90)
    love.graphics.print("Discovered:", 15, 38)

    -- Progress bar background
    local barX, barY, barW, barH = 100, 40, 120, 12
    setColor(0.15, 0.20, 0.25)
    love.graphics.rectangle("fill", barX, barY, barW, barH, 3, 3)

    -- Progress bar fill
    local progress = #self.pointsOfInterest > 0 and (discoveredCount / #self.pointsOfInterest) or 0
    local fillColor = progress >= 1 and {0.55, 0.90, 0.55} or {0.45, 0.70, 0.90}
    setColor(fillColor[1], fillColor[2], fillColor[3])
    love.graphics.rectangle("fill", barX + 2, barY + 2, (barW - 4) * progress, barH - 4, 2, 2)

    -- Progress bar highlight
    setColor(fillColor[1] + 0.2, fillColor[2] + 0.2, fillColor[3] + 0.2, 0.5)
    love.graphics.rectangle("fill", barX + 2, barY + 2, (barW - 4) * progress, (barH - 4) / 2, 2, 2)

    -- POI count
    setColor(1, 1, 1)
    love.graphics.print(string.format("%d/%d", discoveredCount, #self.pointsOfInterest), 230, 38)

    -- Controls hint
    setColor(0.45, 0.55, 0.65)
    love.graphics.print("WASD: Move  |  SPACE: Enter  |  ESC: Save & Exit", 15, 55)
end

function WorldMap:drawInteractionPrompt()
    local screenW, screenH = love.graphics.getDimensions()
    local prompt = self.interactionPrompt
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(prompt)

    local boxW = textWidth + 30
    local boxH = 32
    local boxX = (screenW - boxW) / 2
    local boxY = screenH - 80

    -- Pulsing effect
    local pulse = math.sin(love.timer.getTime() * 4) * 0.15 + 0.85

    -- Background
    setColor(0.08, 0.12, 0.18, 0.9 * pulse)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 8, 8)

    -- Border with glow
    setColor(0.55, 0.85, 0.65, pulse)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 8, 8)

    -- Text
    setColor(0.85, 1, 0.90, pulse)
    love.graphics.print(prompt, boxX + 15, boxY + 8)
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

    -- Semi-transparent background with vignette
    setColor(0, 0, 0, 0.6 * alpha)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Message box dimensions
    local boxWidth = 620
    local boxHeight = 220
    local boxX = (screenW - boxWidth) / 2
    local boxY = (screenH - boxHeight) / 2

    -- Outer glow/shadow
    setColor(0, 0, 0, 0.5 * alpha)
    love.graphics.rectangle("fill", boxX - 4, boxY - 4, boxWidth + 8, boxHeight + 8, 12, 12)

    -- Main box background
    setColor(0.06, 0.10, 0.16, 0.95 * alpha)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 8, 8)

    -- Inner panel (slightly lighter)
    setColor(0.10, 0.14, 0.20, 0.9 * alpha)
    love.graphics.rectangle("fill", boxX + 4, boxY + 4, boxWidth - 8, boxHeight - 8, 6, 6)

    -- Decorative border
    love.graphics.setLineWidth(3)
    setColor(0.45, 0.60, 0.75, alpha)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 8, 8)

    -- Inner highlight border
    love.graphics.setLineWidth(1)
    setColor(0.55, 0.70, 0.85, 0.4 * alpha)
    love.graphics.rectangle("line", boxX + 3, boxY + 3, boxWidth - 6, boxHeight - 6, 6, 6)

    -- Corner decorations
    local cornerSize = 12
    setColor(0.55, 0.70, 0.85, alpha)
    -- Top-left
    love.graphics.rectangle("fill", boxX + 8, boxY + 8, cornerSize, 2)
    love.graphics.rectangle("fill", boxX + 8, boxY + 8, 2, cornerSize)
    -- Top-right
    love.graphics.rectangle("fill", boxX + boxWidth - 8 - cornerSize, boxY + 8, cornerSize, 2)
    love.graphics.rectangle("fill", boxX + boxWidth - 10, boxY + 8, 2, cornerSize)
    -- Bottom-left
    love.graphics.rectangle("fill", boxX + 8, boxY + boxHeight - 10, cornerSize, 2)
    love.graphics.rectangle("fill", boxX + 8, boxY + boxHeight - 8 - cornerSize, 2, cornerSize)
    -- Bottom-right
    love.graphics.rectangle("fill", boxX + boxWidth - 8 - cornerSize, boxY + boxHeight - 10, cornerSize, 2)
    love.graphics.rectangle("fill", boxX + boxWidth - 10, boxY + boxHeight - 8 - cornerSize, 2, cornerSize)

    -- Discovery icon (star burst effect)
    local iconX = boxX + boxWidth / 2
    local iconY = boxY + 35
    local starPulse = math.sin(love.timer.getTime() * 5) * 0.2 + 1
    setColor(0.95, 0.85, 0.45, alpha)
    for i = 0, 7 do
        local angle = (i / 8) * math.pi * 2 + love.timer.getTime()
        local len = 12 * starPulse
        love.graphics.line(
            iconX, iconY,
            iconX + math.cos(angle) * len, iconY + math.sin(angle) * len
        )
    end
    love.graphics.circle("fill", iconX, iconY, 6)

    -- Title with badge background
    local font = love.graphics.getFont()
    local titleWidth = font:getWidth(msg.title)
    setColor(0.20, 0.28, 0.38, 0.9 * alpha)
    love.graphics.rectangle("fill", boxX + (boxWidth - titleWidth) / 2 - 15, boxY + 55, titleWidth + 30, 28, 4, 4)
    setColor(0.45, 0.60, 0.75, alpha)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", boxX + (boxWidth - titleWidth) / 2 - 15, boxY + 55, titleWidth + 30, 28, 4, 4)

    setColor(0.95, 0.90, 0.70, alpha)
    love.graphics.printf(msg.title, boxX + 20, boxY + 60, boxWidth - 40, "center")

    -- Message text
    setColor(0.90, 0.92, 0.95, alpha)
    love.graphics.printf(msg.message, boxX + 25, boxY + 100, boxWidth - 50, "left")

    -- Progress bar with styled appearance
    local progressWidth = boxWidth - 50
    local progressHeight = 8
    local progressX = boxX + 25
    local progressY = boxY + boxHeight - 35

    -- Progress bar background
    setColor(0.15, 0.20, 0.25, alpha)
    love.graphics.rectangle("fill", progressX, progressY, progressWidth, progressHeight, 3, 3)

    -- Progress bar fill
    local progress = timer / duration
    local gradientColor = {0.45, 0.70, 0.85}
    setColor(gradientColor[1], gradientColor[2], gradientColor[3], alpha)
    love.graphics.rectangle("fill", progressX + 2, progressY + 2, (progressWidth - 4) * progress, progressHeight - 4, 2, 2)

    -- Progress bar highlight
    setColor(gradientColor[1] + 0.2, gradientColor[2] + 0.2, gradientColor[3] + 0.2, 0.6 * alpha)
    love.graphics.rectangle("fill", progressX + 2, progressY + 2, (progressWidth - 4) * progress, (progressHeight - 4) / 2, 2, 2)
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
    elseif key == "space" then
        -- Enter nearby POI
        if self.nearbyPOI then
            if self.nearbyPOI.name == "Rivertown" or self.nearbyPOI.levelType == "town" then
                self:enterTown()
            else
                self:enterLevel(self.nearbyPOI)
            end
        end
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
            color = poi.color,
            levelType = poi.levelType,
            levelSeed = poi.levelSeed,
            visited = poi.visited
        })
    end
    
    -- Save all files
    local statsSuccess = love.filesystem.write(self.saveDir .. "/stats.lua", self:serializeSaveData(statsData))
    local worldSuccess = love.filesystem.write(self.saveDir .. "/world.lua", self:serializeSaveData(worldData))
    local townSuccess = love.filesystem.write(self.saveDir .. "/town.lua", self:serializeSaveData(self.townData))
    
    if statsSuccess and worldSuccess and townSuccess then
        print("Game saved to: " .. self.saveDir)
        -- Update local data
        self.saveData = statsData
        self.worldData = worldData
    else
        print("Failed to save game")
    end
end

function WorldMap:serializeData(data, indent)
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

function WorldMap:serializeSaveData(data)
    return "return " .. self:serializeData(data) .. "\n"
end

return WorldMap


