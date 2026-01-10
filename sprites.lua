-- Enhanced Pixel Art Sprite Generation Module
-- High-fidelity retro style graphics

local Sprites = {}

Sprites.tileSize = 16
Sprites.scale = 2

-- Rich color palettes
local palettes = {
    -- Grass - lush greens with highlights
    grass = {
        dark = {0.12, 0.32, 0.14},
        mid = {0.18, 0.45, 0.20},
        light = {0.25, 0.55, 0.28},
        highlight = {0.35, 0.65, 0.32},
        flower1 = {0.85, 0.35, 0.40},
        flower2 = {0.95, 0.85, 0.35},
        flower3 = {0.70, 0.45, 0.85},
    },
    -- Water - deep blues with shimmer
    water = {
        deep = {0.08, 0.18, 0.42},
        dark = {0.12, 0.28, 0.55},
        mid = {0.18, 0.40, 0.68},
        light = {0.28, 0.52, 0.78},
        highlight = {0.55, 0.75, 0.92},
        foam = {0.85, 0.92, 0.98},
    },
    -- Sand - warm beach tones
    sand = {
        dark = {0.68, 0.55, 0.35},
        mid = {0.82, 0.72, 0.48},
        light = {0.92, 0.85, 0.62},
        highlight = {0.98, 0.95, 0.78},
        pebble = {0.55, 0.48, 0.38},
    },
    -- Stone - varied grays
    stone = {
        dark = {0.28, 0.26, 0.25},
        mid = {0.45, 0.43, 0.42},
        light = {0.58, 0.56, 0.55},
        highlight = {0.72, 0.70, 0.68},
        moss = {0.35, 0.48, 0.32},
        crack = {0.18, 0.16, 0.15},
    },
    -- Cave - dark purples and blues
    cave = {
        void = {0.06, 0.05, 0.10},
        dark = {0.12, 0.10, 0.18},
        mid = {0.22, 0.18, 0.28},
        light = {0.32, 0.28, 0.40},
        crystal1 = {0.45, 0.75, 0.95},
        crystal2 = {0.75, 0.45, 0.90},
        crystal3 = {0.40, 0.95, 0.70},
        glow = {0.65, 0.85, 1.0},
    },
    -- Forest - deep greens and browns
    forest = {
        trunk_dark = {0.25, 0.15, 0.08},
        trunk_mid = {0.38, 0.25, 0.12},
        trunk_light = {0.52, 0.35, 0.18},
        leaf_dark = {0.08, 0.28, 0.12},
        leaf_mid = {0.15, 0.42, 0.18},
        leaf_light = {0.22, 0.55, 0.25},
        leaf_highlight = {0.45, 0.72, 0.35},
    },
    -- Portal - magical purples
    portal = {
        void = {0.12, 0.05, 0.18},
        dark = {0.35, 0.12, 0.48},
        mid = {0.55, 0.25, 0.72},
        light = {0.75, 0.45, 0.88},
        glow = {0.92, 0.72, 1.0},
        spark = {1.0, 0.85, 1.0},
        rune = {0.40, 0.85, 0.95},
    },
    -- Ruins - weathered stone
    ruins = {
        dark = {0.32, 0.28, 0.25},
        mid = {0.48, 0.44, 0.40},
        light = {0.62, 0.58, 0.52},
        moss = {0.32, 0.45, 0.28},
        gold = {0.85, 0.72, 0.35},
        shadow = {0.15, 0.12, 0.10},
    },
    -- Oasis - warm desert with water
    oasis = {
        sand_dark = {0.75, 0.60, 0.38},
        sand_light = {0.92, 0.82, 0.58},
        palm_trunk = {0.55, 0.38, 0.22},
        palm_leaf = {0.25, 0.58, 0.32},
        water = {0.25, 0.62, 0.72},
    },
    -- Path - dirt roads
    path = {
        dark = {0.42, 0.32, 0.22},
        mid = {0.55, 0.45, 0.32},
        light = {0.68, 0.58, 0.42},
        pebble = {0.52, 0.50, 0.48},
    },
    -- Deep water - ocean depths
    deep_water = {
        abyss = {0.02, 0.06, 0.18},
        deep = {0.05, 0.12, 0.28},
        mid = {0.08, 0.18, 0.38},
        caustic = {0.12, 0.25, 0.48},
    },
    -- Mountain - rocky peaks
    mountain = {
        snow = {0.92, 0.94, 0.98},
        snow_shadow = {0.75, 0.80, 0.88},
        rock_light = {0.58, 0.55, 0.52},
        rock_mid = {0.42, 0.40, 0.38},
        rock_dark = {0.28, 0.26, 0.25},
        rock_shadow = {0.18, 0.16, 0.15},
    },
    -- Hills - elevated terrain
    hills = {
        grass_light = {0.35, 0.58, 0.32},
        grass_mid = {0.25, 0.48, 0.25},
        grass_dark = {0.18, 0.38, 0.18},
        shadow = {0.12, 0.28, 0.12},
    },
    -- Highway - paved roads
    highway = {
        asphalt = {0.25, 0.25, 0.28},
        asphalt_light = {0.32, 0.32, 0.35},
        line_yellow = {0.90, 0.80, 0.25},
        line_white = {0.92, 0.92, 0.95},
        edge = {0.18, 0.18, 0.20},
    },
}

-- Helper functions
local function setPixel(data, x, y, color, alpha)
    if x >= 0 and x < data:getWidth() and y >= 0 and y < data:getHeight() then
        data:setPixel(x, y, color[1], color[2], color[3], alpha or 1)
    end
end

local function hash(x, y, seed)
    local n = x + y * 57 + (seed or 0) * 131
    n = bit.bxor(bit.lshift(n, 13), n)
    return bit.band(n * (n * n * 15731 + 789221) + 1376312589, 0x7FFFFFFF) / 0x7FFFFFFF
end

