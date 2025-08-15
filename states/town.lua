local Town = {}

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

function Town:load()
    -- Player state
    self.player = {
        x = 400,
        y = 300,
        speed = 180,
        size = 12,
        direction = "down", -- down, up, left, right
        isMoving = false
    }

    -- Town and tiles
    self.town = {
        tileSize = 24,
        cols = 80,
        rows = 60,
        width = 0,
        height = 0,
    }
    self.town.width = self.town.cols * self.town.tileSize
    self.town.height = self.town.rows * self.town.tileSize

    -- Camera
    self.camera = { x = 0, y = 0 }

    -- HUD
    self.hud = {
        name = "",
        level = 1,
        currentTown = "Rivertown"
    }

    -- NPCs and Actors
    self.npcs = {}
    self.actors = {} -- For cutscenes

    -- Dialogue system
    self.dialogue = {
        active = false,
        currentNPC = nil,
        currentText = "",
        fullText = "",
        textSpeed = 0.03,
        textTimer = 0,
        choices = {},
        selectedChoice = 1
    }

    -- Cutscene system
    self.cutscene = {
        active = false,
        currentScene = nil,
        sceneTimer = 0,
        actors = {},
        script = {},
        currentAction = 1
    }

    -- Town data (will be loaded from save)
    self.townData = nil
end

function Town:enter()
    if self.saveData and self.townData then
        self.hud.name = self.saveData.characterName or ""
        self.hud.level = self.saveData.level or 1
        
        -- Load player position if available
        if self.saveData.townPlayerX and self.saveData.townPlayerY then
            self.player.x = self.saveData.townPlayerX
            self.player.y = self.saveData.townPlayerY
        end
        
        -- Load town data
        self:loadTownFromData()
        
        -- Check if this is the first time entering the town
        if not self.saveData.townVisited then
            self:startWelcomeCutscene()
        end
    else
        -- Fallback: generate default town if no data available
        self.hud.name = "Adventurer"
        self.hud.level = 1
        self:generateDefaultTown()
    end
end

function Town:startWelcomeCutscene()
    local welcomeScript = {
        actors = {
            elder = {
                x = 500,
                y = 250,
                speed = 80,
                color = {0.7, 0.5, 0.3},
                size = 12
            },
            player = {
                x = 400,
                y = 300,
                speed = 100,
                color = {1, 1, 1},
                size = 12
            }
        },
        {
            type = "dialogue",
            text = "Welcome to Rivertown, young adventurer! I am Elder Marcus."
        },
        {
            type = "wait",
            duration = 1.0
        },
        {
            type = "move",
            actor = "elder",
            x = 450,
            y = 280
        },
        {
            type = "dialogue",
            text = "Our town has been here for generations, and we welcome all travelers."
        },
        {
            type = "wait",
            duration = 1.0
        },
        {
            type = "move",
            actor = "player",
            x = 420,
            y = 280
        },
        {
            type = "dialogue",
            text = "Feel free to explore and talk to our townspeople. They have much wisdom to share."
        },
        {
            type = "wait",
            duration = 1.0
        },
        {
            type = "end"
        }
    }
    
    self:startCutscene(welcomeScript)
end

function Town:generateDefaultTown()
    -- Create default town data
    self.townData = {
        seed = 12345,
        tileSize = 24,
        cols = 80,
        rows = 60,
        scale = 0.12,
        playerStartX = 400,
        playerStartY = 300
    }
    
    -- Load the town
    self:loadTownFromData()
end

function Town:loadTownFromData()
    if not self.townData then 
        self:generateDefaultTown()
        return 
    end
    
    -- Set the town seed to regenerate the same town
    love.math.setRandomSeed(self.townData.seed)
    
    -- Update town parameters
    self.town.tileSize = self.townData.tileSize or 24
    self.town.cols = self.townData.cols or 80
    self.town.rows = self.townData.rows or 60
    self.town.width = self.town.cols * self.town.tileSize
    self.town.height = self.town.rows * self.town.tileSize
    
    -- Generate town tiles
    self:generateTownTiles()
    
    -- Load NPCs
    self:loadNPCs()
    
    -- Load town events and cutscenes
    self:loadTownEvents()
end

