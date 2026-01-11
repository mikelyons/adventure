local Level = {}
local Sprites = require "sprites"
local Color = require("color")
local Utils = require("utils")

-- Helper function alias from Utils module
local clamp = Utils.clamp

function Level:load()
    -- Player state
    self.player = {
        x = 400,
        y = 450,
        speed = 180,
        size = 12,
        direction = "up"
    }

    -- Level dimensions
    self.level = {
        tileSize = 32,
        cols = 40,
        rows = 30,
        width = 0,
        height = 0
    }
    self.level.width = self.level.cols * self.level.tileSize
    self.level.height = self.level.rows * self.level.tileSize

    -- Camera
    self.camera = { x = 0, y = 0 }

    -- Tiles
    self.tiles = {}

    -- NPCs
    self.npcs = {}

    -- Level info
    self.levelType = "ruins"
    self.levelName = "Unknown"
    self.levelSeed = 12345

    -- Dialogue system
    self.dialogue = {
        active = false,
        currentNPC = nil,
        currentText = "",
        fullText = "",
        textSpeed = 0.03,
        textTimer = 0
    }

    -- Interaction
    self.nearbyNPC = nil
    self.interactionPrompt = nil

    -- First visit message
    self.showWelcome = false
    self.welcomeTimer = 0
    self.welcomeDuration = 3.0
end

function Level:enter()
    if self.poiData then
        self.levelType = self.poiData.levelType or "ruins"
        self.levelName = self.poiData.name or "Unknown"
        self.levelSeed = self.poiData.levelSeed or 12345
        self.showWelcome = not self.poiData.visited

        -- Mark as visited
        self.poiData.visited = true
    end

    -- Generate level based on type
    love.math.setRandomSeed(self.levelSeed)
    self:generateLevel()

    -- Position player at entrance
    self.player.x = self.level.width / 2
    self.player.y = self.level.height - 60
end

function Level:generateLevel()
    if self.levelType == "ruins" then
        self:generateRuins()
    elseif self.levelType == "cave" then
        self:generateCave()
    elseif self.levelType == "forest" then
        self:generateForest()
    elseif self.levelType == "oasis" then
        self:generateOasis()
    elseif self.levelType == "portal" then
        self:generatePortal()
    else
        self:generateRuins()
    end
end

-- RUINS GENERATION --
function Level:generateRuins()
    self.tiles = {}
    local scale = 0.15

    for row = 1, self.level.rows do
        self.tiles[row] = {}
        for col = 1, self.level.cols do
            local n = love.math.noise(col * scale, row * scale)
            local tile
            if n < 0.3 then
                tile = "ruins_floor"
            elseif n < 0.6 then
                tile = "stone"
            elseif n < 0.8 then
                tile = "ruins_floor"
            else
                tile = "grass"
            end
            self.tiles[row][col] = tile
        end
    end

    -- Add border walls
    for col = 1, self.level.cols do
        self.tiles[1][col] = "stone"
        self.tiles[2][col] = "stone"
        self.tiles[self.level.rows][col] = "stone"
    end
    for row = 1, self.level.rows do
        self.tiles[row][1] = "stone"
        self.tiles[row][self.level.cols] = "stone"
    end

    -- Create entrance at bottom
    local midCol = math.floor(self.level.cols / 2)
    self.tiles[self.level.rows][midCol] = "path"
    self.tiles[self.level.rows][midCol + 1] = "path"
    self.tiles[self.level.rows - 1][midCol] = "path"
    self.tiles[self.level.rows - 1][midCol + 1] = "path"

    -- Add NPC
    self.npcs = {
        {
            x = self.level.width / 2,
            y = 150,
            name = "Ancient Spirit",
            size = 14,
            color = {0.7, 0.8, 1.0},
            dialogue = {
                "Welcome, traveler... I have waited centuries for someone to find this place.",
                "These ruins hold the secrets of the old kingdom. Many have sought them.",
                "Beware the shadows that linger here. Not all who entered have left.",
                "Perhaps you are the one destined to uncover the truth..."
            },
            currentDialogue = 1
        }
    }