local function lerp(a, b, t)
    return {a[1] + (b[1]-a[1])*t, a[2] + (b[2]-a[2])*t, a[3] + (b[3]-a[3])*t}
end

local function dither(x, y, threshold)
    local pattern = {
        {0.0, 0.5, 0.125, 0.625},
        {0.75, 0.25, 0.875, 0.375},
        {0.1875, 0.6875, 0.0625, 0.5625},
        {0.9375, 0.4375, 0.8125, 0.3125}
    }
    return pattern[(y % 4) + 1][(x % 4) + 1] < threshold
end

function Sprites:init()
    self.images = {}
    self.animatedTiles = {}

    -- World map tiles
    self.images.grass = self:createGrassTile(1)
    self.images.grass2 = self:createGrassTile(2)
    self.images.grass3 = self:createGrassTile(3)
    self.images.water = self:createWaterTile(1)
    self.images.water2 = self:createWaterTile(2)
    self.images.sand = self:createSandTile(1)
    self.images.sand2 = self:createSandTile(2)

    -- Enhanced terrain tiles
    self.images.deep_water = self:createDeepWaterTile()
    self.images.mountain = self:createMountainTile()
    self.images.hills = self:createHillsTile()
    self.images.highway = self:createHighwayTile()
    self.images.highway_h = self:createHighwayTile("horizontal")
    self.images.highway_v = self:createHighwayTile("vertical")

    -- Vehicle sprites
    self.images.car = self:createCarSprite()
    self.images.car_right = self:createCarSprite("right")
    self.images.car_left = self:createCarSprite("left")
    self.images.car_up = self:createCarSprite("up")
    self.images.car_down = self:createCarSprite("down")

    -- Level tiles
    self.images.stone = self:createStoneTile()
    self.images.ruins_floor = self:createRuinsFloorTile()
    self.images.cave_floor = self:createCaveFloorTile()
    self.images.crystal = self:createCrystalTile()
    self.images.tree = self:createTreeTile()
    self.images.forest_floor = self:createForestFloorTile()
    self.images.path = self:createPathTile()
    self.images.portal_floor = self:createPortalFloorTile()
    self.images.magic_rune = self:createMagicRuneTile()
    self.images.oasis_sand = self:createOasisSandTile()
    self.images.pond = self:createPondTile()

    -- Building tiles
    self.images.wood_floor = self:createWoodFloorTile()
    self.images.stone_floor = self:createStoneFloorTile()
    self.images.wood_wall = self:createWoodWallTile()
    self.images.stone_wall = self:createStoneWallTile()

    -- POI markers
    self.images.poi_ruins = self:createPOIMarker("ruins")
    self.images.poi_cave = self:createPOIMarker("cave")
    self.images.poi_forest = self:createPOIMarker("forest")
    self.images.poi_oasis = self:createPOIMarker("oasis")
    self.images.poi_portal = self:createPOIMarker("portal")
    self.images.poi_town = self:createPOIMarker("town")

    -- Player sprite
    self.images.player = self:createPlayerSprite()
    self.images.player_walk1 = self:createPlayerSprite(1)
    self.images.player_walk2 = self:createPlayerSprite(2)

    -- Set filtering
    for _, img in pairs(self.images) do
        img:setFilter("nearest", "nearest")
    end

    print("Sprites initialized: " .. self:countImages() .. " images created")
end

function Sprites:countImages()
    local c = 0
    for _ in pairs(self.images) do c = c + 1 end
    return c
end

-- GRASS TILES --
function Sprites:createGrassTile(variant)
    local data = love.image.newImageData(16, 16)
    local p = palettes.grass
    local seed = variant * 100

    for y = 0, 15 do
        for x = 0, 15 do
            local h = hash(x, y, seed)
            local color

            -- Base grass with variation
            if h < 0.35 then
                color = p.dark
            elseif h < 0.65 then
                color = p.mid
            elseif h < 0.88 then
                color = p.light
            else
                color = p.highlight
            end

            -- Add subtle dithering between shades
            if dither(x, y, h * 0.3) then
                color = lerp(color, p.mid, 0.3)
            end

            setPixel(data, x, y, color)
        end
    end

    -- Add grass blade details
    for i = 1, 6 do
        local bx = math.floor(hash(i, 0, seed + 50) * 14) + 1
        local by = math.floor(hash(0, i, seed + 50) * 12) + 2
        setPixel(data, bx, by, p.highlight)
        setPixel(data, bx, by - 1, p.light)
        if hash(i, i, seed) > 0.7 then
            setPixel(data, bx, by - 2, p.highlight)
        end
    end

    -- Occasional flowers
    if variant == 2 then
        setPixel(data, 4, 8, p.flower1)
        setPixel(data, 12, 5, p.flower2)
    elseif variant == 3 then
        setPixel(data, 7, 10, p.flower3)
        setPixel(data, 10, 3, p.flower1)
    end

    return love.graphics.newImage(data)
end

-- WATER TILES --
function Sprites:createWaterTile(variant)
    local data = love.image.newImageData(16, 16)
    local p = palettes.water
    local seed = variant * 200

    for y = 0, 15 do
        for x = 0, 15 do
            -- Wave pattern
            local wave = math.sin((x + y * 0.5 + seed * 0.1) * 0.6) * 0.5 + 0.5
            local h = hash(x, y, seed) * 0.4 + wave * 0.6
            local color

            if h < 0.25 then
                color = p.deep
            elseif h < 0.45 then
                color = p.dark
            elseif h < 0.65 then
                color = p.mid
            elseif h < 0.85 then
                color = p.light
            else
                color = p.highlight
            end

            setPixel(data, x, y, color)
        end
    end

    -- Wave highlights
    local waveY = variant == 1 and 4 or 12
    for x = 1, 14, 3 do
        setPixel(data, x, waveY, p.highlight)
        setPixel(data, x + 1, waveY, p.foam)
    end

    -- Sparkle
    if variant == 1 then
        setPixel(data, 6, 7, p.foam)
        setPixel(data, 11, 3, p.foam)
    else
        setPixel(data, 3, 9, p.foam)
        setPixel(data, 13, 6, p.foam)
    end

    return love.graphics.newImage(data)