function Town:generateTownTiles()
    self.tiles = {}
    local scale = self.townData.scale or 0.12
    
    for row = 1, self.town.rows do
        self.tiles[row] = {}
        for col = 1, self.town.cols do
            local n = love.math.noise(col * scale, row * scale)
            local tile
            if n < 0.3 then
                tile = "water"
            elseif n < 0.4 then
                tile = "grass"
            elseif n < 0.6 then
                tile = "path"
            elseif n < 0.8 then
                tile = "building"
            else
                tile = "market"
            end
            self.tiles[row][col] = tile
        end
    end
    
    print("Generated town tiles: " .. self.town.cols .. "x" .. self.town.rows)
end

function Town:loadNPCs()
    self.npcs = {}
    if self.townData.npcs then
        for _, npcData in ipairs(self.townData.npcs) do
            if npcData and npcData.x and npcData.y and npcData.name then
                local npc = {
                    x = npcData.x,
                    y = npcData.y,
                    name = npcData.name,
                    size = npcData.size or 10,
                    color = npcData.color or {0.8, 0.6, 0.4},
                    dialogue = npcData.dialogue or {},
                    schedule = npcData.schedule or {},
                    currentDialogue = 1,
                    lastTalked = 0,
                    isMoving = false,
                    targetX = npcData.x,
                    targetY = npcData.y,
                    speed = npcData.speed or 30
                }
                table.insert(self.npcs, npc)
            end
        end
    end
    
    -- Create default NPCs if none loaded
    if #self.npcs == 0 then
        self:createDefaultNPCs()
    end
end

function Town:createDefaultNPCs()
    self.npcs = {
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
            schedule = {},
            currentDialogue = 1,
            lastTalked = 0,
            isMoving = false,
            targetX = 500,
            targetY = 250,
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
            schedule = {},
            currentDialogue = 1,
            lastTalked = 0,
            isMoving = false,
            targetX = 600,
            targetY = 400,
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
            schedule = {},
            currentDialogue = 1,
            lastTalked = 0,
            isMoving = false,
            targetX = 350,
            targetY = 350,
            speed = 30
        }
    }
end

function Town:loadTownEvents()
    -- Load cutscenes and town events
    self.townEvents = self.townData.events or {}
end

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function Town:update(dt)
    if self.cutscene.active then
        self:updateCutscene(dt)
        return
    end
    
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

    self.player.isMoving = (moveX ~= 0 or moveY ~= 0)
    
    if self.player.isMoving then
        local length = math.sqrt(moveX * moveX + moveY * moveY)
        moveX, moveY = moveX / length, moveY / length
        self.player.x = self.player.x + moveX * self.player.speed * dt
        self.player.y = self.player.y + moveY * self.player.speed * dt
    end

    -- Clamp player to town bounds
    local half = self.player.size / 2
    self.player.x = clamp(self.player.x, half, self.town.width - half)
    self.player.y = clamp(self.player.y, half, self.town.height - half)

    -- Update NPCs
    self:updateNPCs(dt)

    -- Check for NPC interactions
    self:checkNPCInteractions()

    -- Camera follows player
    local screenW, screenH = love.graphics.getDimensions()
    self.camera.x = clamp(self.player.x - screenW / 2, 0, self.town.width - screenW)
    self.camera.y = clamp(self.player.y - screenH / 2, 0, self.town.height - screenH)
end

function Town:updateNPCs(dt)
    for _, npc in ipairs(self.npcs) do
        -- Simple NPC movement (can be expanded with pathfinding)
        if npc.isMoving then
            local dx = npc.targetX - npc.x
            local dy = npc.targetY - npc.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance > 5 then
                local moveX = dx / distance * npc.speed * dt
                local moveY = dy / distance * npc.speed * dt
                npc.x = npc.x + moveX
                npc.y = npc.y + moveY
            else
                npc.isMoving = false
            end
        end
    end
end

function Town:checkNPCInteractions()
    for _, npc in ipairs(self.npcs) do
        local distance = math.sqrt((self.player.x - npc.x)^2 + (self.player.y - npc.y)^2)
        local interactionDistance = self.player.size + npc.size + 10
        
        if distance <= interactionDistance then
            -- Show interaction prompt
            self.interactionPrompt = "Press SPACE to talk to " .. npc.name
            self.nearbyNPC = npc
            return
        end
    end
    
    self.interactionPrompt = nil
    self.nearbyNPC = nil
end

function Town:updateDialogue(dt)
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