end

-- CAVE GENERATION --
function Level:generateCave()
    self.tiles = {}
    local scale = 0.12

    for row = 1, self.level.rows do
        self.tiles[row] = {}
        for col = 1, self.level.cols do
            local n = love.math.noise(col * scale, row * scale)
            local tile
            if n < 0.35 then
                tile = "cave_floor"
            elseif n < 0.5 then
                tile = "stone"
            elseif n < 0.85 then
                tile = "cave_floor"
            else
                tile = "crystal"
            end
            self.tiles[row][col] = tile
        end
    end

    -- Cave walls
    for col = 1, self.level.cols do
        self.tiles[1][col] = "stone"
        self.tiles[self.level.rows][col] = "stone"
    end
    for row = 1, self.level.rows do
        self.tiles[row][1] = "stone"
        self.tiles[row][self.level.cols] = "stone"
    end

    -- Entrance
    local midCol = math.floor(self.level.cols / 2)
    self.tiles[self.level.rows][midCol] = "cave_floor"
    self.tiles[self.level.rows][midCol + 1] = "cave_floor"

    -- Add NPC
    self.npcs = {
        {
            x = self.level.width / 2 - 100,
            y = 200,
            name = "Cave Hermit",
            size = 11,
            color = {0.6, 0.5, 0.4},
            dialogue = {
                "Ah, a visitor! It's been so long since anyone ventured this deep.",
                "The crystals here... they sing if you listen closely.",
                "I came here seeking solitude. I found something far more valuable.",
                "The light they emit... it shows truths hidden from the sun."
            },
            currentDialogue = 1
        }
    }
end

-- FOREST GENERATION --
function Level:generateForest()
    self.tiles = {}
    local scale = 0.1

    for row = 1, self.level.rows do
        self.tiles[row] = {}
        for col = 1, self.level.cols do
            local n = love.math.noise(col * scale, row * scale)
            local distFromCenter = math.sqrt((col - self.level.cols/2)^2 + (row - self.level.rows/2)^2)
            local tile

            -- Create a clearing in the center
            if distFromCenter < 6 then
                tile = "forest_floor"
            elseif n < 0.4 then
                tile = "tree"
            elseif n < 0.7 then
                tile = "forest_floor"
            else
                tile = "tree"
            end
            self.tiles[row][col] = tile
        end
    end

    -- Border of trees
    for col = 1, self.level.cols do
        self.tiles[1][col] = "tree"
        self.tiles[self.level.rows][col] = "tree"
    end
    for row = 1, self.level.rows do
        self.tiles[row][1] = "tree"
        self.tiles[row][self.level.cols] = "tree"
    end

    -- Path entrance
    local midCol = math.floor(self.level.cols / 2)
    self.tiles[self.level.rows][midCol] = "path"
    self.tiles[self.level.rows][midCol + 1] = "path"
    self.tiles[self.level.rows - 1][midCol] = "forest_floor"
    self.tiles[self.level.rows - 1][midCol + 1] = "forest_floor"

    -- Add NPC
    self.npcs = {
        {
            x = self.level.width / 2,
            y = self.level.height / 2 - 50,
            name = "Forest Guardian",
            size = 13,
            color = {0.3, 0.7, 0.4},
            dialogue = {
                "The grove welcomes you, child of the outer world.",
                "These ancient trees have witnessed the rise and fall of empires.",
                "The magic here is old... older than memory itself.",
                "Listen to the whispers of the leaves. They speak of times to come."
            },
            currentDialogue = 1
        }
    }
end