end

-- SAND TILES --
function Sprites:createSandTile(variant)
    local data = love.image.newImageData(16, 16)
    local p = palettes.sand
    local seed = variant * 300

    for y = 0, 15 do
        for x = 0, 15 do
            local h = hash(x, y, seed)
            local color

            if h < 0.3 then
                color = p.dark
            elseif h < 0.7 then
                color = p.mid
            elseif h < 0.92 then
                color = p.light
            else
                color = p.highlight
            end

            -- Dither for smooth gradient
            if dither(x, y, h * 0.4) then
                color = lerp(color, p.mid, 0.25)
            end

            setPixel(data, x, y, color)
        end
    end

    -- Pebbles and texture
    for i = 1, 4 do
        local px = math.floor(hash(i, 0, seed + 99) * 14) + 1
        local py = math.floor(hash(0, i, seed + 99) * 14) + 1
        setPixel(data, px, py, p.pebble)
    end

    -- Dotted pattern for sand texture
    for y = 2, 14, 4 do
        for x = 2, 14, 4 do
            local offset = ((y / 4) % 2) * 2
            setPixel(data, x + offset, y, p.dark)
        end
    end

    return love.graphics.newImage(data)
end

-- DEEP WATER TILES (Ocean) --
function Sprites:createDeepWaterTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.deep_water
    local seed = 250

    for y = 0, 15 do
        for x = 0, 15 do
            -- Deep ocean wave pattern
            local wave = math.sin((x * 0.4 + y * 0.3 + seed * 0.1) * 0.8) * 0.5 + 0.5
            local h = hash(x, y, seed) * 0.3 + wave * 0.7
            local color

            if h < 0.3 then
                color = p.abyss
            elseif h < 0.55 then
                color = p.deep
            elseif h < 0.8 then
                color = p.mid
            else
                color = p.caustic
            end

            setPixel(data, x, y, color)
        end
    end

    -- Deep water caustic patterns (light rays)
    for i = 1, 3 do
        local cx = math.floor(hash(i, 0, seed + 50) * 12) + 2
        local cy = math.floor(hash(0, i, seed + 50) * 12) + 2
        setPixel(data, cx, cy, p.caustic)
        if hash(i, i, seed) > 0.5 then
            setPixel(data, cx + 1, cy, p.mid)
        end
    end

    return love.graphics.newImage(data)
end

-- MOUNTAIN TILES (3D effect with shadows) --
function Sprites:createMountainTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.mountain
    local seed = 350

    -- Draw mountain peak with 3D shading
    for y = 0, 15 do
        for x = 0, 15 do
            local h = hash(x, y, seed)

            -- Mountain shape (peak in center-top)
            local peakX, peakY = 8, 3
            local dist = math.sqrt((x - peakX)^2 + (y - peakY)^2)
            local slope = y - peakY

            local color
            if slope < 0 then
                -- Above peak - shouldn't happen much
                color = p.rock_shadow
            elseif slope < 4 then
                -- Snow cap
                if x < peakX then
                    color = p.snow_shadow
                else
                    color = p.snow
                end
            elseif slope < 8 then
                -- Upper rock face
                if x < peakX - 1 then
                    color = p.rock_shadow
                elseif x < peakX then
                    color = p.rock_dark
                elseif x < peakX + 2 then
                    color = p.rock_mid
                else
                    color = p.rock_light
                end
            else
                -- Lower rock/base
                if x < peakX - 2 then
                    color = p.rock_shadow
                elseif x < peakX then
                    color = p.rock_dark
                else
                    color = lerp(p.rock_mid, p.rock_light, h * 0.5)
                end
            end

            -- Add some noise variation
            if h > 0.85 and slope > 4 then
                color = p.rock_light
            elseif h < 0.15 and slope > 4 then
                color = p.rock_shadow
            end

            setPixel(data, x, y, color)
        end
    end

    -- Snow highlights
    setPixel(data, 9, 4, {0.98, 0.99, 1.0})
    setPixel(data, 8, 3, {0.98, 0.99, 1.0})

    return love.graphics.newImage(data)
end

-- HILLS TILES (Elevated terrain) --
function Sprites:createHillsTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.hills
    local seed = 450

    for y = 0, 15 do
        for x = 0, 15 do
            local h = hash(x, y, seed)

            -- Hill shape - lighter at top, darker at bottom
            local elevation = 1 - (y / 16)
            local combined = h * 0.4 + elevation * 0.6

            local color
            if combined > 0.75 then
                color = p.grass_light
            elseif combined > 0.5 then
                color = p.grass_mid
            elseif combined > 0.25 then
                color = p.grass_dark
            else
                color = p.shadow
            end

            -- Add dithering for smooth gradient
            if dither(x, y, combined * 0.4) then
                color = lerp(color, p.grass_mid, 0.3)
            end

            setPixel(data, x, y, color)
        end
    end

    -- Hill contour lines for depth
    for x = 0, 15 do
        if x % 4 == 0 then
            setPixel(data, x, 12, p.shadow)
        end
    end

    -- Grass detail
    setPixel(data, 5, 3, p.grass_light)
    setPixel(data, 10, 5, p.grass_light)
    setPixel(data, 3, 8, p.grass_mid)

    return love.graphics.newImage(data)
end

