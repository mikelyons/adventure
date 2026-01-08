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

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpColor(c1, c2, t)
    return {lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t), lerp(c1[3], c2[3], t)}
end

-- Dithering pattern for retro-style shading
local function shouldDither(x, y, threshold)
    local pattern = {
        {0.0, 0.5, 0.125, 0.625},
        {0.75, 0.25, 0.875, 0.375},
        {0.1875, 0.6875, 0.0625, 0.5625},
        {0.9375, 0.4375, 0.8125, 0.3125}
    }
    return pattern[(y % 4) + 1][(x % 4) + 1] < threshold
end

-- Simple noise for texture variation
local function simpleNoise(x, y, seed)
    local n = math.sin(x * 12.9898 + y * 78.233 + (seed or 0)) * 43758.5453
    return n - math.floor(n)
end

-- Tile color palettes for rich graphics
local TILE_PALETTES = {
    water = {
        base = {{0.15, 0.35, 0.62}, {0.12, 0.30, 0.55}, {0.22, 0.42, 0.70}},
        foam = {0.45, 0.62, 0.80}
    },
    grass = {
        base = {{0.25, 0.52, 0.30}, {0.20, 0.45, 0.25}, {0.32, 0.60, 0.35}},
        flower = {{0.92, 0.72, 0.35}, {0.85, 0.45, 0.55}, {0.75, 0.55, 0.85}}
    },
    path = {
        base = {{0.62, 0.52, 0.42}, {0.55, 0.45, 0.35}, {0.72, 0.62, 0.50}},
        stone = {{0.50, 0.48, 0.45}, {0.58, 0.55, 0.52}}
    },
    building = {
        base = {{0.45, 0.35, 0.28}, {0.38, 0.28, 0.22}, {0.55, 0.45, 0.35}},
        roof = {{0.65, 0.35, 0.30}, {0.55, 0.28, 0.25}}
    },
    market = {
        base = {{0.82, 0.72, 0.52}, {0.75, 0.65, 0.45}, {0.90, 0.80, 0.60}},
        stall = {{0.60, 0.40, 0.30}, {0.72, 0.28, 0.28}}
    }
}

-- NPC type palettes
local NPC_PALETTES = {
    elder = {
        skin = {{0.78, 0.62, 0.48}, {0.65, 0.50, 0.38}},
        robe = {{0.55, 0.38, 0.28}, {0.42, 0.28, 0.20}},
        hair = {0.75, 0.75, 0.80}
    },
    merchant = {
        skin = {{0.85, 0.70, 0.55}, {0.72, 0.58, 0.45}},
        clothes = {{0.75, 0.55, 0.25}, {0.60, 0.42, 0.18}},
        apron = {0.92, 0.90, 0.85}
    },
    guard = {
        skin = {{0.72, 0.58, 0.45}, {0.60, 0.48, 0.38}},
        armor = {{0.52, 0.52, 0.58}, {0.42, 0.42, 0.48}},
        helmet = {{0.45, 0.45, 0.52}, {0.55, 0.55, 0.62}}
    },
    villager = {
        skin = {{0.85, 0.70, 0.55}, {0.72, 0.58, 0.45}},
        clothes = {{0.45, 0.55, 0.42}, {0.35, 0.45, 0.32}},
        hair = {{0.35, 0.25, 0.18}, {0.55, 0.42, 0.28}, {0.72, 0.62, 0.45}}
    }
}

-- Draw a detailed water tile with animated waves
local function drawWaterTile(x, y, ts, time)
    local pal = TILE_PALETTES.water

    -- Base water color with depth variation
    for py = 0, ts - 1 do
        for px = 0, ts - 1 do
            local wx = x + px
            local wy = y + py
            local wave = math.sin((wx * 0.3) + (wy * 0.2) + time * 2) * 0.5 + 0.5
            local depth = simpleNoise(math.floor(wx / 4), math.floor(wy / 4), 42)

            local colorIdx = 1
            if depth > 0.6 then colorIdx = 2
            elseif depth < 0.3 then colorIdx = 3 end

            local c = pal.base[colorIdx]
            local brightness = 1.0 + wave * 0.15

            -- Add foam highlights on wave peaks
            if wave > 0.8 and shouldDither(px, py, wave - 0.7) then
                c = pal.foam
                brightness = 1.1
            end

            setColor(c[1] * brightness, c[2] * brightness, c[3] * brightness)
            love.graphics.rectangle("fill", wx, wy, 1, 1)
        end
    end
