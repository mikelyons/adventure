local Town = {}
local Color = require("color")
local GameClock = require("gameclock")

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
        apron = {0.92, 0.90, 0.85},
        hair = {{0.45, 0.32, 0.22}, {0.35, 0.25, 0.18}}
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

            Color.set(c[1] * brightness, c[2] * brightness, c[3] * brightness)
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

            Color.set(c[1], c[2], c[3])
            love.graphics.rectangle("fill", wx, wy, 1, 1)
        end
    end

    -- Add occasional flowers
    local flowerSeed = simpleNoise(col, row, 123)
    if flowerSeed > 0.7 then
        local flowerColor = pal.flower[math.floor(flowerSeed * 3) + 1]
        local fx = x + math.floor(flowerSeed * (ts - 4)) + 2
        local fy = y + math.floor(simpleNoise(col, row, 456) * (ts - 4)) + 2
        Color.set(flowerColor[1], flowerColor[2], flowerColor[3])
        love.graphics.rectangle("fill", fx, fy, 2, 2)
        Color.set(0.95, 0.92, 0.55) -- Yellow center
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
            Color.set(c[1], c[2], c[3])
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
        Color.set(stoneColor[1], stoneColor[2], stoneColor[3])
        love.graphics.rectangle("fill", stoneX, stoneY, stoneW, stoneH)

        -- Stone highlight
        Color.set(stoneColor[1] + 0.1, stoneColor[2] + 0.1, stoneColor[3] + 0.1)
        love.graphics.rectangle("fill", stoneX, stoneY, stoneW, 1)

        -- Stone shadow
        Color.set(stoneColor[1] - 0.1, stoneColor[2] - 0.1, stoneColor[3] - 0.1)
        love.graphics.rectangle("fill", stoneX, stoneY + stoneH - 1, stoneW, 1)
    end
end

-- Draw a road tile (main streets)
local function drawRoadTile(x, y, ts, col, row)
    local seed = col * 1000 + row

    -- Base road color (dark brown/gray)
    for py = 0, ts - 1 do
        for px = 0, ts - 1 do
            local wx = x + px
            local wy = y + py
            local noise = simpleNoise(wx, wy, seed)

            local base = 0.35 + noise * 0.08
            Color.set(base, base * 0.95, base * 0.85)
            love.graphics.rectangle("fill", wx, wy, 1, 1)
        end
    end

    -- Add cart wheel tracks
    local trackY1 = y + 6
    local trackY2 = y + ts - 8
    Color.set(0.28, 0.26, 0.24)
    love.graphics.rectangle("fill", x, trackY1, ts, 2)
    love.graphics.rectangle("fill", x, trackY2, ts, 2)
end

-- Draw a plaza tile (central market square)
local function drawPlazaTile(x, y, ts, col, row)
    local seed = col * 1000 + row

    -- Base sandstone color
    for py = 0, ts - 1 do
        for px = 0, ts - 1 do
            local wx = x + px
            local wy = y + py
            local noise = simpleNoise(wx, wy, seed)

            -- Checkered pattern for plaza stones
            local checker = ((math.floor(px / 8) + math.floor(py / 8)) % 2 == 0)
            local base = checker and 0.72 or 0.68
            base = base + noise * 0.05

            Color.set(base, base * 0.92, base * 0.78)
            love.graphics.rectangle("fill", wx, wy, 1, 1)
        end
    end

    -- Add stone borders
    Color.set(0.55, 0.50, 0.42)
    if col % 3 == 0 then
        love.graphics.rectangle("fill", x, y, 1, ts)
    end
    if row % 3 == 0 then
        love.graphics.rectangle("fill", x, y, ts, 1)
    end
end

-- Draw a cobblestone tile
local function drawCobbleTile(x, y, ts, col, row)
    local seed = col * 1000 + row

    -- Base gray
    Color.set(0.50, 0.48, 0.45)
    love.graphics.rectangle("fill", x, y, ts, ts)

    -- Draw individual cobblestones
    local stoneSize = 6
    for sy = 0, ts - stoneSize, stoneSize + 1 do
        for sx = 0, ts - stoneSize, stoneSize + 1 do
            local offset = (math.floor(sy / (stoneSize + 1)) % 2) * 3
            local stoneX = x + sx + offset
            local stoneY = y + sy

            local noise = simpleNoise(stoneX, stoneY, seed)
            local shade = 0.45 + noise * 0.15

            Color.set(shade, shade * 0.98, shade * 0.95)
            love.graphics.rectangle("fill", stoneX, stoneY, stoneSize, stoneSize)

            -- Highlight
            Color.set(shade + 0.1, shade + 0.08, shade + 0.05)
            love.graphics.rectangle("fill", stoneX, stoneY, stoneSize, 1)

            -- Shadow
            Color.set(shade - 0.1, shade - 0.1, shade - 0.08)
            love.graphics.rectangle("fill", stoneX, stoneY + stoneSize - 1, stoneSize, 1)
        end
    end
end