-- HIGHWAY TILES --
function Sprites:createHighwayTile(direction)
    local data = love.image.newImageData(16, 16)
    local p = palettes.highway
    direction = direction or "horizontal"

    -- Base asphalt
    for y = 0, 15 do
        for x = 0, 15 do
            local h = hash(x, y, 550)
            local color = h < 0.7 and p.asphalt or p.asphalt_light
            setPixel(data, x, y, color)
        end
    end

    if direction == "horizontal" then
        -- Road edges
        for x = 0, 15 do
            setPixel(data, x, 0, p.edge)
            setPixel(data, x, 1, p.edge)
            setPixel(data, x, 14, p.edge)
            setPixel(data, x, 15, p.edge)
        end

        -- Center line (dashed yellow)
        for x = 0, 15, 4 do
            setPixel(data, x, 7, p.line_yellow)
            setPixel(data, x + 1, 7, p.line_yellow)
            setPixel(data, x, 8, p.line_yellow)
            setPixel(data, x + 1, 8, p.line_yellow)
        end

        -- Edge lines (white)
        for x = 0, 15 do
            setPixel(data, x, 2, p.line_white)
            setPixel(data, x, 13, p.line_white)
        end
    elseif direction == "vertical" then
        -- Road edges
        for y = 0, 15 do
            setPixel(data, 0, y, p.edge)
            setPixel(data, 1, y, p.edge)
            setPixel(data, 14, y, p.edge)
            setPixel(data, 15, y, p.edge)
        end

        -- Center line (dashed yellow)
        for y = 0, 15, 4 do
            setPixel(data, 7, y, p.line_yellow)
            setPixel(data, 7, y + 1, p.line_yellow)
            setPixel(data, 8, y, p.line_yellow)
            setPixel(data, 8, y + 1, p.line_yellow)
        end

        -- Edge lines (white)
        for y = 0, 15 do
            setPixel(data, 2, y, p.line_white)
            setPixel(data, 13, y, p.line_white)
        end
    end

    return love.graphics.newImage(data)
end

-- CAR SPRITE --
function Sprites:createCarSprite(direction)
    direction = direction or "right"
    local data = love.image.newImageData(16, 16)

    -- Transparent background
    for y = 0, 15 do
        for x = 0, 15 do
            data:setPixel(x, y, 0, 0, 0, 0)
        end
    end

    local body = {0.85, 0.25, 0.25}      -- Red car body
    local body_dark = {0.65, 0.18, 0.18}
    local body_light = {0.95, 0.40, 0.40}
    local window = {0.45, 0.65, 0.85}
    local window_light = {0.65, 0.82, 0.95}
    local wheel = {0.15, 0.15, 0.18}
    local chrome = {0.75, 0.78, 0.82}
    local outline = {0.10, 0.08, 0.12}

    if direction == "right" or direction == "left" then
        -- Side view car
        local flip = direction == "left" and -1 or 1

        -- Shadow
        for x = 3, 12 do
            setPixel(data, x, 14, {0, 0, 0, 0.3})
        end

        -- Wheels
        for dy = 0, 2 do
            for dx = 0, 2 do
                setPixel(data, 3 + dx, 11 + dy, wheel)
                setPixel(data, 10 + dx, 11 + dy, wheel)
            end
        end
        -- Wheel highlights
        setPixel(data, 4, 11, chrome)
        setPixel(data, 11, 11, chrome)

        -- Car body (lower)
        for y = 9, 12 do
            for x = 2, 13 do
                local color = y > 10 and body_dark or body
                setPixel(data, x, y, color)
            end
        end

        -- Car body (cabin)
        for y = 5, 9 do
            for x = 4, 11 do
                setPixel(data, x, y, body)
            end
        end

        -- Roof
        for x = 5, 10 do
            setPixel(data, x, 4, body)
            setPixel(data, x, 5, body_light)
        end

        -- Windows
        for y = 6, 8 do
            setPixel(data, 5, y, window)
            setPixel(data, 6, y, window_light)
            setPixel(data, 9, y, window)
            setPixel(data, 10, y, window_light)
        end

        -- Headlight/taillight
        setPixel(data, 2, 10, chrome)
        setPixel(data, 13, 10, {0.95, 0.35, 0.30})

        -- Outline
        for x = 2, 13 do
            setPixel(data, x, 3, outline)
        end

    elseif direction == "up" or direction == "down" then
        -- Top-down view car
        local flip = direction == "up" and -1 or 1

        -- Shadow
        for y = 3, 12 do
            setPixel(data, 14, y, {0, 0, 0, 0.3})
        end

        -- Car body outline
        for y = 2, 13 do
            for x = 4, 11 do
                setPixel(data, x, y, body)
            end
        end

        -- Front/back curves
        for x = 5, 10 do
            setPixel(data, x, 1, body)
            setPixel(data, x, 14, body_dark)
        end

        -- Roof/hood shading
        for y = 4, 11 do
            setPixel(data, 5, y, body_light)
            setPixel(data, 10, y, body_dark)
        end

        -- Windshield
        for x = 5, 10 do
            setPixel(data, x, 4, window)
            setPixel(data, x, 5, window_light)
        end

        -- Rear window
        for x = 5, 10 do
            setPixel(data, x, 10, window)
            setPixel(data, x, 11, window)
        end

        -- Wheels (visible from top)
        setPixel(data, 4, 3, wheel)
        setPixel(data, 4, 4, wheel)
        setPixel(data, 11, 3, wheel)
        setPixel(data, 11, 4, wheel)
        setPixel(data, 4, 11, wheel)
        setPixel(data, 4, 12, wheel)
        setPixel(data, 11, 11, wheel)
        setPixel(data, 11, 12, wheel)

        -- Headlights
        setPixel(data, 5, 2, chrome)
        setPixel(data, 10, 2, chrome)

        -- Taillights
        setPixel(data, 5, 13, {0.95, 0.25, 0.25})
        setPixel(data, 10, 13, {0.95, 0.25, 0.25})
    end

    return love.graphics.newImage(data)
end