end

-- Draw a detailed grass tile with flowers
local function drawGrassTile(x, y, ts, col, row)
    local pal = TILE_PALETTES.grass
    local seed = col * 1000 + row

    for py = 0, ts - 1 do
        for px = 0, ts - 1 do
            local wx = x + px
            local wy = y + py
            local noise = simpleNoise(wx, wy, seed)

            -- Grass color variation
            local colorIdx = 1
            if noise > 0.7 then colorIdx = 2
            elseif noise < 0.3 then colorIdx = 3 end

            local c = pal.base[colorIdx]

            -- Add grass blade texture
            local blade = (px + py * 3) % 5 == 0
            if blade then
                c = lerpColor(c, {0.18, 0.38, 0.22}, 0.3)
            end

            setColor(c[1], c[2], c[3])
            love.graphics.rectangle("fill", wx, wy, 1, 1)
        end
    end

    -- Add occasional flowers
    local flowerSeed = simpleNoise(col, row, 123)
    if flowerSeed > 0.7 then
        local flowerColor = pal.flower[math.floor(flowerSeed * 3) + 1]
        local fx = x + math.floor(flowerSeed * (ts - 4)) + 2
        local fy = y + math.floor(simpleNoise(col, row, 456) * (ts - 4)) + 2
        setColor(flowerColor[1], flowerColor[2], flowerColor[3])
        love.graphics.rectangle("fill", fx, fy, 2, 2)
        setColor(0.95, 0.92, 0.55) -- Yellow center
        love.graphics.rectangle("fill", fx, fy, 1, 1)
    end
end

-- Draw a detailed path tile with cobblestones
local function drawPathTile(x, y, ts, col, row)
    local pal = TILE_PALETTES.path
    local seed = col * 1000 + row

    -- Base dirt
    for py = 0, ts - 1 do
        for px = 0, ts - 1 do
            local wx = x + px
            local wy = y + py
            local noise = simpleNoise(wx, wy, seed)

            local colorIdx = 1
            if noise > 0.7 then colorIdx = 2
            elseif noise < 0.3 then colorIdx = 3 end

            local c = pal.base[colorIdx]
            setColor(c[1], c[2], c[3])
            love.graphics.rectangle("fill", wx, wy, 1, 1)
        end
    end

    -- Add cobblestones
    for i = 0, 3 do
        local stoneX = x + (i % 2) * 10 + 3 + math.floor(simpleNoise(col + i, row, 789) * 4)
        local stoneY = y + math.floor(i / 2) * 10 + 3 + math.floor(simpleNoise(col, row + i, 987) * 4)
        local stoneW = 6 + math.floor(simpleNoise(col + i, row + i, 654) * 3)
        local stoneH = 5 + math.floor(simpleNoise(col + i, row - i, 321) * 3)

        local stoneColor = pal.stone[i % 2 + 1]

        -- Stone body
        setColor(stoneColor[1], stoneColor[2], stoneColor[3])
        love.graphics.rectangle("fill", stoneX, stoneY, stoneW, stoneH)

        -- Stone highlight
        setColor(stoneColor[1] + 0.1, stoneColor[2] + 0.1, stoneColor[3] + 0.1)
        love.graphics.rectangle("fill", stoneX, stoneY, stoneW, 1)

        -- Stone shadow
        setColor(stoneColor[1] - 0.1, stoneColor[2] - 0.1, stoneColor[3] - 0.1)
        love.graphics.rectangle("fill", stoneX, stoneY + stoneH - 1, stoneW, 1)
    end
end