-- Draw a garden tile
local function drawGardenTile(x, y, ts, col, row)
    local seed = col * 1000 + row

    -- Draw grass base first
    drawGrassTile(x, y, ts, col, row)

    -- Add flowers
    local flowerColors = {
        {0.95, 0.45, 0.50},  -- Red
        {0.95, 0.85, 0.40},  -- Yellow
        {0.55, 0.45, 0.90},  -- Purple
        {0.95, 0.70, 0.80},  -- Pink
        {0.40, 0.70, 0.95},  -- Blue
    }

    for i = 1, 5 do
        local fx = x + math.floor(simpleNoise(col + i, row, seed) * (ts - 4)) + 2
        local fy = y + math.floor(simpleNoise(col, row + i, seed + 1) * (ts - 4)) + 2
        local colorIdx = math.floor(simpleNoise(col * i, row * i, seed + 2) * #flowerColors) + 1
        local flowerColor = flowerColors[colorIdx]

        -- Flower petals
        Color.set(flowerColor[1], flowerColor[2], flowerColor[3])
        love.graphics.rectangle("fill", fx - 1, fy, 3, 1)
        love.graphics.rectangle("fill", fx, fy - 1, 1, 3)

        -- Flower center
        Color.set(0.95, 0.90, 0.40)
        love.graphics.rectangle("fill", fx, fy, 1, 1)
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
            Color.set(c[1], c[2], c[3])
            love.graphics.rectangle("fill", wx, wy, 1, 1)
        end
    end

    -- Add occasional wood knot
    if simpleNoise(col, row, 111) > 0.85 then
        local kx = x + math.floor(simpleNoise(col, row, 222) * (ts - 6)) + 3
        local ky = y + math.floor(simpleNoise(col, row, 333) * (ts - 6)) + 3
        Color.set(pal.base[2][1] - 0.08, pal.base[2][2] - 0.05, pal.base[2][3] - 0.05)
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
            Color.set(c[1], c[2], c[3])
            love.graphics.rectangle("fill", wx, wy, 1, 1)
        end
    end

    -- Add market stall elements for some tiles
    if simpleNoise(col, row, 444) > 0.6 then
        local stallColor = pal.stall[math.floor(simpleNoise(col, row, 555) * 2) + 1]

        -- Draw awning stripe
        Color.set(stallColor[1], stallColor[2], stallColor[3])
        love.graphics.rectangle("fill", x + 2, y + 2, ts - 4, 4)

        -- Awning highlight
        Color.set(stallColor[1] + 0.15, stallColor[2] + 0.15, stallColor[3] + 0.15)
        love.graphics.rectangle("fill", x + 2, y + 2, ts - 4, 1)
    end

    -- Add goods crates for some tiles
    if simpleNoise(col, row, 666) > 0.75 then
        local cx = x + math.floor(simpleNoise(col, row, 777) * (ts - 8)) + 2
        local cy = y + 10
        Color.set(0.55, 0.42, 0.28) -- Crate color
        love.graphics.rectangle("fill", cx, cy, 6, 6)
        Color.set(0.45, 0.32, 0.20) -- Crate shadow
        love.graphics.rectangle("fill", cx, cy + 5, 6, 1)
        Color.set(0.65, 0.52, 0.38) -- Crate highlight
        love.graphics.rectangle("fill", cx, cy, 6, 1)
    end
end

-- Draw a detailed NPC sprite
local function drawNPC(npc, time)
    local x, y = npc.x, npc.y
    local size = npc.size or 20
    local moving = npc.isMoving
    local isSleeping = npc.isSleeping

    -- Determine NPC appearance based on type
    local tunicColor, tunicShadow, pantsColor, hairColor, skinColor
    local npcType = npc.type or "villager"

    if npcType == "merchant" or npc.name:find("Merchant") then
        tunicColor = {0.65, 0.50, 0.25}      -- Brown merchant clothes
        tunicShadow = {0.50, 0.38, 0.18}
        pantsColor = {0.40, 0.35, 0.30}
        hairColor = {0.35, 0.25, 0.18}
    elseif npcType == "blacksmith" or npc.name:find("Smith") then
        tunicColor = {0.45, 0.42, 0.40}      -- Gray work clothes
        tunicShadow = {0.35, 0.32, 0.30}
        pantsColor = {0.30, 0.28, 0.26}
        hairColor = {0.20, 0.18, 0.15}
    elseif npcType == "innkeeper" or npc.name:find("Inn") then
        tunicColor = {0.55, 0.35, 0.35}      -- Red-brown innkeeper
        tunicShadow = {0.42, 0.25, 0.25}
        pantsColor = {0.35, 0.30, 0.28}
        hairColor = {0.55, 0.35, 0.20}
    elseif npc.name:find("Elder") then
        tunicColor = {0.50, 0.45, 0.60}      -- Purple elder robes
        tunicShadow = {0.38, 0.33, 0.48}
        pantsColor = {0.35, 0.32, 0.40}
        hairColor = {0.75, 0.72, 0.70}       -- Gray hair
    elseif npc.name:find("Guard") then
        tunicColor = {0.50, 0.52, 0.58}      -- Guard armor
        tunicShadow = {0.38, 0.40, 0.45}
        pantsColor = {0.35, 0.35, 0.38}
        hairColor = {0.30, 0.25, 0.20}
    else
        -- Villager - varied colors based on position
        local colorSeed = (npc.homeX or npc.x) + (npc.homeY or npc.y) * 100
        local hueVariation = simpleNoise(colorSeed, 0, 12345) * 0.3
        tunicColor = {0.45 + hueVariation, 0.50, 0.55 - hueVariation}
        tunicShadow = {0.33 + hueVariation, 0.38, 0.42 - hueVariation}
        pantsColor = {0.35, 0.32, 0.30}
        local hairSeed = simpleNoise(colorSeed, 1, 54321)
        if hairSeed < 0.3 then
            hairColor = {0.25, 0.20, 0.15}   -- Dark brown
        elseif hairSeed < 0.6 then
            hairColor = {0.55, 0.40, 0.25}   -- Light brown
        else
            hairColor = {0.70, 0.55, 0.35}   -- Blonde
        end
    end
    skinColor = {0.92, 0.78, 0.62}

    -- Animation
    local walkCycle = moving and math.sin(time * 8) or 0
    local bobY = moving and math.abs(walkCycle) * 2 or 0

    -- If sleeping, draw lying down indicator
    if isSleeping then
        Color.set(0, 0, 0, 0.2)
        love.graphics.ellipse("fill", x, y, size * 1.2, size * 0.4)
        -- Draw "Zzz"
        Color.set(0.8, 0.8, 1.0, 0.7)
        love.graphics.print("z", x + size * 0.3, y - size * 0.8 + math.sin(time * 2) * 3)
        love.graphics.print("z", x + size * 0.5, y - size * 1.0 + math.sin(time * 2 + 0.5) * 3)
        return
    end

    -- Shadow
    Color.set(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", x, y + size * 0.9, size * 0.7, size * 0.3)

    -- Legs (animated when moving)
    Color.set(pantsColor[1], pantsColor[2], pantsColor[3])
    if moving then
        local legOffset = walkCycle * size * 0.3
        love.graphics.rectangle("fill", x - size * 0.35, y + size * 0.2 - bobY, size * 0.25, size * 0.7 + legOffset * 0.5)
        love.graphics.rectangle("fill", x + size * 0.1, y + size * 0.2 - bobY, size * 0.25, size * 0.7 - legOffset * 0.5)
    else
        love.graphics.rectangle("fill", x - size * 0.35, y + size * 0.2, size * 0.25, size * 0.7)
        love.graphics.rectangle("fill", x + size * 0.1, y + size * 0.2, size * 0.25, size * 0.7)
    end

    -- Boots
    Color.set(0.40, 0.32, 0.25)
    love.graphics.rectangle("fill", x - size * 0.4, y + size * 0.75, size * 0.35, size * 0.2)
    love.graphics.rectangle("fill", x + size * 0.05, y + size * 0.75, size * 0.35, size * 0.2)

    -- Body/tunic
    Color.set(tunicColor[1], tunicColor[2], tunicColor[3])
    love.graphics.rectangle("fill", x - size * 0.45, y - size * 0.4 - bobY, size * 0.9, size * 0.7)

    -- Tunic shading
    Color.set(tunicShadow[1], tunicShadow[2], tunicShadow[3])
    love.graphics.rectangle("fill", x + size * 0.15, y - size * 0.4 - bobY, size * 0.3, size * 0.7)

    -- Belt
    Color.set(0.45, 0.35, 0.25)
    love.graphics.rectangle("fill", x - size * 0.45, y + size * 0.15 - bobY, size * 0.9, size * 0.1)

    -- Arms
    Color.set(tunicColor[1], tunicColor[2], tunicColor[3])
    love.graphics.rectangle("fill", x - size * 0.6, y - size * 0.25 - bobY, size * 0.18, size * 0.4)
    love.graphics.rectangle("fill", x + size * 0.42, y - size * 0.25 - bobY, size * 0.18, size * 0.4)

    -- Hands
    Color.set(skinColor[1], skinColor[2], skinColor[3])
    love.graphics.circle("fill", x - size * 0.52, y + size * 0.15 - bobY, size * 0.1)
    love.graphics.circle("fill", x + size * 0.52, y + size * 0.15 - bobY, size * 0.1)

    -- Head
    Color.set(skinColor[1], skinColor[2], skinColor[3])
    love.graphics.ellipse("fill", x, y - size * 0.65 - bobY, size * 0.38, size * 0.42)

    -- Hair
    Color.set(hairColor[1], hairColor[2], hairColor[3])
    love.graphics.arc("fill", x, y - size * 0.72 - bobY, size * 0.4, math.pi * 1.0, math.pi * 2.0)
    -- Hair sides
    love.graphics.rectangle("fill", x - size * 0.4, y - size * 0.75 - bobY, size * 0.12, size * 0.25)
    love.graphics.rectangle("fill", x + size * 0.28, y - size * 0.75 - bobY, size * 0.12, size * 0.25)

    -- Eyes
    Color.set(1, 1, 1)
    love.graphics.circle("fill", x - size * 0.15, y - size * 0.68 - bobY, size * 0.1)
    love.graphics.circle("fill", x + size * 0.15, y - size * 0.68 - bobY, size * 0.1)

    -- Pupils
    local eyeOffset = math.sin(time * 1.5) * 0.02
    Color.set(0.15, 0.12, 0.10)
    love.graphics.circle("fill", x - size * 0.15 + eyeOffset * size, y - size * 0.68 - bobY, size * 0.05)
    love.graphics.circle("fill", x + size * 0.15 + eyeOffset * size, y - size * 0.68 - bobY, size * 0.05)

    -- Name tag with background
    local font = love.graphics.getFont()
    local nameWidth = font:getWidth(npc.name)
    local nameX = x - nameWidth / 2
    local nameY = y - size * 1.5 - bobY

    -- Name background
    Color.set(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", nameX - 4, nameY - 2, nameWidth + 8, 16, 3, 3)

    -- Name text
    Color.set(1, 1, 0.9)
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
    Color.set(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", x, y + size * 0.9, size * 0.7, size * 0.3)

    -- Legs (animated when moving)
    Color.set(0.35, 0.30, 0.25) -- Dark pants
    if moving then
        local legOffset = walkCycle * size * 0.3
        love.graphics.rectangle("fill", x - size * 0.35, y + size * 0.2 - bobY, size * 0.25, size * 0.7 + legOffset * 0.5)
        love.graphics.rectangle("fill", x + size * 0.1, y + size * 0.2 - bobY, size * 0.25, size * 0.7 - legOffset * 0.5)
    else
        love.graphics.rectangle("fill", x - size * 0.35, y + size * 0.2, size * 0.25, size * 0.7)
        love.graphics.rectangle("fill", x + size * 0.1, y + size * 0.2, size * 0.25, size * 0.7)
    end

    -- Boots
    Color.set(0.45, 0.35, 0.25)
    love.graphics.rectangle("fill", x - size * 0.4, y + size * 0.75, size * 0.35, size * 0.2)
    love.graphics.rectangle("fill", x + size * 0.05, y + size * 0.75, size * 0.35, size * 0.2)

    -- Body/tunic
    Color.set(0.25, 0.45, 0.65) -- Blue tunic
    love.graphics.rectangle("fill", x - size * 0.45, y - size * 0.4 - bobY, size * 0.9, size * 0.7)

    -- Tunic shading
    Color.set(0.18, 0.35, 0.52)
    love.graphics.rectangle("fill", x + size * 0.15, y - size * 0.4 - bobY, size * 0.3, size * 0.7)

    -- Belt
    Color.set(0.55, 0.40, 0.25)
    love.graphics.rectangle("fill", x - size * 0.45, y + size * 0.15 - bobY, size * 0.9, size * 0.12)

    -- Belt buckle
    Color.set(0.85, 0.75, 0.45)
    love.graphics.rectangle("fill", x - size * 0.1, y + size * 0.15 - bobY, size * 0.2, size * 0.12)

    -- Arms
    Color.set(0.25, 0.45, 0.65)
    if dir == "left" then
        love.graphics.rectangle("fill", x - size * 0.65, y - size * 0.25 - bobY, size * 0.25, size * 0.5)
    elseif dir == "right" then
        love.graphics.rectangle("fill", x + size * 0.4, y - size * 0.25 - bobY, size * 0.25, size * 0.5)
    else
        love.graphics.rectangle("fill", x - size * 0.65, y - size * 0.25 - bobY, size * 0.2, size * 0.45)
        love.graphics.rectangle("fill", x + size * 0.45, y - size * 0.25 - bobY, size * 0.2, size * 0.45)
    end

    -- Hands
    Color.set(0.92, 0.78, 0.62) -- Skin
    love.graphics.circle("fill", x - size * 0.55, y + size * 0.2 - bobY, size * 0.12)
    love.graphics.circle("fill", x + size * 0.55, y + size * 0.2 - bobY, size * 0.12)

    -- Head
    Color.set(0.92, 0.78, 0.62)
    love.graphics.circle("fill", x, y - size * 0.65 - bobY, size * 0.45)

    -- Hair
    Color.set(0.35, 0.25, 0.18)
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
        Color.set(0.35, 0.25, 0.18)
        love.graphics.arc("fill", x, y - size * 0.65 - bobY, size * 0.4, math.pi * 0.2, math.pi * 0.8)
    else
        -- Eyes
        local eyeOffsetX = 0
        if dir == "left" then eyeOffsetX = -size * 0.1
        elseif dir == "right" then eyeOffsetX = size * 0.1 end

        Color.set(1, 1, 1)
        love.graphics.circle("fill", x - size * 0.18 + eyeOffsetX, y - size * 0.7 - bobY, size * 0.1)
        love.graphics.circle("fill", x + size * 0.18 + eyeOffsetX, y - size * 0.7 - bobY, size * 0.1)

        -- Pupils
        Color.set(0.2, 0.35, 0.5)
        love.graphics.circle("fill", x - size * 0.16 + eyeOffsetX, y - size * 0.7 - bobY, size * 0.06)
        love.graphics.circle("fill", x + size * 0.2 + eyeOffsetX, y - size * 0.7 - bobY, size * 0.06)

        -- Eyebrows
        Color.set(0.30, 0.22, 0.15)
        love.graphics.rectangle("fill", x - size * 0.28 + eyeOffsetX, y - size * 0.85 - bobY, size * 0.2, size * 0.06)
        love.graphics.rectangle("fill", x + size * 0.08 + eyeOffsetX, y - size * 0.85 - bobY, size * 0.2, size * 0.06)

        -- Mouth
        Color.set(0.75, 0.55, 0.50)
        love.graphics.rectangle("fill", x - size * 0.1 + eyeOffsetX, y - size * 0.45 - bobY, size * 0.2, size * 0.06)
    end
end

function Town:load()
    -- Player state with velocity for smooth movement
    self.player = {
        x = 400,
        y = 300,
        vx = 0,              -- velocity x
        vy = 0,              -- velocity y
        maxSpeed = 180,      -- max movement speed
        accel = 1200,        -- acceleration (pixels/sec^2)
        friction = 800,      -- deceleration when not moving
        size = 12,
        direction = "down",  -- down, up, left, right
        isMoving = false,
        animTimer = 0,       -- for walk animation
        animFrame = 0
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

    -- Buildings with entrances (Metroid-style interiors)
    self.buildings = {}
    self.nearbyBuilding = nil

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
    -- Set controls panel mode
    if ControlsPanel then ControlsPanel:setMode("town") end

    -- Reset velocity for clean movement state
    self.player.vx = 0
    self.player.vy = 0
    self.player.animTimer = 0
    self.player.animFrame = 0

    if self.saveData then
        self.hud.name = self.saveData.characterName or ""
        self.hud.level = self.saveData.level or 1

        -- Load player position if available
        if self.saveData.townPlayerX and self.saveData.townPlayerY then
            self.player.x = self.saveData.townPlayerX
            self.player.y = self.saveData.townPlayerY
        end
    end

    if self.townData then
        -- Set town name from townData
        self.hud.currentTown = self.townData.name or "Rivertown"

        -- Load town data
        self:loadTownFromData()

        -- Check if this is the first time entering the town
        if self.saveData and not self.saveData.townVisited then
            self:startWelcomeCutscene()
        end
    else
        -- Fallback: generate default town if no data available
        self.hud.name = self.hud.name or "Adventurer"
        self.hud.level = self.hud.level or 1
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
    local cols, rows = self.town.cols, self.town.rows

    -- Initialize all tiles as grass
    for row = 1, rows do
        self.tiles[row] = {}
        for col = 1, cols do
            self.tiles[row][col] = "grass"
        end
    end

    -- Town center
    local centerCol = math.floor(cols / 2)
    local centerRow = math.floor(rows / 2)

    -- Create central plaza (market square)
    local plazaSize = 8
    for dr = -plazaSize, plazaSize do
        for dc = -plazaSize, plazaSize do
            local r, c = centerRow + dr, centerCol + dc
            if r >= 1 and r <= rows and c >= 1 and c <= cols then
                self.tiles[r][c] = "plaza"
            end
        end
    end

    -- Create main streets (cross pattern from center)
    local streetWidth = 3

    -- Horizontal main street
    for col = 1, cols do
        for dr = -math.floor(streetWidth/2), math.floor(streetWidth/2) do
            local r = centerRow + dr
            if r >= 1 and r <= rows then
                self.tiles[r][col] = "road"
            end
        end
    end

    -- Vertical main street
    for row = 1, rows do
        for dc = -math.floor(streetWidth/2), math.floor(streetWidth/2) do
            local c = centerCol + dc
            if c >= 1 and c <= cols then
                self.tiles[row][c] = "road"
            end
        end
    end

    -- Create secondary streets (parallel to main streets)
    local streetSpacing = 15
    local secondaryWidth = 2

    -- Horizontal secondary streets
    for offset = -2, 2 do
        if offset ~= 0 then
            local streetRow = centerRow + offset * streetSpacing
            if streetRow >= 5 and streetRow <= rows - 5 then
                for col = 5, cols - 5 do
                    for dr = 0, secondaryWidth - 1 do
                        local r = streetRow + dr
                        if r >= 1 and r <= rows then
                            if self.tiles[r][col] == "grass" then
                                self.tiles[r][col] = "road"
                            end
                        end
                    end
                end
            end
        end
    end

    -- Vertical secondary streets
    for offset = -2, 2 do
        if offset ~= 0 then
            local streetCol = centerCol + offset * streetSpacing
            if streetCol >= 5 and streetCol <= cols - 5 then
                for row = 5, rows - 5 do
                    for dc = 0, secondaryWidth - 1 do
                        local c = streetCol + dc
                        if c >= 1 and c <= cols then
                            if self.tiles[row][c] == "grass" then
                                self.tiles[row][c] = "road"
                            end
                        end
                    end
                end
            end
        end
    end

    -- Add some decorative elements around plaza
    for dr = -plazaSize - 1, plazaSize + 1 do
        for dc = -plazaSize - 1, plazaSize + 1 do
            local r, c = centerRow + dr, centerCol + dc
            if r >= 1 and r <= rows and c >= 1 and c <= cols then
                if self.tiles[r][c] == "grass" then
                    -- Edge of plaza gets cobblestone
                    local distFromCenter = math.max(math.abs(dr), math.abs(dc))
                    if distFromCenter == plazaSize + 1 then
                        self.tiles[r][c] = "cobble"
                    end
                end
            end
        end
    end

    -- Add a fountain in center of plaza
    self.fountain = {
        x = centerCol * self.town.tileSize,
        y = centerRow * self.town.tileSize,
        radius = self.town.tileSize * 2
    }

    -- Generate buildings along streets
    self:generateBuildings()

    -- Add some grass patches and gardens
    self:addGardens()

    print("Generated town tiles: " .. cols .. "x" .. rows)
end

function Town:addGardens()
    local cols, rows = self.town.cols, self.town.rows

    -- Add random garden patches in grass areas
    for i = 1, 20 do
        local col = math.random(5, cols - 5)
        local row = math.random(5, rows - 5)

        -- Check if area is suitable (all grass)
        local suitable = true
        for dr = -1, 1 do
            for dc = -1, 1 do
                local r, c = row + dr, col + dc
                if r >= 1 and r <= rows and c >= 1 and c <= cols then
                    if self.tiles[r][c] ~= "grass" then
                        suitable = false
                    end
                end
            end
        end

        if suitable then
            self.tiles[row][col] = "garden"
        end
    end
end

function Town:generateBuildings()
    self.buildings = {}
    local ts = self.town.tileSize
    local cols, rows = self.town.cols, self.town.rows
    local centerCol = math.floor(cols / 2)
    local centerRow = math.floor(rows / 2)

    -- Building types with their properties
    local commercialBuildings = {
        {type = "inn", name = "The Weary Traveler Inn", width = 6, height = 5, color = {0.55, 0.35, 0.25}},
        {type = "shop", name = "General Store", width = 5, height = 4, color = {0.50, 0.45, 0.35}},
        {type = "tavern", name = "The Golden Mug", width = 6, height = 4, color = {0.45, 0.30, 0.25}},
        {type = "blacksmith", name = "Ironforge Smithy", width = 5, height = 5, color = {0.40, 0.38, 0.42}},
    }

    local residentialBuildings = {
        {type = "house", name = "House", width = 4, height = 4, color = {0.50, 0.42, 0.35}},
        {type = "house", name = "Cottage", width = 3, height = 3, color = {0.55, 0.48, 0.38}},
        {type = "house", name = "Dwelling", width = 4, height = 3, color = {0.48, 0.40, 0.32}},
    }

    -- Place commercial buildings around the plaza
    local plazaPositions = {
        {col = centerCol - 15, row = centerRow - 12, facing = "south"},
        {col = centerCol + 10, row = centerRow - 12, facing = "south"},
        {col = centerCol - 15, row = centerRow + 10, facing = "north"},
        {col = centerCol + 10, row = centerRow + 10, facing = "north"},
    }

    for i, pos in ipairs(plazaPositions) do
        if i <= #commercialBuildings then
            local bldg = commercialBuildings[i]
            self:placeBuilding(pos.col, pos.row, bldg, pos.facing)
        end
    end

    -- Place residential buildings along secondary streets
    local residentialPositions = {}

    -- Along secondary horizontal streets
    for offset = -2, 2 do
        if offset ~= 0 then
            local streetRow = centerRow + offset * 15
            if streetRow >= 10 and streetRow <= rows - 10 then
                -- Buildings on both sides of street
                for colOffset = -30, 30, 12 do
                    local col = centerCol + colOffset
                    if col >= 8 and col <= cols - 12 then
                        -- Above street
                        table.insert(residentialPositions, {col = col, row = streetRow - 6, facing = "south"})
                        -- Below street
                        table.insert(residentialPositions, {col = col, row = streetRow + 4, facing = "north"})
                    end
                end
            end
        end
    end

    -- Place residential buildings
    local houseIndex = 1
    for i, pos in ipairs(residentialPositions) do
        if self:canPlaceBuilding(pos.col, pos.row, 4, 4) then
            local bldg = residentialBuildings[((houseIndex - 1) % #residentialBuildings) + 1]
            local building = self:placeBuilding(pos.col, pos.row, bldg, pos.facing)
            if building then
                houseIndex = houseIndex + 1
            end
        end
    end

    print("Placed " .. #self.buildings .. " buildings")
end

function Town:canPlaceBuilding(col, row, width, height)
    local cols, rows = self.town.cols, self.town.rows

    -- Check bounds
    if col < 3 or col + width > cols - 3 or row < 3 or row + height > rows - 3 then
        return false
    end

    -- Check if area is grass (not on roads/plaza)
    for r = row, row + height - 1 do
        for c = col, col + width - 1 do
            local tile = self.tiles[r] and self.tiles[r][c]
            if tile ~= "grass" and tile ~= "garden" then
                return false
            end
        end
    end

    -- Check for overlap with existing buildings (with margin)
    local ts = self.town.tileSize
    for _, existing in ipairs(self.buildings) do
        local newX = col * ts
        local newY = row * ts
        local newW = width * ts
        local newH = height * ts
        local margin = ts * 2

        if newX < existing.x + existing.width + margin and
           newX + newW + margin > existing.x and
           newY < existing.y + existing.height + margin and
           newY + newH + margin > existing.y then
            return false
        end
    end

    return true
end

function Town:placeBuilding(col, row, bldgDef, facing)
    local ts = self.town.tileSize

    if not self:canPlaceBuilding(col, row, bldgDef.width, bldgDef.height) then
        return nil
    end

    -- Calculate door position based on facing
    local doorCol, doorRow
    if facing == "south" then
        doorCol = col + math.floor(bldgDef.width / 2)
        doorRow = row + bldgDef.height
    elseif facing == "north" then
        doorCol = col + math.floor(bldgDef.width / 2)
        doorRow = row - 1
    elseif facing == "east" then
        doorCol = col + bldgDef.width
        doorRow = row + math.floor(bldgDef.height / 2)
    else -- west
        doorCol = col - 1
        doorRow = row + math.floor(bldgDef.height / 2)
    end

    local building = {
        x = col * ts,
        y = row * ts,
        width = bldgDef.width * ts,
        height = bldgDef.height * ts,
        type = bldgDef.type,
        name = bldgDef.name,
        color = bldgDef.color or {0.50, 0.40, 0.30},
        doorX = doorCol * ts,
        doorY = doorRow * ts,
        facing = facing,
        col = col,
        row = row,
        gridWidth = bldgDef.width,
        gridHeight = bldgDef.height
    }

    table.insert(self.buildings, building)

    -- Mark tiles as building footprint
    for r = row, row + bldgDef.height - 1 do
        for c = col, col + bldgDef.width - 1 do
            self.tiles[r][c] = "building_floor"
        end
    end

    -- Create path from door to nearest road
    self:createPathToRoad(doorCol, doorRow)

    return building
end

function Town:createPathToRoad(startCol, startRow)
    local cols, rows = self.town.cols, self.town.rows

    -- Simple path finding to nearest road
    local directions = {{0, 1}, {0, -1}, {1, 0}, {-1, 0}}
    local col, row = startCol, startRow

    for step = 1, 10 do
        if row < 1 or row > rows or col < 1 or col > cols then break end

        local tile = self.tiles[row] and self.tiles[row][col]
        if tile == "road" or tile == "plaza" then
            break
        end

        if tile == "grass" or tile == "garden" then
            self.tiles[row][col] = "path"
        end

        -- Move towards center (where roads are)
        local centerCol = math.floor(cols / 2)
        local centerRow = math.floor(rows / 2)

        if math.abs(col - centerCol) > math.abs(row - centerRow) then
            col = col + (centerCol > col and 1 or -1)
        else
            row = row + (centerRow > row and 1 or -1)
        end
    end
end

function Town:loadNPCs()
    self.npcs = {}
    if self.townData and self.townData.npcs then
        for _, npcData in ipairs(self.townData.npcs) do
            if npcData and npcData.name then
                -- Calculate positions based on buildings
                local homeX = npcData.homeX or npcData.x or 400
                local homeY = npcData.homeY or npcData.y or 300

                -- Find work location based on NPC type
                local workX, workY = homeX, homeY
                local marketX, marketY = self.town.width / 2, self.town.height / 2
                local tavernX, tavernY = self.town.width / 3, self.town.height / 3

                -- Assign work locations based on buildings if available
                if self.buildings then
                    for _, building in ipairs(self.buildings) do
                        if npcData.type == "merchant" and building.type == "shop" then
                            workX = building.x + building.width / 2
                            workY = building.y + building.height / 2
                        elseif npcData.type == "blacksmith" and building.type == "blacksmith" then
                            workX = building.x + building.width / 2
                            workY = building.y + building.height / 2
                        elseif npcData.type == "innkeeper" and building.type == "inn" then
                            workX = building.x + building.width / 2
                            workY = building.y + building.height / 2
                        elseif building.type == "market" then
                            marketX = building.x + building.width / 2
                            marketY = building.y + building.height / 2
                        elseif building.type == "tavern" then
                            tavernX = building.x + building.width / 2
                            tavernY = building.y + building.height / 2
                        end
                    end
                end

                local npc = {
                    x = homeX,
                    y = homeY,
                    name = npcData.name,
                    type = npcData.type or "villager",
                    size = npcData.size or 10,
                    color = npcData.color or {0.8, 0.6, 0.4},
                    dialogue = npcData.dialogue or {},
                    schedule = npcData.schedule or {},
                    currentDialogue = 1,
                    lastTalked = 0,
                    isMoving = false,
                    isSleeping = false,
                    targetX = homeX,
                    targetY = homeY,
                    homeX = homeX,
                    homeY = homeY,
                    workX = workX,
                    workY = workY,
                    marketX = marketX,
                    marketY = marketY,
                    tavernX = tavernX,
                    tavernY = tavernY,
                    speed = npcData.speed or 40
                }
                table.insert(self.npcs, npc)
            end
        end
    end

    -- Create default NPCs if none loaded
    if #self.npcs == 0 then
        self:createDefaultNPCs()
    end

    print("Loaded " .. #self.npcs .. " NPCs")
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
    -- Update game clock
    GameClock:update(dt)

    if self.cutscene.active then
        self:updateCutscene(dt)
        return
    end

    if self.dialogue.active then
        self:updateDialogue(dt)
        return
    end

    -- Player movement with smooth acceleration (Zelda-like)
    local inputX, inputY = 0, 0
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        inputX = inputX - 1
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        inputX = inputX + 1
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        inputY = inputY - 1
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        inputY = inputY + 1
    end

    -- Normalize diagonal input
    local inputLen = math.sqrt(inputX * inputX + inputY * inputY)
    if inputLen > 0 then
        inputX, inputY = inputX / inputLen, inputY / inputLen
    end

    local hasInput = (inputX ~= 0 or inputY ~= 0)

    if hasInput then
        -- Apply acceleration in input direction
        self.player.vx = self.player.vx + inputX * self.player.accel * dt
        self.player.vy = self.player.vy + inputY * self.player.accel * dt

        -- Update facing direction based on strongest input
        if math.abs(inputX) > math.abs(inputY) then
            self.player.direction = inputX > 0 and "right" or "left"
        else
            self.player.direction = inputY > 0 and "down" or "up"
        end
    else
        -- Apply friction when no input (smooth deceleration)
        local speed = math.sqrt(self.player.vx * self.player.vx + self.player.vy * self.player.vy)
        if speed > 0 then
            local frictionForce = self.player.friction * dt
            if frictionForce >= speed then
                -- Stop completely
                self.player.vx = 0
                self.player.vy = 0
            else
                -- Reduce velocity proportionally
                local ratio = (speed - frictionForce) / speed
                self.player.vx = self.player.vx * ratio
                self.player.vy = self.player.vy * ratio
            end
        end
    end

    -- Clamp to max speed
    local speed = math.sqrt(self.player.vx * self.player.vx + self.player.vy * self.player.vy)
    if speed > self.player.maxSpeed then
        local ratio = self.player.maxSpeed / speed
        self.player.vx = self.player.vx * ratio
        self.player.vy = self.player.vy * ratio
    end

    -- Apply velocity to position
    self.player.x = self.player.x + self.player.vx * dt
    self.player.y = self.player.y + self.player.vy * dt

    -- Update movement state (for animations)
    self.player.isMoving = (math.abs(self.player.vx) > 5 or math.abs(self.player.vy) > 5)

    -- Update animation timer
    if self.player.isMoving then
        self.player.animTimer = self.player.animTimer + dt * 8
        self.player.animFrame = math.floor(self.player.animTimer) % 4
    else
        self.player.animTimer = 0
        self.player.animFrame = 0
    end

    -- Clamp player to town bounds
    local half = self.player.size / 2
    self.player.x = clamp(self.player.x, half, self.town.width - half)
    self.player.y = clamp(self.player.y, half, self.town.height - half)

    -- Stop velocity at bounds
    if self.player.x <= half or self.player.x >= self.town.width - half then
        self.player.vx = 0
    end
    if self.player.y <= half or self.player.y >= self.town.height - half then
        self.player.vy = 0
    end

    -- Update NPCs
    self:updateNPCs(dt)

    -- Check for NPC interactions
    self:checkNPCInteractions()

    -- Check for building interactions
    self:checkBuildingInteractions()

    -- Camera follows player with smooth lerp
    local screenW, screenH = love.graphics.getDimensions()
    local targetCamX = clamp(self.player.x - screenW / 2, 0, math.max(0, self.town.width - screenW))
    local targetCamY = clamp(self.player.y - screenH / 2, 0, math.max(0, self.town.height - screenH))

    -- Smooth camera interpolation (lerp)
    local camSpeed = 6  -- Higher = snappier camera, lower = smoother follow
    self.camera.x = self.camera.x + (targetCamX - self.camera.x) * camSpeed * dt
    self.camera.y = self.camera.y + (targetCamY - self.camera.y) * camSpeed * dt

    -- Snap to target if very close (prevents jittering)
    if math.abs(self.camera.x - targetCamX) < 0.5 then self.camera.x = targetCamX end
    if math.abs(self.camera.y - targetCamY) < 0.5 then self.camera.y = targetCamY end
end

function Town:updateNPCs(dt)
    for _, npc in ipairs(self.npcs) do
        -- Check NPC schedule based on game clock
        if npc.schedule and #npc.schedule > 0 then
            local location, isSleeping = GameClock:getNPCLocation(npc)

            -- Get target position based on schedule location
            local targetX, targetY = npc.homeX or npc.x, npc.homeY or npc.y

            if location == "home" then
                targetX = npc.homeX or npc.x
                targetY = npc.homeY or npc.y
            elseif location == "work" then
                targetX = npc.workX or npc.x
                targetY = npc.workY or npc.y
            elseif location == "market" then
                -- Find market area
                targetX = npc.marketX or (self.town.width / 2 + math.random(-100, 100))
                targetY = npc.marketY or (self.town.height / 2 + math.random(-100, 100))
            elseif location == "tavern" then
                targetX = npc.tavernX or (self.town.width / 3 + math.random(-50, 50))
                targetY = npc.tavernY or (self.town.height / 3 + math.random(-50, 50))
            elseif location == "roam" then
                -- Random wandering if not currently moving
                if not npc.isMoving and math.random() < 0.01 then
                    targetX = npc.x + math.random(-100, 100)
                    targetY = npc.y + math.random(-100, 100)
                    -- Clamp to town bounds
                    targetX = math.max(50, math.min(self.town.width - 50, targetX))
                    targetY = math.max(50, math.min(self.town.height - 50, targetY))
                end
            end

            -- If sleeping, NPC doesn't move
            if isSleeping then
                npc.isMoving = false
                npc.isSleeping = true
            else
                npc.isSleeping = false
                -- Set target if changed
                if math.abs(targetX - npc.targetX) > 5 or math.abs(targetY - npc.targetY) > 5 then
                    npc.targetX = targetX
                    npc.targetY = targetY
                    npc.isMoving = true
                end
            end
        end

        -- Move NPC towards target
        if npc.isMoving and not npc.isSleeping then
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

function Town:checkBuildingInteractions()
    if not self.buildings then return end

    for _, building in ipairs(self.buildings) do
        -- Check distance to door
        local doorCenterX = building.doorX + self.town.tileSize / 2
        local doorCenterY = building.doorY + self.town.tileSize / 2

        local dx = self.player.x - doorCenterX
        local dy = self.player.y - doorCenterY
        local distance = math.sqrt(dx * dx + dy * dy)

        local interactionDistance = self.player.size + self.town.tileSize

        if distance <= interactionDistance then
            self.interactionPrompt = "Press SPACE to enter " .. building.name
            self.nearbyBuilding = building
            return
        end
    end

    self.nearbyBuilding = nil
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

function Town:drawFountain(time)
    local f = self.fountain
    if not f then return end

    local x, y = f.x, f.y
    local radius = f.radius

    -- Fountain base (stone circle)
    Color.set(0.45, 0.42, 0.40)
    love.graphics.circle("fill", x, y, radius + 8)

    -- Inner rim
    Color.set(0.55, 0.52, 0.48)
    love.graphics.circle("fill", x, y, radius + 4)

    -- Water pool
    local waterPulse = math.sin(time * 2) * 0.05 + 0.95
    Color.set(0.30 * waterPulse, 0.50 * waterPulse, 0.70 * waterPulse, 0.8)
    love.graphics.circle("fill", x, y, radius)

    -- Water ripples
    for i = 1, 3 do
        local rippleRadius = (radius * 0.3) + (((time * 30 + i * 20) % 60) / 60) * radius * 0.6
        local alpha = 1 - (rippleRadius / radius)
        Color.set(0.60, 0.75, 0.90, alpha * 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", x, y, rippleRadius)
    end

    -- Central pillar
    Color.set(0.50, 0.48, 0.45)
    love.graphics.rectangle("fill", x - 8, y - 30, 16, 30)

    -- Pillar highlight
    Color.set(0.60, 0.58, 0.55)
    love.graphics.rectangle("fill", x - 8, y - 30, 4, 30)

    -- Water spout (animated)
    local spoutHeight = 20 + math.sin(time * 5) * 5
    Color.set(0.50, 0.70, 0.90, 0.7)
    love.graphics.polygon("fill",
        x - 3, y - 30,
        x + 3, y - 30,
        x + 1, y - 30 - spoutHeight,
        x - 1, y - 30 - spoutHeight
    )

    -- Water droplets falling
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2 + time
        local dropDist = radius * 0.6 + math.sin(time * 3 + i) * 10
        local dropX = x + math.cos(angle) * dropDist
        local dropY = y + math.sin(angle) * dropDist * 0.5 - 10
        local dropAlpha = 0.5 + math.sin(time * 4 + i) * 0.3

        Color.set(0.60, 0.80, 0.95, dropAlpha)
        love.graphics.circle("fill", dropX, dropY, 2)
    end
end

function Town:drawBuildings(screenW, screenH, time)
    if not self.buildings then return end

    local ts = self.town.tileSize

    for _, building in ipairs(self.buildings) do
        -- Check if building is visible
        if building.x + building.width > self.camera.x and
           building.x < self.camera.x + screenW and
           building.y + building.height > self.camera.y and
           building.y < self.camera.y + screenH then

            local bx, by = building.x, building.y
            local bw, bh = building.width, building.height

            -- Building shadow
            Color.set(0, 0, 0, 0.3)
            love.graphics.rectangle("fill", bx + 4, by + 4, bw, bh)

            -- Building walls
            Color.set(0.55, 0.42, 0.32)
            love.graphics.rectangle("fill", bx, by, bw, bh)

            -- Wall detail (planks)
            Color.set(0.48, 0.36, 0.28)
            for px = bx, bx + bw - 1, 12 do
                love.graphics.rectangle("fill", px, by, 2, bh)
            end

            -- Roof
            local roofHeight = ts * 1.5
            Color.set(0.60, 0.32, 0.28)
            love.graphics.polygon("fill",
                bx - 8, by,
                bx + bw / 2, by - roofHeight,
                bx + bw + 8, by
            )

            -- Roof shingles
            Color.set(0.50, 0.25, 0.22)
            for ry = by - roofHeight + 8, by - 4, 8 do
                local roofProgress = (ry - (by - roofHeight)) / roofHeight
                local halfWidth = (bw / 2 + 8) * roofProgress
                love.graphics.line(bx + bw / 2 - halfWidth, ry, bx + bw / 2 + halfWidth, ry)
            end

            -- Door
            local doorX = building.doorX
            local doorY = building.doorY
            local doorW = ts
            local doorH = ts * 1.5
            local isNear = self.nearbyBuilding == building

            -- Door frame
            Color.set(0.35, 0.25, 0.18)
            love.graphics.rectangle("fill", doorX - 3, doorY - doorH - 3, doorW + 6, doorH + 6)

            -- Door
            if isNear then
                Color.set(0.60, 0.45, 0.30)
            else
                Color.set(0.50, 0.38, 0.25)
            end
            love.graphics.rectangle("fill", doorX, doorY - doorH, doorW, doorH)

            -- Door handle
            Color.set(0.70, 0.55, 0.25)
            love.graphics.circle("fill", doorX + doorW - 6, doorY - doorH / 2, 3)

            -- Windows
            local windowY = by + ts / 2
            local windowSize = ts * 0.6

            -- Left window
            if bw > ts * 3 then
                Color.set(0.35, 0.28, 0.22)
                love.graphics.rectangle("fill", bx + ts / 2 - 2, windowY - 2, windowSize + 4, windowSize + 4)
                Color.set(0.55, 0.70, 0.85)
                love.graphics.rectangle("fill", bx + ts / 2, windowY, windowSize, windowSize)
                -- Window cross
                Color.set(0.35, 0.28, 0.22)
                love.graphics.rectangle("fill", bx + ts / 2 + windowSize / 2 - 1, windowY, 2, windowSize)
                love.graphics.rectangle("fill", bx + ts / 2, windowY + windowSize / 2 - 1, windowSize, 2)
            end

            -- Right window
            if bw > ts * 4 then
                local rwx = bx + bw - ts / 2 - windowSize
                Color.set(0.35, 0.28, 0.22)
                love.graphics.rectangle("fill", rwx - 2, windowY - 2, windowSize + 4, windowSize + 4)
                Color.set(0.55, 0.70, 0.85)
                love.graphics.rectangle("fill", rwx, windowY, windowSize, windowSize)
                Color.set(0.35, 0.28, 0.22)
                love.graphics.rectangle("fill", rwx + windowSize / 2 - 1, windowY, 2, windowSize)
                love.graphics.rectangle("fill", rwx, windowY + windowSize / 2 - 1, windowSize, 2)
            end

            -- Building name sign (if near)
            if isNear then
                local signY = by - roofHeight - 15
                local nameWidth = love.graphics.getFont():getWidth(building.name) + 16

                Color.set(0.15, 0.12, 0.10, 0.9)
                love.graphics.rectangle("fill", bx + bw / 2 - nameWidth / 2, signY, nameWidth, 18, 3, 3)

                Color.set(0.90, 0.85, 0.60)
                love.graphics.printf(building.name, bx + bw / 2 - nameWidth / 2, signY + 3, nameWidth, "center")
            end
        end
    end
end

function Town:draw()
    local screenW, screenH = love.graphics.getDimensions()
    local ts = self.town.tileSize
    local time = love.timer.getTime()

    love.graphics.push()
    -- Round camera position to prevent sub-pixel jittering
    love.graphics.translate(-math.floor(self.camera.x + 0.5), -math.floor(self.camera.y + 0.5))

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
                    elseif tile == "road" then
                        drawRoadTile(tx, ty, ts, col, row)
                    elseif tile == "plaza" then
                        drawPlazaTile(tx, ty, ts, col, row)
                    elseif tile == "cobble" then
                        drawCobbleTile(tx, ty, ts, col, row)
                    elseif tile == "garden" then
                        drawGardenTile(tx, ty, ts, col, row)
                    elseif tile == "building" or tile == "building_floor" then
                        drawBuildingTile(tx, ty, ts, col, row)
                    elseif tile == "market" then
                        drawMarketTile(tx, ty, ts, col, row)
                    else
                        -- Default to grass for unknown tiles
                        drawGrassTile(tx, ty, ts, col, row)
                    end
                end
            end
        end
    else
        -- Fallback: draw a simple background if tiles aren't loaded
        Color.set(0.3, 0.4, 0.3)
        love.graphics.rectangle("fill", 0, 0, self.town.width, self.town.height)
    end

    -- Draw fountain in center
    if self.fountain then
        self:drawFountain(time)
    end

    -- Draw buildings with doors
    self:drawBuildings(screenW, screenH, time)

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
            Color.set(actor.color[1] * 0.5, actor.color[2] * 0.5, actor.color[3] * 0.5, 0.3)
            love.graphics.circle("fill", actor.x, actor.y + actor.size * 0.8, actor.size * 1.2)

            Color.set(actor.color[1], actor.color[2], actor.color[3])
            love.graphics.circle("fill", actor.x, actor.y, actor.size)
            Color.set(actor.color[1] + 0.2, actor.color[2] + 0.2, actor.color[3] + 0.2)
            love.graphics.circle("fill", actor.x - actor.size * 0.3, actor.y - actor.size * 0.3, actor.size * 0.3)
        end
    end

    love.graphics.pop()

    -- Day/night ambient overlay
    local screenW, screenH = love.graphics.getDimensions()
    local ambient = GameClock:getInterpolatedAmbient()
    if ambient[1] < 1 or ambient[2] < 1 or ambient[3] < 1 then
        -- Calculate darkness overlay
        local darkness = 1 - math.min(ambient[1], ambient[2], ambient[3])
        if darkness > 0.1 then
            -- Blue-tinted darkness for night
            local r = 0.05 * (1 - ambient[1])
            local g = 0.05 * (1 - ambient[2])
            local b = 0.15 * (1 - ambient[3])
            Color.set(r, g, b, darkness * 0.5)
            love.graphics.rectangle("fill", 0, 0, screenW, screenH)
        end
    end

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
    Color.set(0.08, 0.08, 0.15, 0.85)
    love.graphics.rectangle("fill", 5, 5, 480, 55, 6, 6)

    -- Panel border
    Color.set(0.35, 0.32, 0.45)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 5, 5, 480, 55, 6, 6)

    -- Inner highlight
    Color.set(0.45, 0.42, 0.55, 0.3)
    love.graphics.rectangle("line", 7, 7, 476, 51, 5, 5)

    -- Town name with icon
    Color.set(0.65, 0.75, 0.95)
    love.graphics.print("Town:", 15, 12)
    Color.set(1, 0.95, 0.85)
    love.graphics.print(self.hud.currentTown, 60, 12)

    -- Separator
    Color.set(0.35, 0.32, 0.45)
    love.graphics.rectangle("fill", 150, 10, 2, 20)

    -- Player name and level
    Color.set(0.65, 0.95, 0.75)
    love.graphics.print(self.hud.name, 165, 12)
    Color.set(0.95, 0.85, 0.55)
    love.graphics.print("Lv." .. self.hud.level, 280, 12)

    -- Separator
    Color.set(0.35, 0.32, 0.45)
    love.graphics.rectangle("fill", 325, 10, 2, 20)

    -- Game clock display
    local periodName = GameClock:getPeriod()
    local timeStr = GameClock:getTimeString()

    -- Time-based color for period
    local periodColors = {
        Night = {0.4, 0.4, 0.7},
        Dawn = {0.9, 0.7, 0.5},
        Morning = {1.0, 0.95, 0.7},
        Afternoon = {1.0, 1.0, 0.9},
        Evening = {0.95, 0.75, 0.5},
        Dusk = {0.7, 0.5, 0.7}
    }
    local periodColor = periodColors[periodName] or {0.8, 0.8, 0.8}

    Color.set(periodColor[1], periodColor[2], periodColor[3])
    love.graphics.print(timeStr, 340, 12)
    Color.set(0.6, 0.6, 0.7)
    love.graphics.print(periodName, 420, 12)

    -- Controls hint
    Color.set(0.5, 0.5, 0.6)
    love.graphics.print("WASD: Move  |  SPACE: Talk/Enter  |  ESC: World Map", 15, 38)
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
    Color.set(0.1, 0.1, 0.2, 0.9 * pulse)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 8, 8)

    -- Border with glow
    Color.set(0.85, 0.80, 0.45, pulse)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 8, 8)

    -- Text
    Color.set(1, 1, 0.9, pulse)
    love.graphics.print(prompt, boxX + 15, boxY + 8)
end

function Town:drawDialogueOverlay()
    local screenW, screenH = love.graphics.getDimensions()
    local time = love.timer.getTime()

    -- Semi-transparent background with vignette effect
    Color.set(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Dialogue box dimensions
    local boxWidth = 700
    local boxHeight = 160
    local boxX = (screenW - boxWidth) / 2
    local boxY = screenH - boxHeight - 40

    -- Outer glow/shadow
    Color.set(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", boxX - 4, boxY - 4, boxWidth + 8, boxHeight + 8, 12, 12)

    -- Main box background with gradient effect
    Color.set(0.08, 0.08, 0.18, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 8, 8)

    -- Inner panel (slightly lighter)
    Color.set(0.12, 0.12, 0.22, 0.9)
    love.graphics.rectangle("fill", boxX + 4, boxY + 4, boxWidth - 8, boxHeight - 8, 6, 6)

    -- Decorative border
    love.graphics.setLineWidth(3)
    Color.set(0.55, 0.50, 0.70)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 8, 8)

    -- Inner highlight border
    love.graphics.setLineWidth(1)
    Color.set(0.70, 0.65, 0.85, 0.4)
    love.graphics.rectangle("line", boxX + 3, boxY + 3, boxWidth - 6, boxHeight - 6, 6, 6)

    -- Corner decorations
    local cornerSize = 12
    Color.set(0.75, 0.70, 0.90)
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
        Color.set(0.25, 0.22, 0.35, 0.9)
        love.graphics.rectangle("fill", boxX + 15, boxY + 12, nameWidth + 20, 24, 4, 4)

        -- Name badge border
        Color.set(0.65, 0.60, 0.80)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", boxX + 15, boxY + 12, nameWidth + 20, 24, 4, 4)

        -- Name text
        Color.set(1, 0.95, 0.75)
        love.graphics.print(npcName, boxX + 25, boxY + 16)
    end

    -- Dialogue text with slight padding
    Color.set(0.95, 0.95, 1)
    love.graphics.printf(self.dialogue.currentText, boxX + 25, boxY + 50, boxWidth - 50, "left")

    -- Continue prompt with animation
    if #self.dialogue.currentText >= #self.dialogue.fullText then
        local bounce = math.sin(time * 5) * 3

        -- Prompt background
        Color.set(0.18, 0.18, 0.28, 0.8)
        love.graphics.rectangle("fill", boxX + boxWidth - 200, boxY + boxHeight - 35 + bounce, 180, 25, 4, 4)

        -- Prompt text
        Color.set(0.95, 0.90, 0.55)
        love.graphics.print("SPACE to continue", boxX + boxWidth - 190, boxY + boxHeight - 31 + bounce)

        -- Arrow indicator
        Color.set(0.95, 0.90, 0.55)
        love.graphics.polygon("fill",
            boxX + boxWidth - 25, boxY + boxHeight - 23 + bounce,
            boxX + boxWidth - 15, boxY + boxHeight - 23 + bounce,
            boxX + boxWidth - 20, boxY + boxHeight - 15 + bounce
        )
    else
        -- Typing indicator (animated dots)
        local dots = math.floor(time * 3) % 4
        Color.set(0.6, 0.6, 0.7)
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
        Gamestate:push(require("states.pause"))
    elseif key == "space" then
        if self.nearbyBuilding then
            -- Enter building (Metroid-style interior)
            local interior = require("states.buildinginterior")
            interior:enter(self.nearbyBuilding.type, self.nearbyBuilding.name)
            Gamestate:push(interior)
        elseif self.nearbyNPC then
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