-- STONE TILES --
function Sprites:createStoneTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.stone

    for y = 0, 15 do
        for x = 0, 15 do
            local h = hash(x, y, 400)
            local color

            if h < 0.3 then
                color = p.dark
            elseif h < 0.6 then
                color = p.mid
            elseif h < 0.85 then
                color = p.light
            else
                color = p.highlight
            end

            setPixel(data, x, y, color)
        end
    end

    -- Stone block pattern
    for x = 0, 15 do
        setPixel(data, x, 0, p.dark)
        setPixel(data, x, 8, p.dark)
    end
    for y = 0, 7 do
        setPixel(data, 0, y, p.dark)
        setPixel(data, 8, y, p.dark)
    end
    for y = 8, 15 do
        setPixel(data, 4, y, p.dark)
        setPixel(data, 12, y, p.dark)
    end

    -- Highlights on edges
    for x = 1, 7 do
        setPixel(data, x, 1, p.highlight)
    end
    for x = 9, 15 do
        setPixel(data, x, 1, p.highlight)
    end

    -- Cracks
    setPixel(data, 5, 4, p.crack)
    setPixel(data, 6, 5, p.crack)
    setPixel(data, 11, 11, p.crack)

    -- Moss
    setPixel(data, 2, 6, p.moss)
    setPixel(data, 13, 14, p.moss)

    return love.graphics.newImage(data)
end

-- RUINS FLOOR --
function Sprites:createRuinsFloorTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.ruins

    for y = 0, 15 do
        for x = 0, 15 do
            local h = hash(x, y, 500)
            local color

            if h < 0.4 then
                color = p.dark
            elseif h < 0.75 then
                color = p.mid
            else
                color = p.light
            end

            setPixel(data, x, y, color)
        end
    end

    -- Tile grid pattern (ancient floor tiles)
    for i = 0, 15, 8 do
        for j = 0, 15 do
            setPixel(data, i, j, p.shadow)
            setPixel(data, j, i, p.shadow)
        end
    end

    -- Worn edges and cracks
    setPixel(data, 3, 3, p.shadow)
    setPixel(data, 4, 3, p.shadow)
    setPixel(data, 12, 5, p.shadow)
    setPixel(data, 12, 6, p.shadow)

    -- Moss growth
    setPixel(data, 2, 10, p.moss)
    setPixel(data, 3, 10, p.moss)
    setPixel(data, 9, 2, p.moss)

    -- Ancient gold inlay (rare)
    setPixel(data, 4, 4, p.gold)

    return love.graphics.newImage(data)
end

-- CAVE FLOOR --
function Sprites:createCaveFloorTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.cave

    for y = 0, 15 do
        for x = 0, 15 do
            local h = hash(x, y, 600)
            local color

            if h < 0.4 then
                color = p.void
            elseif h < 0.7 then
                color = p.dark
            elseif h < 0.9 then
                color = p.mid
            else
                color = p.light
            end

            setPixel(data, x, y, color)
        end
    end

    -- Rocky texture
    for i = 1, 5 do
        local rx = math.floor(hash(i, 0, 601) * 14) + 1
        local ry = math.floor(hash(0, i, 601) * 14) + 1
        setPixel(data, rx, ry, p.light)
    end

    return love.graphics.newImage(data)
end

-- CRYSTAL TILE --
function Sprites:createCrystalTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.cave

    -- Dark cave background
    for y = 0, 15 do
        for x = 0, 15 do
            setPixel(data, x, y, p.void)
        end
    end

    -- Crystal color (vary between blue, purple, green)
    local crystalType = hash(0, 0, 700)
    local crystalColor, crystalHighlight
    if crystalType < 0.33 then
        crystalColor, crystalHighlight = p.crystal1, p.glow
    elseif crystalType < 0.66 then
        crystalColor, crystalHighlight = p.crystal2, {0.90, 0.70, 1.0}
    else
        crystalColor, crystalHighlight = p.crystal3, {0.70, 1.0, 0.85}
    end

    -- Main crystal formation
    local cx, cy = 8, 8
    for y = 3, 14 do
        local width = math.max(1, 5 - math.abs(y - 9) * 0.6)
        for x = math.floor(cx - width), math.floor(cx + width) do
            if x >= 0 and x < 16 then
                local dist = math.abs(x - cx)
                if dist < width * 0.3 then
                    setPixel(data, x, y, crystalHighlight)
                elseif dist < width * 0.6 then
                    setPixel(data, x, y, crystalColor)
                else
                    setPixel(data, x, y, lerp(crystalColor, p.dark, 0.5))
                end
            end
        end
    end

    -- Smaller crystal
    for y = 8, 13 do
        local w = math.max(0, 2 - math.abs(y - 10) * 0.4)
        for x = 11, math.floor(11 + w) do
            setPixel(data, x, y, crystalColor)
        end
    end

    -- Glow effect
    setPixel(data, 7, 5, p.glow)
    setPixel(data, 8, 4, p.glow)

    return love.graphics.newImage(data)
end

-- TREE TILE --
function Sprites:createTreeTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.forest

    -- Ground
    for y = 12, 15 do
        for x = 0, 15 do
            local h = hash(x, y, 800)
            setPixel(data, x, y, h < 0.5 and p.leaf_dark or palettes.grass.dark)
        end
    end

    -- Trunk
    for y = 8, 14 do
        for x = 6, 9 do
            local shade = x < 8 and p.trunk_dark or p.trunk_mid
            if x == 9 then shade = p.trunk_light end
            setPixel(data, x, y, shade)
        end
    end

    -- Canopy (layered for depth)
    local canopyLayers = {
        {y = 0, width = 4, color = p.leaf_dark},
        {y = 1, width = 5, color = p.leaf_dark},
        {y = 2, width = 6, color = p.leaf_mid},
        {y = 3, width = 7, color = p.leaf_mid},
        {y = 4, width = 7, color = p.leaf_mid},
        {y = 5, width = 6, color = p.leaf_light},
        {y = 6, width = 6, color = p.leaf_light},
        {y = 7, width = 5, color = p.leaf_mid},
        {y = 8, width = 3, color = p.leaf_dark},
    }

    for _, layer in ipairs(canopyLayers) do
        local startX = 8 - layer.width
        for x = startX, startX + layer.width * 2 - 1 do
            local h = hash(x, layer.y, 801)
            local color = layer.color
            if h > 0.7 then color = p.leaf_highlight end
            if h < 0.2 then color = p.leaf_dark end
            setPixel(data, x, layer.y, color)
        end
    end

    return love.graphics.newImage(data)