-- OASIS GENERATION --
function Level:generateOasis()
    self.tiles = {}

    for row = 1, self.level.rows do
        self.tiles[row] = {}
        for col = 1, self.level.cols do
            local distFromCenter = math.sqrt((col - self.level.cols/2)^2 + (row - self.level.rows/2)^2)
            local tile

            -- Central pond
            if distFromCenter < 5 then
                tile = "pond"
            elseif distFromCenter < 8 then
                tile = "grass"
            elseif distFromCenter < 12 then
                tile = "oasis_sand"
            else
                tile = "sand"
            end
            self.tiles[row][col] = tile
        end
    end

    -- Sandy border
    for col = 1, self.level.cols do
        self.tiles[1][col] = "sand"
        self.tiles[self.level.rows][col] = "sand"
    end
    for row = 1, self.level.rows do
        self.tiles[row][1] = "sand"
        self.tiles[row][self.level.cols] = "sand"
    end

    -- Entrance path
    local midCol = math.floor(self.level.cols / 2)
    self.tiles[self.level.rows][midCol] = "oasis_sand"
    self.tiles[self.level.rows][midCol + 1] = "oasis_sand"

    -- Add NPC
    self.npcs = {
        {
            x = self.level.width / 2 + 120,
            y = self.level.height / 2,
            name = "Desert Wanderer",
            size = 11,
            color = {0.9, 0.8, 0.6},
            dialogue = {
                "Ah, another soul guided by the shimmer on the horizon.",
                "This oasis has saved many travelers. It will save many more.",
                "The desert tests us, but it also teaches us.",
                "Rest here, friend. The sands will wait for your return."
            },
            currentDialogue = 1
        }
    }
end

-- PORTAL GENERATION --
function Level:generatePortal()
    self.tiles = {}
    local scale = 0.08

    for row = 1, self.level.rows do
        self.tiles[row] = {}
        for col = 1, self.level.cols do
            local distFromCenter = math.sqrt((col - self.level.cols/2)^2 + (row - self.level.rows/2)^2)
            local n = love.math.noise(col * scale, row * scale)
            local tile

            -- Central magic area
            if distFromCenter < 4 then
                tile = "magic_rune"
            elseif distFromCenter < 8 then
                tile = "portal_floor"
            elseif n < 0.5 then
                tile = "portal_floor"
            else
                tile = "stone"
            end
            self.tiles[row][col] = tile
        end
    end

    -- Stone border
    for col = 1, self.level.cols do
        self.tiles[1][col] = "stone"
        self.tiles[self.level.rows][col] = "stone"
    end
    for row = 1, self.level.rows do
        self.tiles[row][1] = "stone"
        self.tiles[row][self.level.cols] = "stone"
    end

    -- Entrance
    local midCol = math.floor(self.level.cols / 2)
    self.tiles[self.level.rows][midCol] = "portal_floor"
    self.tiles[self.level.rows][midCol + 1] = "portal_floor"

    -- Add NPC
    self.npcs = {
        {
            x = self.level.width / 2,
            y = 180,
            name = "Void Walker",
            size = 14,
            color = {0.8, 0.5, 1.0},
            dialogue = {
                "You stand at the threshold between worlds, mortal.",
                "This portal has connected realms since before time had meaning.",
                "I am but an echo of what once passed through here.",
                "The power here is neither good nor evil. It simply... is."
            },
            currentDialogue = 1
        }
    }
end

function Level:update(dt)
    -- Welcome message timer
    if self.showWelcome then
        self.welcomeTimer = self.welcomeTimer + dt
        if self.welcomeTimer >= self.welcomeDuration then
            self.showWelcome = false
        end
    end

    -- Handle dialogue
    if self.dialogue.active then
        self:updateDialogue(dt)
        return
    end

    -- Player movement
    local moveX, moveY = 0, 0
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        moveX = moveX - 1
        self.player.direction = "left"
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        moveX = moveX + 1
        self.player.direction = "right"
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        moveY = moveY - 1
        self.player.direction = "up"
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        moveY = moveY + 1
        self.player.direction = "down"
    end

    if moveX ~= 0 or moveY ~= 0 then
        local length = math.sqrt(moveX * moveX + moveY * moveY)
        moveX, moveY = moveX / length, moveY / length

        local newX = self.player.x + moveX * self.player.speed * dt
        local newY = self.player.y + moveY * self.player.speed * dt

        -- Simple collision with solid tiles
        if self:canMoveTo(newX, self.player.y) then
            self.player.x = newX
        end
        if self:canMoveTo(self.player.x, newY) then
            self.player.y = newY
        end
    end

    -- Clamp to bounds
    local half = self.player.size / 2
    self.player.x = clamp(self.player.x, half + 32, self.level.width - half - 32)
    self.player.y = clamp(self.player.y, half + 32, self.level.height - half - 32)

    -- Check NPC interactions
    self:checkNPCInteractions()

    -- Camera
    local screenW, screenH = love.graphics.getDimensions()
    self.camera.x = clamp(self.player.x - screenW / 2, 0, math.max(0, self.level.width - screenW))
    self.camera.y = clamp(self.player.y - screenH / 2, 0, math.max(0, self.level.height - screenH))