-- Draw a detailed building tile
local function drawBuildingTile(x, y, ts, col, row)
    local pal = TILE_PALETTES.building
    local seed = col * 1000 + row

    -- Wooden floor planks
    for py = 0, ts - 1 do
        for px = 0, ts - 1 do
            local wx = x + px
            local wy = y + py

            -- Plank pattern
            local plankY = py % 8
            local plankOffset = (math.floor(py / 8) % 2) * 12
            local plankX = (px + plankOffset) % 24

            local colorIdx = 1
            if plankY == 0 or plankY == 7 then
                colorIdx = 2 -- Gap between planks
            elseif plankX == 0 then
                colorIdx = 2 -- Gap between planks
            elseif simpleNoise(wx, wy, seed) > 0.8 then
                colorIdx = 3 -- Wood grain highlight
            end

            local c = pal.base[colorIdx]
            setColor(c[1], c[2], c[3])
            love.graphics.rectangle("fill", wx, wy, 1, 1)
        end
    end

    -- Add occasional wood knot
    if simpleNoise(col, row, 111) > 0.85 then
        local kx = x + math.floor(simpleNoise(col, row, 222) * (ts - 6)) + 3
        local ky = y + math.floor(simpleNoise(col, row, 333) * (ts - 6)) + 3
        setColor(pal.base[2][1] - 0.08, pal.base[2][2] - 0.05, pal.base[2][3] - 0.05)
        love.graphics.circle("fill", kx, ky, 2)
    end
end

-- Draw a detailed market tile with colorful stall hints
local function drawMarketTile(x, y, ts, col, row)
    local pal = TILE_PALETTES.market
    local seed = col * 1000 + row

    -- Sandy/wooden market floor
    for py = 0, ts - 1 do
        for px = 0, ts - 1 do
            local wx = x + px
            local wy = y + py
            local noise = simpleNoise(wx, wy, seed)

            local colorIdx = 1
            if noise > 0.7 then colorIdx = 2
            elseif noise < 0.3 then colorIdx = 3 end

            local c = pal.base[colorIdx]
            setColor(c[1], c[2], c[3])
            love.graphics.rectangle("fill", wx, wy, 1, 1)
        end
    end

    -- Add market stall elements for some tiles
    if simpleNoise(col, row, 444) > 0.6 then
        local stallColor = pal.stall[math.floor(simpleNoise(col, row, 555) * 2) + 1]

        -- Draw awning stripe
        setColor(stallColor[1], stallColor[2], stallColor[3])
        love.graphics.rectangle("fill", x + 2, y + 2, ts - 4, 4)

        -- Awning highlight
        setColor(stallColor[1] + 0.15, stallColor[2] + 0.15, stallColor[3] + 0.15)
        love.graphics.rectangle("fill", x + 2, y + 2, ts - 4, 1)
    end

    -- Add goods crates for some tiles
    if simpleNoise(col, row, 666) > 0.75 then
        local cx = x + math.floor(simpleNoise(col, row, 777) * (ts - 8)) + 2
        local cy = y + 10
        setColor(0.55, 0.42, 0.28) -- Crate color
        love.graphics.rectangle("fill", cx, cy, 6, 6)
        setColor(0.45, 0.32, 0.20) -- Crate shadow
        love.graphics.rectangle("fill", cx, cy + 5, 6, 1)
        setColor(0.65, 0.52, 0.38) -- Crate highlight
        love.graphics.rectangle("fill", cx, cy, 6, 1)
    end
end