end

-- FOREST FLOOR --
function Sprites:createForestFloorTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.forest
    local g = palettes.grass

    for y = 0, 15 do
        for x = 0, 15 do
            local h = hash(x, y, 900)
            local color

            if h < 0.3 then
                color = p.leaf_dark
            elseif h < 0.5 then
                color = g.dark
            elseif h < 0.75 then
                color = g.mid
            elseif h < 0.92 then
                color = p.leaf_mid
            else
                -- Small flowers/mushrooms
                color = h < 0.96 and g.flower1 or g.flower2
            end

            setPixel(data, x, y, color)
        end
    end

    -- Fallen leaves
    setPixel(data, 3, 5, p.trunk_light)
    setPixel(data, 11, 9, p.trunk_mid)
    setPixel(data, 7, 13, p.trunk_light)

    return love.graphics.newImage(data)
end

-- PATH TILE --
function Sprites:createPathTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.path

    for y = 0, 15 do
        for x = 0, 15 do
            local h = hash(x, y, 1000)
            local color

            if h < 0.35 then
                color = p.dark
            elseif h < 0.7 then
                color = p.mid
            else
                color = p.light
            end

            setPixel(data, x, y, color)
        end
    end

    -- Pebbles
    local pebbles = {{3,4}, {8,2}, {12,7}, {5,11}, {10,13}, {2,9}}
    for _, pb in ipairs(pebbles) do
        setPixel(data, pb[1], pb[2], p.pebble)
    end

    -- Wheel ruts / footprints
    setPixel(data, 6, 3, p.dark)
    setPixel(data, 6, 7, p.dark)
    setPixel(data, 6, 11, p.dark)
    setPixel(data, 9, 5, p.dark)
    setPixel(data, 9, 9, p.dark)
    setPixel(data, 9, 13, p.dark)

    return love.graphics.newImage(data)
end

-- PORTAL FLOOR --
function Sprites:createPortalFloorTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.portal

    for y = 0, 15 do
        for x = 0, 15 do
            local dist = math.sqrt((x - 8)^2 + (y - 8)^2)
            local h = hash(x, y, 1100)
            local color

            if dist < 3 then
                color = lerp(p.light, p.glow, h)
            elseif dist < 6 then
                color = lerp(p.mid, p.light, h * 0.5)
            elseif dist < 9 then
                color = lerp(p.dark, p.mid, h * 0.5)
            else
                color = p.void
            end

            -- Add sparkle
            if h > 0.95 and dist < 7 then
                color = p.spark
            end

            setPixel(data, x, y, color)
        end
    end

    return love.graphics.newImage(data)
end

-- MAGIC RUNE --
function Sprites:createMagicRuneTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.portal

    -- Dark background
    for y = 0, 15 do
        for x = 0, 15 do
            setPixel(data, x, y, p.void)
        end
    end

    -- Rune circle
    for angle = 0, math.pi * 2, 0.15 do
        local rx = math.floor(8 + math.cos(angle) * 6.5)
        local ry = math.floor(8 + math.sin(angle) * 6.5)
        setPixel(data, rx, ry, p.rune)
    end

    -- Inner rune pattern
    for angle = 0, math.pi * 2, 0.3 do
        local rx = math.floor(8 + math.cos(angle) * 4)
        local ry = math.floor(8 + math.sin(angle) * 4)
        setPixel(data, rx, ry, p.glow)
    end

    -- Cross pattern
    for i = 3, 12 do
        setPixel(data, i, 8, p.light)
        setPixel(data, 8, i, p.light)
    end

    -- Center glow
    setPixel(data, 7, 7, p.spark)
    setPixel(data, 8, 7, p.spark)
    setPixel(data, 7, 8, p.spark)
    setPixel(data, 8, 8, p.glow)

    return love.graphics.newImage(data)
end

-- OASIS SAND --
function Sprites:createOasisSandTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.oasis

    for y = 0, 15 do
        for x = 0, 15 do
            local h = hash(x, y, 1200)
            local color = h < 0.6 and p.sand_dark or p.sand_light
            setPixel(data, x, y, color)
        end
    end

    return love.graphics.newImage(data)
end

-- POND --
function Sprites:createPondTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.oasis
    local w = palettes.water

    for y = 0, 15 do
        for x = 0, 15 do
            local dist = math.sqrt((x - 8)^2 + (y - 8)^2)
            local h = hash(x, y, 1300)

            if dist < 5 then
                setPixel(data, x, y, h < 0.5 and w.mid or w.light)
            elseif dist < 6 then
                setPixel(data, x, y, w.foam)
            elseif dist < 7 then
                setPixel(data, x, y, palettes.grass.mid)
            else
                setPixel(data, x, y, h < 0.5 and p.sand_dark or p.sand_light)
            end
        end
    end

    -- Water highlights
    setPixel(data, 6, 5, w.highlight)
    setPixel(data, 7, 4, w.foam)

    return love.graphics.newImage(data)
end

-- WOOD FLOOR --
function Sprites:createWoodFloorTile()
    local data = love.image.newImageData(16, 16)
    local colors = {
        dark = {0.45, 0.30, 0.18},
        mid = {0.58, 0.42, 0.25},
        light = {0.70, 0.52, 0.32},
        grain = {0.38, 0.25, 0.15},
    }

    for y = 0, 15 do
        for x = 0, 15 do
            local plank = math.floor(y / 4)
            local h = hash(x, plank, 1400)
            local color = h < 0.4 and colors.dark or (h < 0.8 and colors.mid or colors.light)
            setPixel(data, x, y, color)
        end
    end

    -- Plank gaps
    for x = 0, 15 do
        setPixel(data, x, 0, colors.grain)
        setPixel(data, x, 4, colors.grain)
        setPixel(data, x, 8, colors.grain)
        setPixel(data, x, 12, colors.grain)
    end

    -- Wood grain
    for y = 1, 15, 4 do
        for x = 2, 14, 5 do
            setPixel(data, x, y + 1, colors.grain)
            setPixel(data, x + 1, y + 2, colors.grain)
        end
    end

    return love.graphics.newImage(data)