function Town:updateCutscene(dt)
    if not self.cutscene.active then return end
    
    self.cutscene.sceneTimer = self.cutscene.sceneTimer + dt
    
    -- Execute current cutscene action
    local action = self.cutscene.script[self.cutscene.currentAction]
    if action then
        if action.type == "wait" then
            if self.cutscene.sceneTimer >= action.duration then
                self.cutscene.currentAction = self.cutscene.currentAction + 1
                self.cutscene.sceneTimer = 0
            end
        elseif action.type == "move" then
            -- Move actor to position
            local actor = self.cutscene.actors[action.actor]
            if actor then
                local dx = action.x - actor.x
                local dy = action.y - actor.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                if distance > 2 then
                    local moveX = dx / distance * actor.speed * dt
                    local moveY = dy / distance * actor.speed * dt
                    actor.x = actor.x + moveX
                    actor.y = actor.y + moveY
                else
                    self.cutscene.currentAction = self.cutscene.currentAction + 1
                end
            else
                self.cutscene.currentAction = self.cutscene.currentAction + 1
            end
        elseif action.type == "dialogue" then
            -- Show dialogue
            self.dialogue.active = true
            self.dialogue.fullText = action.text
            self.dialogue.currentText = ""
            self.dialogue.textTimer = 0
            self.cutscene.currentAction = self.cutscene.currentAction + 1
        elseif action.type == "end" then
            self.cutscene.active = false
        end
    end
end

function Town:startDialogue(npc)
    if not npc or not npc.dialogue then return end
    
    self.dialogue.active = true
    self.dialogue.currentNPC = npc
    self.dialogue.fullText = npc.dialogue[npc.currentDialogue]
    self.dialogue.currentText = ""
    self.dialogue.textTimer = 0
    
    -- Cycle through dialogue
    npc.currentDialogue = npc.currentDialogue + 1
    if npc.currentDialogue > #npc.dialogue then
        npc.currentDialogue = 1
    end
    
    npc.lastTalked = love.timer.getTime()
end

function Town:startCutscene(script)
    self.cutscene.active = true
    self.cutscene.script = script
    self.cutscene.currentAction = 1
    self.cutscene.sceneTimer = 0
    
    -- Create actors for cutscene
    self.cutscene.actors = {}
    for name, actorData in pairs(script.actors or {}) do
        self.cutscene.actors[name] = {
            x = actorData.x or 400,
            y = actorData.y or 300,
            speed = actorData.speed or 100,
            color = actorData.color or {1, 1, 1},
            size = actorData.size or 12
        }
    end
end

function Town:draw()
    local screenW, screenH = love.graphics.getDimensions()
    local ts = self.town.tileSize

    love.graphics.push()
    love.graphics.translate(-self.camera.x, -self.camera.y)

    -- Draw visible tiles only (with safety check)
    if self.tiles then
        local startCol = math.max(1, math.floor(self.camera.x / ts) + 1)
        local endCol = math.min(self.town.cols, math.floor((self.camera.x + screenW) / ts) + 1)
        local startRow = math.max(1, math.floor(self.camera.y / ts) + 1)
        local endRow = math.min(self.town.rows, math.floor((self.camera.y + screenH) / ts) + 1)

        for row = startRow, endRow do
            for col = startCol, endCol do
                local tile = self.tiles[row][col]
                if tile then
                    if tile == "water" then
                        setColor(0.17, 0.35, 0.60)
                    elseif tile == "grass" then
                        setColor(0.23, 0.50, 0.28)
                    elseif tile == "path" then
                        setColor(0.6, 0.5, 0.4)
                    elseif tile == "building" then
                        setColor(0.4, 0.3, 0.2)
                    else -- market
                        setColor(0.8, 0.7, 0.5)
                    end
                    love.graphics.rectangle("fill", (col - 1) * ts, (row - 1) * ts, ts, ts)
                end
            end
        end
    else
        -- Fallback: draw a simple background if tiles aren't loaded
        setColor(0.3, 0.4, 0.3)
        love.graphics.rectangle("fill", 0, 0, self.town.width, self.town.height)
    end

    -- Draw NPCs
    for _, npc in ipairs(self.npcs) do
        if npc.x >= self.camera.x - npc.size and npc.x <= self.camera.x + screenW + npc.size and
           npc.y >= self.camera.y - npc.size and npc.y <= self.camera.y + screenH + npc.size then
            
            setColor(npc.color[1], npc.color[2], npc.color[3])
            love.graphics.circle("fill", npc.x, npc.y, npc.size)
            setColor(0.1, 0.1, 0.2)
            love.graphics.setLineWidth(1)
            love.graphics.circle("line", npc.x, npc.y, npc.size)
            
            -- Draw name
            setColor(1, 1, 1, 0.9)
            love.graphics.print(npc.name, npc.x - love.graphics.getFont():getWidth(npc.name) / 2, npc.y - npc.size - 20)
        end
    end

    -- Draw cutscene actors
    if self.cutscene.active then
        for _, actor in pairs(self.cutscene.actors) do
            setColor(actor.color[1], actor.color[2], actor.color[3])
            love.graphics.circle("fill", actor.x, actor.y, actor.size)
            setColor(0.1, 0.1, 0.2)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", actor.x, actor.y, actor.size)
        end
    end

    -- Player icon
    setColor(1, 1, 1)
    love.graphics.circle("fill", self.player.x, self.player.y, self.player.size)
    setColor(0.1, 0.1, 0.2)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.player.x, self.player.y, self.player.size)

    love.graphics.pop()

    -- HUD
    setColor(1, 1, 1)
    local hudText = string.format("Town: %s  |  %s  Lv.%d  |  (%.0f, %.0f)", 
        self.hud.currentTown, self.hud.name, self.hud.level, self.player.x, self.player.y)
    love.graphics.print(hudText, 10, 10)
    love.graphics.print("Arrows/WASD to move, SPACE to talk, ESC to return to world", 10, 30)
    
    -- Interaction prompt
    if self.interactionPrompt then
        setColor(1, 1, 0.8)
        love.graphics.print(self.interactionPrompt, 10, 50)
    end

    -- Dialogue overlay
    if self.dialogue.active then
        self:drawDialogueOverlay()
    end