-- Draw a detailed NPC sprite
local function drawNPC(npc, time)
    local x, y = npc.x, npc.y
    local size = npc.size
    local scale = size / 10 -- Base size is 10

    -- Determine NPC type palette based on name
    local pal
    if npc.name:find("Elder") then
        pal = NPC_PALETTES.elder
    elseif npc.name:find("Merchant") then
        pal = NPC_PALETTES.merchant
    elseif npc.name:find("Guard") then
        pal = NPC_PALETTES.guard
    else
        pal = NPC_PALETTES.villager
    end

    -- Shadow
    setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", x, y + size * 0.9, size * 0.7, size * 0.3)

    -- Body/clothes
    local bodyColor = pal.robe and pal.robe[1] or (pal.clothes and pal.clothes[1]) or (pal.armor and pal.armor[1]) or {0.5, 0.5, 0.5}
    local bodyShadow = pal.robe and pal.robe[2] or (pal.clothes and pal.clothes[2]) or (pal.armor and pal.armor[2]) or {0.4, 0.4, 0.4}

    -- Body base
    setColor(bodyColor[1], bodyColor[2], bodyColor[3])
    love.graphics.rectangle("fill", x - size * 0.5, y - size * 0.3, size, size * 1.2)

    -- Body shading
    setColor(bodyShadow[1], bodyShadow[2], bodyShadow[3])
    love.graphics.rectangle("fill", x - size * 0.5, y + size * 0.4, size, size * 0.5)
    love.graphics.rectangle("fill", x + size * 0.2, y - size * 0.3, size * 0.3, size * 1.2)

    -- Apron for merchant
    if pal.apron then
        setColor(pal.apron[1], pal.apron[2], pal.apron[3])
        love.graphics.rectangle("fill", x - size * 0.35, y, size * 0.7, size * 0.8)
    end

    -- Helmet for guard
    if pal.helmet then
        setColor(pal.helmet[1][1], pal.helmet[1][2], pal.helmet[1][3])
        love.graphics.rectangle("fill", x - size * 0.45, y - size * 1.1, size * 0.9, size * 0.5)
        -- Helmet highlight
        setColor(pal.helmet[2][1], pal.helmet[2][2], pal.helmet[2][3])
        love.graphics.rectangle("fill", x - size * 0.45, y - size * 1.1, size * 0.9, size * 0.15)
    end

    -- Head
    setColor(pal.skin[1][1], pal.skin[1][2], pal.skin[1][3])
    love.graphics.circle("fill", x, y - size * 0.6, size * 0.5)

    -- Face shadow
    setColor(pal.skin[2][1], pal.skin[2][2], pal.skin[2][3])
    love.graphics.arc("fill", x, y - size * 0.6, size * 0.5, math.pi * 0.1, math.pi * 0.9)

    -- Hair (not for helmeted guard)
    if not pal.helmet then
        local hairColor = pal.hair
        if type(hairColor[1]) == "table" then
            hairColor = hairColor[math.floor(simpleNoise(npc.x, npc.y, 123) * #hairColor) + 1]
        end
        setColor(hairColor[1], hairColor[2], hairColor[3])
        love.graphics.arc("fill", x, y - size * 0.7, size * 0.5, math.pi * 1.1, math.pi * 1.9)
    end

    -- Eyes
    setColor(1, 1, 1)
    love.graphics.circle("fill", x - size * 0.2, y - size * 0.65, size * 0.12)
    love.graphics.circle("fill", x + size * 0.2, y - size * 0.65, size * 0.12)

    -- Pupils (with slight animation)
    local eyeOffset = math.sin(time * 2) * 0.02
    setColor(0.1, 0.1, 0.15)
    love.graphics.circle("fill", x - size * 0.2 + eyeOffset * size, y - size * 0.65, size * 0.06)
    love.graphics.circle("fill", x + size * 0.2 + eyeOffset * size, y - size * 0.65, size * 0.06)

    -- Name tag with background
    local font = love.graphics.getFont()
    local nameWidth = font:getWidth(npc.name)
    local nameX = x - nameWidth / 2
    local nameY = y - size * 1.6

    -- Name background
    setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", nameX - 4, nameY - 2, nameWidth + 8, 16, 3, 3)

    -- Name text
    setColor(1, 1, 0.9)
    love.graphics.print(npc.name, nameX, nameY)
end

-- Draw detailed player sprite
local function drawPlayer(player, time)
    local x, y = player.x, player.y
    local size = player.size
    local dir = player.direction
    local moving = player.isMoving

    -- Animation
    local walkCycle = moving and math.sin(time * 10) or 0
    local bobY = moving and math.abs(walkCycle) * 2 or 0

    -- Shadow
    setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", x, y + size * 0.9, size * 0.7, size * 0.3)

    -- Legs (animated when moving)
    setColor(0.35, 0.30, 0.25) -- Dark pants
    if moving then
        local legOffset = walkCycle * size * 0.3
        love.graphics.rectangle("fill", x - size * 0.35, y + size * 0.2 - bobY, size * 0.25, size * 0.7 + legOffset * 0.5)
        love.graphics.rectangle("fill", x + size * 0.1, y + size * 0.2 - bobY, size * 0.25, size * 0.7 - legOffset * 0.5)
    else
        love.graphics.rectangle("fill", x - size * 0.35, y + size * 0.2, size * 0.25, size * 0.7)
        love.graphics.rectangle("fill", x + size * 0.1, y + size * 0.2, size * 0.25, size * 0.7)
    end

    -- Boots
    setColor(0.45, 0.35, 0.25)
    love.graphics.rectangle("fill", x - size * 0.4, y + size * 0.75, size * 0.35, size * 0.2)
    love.graphics.rectangle("fill", x + size * 0.05, y + size * 0.75, size * 0.35, size * 0.2)

    -- Body/tunic
    setColor(0.25, 0.45, 0.65) -- Blue tunic
    love.graphics.rectangle("fill", x - size * 0.45, y - size * 0.4 - bobY, size * 0.9, size * 0.7)

    -- Tunic shading
    setColor(0.18, 0.35, 0.52)
    love.graphics.rectangle("fill", x + size * 0.15, y - size * 0.4 - bobY, size * 0.3, size * 0.7)

    -- Belt
    setColor(0.55, 0.40, 0.25)
    love.graphics.rectangle("fill", x - size * 0.45, y + size * 0.15 - bobY, size * 0.9, size * 0.12)

    -- Belt buckle
    setColor(0.85, 0.75, 0.45)
    love.graphics.rectangle("fill", x - size * 0.1, y + size * 0.15 - bobY, size * 0.2, size * 0.12)

    -- Arms
    setColor(0.25, 0.45, 0.65)
    if dir == "left" then
        love.graphics.rectangle("fill", x - size * 0.65, y - size * 0.25 - bobY, size * 0.25, size * 0.5)
    elseif dir == "right" then
        love.graphics.rectangle("fill", x + size * 0.4, y - size * 0.25 - bobY, size * 0.25, size * 0.5)
    else
        love.graphics.rectangle("fill", x - size * 0.65, y - size * 0.25 - bobY, size * 0.2, size * 0.45)
        love.graphics.rectangle("fill", x + size * 0.45, y - size * 0.25 - bobY, size * 0.2, size * 0.45)
    end

    -- Hands
    setColor(0.92, 0.78, 0.62) -- Skin
    love.graphics.circle("fill", x - size * 0.55, y + size * 0.2 - bobY, size * 0.12)
    love.graphics.circle("fill", x + size * 0.55, y + size * 0.2 - bobY, size * 0.12)

    -- Head
    setColor(0.92, 0.78, 0.62)
    love.graphics.circle("fill", x, y - size * 0.65 - bobY, size * 0.45)

    -- Hair
    setColor(0.35, 0.25, 0.18)
    love.graphics.arc("fill", x, y - size * 0.75 - bobY, size * 0.45, math.pi * 1.1, math.pi * 1.9)
    -- Hair tuft
    love.graphics.polygon("fill",
        x - size * 0.1, y - size * 1.05 - bobY,
        x + size * 0.15, y - size * 1.15 - bobY,
        x + size * 0.1, y - size * 0.85 - bobY
    )

    -- Face based on direction
    if dir == "up" then
        -- Back of head (no face visible)
        setColor(0.35, 0.25, 0.18)
        love.graphics.arc("fill", x, y - size * 0.65 - bobY, size * 0.4, math.pi * 0.2, math.pi * 0.8)
    else
        -- Eyes
        local eyeOffsetX = 0
        if dir == "left" then eyeOffsetX = -size * 0.1
        elseif dir == "right" then eyeOffsetX = size * 0.1 end

        setColor(1, 1, 1)
        love.graphics.circle("fill", x - size * 0.18 + eyeOffsetX, y - size * 0.7 - bobY, size * 0.1)
        love.graphics.circle("fill", x + size * 0.18 + eyeOffsetX, y - size * 0.7 - bobY, size * 0.1)

        -- Pupils
        setColor(0.2, 0.35, 0.5)
        love.graphics.circle("fill", x - size * 0.16 + eyeOffsetX, y - size * 0.7 - bobY, size * 0.06)
        love.graphics.circle("fill", x + size * 0.2 + eyeOffsetX, y - size * 0.7 - bobY, size * 0.06)

        -- Eyebrows
        setColor(0.30, 0.22, 0.15)
        love.graphics.rectangle("fill", x - size * 0.28 + eyeOffsetX, y - size * 0.85 - bobY, size * 0.2, size * 0.06)
        love.graphics.rectangle("fill", x + size * 0.08 + eyeOffsetX, y - size * 0.85 - bobY, size * 0.2, size * 0.06)

        -- Mouth
        setColor(0.75, 0.55, 0.50)
        love.graphics.rectangle("fill", x - size * 0.1 + eyeOffsetX, y - size * 0.45 - bobY, size * 0.2, size * 0.06)
    end
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
    local time = love.timer.getTime()

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
                    local tx = (col - 1) * ts
                    local ty = (row - 1) * ts

                    if tile == "water" then
                        drawWaterTile(tx, ty, ts, time)
                    elseif tile == "grass" then
                        drawGrassTile(tx, ty, ts, col, row)
                    elseif tile == "path" then
                        drawPathTile(tx, ty, ts, col, row)
                    elseif tile == "building" then
                        drawBuildingTile(tx, ty, ts, col, row)
                    else -- market
                        drawMarketTile(tx, ty, ts, col, row)
                    end
                end
            end
        end
    else
        -- Fallback: draw a simple background if tiles aren't loaded
        setColor(0.3, 0.4, 0.3)
        love.graphics.rectangle("fill", 0, 0, self.town.width, self.town.height)
    end

    -- Draw NPCs (sorted by Y for depth)
    local sortedNPCs = {}
    for _, npc in ipairs(self.npcs) do
        if npc.x >= self.camera.x - npc.size * 2 and npc.x <= self.camera.x + screenW + npc.size * 2 and
           npc.y >= self.camera.y - npc.size * 2 and npc.y <= self.camera.y + screenH + npc.size * 2 then
            table.insert(sortedNPCs, npc)
        end
    end
    table.sort(sortedNPCs, function(a, b) return a.y < b.y end)

    -- Draw player and NPCs with proper depth sorting
    local playerDrawn = false
    for _, npc in ipairs(sortedNPCs) do
        if not playerDrawn and self.player.y < npc.y then
            drawPlayer(self.player, time)
            playerDrawn = true
        end
        drawNPC(npc, time)
    end
    if not playerDrawn then
        drawPlayer(self.player, time)
    end

    -- Draw cutscene actors
    if self.cutscene.active then
        for _, actor in pairs(self.cutscene.actors) do
            -- Draw cutscene actors as simple circles with glow
            setColor(actor.color[1] * 0.5, actor.color[2] * 0.5, actor.color[3] * 0.5, 0.3)
            love.graphics.circle("fill", actor.x, actor.y + actor.size * 0.8, actor.size * 1.2)

            setColor(actor.color[1], actor.color[2], actor.color[3])
            love.graphics.circle("fill", actor.x, actor.y, actor.size)
            setColor(actor.color[1] + 0.2, actor.color[2] + 0.2, actor.color[3] + 0.2)
            love.graphics.circle("fill", actor.x - actor.size * 0.3, actor.y - actor.size * 0.3, actor.size * 0.3)
        end
    end

    love.graphics.pop()

    -- Enhanced HUD
    self:drawHUD()

    -- Interaction prompt
    if self.interactionPrompt then
        self:drawInteractionPrompt()
    end

    -- Dialogue overlay
    if self.dialogue.active then
        self:drawDialogueOverlay()
    end
end

function Town:drawHUD()
    local screenW = love.graphics.getDimensions()

    -- HUD background panel
    setColor(0.08, 0.08, 0.15, 0.85)
    love.graphics.rectangle("fill", 5, 5, 400, 55, 6, 6)

    -- Panel border
    setColor(0.35, 0.32, 0.45)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 5, 5, 400, 55, 6, 6)

    -- Inner highlight
    setColor(0.45, 0.42, 0.55, 0.3)
    love.graphics.rectangle("line", 7, 7, 396, 51, 5, 5)

    -- Town name with icon
    setColor(0.65, 0.75, 0.95)
    love.graphics.print("Town:", 15, 12)
    setColor(1, 0.95, 0.85)
    love.graphics.print(self.hud.currentTown, 60, 12)

    -- Separator
    setColor(0.35, 0.32, 0.45)
    love.graphics.rectangle("fill", 150, 10, 2, 20)

    -- Player name and level
    setColor(0.65, 0.95, 0.75)
    love.graphics.print(self.hud.name, 165, 12)
    setColor(0.95, 0.85, 0.55)
    love.graphics.print("Lv." .. self.hud.level, 280, 12)

    -- Coordinates
    setColor(0.6, 0.6, 0.7)
    love.graphics.print(string.format("(%.0f, %.0f)", self.player.x, self.player.y), 330, 12)

    -- Controls hint
    setColor(0.5, 0.5, 0.6)
    love.graphics.print("WASD: Move  |  SPACE: Talk  |  ESC: World Map", 15, 38)
end

function Town:drawInteractionPrompt()
    local screenW, screenH = love.graphics.getDimensions()
    local prompt = self.interactionPrompt
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(prompt)

    local boxW = textWidth + 30
    local boxH = 32
    local boxX = (screenW - boxW) / 2
    local boxY = screenH - 100

    -- Pulsing effect
    local pulse = math.sin(love.timer.getTime() * 4) * 0.15 + 0.85

    -- Background
    setColor(0.1, 0.1, 0.2, 0.9 * pulse)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 8, 8)

    -- Border with glow
    setColor(0.85, 0.80, 0.45, pulse)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 8, 8)

    -- Text
    setColor(1, 1, 0.9, pulse)
    love.graphics.print(prompt, boxX + 15, boxY + 8)