end

-- STONE FLOOR --
function Sprites:createStoneFloorTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.stone

    for y = 0, 15 do
        for x = 0, 15 do
            local h = hash(x, y, 1500)
            local color = h < 0.4 and p.mid or (h < 0.8 and p.light or p.highlight)
            setPixel(data, x, y, color)
        end
    end

    -- Tile pattern
    for x = 0, 15 do
        setPixel(data, x, 0, p.dark)
        setPixel(data, x, 8, p.dark)
    end
    for y = 0, 15 do
        setPixel(data, 0, y, p.dark)
        setPixel(data, 8, y, p.dark)
    end

    return love.graphics.newImage(data)
end

-- WOOD WALL --
function Sprites:createWoodWallTile()
    local data = love.image.newImageData(16, 16)
    local colors = {
        dark = {0.35, 0.22, 0.12},
        mid = {0.48, 0.32, 0.18},
        light = {0.58, 0.40, 0.22},
        highlight = {0.68, 0.50, 0.30},
    }

    -- Vertical planks
    for x = 0, 15 do
        local plank = math.floor(x / 4)
        local h = hash(plank, 0, 1600)
        local baseColor = h < 0.5 and colors.mid or colors.light

        for y = 0, 15 do
            local yh = hash(x, y, 1601)
            local color = yh < 0.2 and colors.dark or baseColor
            if yh > 0.9 then color = colors.highlight end
            setPixel(data, x, y, color)
        end
    end

    -- Plank gaps
    for y = 0, 15 do
        setPixel(data, 0, y, colors.dark)
        setPixel(data, 4, y, colors.dark)
        setPixel(data, 8, y, colors.dark)
        setPixel(data, 12, y, colors.dark)
    end

    -- Top shadow
    for x = 0, 15 do
        setPixel(data, x, 0, colors.dark)
        setPixel(data, x, 1, colors.dark)
    end

    return love.graphics.newImage(data)
end

-- STONE WALL --
function Sprites:createStoneWallTile()
    local data = love.image.newImageData(16, 16)
    local p = palettes.stone

    for y = 0, 15 do
        for x = 0, 15 do
            local h = hash(x, y, 1700)
            local color = h < 0.3 and p.dark or (h < 0.7 and p.mid or p.light)
            setPixel(data, x, y, color)
        end
    end

    -- Brick pattern
    for y = 0, 15, 4 do
        for x = 0, 15 do
            setPixel(data, x, y, p.crack)
        end
    end
    local offsets = {0, 4, 0, 4}
    for row = 0, 3 do
        local off = offsets[row + 1]
        for x = off, 15, 8 do
            for y = row * 4 + 1, row * 4 + 3 do
                if y < 16 then
                    setPixel(data, x, y, p.crack)
                end
            end
        end
    end

    -- Top highlight
    for x = 0, 15 do
        setPixel(data, x, 1, p.highlight)
    end

    return love.graphics.newImage(data)
end

-- POI MARKERS --
function Sprites:createPOIMarker(poiType)
    local data = love.image.newImageData(16, 16)

    -- Transparent background
    for y = 0, 15 do
        for x = 0, 15 do
            data:setPixel(x, y, 0, 0, 0, 0)
        end
    end

    local colors = {
        ruins = {{0.85, 0.70, 0.35}, {0.65, 0.50, 0.25}, {0.45, 0.35, 0.18}},
        cave = {{0.50, 0.80, 0.95}, {0.35, 0.60, 0.80}, {0.20, 0.40, 0.60}},
        forest = {{0.40, 0.75, 0.45}, {0.25, 0.55, 0.30}, {0.15, 0.38, 0.18}},
        oasis = {{0.45, 0.80, 0.85}, {0.90, 0.80, 0.55}, {0.70, 0.60, 0.40}},
        portal = {{0.85, 0.55, 0.95}, {0.65, 0.35, 0.80}, {0.45, 0.20, 0.60}},
        town = {{0.90, 0.70, 0.50}, {0.70, 0.50, 0.35}, {0.50, 0.35, 0.22}},
    }

    local c = colors[poiType] or colors.town
    local light, mid, dark = c[1], c[2], c[3]

    -- Diamond shape with shading
    for y = 0, 15 do
        for x = 0, 15 do
            local dx = math.abs(x - 7.5)
            local dy = math.abs(y - 7.5)
            local dist = dx + dy

            if dist <= 6.5 then
                local color
                if dist > 5.5 then
                    color = dark
                elseif x < 8 then
                    color = mid
                else
                    color = light
                end
                setPixel(data, x, y, color)
            end
        end
    end

    -- Inner highlight
    setPixel(data, 6, 5, {light[1] + 0.15, light[2] + 0.15, light[3] + 0.15})
    setPixel(data, 7, 4, {light[1] + 0.2, light[2] + 0.2, light[3] + 0.2})

    -- Icon based on type
    if poiType == "ruins" then
        -- Pillar icon
        for y = 5, 10 do
            setPixel(data, 7, y, dark)
            setPixel(data, 8, y, dark)
        end
        setPixel(data, 6, 5, dark)
        setPixel(data, 9, 5, dark)
    elseif poiType == "cave" then
        -- Cave entrance
        setPixel(data, 7, 6, {0.1, 0.1, 0.15})
        setPixel(data, 8, 6, {0.1, 0.1, 0.15})
        setPixel(data, 7, 7, {0.1, 0.1, 0.15})
        setPixel(data, 8, 7, {0.1, 0.1, 0.15})
        setPixel(data, 6, 8, dark)
        setPixel(data, 9, 8, dark)
    elseif poiType == "forest" then
        -- Tree icon
        setPixel(data, 7, 5, {0.2, 0.5, 0.25})
        setPixel(data, 8, 5, {0.2, 0.5, 0.25})
        setPixel(data, 6, 6, {0.2, 0.5, 0.25})
        setPixel(data, 9, 6, {0.2, 0.5, 0.25})
        setPixel(data, 7, 8, {0.4, 0.28, 0.15})
        setPixel(data, 8, 8, {0.4, 0.28, 0.15})
    elseif poiType == "portal" then
        -- Swirl
        setPixel(data, 7, 5, {0.9, 0.7, 1.0})
        setPixel(data, 9, 7, {0.9, 0.7, 1.0})
        setPixel(data, 7, 9, {0.9, 0.7, 1.0})
        setPixel(data, 5, 7, {0.9, 0.7, 1.0})
    elseif poiType == "town" then
        -- House icon
        setPixel(data, 7, 5, dark)
        setPixel(data, 8, 5, dark)
        setPixel(data, 6, 6, dark)
        setPixel(data, 9, 6, dark)
        for y = 7, 9 do
            setPixel(data, 6, y, dark)
            setPixel(data, 9, y, dark)
        end
    end

    return love.graphics.newImage(data)