end

function Town:drawDialogueOverlay()
    local screenW, screenH = love.graphics.getDimensions()
    
    -- Semi-transparent background
    setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    
    -- Dialogue box
    local boxWidth = 700
    local boxHeight = 150
    local boxX = (screenW - boxWidth) / 2
    local boxY = screenH - boxHeight - 50
    
    setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)
    setColor(0.8, 0.8, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight)
    
    -- NPC name
    if self.dialogue.currentNPC then
        setColor(1, 1, 0.8)
        love.graphics.print(self.dialogue.currentNPC.name, boxX + 20, boxY + 20)
    end
    
    -- Dialogue text
    setColor(1, 1, 1)
    love.graphics.printf(self.dialogue.currentText, boxX + 20, boxY + 50, boxWidth - 40, "left")
    
    -- Continue prompt
    if #self.dialogue.currentText >= #self.dialogue.fullText then
        setColor(0.8, 0.8, 0.2)
        love.graphics.print("Press SPACE to continue", boxX + 20, boxY + boxHeight - 30)
    end
end

function Town:keypressed(key)
    if self.cutscene.active then
        if key == "space" then
            -- Skip cutscene
            self.cutscene.active = false
        end
        return
    end
    
    if self.dialogue.active then
        if key == "space" then
            if #self.dialogue.currentText >= #self.dialogue.fullText then
                self.dialogue.active = false
            else
                -- Skip text animation
                self.dialogue.currentText = self.dialogue.fullText
            end
        end
        return
    end
    
    if key == "escape" then
        -- Save town position before returning to world
        if self.saveDir then
            self:saveTownState()
        end
        Gamestate:pop()
    elseif key == "space" then
        if self.nearbyNPC then
            self:startDialogue(self.nearbyNPC)
        end
    end
end

function Town:saveTownState()
    if not self.saveDir then return end
    
    -- Update save data with town position
    local statsData = {
        characterName = self.hud.name,
        createdAt = self.saveData.createdAt,
        lastPlayed = os.time(),
        playTime = self.saveData.playTime or 0,
        level = self.hud.level,
        experience = self.saveData.experience or 0,
        pointsOfInterest = self.saveData.pointsOfInterest or 0,
        totalSaves = (self.saveData.totalSaves or 0) + 1,
        playerX = self.saveData.playerX,
        playerY = self.saveData.playerY,
        townPlayerX = self.player.x,
        townPlayerY = self.player.y,
        townVisited = true
    }
    
    -- Save stats file
    love.filesystem.write(self.saveDir .. "/stats.lua", self:serializeSaveData(statsData))
    
    print("Town state saved")
end

function Town:serializeSaveData(data)
    local result = "return {\n"
    
    for key, value in pairs(data) do
        if type(value) == "string" then
            result = result .. string.format("  %s = \"%s\",\n", key, value)
        elseif type(value) == "table" then
            result = result .. string.format("  %s = {\n", key)
            for i, v in ipairs(value) do
                if type(v) == "table" then
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

return Town