end

function Town:drawDialogueOverlay()
    local screenW, screenH = love.graphics.getDimensions()
    local time = love.timer.getTime()

    -- Semi-transparent background with vignette effect
    setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Dialogue box dimensions
    local boxWidth = 700
    local boxHeight = 160
    local boxX = (screenW - boxWidth) / 2
    local boxY = screenH - boxHeight - 40

    -- Outer glow/shadow
    setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", boxX - 4, boxY - 4, boxWidth + 8, boxHeight + 8, 12, 12)

    -- Main box background with gradient effect
    setColor(0.08, 0.08, 0.18, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 8, 8)

    -- Inner panel (slightly lighter)
    setColor(0.12, 0.12, 0.22, 0.9)
    love.graphics.rectangle("fill", boxX + 4, boxY + 4, boxWidth - 8, boxHeight - 8, 6, 6)

    -- Decorative border
    love.graphics.setLineWidth(3)
    setColor(0.55, 0.50, 0.70)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 8, 8)

    -- Inner highlight border
    love.graphics.setLineWidth(1)
    setColor(0.70, 0.65, 0.85, 0.4)
    love.graphics.rectangle("line", boxX + 3, boxY + 3, boxWidth - 6, boxHeight - 6, 6, 6)

    -- Corner decorations
    local cornerSize = 12
    setColor(0.75, 0.70, 0.90)
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

    -- NPC name with background badge
    if self.dialogue.currentNPC then
        local npcName = self.dialogue.currentNPC.name
        local font = love.graphics.getFont()
        local nameWidth = font:getWidth(npcName)

        -- Name badge background
        setColor(0.25, 0.22, 0.35, 0.9)
        love.graphics.rectangle("fill", boxX + 15, boxY + 12, nameWidth + 20, 24, 4, 4)

        -- Name badge border
        setColor(0.65, 0.60, 0.80)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", boxX + 15, boxY + 12, nameWidth + 20, 24, 4, 4)

        -- Name text
        setColor(1, 0.95, 0.75)
        love.graphics.print(npcName, boxX + 25, boxY + 16)
    end

    -- Dialogue text with slight padding
    setColor(0.95, 0.95, 1)
    love.graphics.printf(self.dialogue.currentText, boxX + 25, boxY + 50, boxWidth - 50, "left")

    -- Continue prompt with animation
    if #self.dialogue.currentText >= #self.dialogue.fullText then
        local bounce = math.sin(time * 5) * 3

        -- Prompt background
        setColor(0.18, 0.18, 0.28, 0.8)
        love.graphics.rectangle("fill", boxX + boxWidth - 200, boxY + boxHeight - 35 + bounce, 180, 25, 4, 4)

        -- Prompt text
        setColor(0.95, 0.90, 0.55)
        love.graphics.print("SPACE to continue", boxX + boxWidth - 190, boxY + boxHeight - 31 + bounce)

        -- Arrow indicator
        setColor(0.95, 0.90, 0.55)
        love.graphics.polygon("fill",
            boxX + boxWidth - 25, boxY + boxHeight - 23 + bounce,
            boxX + boxWidth - 15, boxY + boxHeight - 23 + bounce,
            boxX + boxWidth - 20, boxY + boxHeight - 15 + bounce
        )
    else
        -- Typing indicator (animated dots)
        local dots = math.floor(time * 3) % 4
        setColor(0.6, 0.6, 0.7)
        for i = 1, dots do
            love.graphics.circle("fill", boxX + boxWidth - 40 + (i * 8), boxY + boxHeight - 20, 3)
        end
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