end

-- PLAYER SPRITE --
function Sprites:createPlayerSprite(frame)
    frame = frame or 0
    local data = love.image.newImageData(16, 16)

    -- Transparent
    for y = 0, 15 do
        for x = 0, 15 do
            data:setPixel(x, y, 0, 0, 0, 0)
        end
    end

    local skin = {0.90, 0.75, 0.62}
    local skin_shadow = {0.75, 0.58, 0.45}
    local hair = {0.35, 0.25, 0.18}
    local shirt = {0.25, 0.50, 0.80}
    local shirt_shadow = {0.18, 0.38, 0.65}
    local pants = {0.35, 0.30, 0.45}
    local pants_shadow = {0.25, 0.22, 0.35}
    local outline = {0.12, 0.10, 0.15}
    local white = {0.95, 0.95, 0.98}

    -- Animation offset
    local legOffset = frame == 1 and 1 or (frame == 2 and -1 or 0)

    -- Head outline
    for x = 5, 10 do setPixel(data, x, 1, outline) end
    setPixel(data, 4, 2, outline)
    setPixel(data, 11, 2, outline)
    for y = 3, 5 do
        setPixel(data, 4, y, outline)
        setPixel(data, 11, y, outline)
    end
    setPixel(data, 4, 6, outline)
    setPixel(data, 11, 6, outline)
    for x = 5, 10 do setPixel(data, x, 7, outline) end

    -- Head fill
    for y = 2, 6 do
        for x = 5, 10 do
            local color = x < 8 and skin_shadow or skin
            setPixel(data, x, y, color)
        end
    end

    -- Hair
    for x = 5, 10 do
        setPixel(data, x, 2, hair)
    end
    setPixel(data, 5, 3, hair)
    setPixel(data, 10, 3, hair)

    -- Eyes
    setPixel(data, 6, 4, white)
    setPixel(data, 9, 4, white)
    setPixel(data, 6, 5, {0.2, 0.3, 0.5})
    setPixel(data, 9, 5, {0.2, 0.3, 0.5})

    -- Body outline
    for y = 7, 11 do
        setPixel(data, 4, y, outline)
        setPixel(data, 11, y, outline)
    end
    for x = 5, 10 do setPixel(data, x, 12, outline) end

    -- Shirt
    for y = 7, 11 do
        for x = 5, 10 do
            local color = x < 8 and shirt_shadow or shirt
            setPixel(data, x, y, color)
        end
    end

    -- Arms
    setPixel(data, 4, 8, skin_shadow)
    setPixel(data, 4, 9, skin_shadow)
    setPixel(data, 4, 10, skin)
    setPixel(data, 11, 8, skin)
    setPixel(data, 11, 9, skin)
    setPixel(data, 11, 10, skin)

    -- Legs
    local leftLegX = 6 + legOffset
    local rightLegX = 9 - legOffset

    for y = 12, 14 do
        setPixel(data, leftLegX, y, pants_shadow)
        setPixel(data, leftLegX + 1, y, pants)
        setPixel(data, rightLegX - 1, y, pants_shadow)
        setPixel(data, rightLegX, y, pants)
    end

    -- Feet
    setPixel(data, leftLegX, 15, outline)
    setPixel(data, leftLegX + 1, 15, outline)
    setPixel(data, rightLegX - 1, 15, outline)
    setPixel(data, rightLegX, 15, outline)

    return love.graphics.newImage(data)
end

-- Get tile with variation
function Sprites:getTile(name, x, y)
    x, y = x or 0, y or 0
    local variant = ((x + y * 7) % 3) + 1

    if name == "grass" then
        if variant == 1 then return self.images.grass
        elseif variant == 2 then return self.images.grass2
        else return self.images.grass3 end
    elseif name == "water" then
        return variant % 2 == 0 and self.images.water or self.images.water2
    elseif name == "deep_water" then
        return self.images.deep_water
    elseif name == "sand" then
        return variant % 2 == 0 and self.images.sand or self.images.sand2
    elseif name == "mountain" then
        return self.images.mountain
    elseif name == "hills" then
        return self.images.hills
    elseif name == "highway" or name == "highway_h" then
        return self.images.highway_h
    elseif name == "highway_v" then
        return self.images.highway_v
    elseif name == "forest" then
        return self.images.tree
    else
        return self.images[name]
    end
end

-- Get car sprite based on direction
function Sprites:getCarSprite(direction)
    local key = "car_" .. (direction or "right")
    return self.images[key] or self.images.car
end

function Sprites:getPOIMarker(levelType)
    local key = "poi_" .. (levelType or "town")
    return self.images[key] or self.images.poi_town
end

return Sprites