end

function Level:canMoveTo(x, y)
    local col = math.floor(x / self.level.tileSize) + 1
    local row = math.floor(y / self.level.tileSize) + 1

    if row < 1 or row > self.level.rows or col < 1 or col > self.level.cols then
        return false
    end

    local tile = self.tiles[row][col]
    -- Solid tiles
    if tile == "stone" or tile == "tree" or tile == "water" then
        return false
    end

    return true
end

function Level:checkNPCInteractions()
    self.nearbyNPC = nil
    self.interactionPrompt = nil

    for _, npc in ipairs(self.npcs) do
        local distance = math.sqrt((self.player.x - npc.x)^2 + (self.player.y - npc.y)^2)
        local interactionDistance = self.player.size + npc.size + 20

        if distance <= interactionDistance then
            self.nearbyNPC = npc
            self.interactionPrompt = "Press SPACE to talk to " .. npc.name
            return
        end
    end
end

function Level:updateDialogue(dt)
    if not self.dialogue.active then return end

    self.dialogue.textTimer = self.dialogue.textTimer + dt

    if self.dialogue.textTimer >= self.dialogue.textSpeed then
        self.dialogue.textTimer = 0
        local currentLength = #self.dialogue.currentText
        local fullLength = #self.dialogue.fullText

        if currentLength < fullLength then
            self.dialogue.currentText = string.sub(self.dialogue.fullText, 1, currentLength + 1)
        end
    end
end

function Level:startDialogue(npc)
    if not npc or not npc.dialogue then return end

    self.dialogue.active = true
    self.dialogue.currentNPC = npc
    self.dialogue.fullText = npc.dialogue[npc.currentDialogue]
    self.dialogue.currentText = ""
    self.dialogue.textTimer = 0

    npc.currentDialogue = npc.currentDialogue + 1
    if npc.currentDialogue > #npc.dialogue then
        npc.currentDialogue = 1
    end
end

function Level:draw()
    local screenW, screenH = love.graphics.getDimensions()
    local ts = self.level.tileSize

    love.graphics.push()
    love.graphics.translate(-self.camera.x, -self.camera.y)

    -- Draw tiles
    local startCol = math.max(1, math.floor(self.camera.x / ts) + 1)
    local endCol = math.min(self.level.cols, math.floor((self.camera.x + screenW) / ts) + 2)
    local startRow = math.max(1, math.floor(self.camera.y / ts) + 1)
    local endRow = math.min(self.level.rows, math.floor((self.camera.y + screenH) / ts) + 2)

    Color.set(1, 1, 1, 1)
    for row = startRow, endRow do
        for col = startCol, endCol do
            local tile = self.tiles[row] and self.tiles[row][col]
            if tile then
                local sprite = Sprites.images[tile]
                if sprite then
                    love.graphics.draw(sprite, (col - 1) * ts, (row - 1) * ts, 0, Sprites.scale, Sprites.scale)
                end
            end
        end
    end

    -- Draw NPCs
    for _, npc in ipairs(self.npcs) do
        -- Glow effect for mystical NPCs
        local pulse = math.sin(love.timer.getTime() * 2) * 0.2 + 0.8
        Color.set(npc.color[1] * pulse, npc.color[2] * pulse, npc.color[3] * pulse, 0.3)
        love.graphics.circle("fill", npc.x, npc.y, npc.size + 4)

        Color.set(npc.color[1], npc.color[2], npc.color[3], 1)
        love.graphics.circle("fill", npc.x, npc.y, npc.size)
        Color.set(0.1, 0.1, 0.2, 1)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", npc.x, npc.y, npc.size)

        -- NPC name
        Color.set(1, 1, 1, 0.9)
        local nameWidth = love.graphics.getFont():getWidth(npc.name)
        love.graphics.print(npc.name, npc.x - nameWidth / 2, npc.y - npc.size - 20)
    end

    -- Draw player
    Color.set(1, 1, 1, 1)
    local playerSprite = Sprites.images.player
    if playerSprite then
        local playerScale = self.player.size / 6
        love.graphics.draw(playerSprite,
            self.player.x, self.player.y,
            0, playerScale, playerScale, 8, 8)
    else
        love.graphics.circle("fill", self.player.x, self.player.y, self.player.size)
        Color.set(0.1, 0.1, 0.2)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", self.player.x, self.player.y, self.player.size)
    end

    love.graphics.pop()

    -- HUD
    Color.set(1, 1, 1, 1)
    love.graphics.print(self.levelName, 10, 10)
    love.graphics.print("WASD to move, SPACE to talk, ESC to exit", 10, 30)

    -- Interaction prompt
    if self.interactionPrompt and not self.dialogue.active then
        Color.set(1, 1, 0.8, 1)
        love.graphics.print(self.interactionPrompt, 10, 50)
    end

    -- Welcome message
    if self.showWelcome then
        self:drawWelcomeMessage()
    end

    -- Dialogue
    if self.dialogue.active then
        self:drawDialogueOverlay()
    end
end

function Level:drawWelcomeMessage()
    local screenW, screenH = love.graphics.getDimensions()
    local alpha = 1.0

    -- Fade out at the end
    if self.welcomeTimer > self.welcomeDuration - 0.5 then
        alpha = (self.welcomeDuration - self.welcomeTimer) / 0.5
    end

    Color.set(0, 0, 0, 0.6 * alpha)
    love.graphics.rectangle("fill", screenW/2 - 200, 80, 400, 60)

    Color.set(1, 1, 0.9, alpha)
    love.graphics.printf("Entering: " .. self.levelName, screenW/2 - 190, 100, 380, "center")
end

function Level:drawDialogueOverlay()
    local screenW, screenH = love.graphics.getDimensions()

    Color.set(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    local boxWidth = 700
    local boxHeight = 150
    local boxX = (screenW - boxWidth) / 2
    local boxY = screenH - boxHeight - 50

    Color.set(0.1, 0.1, 0.2, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)
    Color.set(0.8, 0.8, 0.8, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight)

    if self.dialogue.currentNPC then
        Color.set(1, 1, 0.8, 1)
        love.graphics.print(self.dialogue.currentNPC.name, boxX + 20, boxY + 15)
    end

    Color.set(1, 1, 1, 1)
    love.graphics.printf(self.dialogue.currentText, boxX + 20, boxY + 45, boxWidth - 40, "left")

    if #self.dialogue.currentText >= #self.dialogue.fullText then
        Color.set(0.8, 0.8, 0.2, 1)
        love.graphics.print("Press SPACE to continue", boxX + 20, boxY + boxHeight - 30)
    end
end

function Level:keypressed(key)
    if self.dialogue.active then
        if key == "space" then
            if #self.dialogue.currentText >= #self.dialogue.fullText then
                self.dialogue.active = false
            else
                self.dialogue.currentText = self.dialogue.fullText
            end
        end
        return
    end

    if key == "escape" then
        Gamestate:push(require("states.pause"))
    elseif key == "space" then
        if self.nearbyNPC then
            self:startDialogue(self.nearbyNPC)
        end
    end
end

return Level
