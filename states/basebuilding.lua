-- Base Building State
-- Top-down base building with paperdoll characters
-- Enhanced high-fidelity retro graphics

local BaseBuilding = {}
local Paperdoll = require "paperdoll"

local function setColor(r, g, b, a)
    a = a or 1
    local major = love.getVersion and love.getVersion() or 0
    if type(major) == "number" and major >= 11 then
        love.graphics.setColor(r, g, b, a)
    else
        love.graphics.setColor(r * 255, g * 255, b * 255, a * 255)
    end
end

local function clamp(v, min, max)
    return v < min and min or (v > max and max or v)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpColor(c1, c2, t)
    return {lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t), lerp(c1[3], c2[3], t)}
end

-- Dithering check for retro shading
local function shouldDither(x, y, threshold)
    local pattern = {
        {0.0, 0.5, 0.125, 0.625},
        {0.75, 0.25, 0.875, 0.375},
        {0.1875, 0.6875, 0.0625, 0.5625},
        {0.9375, 0.4375, 0.8125, 0.3125}
    }
    return pattern[(math.floor(y) % 4) + 1][(math.floor(x) % 4) + 1] < threshold
end

-- Color palettes for terrain types
local PALETTES = {
    ruins = {
        ground = {{0.42, 0.38, 0.32}, {0.35, 0.32, 0.28}, {0.50, 0.45, 0.38}},
        accent = {{0.55, 0.48, 0.38}, {0.48, 0.42, 0.35}}
    },
    cave = {
        ground = {{0.28, 0.25, 0.30}, {0.22, 0.20, 0.25}, {0.35, 0.32, 0.38}},
        accent = {{0.45, 0.40, 0.52}, {0.38, 0.35, 0.45}}
    },
    forest = {
        ground = {{0.32, 0.42, 0.28}, {0.28, 0.38, 0.25}, {0.38, 0.48, 0.32}},
        accent = {{0.25, 0.35, 0.22}, {0.30, 0.40, 0.28}}
    },
    oasis = {
        ground = {{0.85, 0.78, 0.55}, {0.78, 0.72, 0.50}, {0.92, 0.85, 0.62}},
        accent = {{0.75, 0.68, 0.48}, {0.82, 0.75, 0.55}}
    }
}

-- Building definitions
local BUILDINGS = {
    -- Floors
    wood_floor = {
        name = "Wood Floor", category = "floor", solid = false,
        color = {0.6, 0.45, 0.3}, cost = {wood = 2}
    },
    stone_floor = {
        name = "Stone Floor", category = "floor", solid = false,
        color = {0.5, 0.5, 0.52}, cost = {stone = 2}
    },
    grass_path = {
        name = "Grass Path", category = "floor", solid = false,
        color = {0.35, 0.55, 0.3}, cost = {wood = 1}
    },

    -- Walls
    wood_wall = {
        name = "Wood Wall", category = "wall", solid = true,
        color = {0.5, 0.35, 0.2}, cost = {wood = 5}
    },
    stone_wall = {
        name = "Stone Wall", category = "wall", solid = true,
        color = {0.4, 0.4, 0.42}, cost = {stone = 5}
    },
    fence = {
        name = "Fence", category = "wall", solid = true,
        color = {0.55, 0.4, 0.25}, cost = {wood = 3}
    },

    -- Furniture
    bed = {
        name = "Bed", category = "furniture", solid = true, size = {2, 1},
        color = {0.7, 0.3, 0.3}, cost = {wood = 10, cloth = 5}
    },
    table = {
        name = "Table", category = "furniture", solid = true,
        color = {0.55, 0.4, 0.25}, cost = {wood = 8}
    },
    chair = {
        name = "Chair", category = "furniture", solid = true,
        color = {0.5, 0.38, 0.22}, cost = {wood = 4}
    },
    chest = {
        name = "Chest", category = "furniture", solid = true,
        color = {0.6, 0.45, 0.2}, cost = {wood = 12, metal = 2}
    },
    campfire = {
        name = "Campfire", category = "furniture", solid = false,
        color = {0.9, 0.5, 0.2}, cost = {wood = 5, stone = 3}, animated = true
    },
    workbench = {
        name = "Workbench", category = "furniture", solid = true,
        color = {0.5, 0.4, 0.3}, cost = {wood = 15, stone = 5}
    },

    -- Nature/Resources
    tree = {
        name = "Tree", category = "nature", solid = true,
        color = {0.2, 0.5, 0.25}, harvestable = true, gives = {wood = 5}
    },
    rock = {
        name = "Rock", category = "nature", solid = true,
        color = {0.5, 0.5, 0.5}, harvestable = true, gives = {stone = 3}
    },
    bush = {
        name = "Bush", category = "nature", solid = false,
        color = {0.3, 0.6, 0.3}, harvestable = true, gives = {cloth = 1}
    },

    -- Decorations
    torch = {
        name = "Torch", category = "decor", solid = false,
        color = {0.95, 0.7, 0.3}, cost = {wood = 2}, animated = true
    },
    flower_pot = {
        name = "Flower Pot", category = "decor", solid = false,
        color = {0.8, 0.4, 0.5}, cost = {stone = 2}
    },
    rug = {
        name = "Rug", category = "floor", solid = false,
        color = {0.7, 0.25, 0.25}, cost = {cloth = 4}
    },
}

function BaseBuilding:load()
    -- Level grid
    self.gridSize = 32
    self.cols = 50
    self.rows = 40
    self.width = self.cols * self.gridSize
    self.height = self.rows * self.gridSize

    -- Tiles: each cell can have floor + object
    self.floors = {}
    self.objects = {}
    for y = 1, self.rows do
        self.floors[y] = {}
        self.objects[y] = {}
        for x = 1, self.cols do
            self.floors[y][x] = nil
            self.objects[y][x] = nil
        end
    end

    -- Player with paperdoll
    self.player = {
        x = self.width / 2,
        y = self.height / 2,
        speed = 180,
        facing = 1,
        character = nil  -- Will be created in enter()
    }

    -- Camera
    self.camera = {x = 0, y = 0}

    -- Resources
    self.resources = {
        wood = 50,
        stone = 30,
        metal = 10,
        cloth = 15
    }

    -- Build mode
    self.buildMode = false
    self.selectedBuilding = nil
    self.buildCategory = "floor"
    self.cursorX = 0
    self.cursorY = 0

    -- UI state
    self.showInventory = false
    self.showWardrobe = false
    self.wardrobeSelection = {
        category = "hair",
        index = 1
    }

    -- Level info
    self.levelName = "Base"
    self.levelType = "ruins"
end

function BaseBuilding:enter()
    if self.poiData then
        self.levelName = self.poiData.name or "Base"
        self.levelType = self.poiData.levelType or "ruins"
        love.math.setRandomSeed(self.poiData.levelSeed or 12345)
    end

    -- Create player character
    self.player.character = Paperdoll:newCharacter({
        skinTone = "medium",
        hairStyle = "short",
        hairColor = "brown",
        shirtStyle = "tshirt",
        shirtColor = "blue",
        pantsStyle = "pants",
        pantsColor = "brown",
        shoesStyle = "sneakers",
        shoesColor = "black"
    })

    -- Generate initial terrain based on level type
    self:generateTerrain()
end

function BaseBuilding:generateTerrain()
    -- Clear existing
    for y = 1, self.rows do
        for x = 1, self.cols do
            self.floors[y][x] = nil
            self.objects[y][x] = nil
        end
    end

    -- Add natural resources based on level type
    local treeChance, rockChance, bushChance = 0.05, 0.03, 0.02

    if self.levelType == "forest" then
        treeChance, bushChance = 0.12, 0.05
    elseif self.levelType == "cave" then
        rockChance = 0.10
        treeChance = 0.01
    elseif self.levelType == "oasis" then
        treeChance, bushChance = 0.04, 0.06
    elseif self.levelType == "ruins" then
        rockChance = 0.06
    end

    for y = 1, self.rows do
        for x = 1, self.cols do
            local r = love.math.random()
            if r < treeChance then
                self.objects[y][x] = "tree"
            elseif r < treeChance + rockChance then
                self.objects[y][x] = "rock"
            elseif r < treeChance + rockChance + bushChance then
                self.objects[y][x] = "bush"
            end
        end
    end

    -- Clear spawn area
    local cx, cy = math.floor(self.cols / 2), math.floor(self.rows / 2)
    for dy = -2, 2 do
        for dx = -2, 2 do
            local gx, gy = cx + dx, cy + dy
            if gx >= 1 and gx <= self.cols and gy >= 1 and gy <= self.rows then
                self.objects[gy][gx] = nil
            end
        end
    end
end

function BaseBuilding:update(dt)
    if self.showWardrobe then
        return  -- Pause game when wardrobe open
    end

    -- Player movement
    local dx, dy = 0, 0
    if love.keyboard.isDown("left", "a") then dx = -1; self.player.facing = -1 end
    if love.keyboard.isDown("right", "d") then dx = 1; self.player.facing = 1 end
    if love.keyboard.isDown("up", "w") then dy = -1 end
    if love.keyboard.isDown("down", "s") then dy = 1 end

    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx*dx + dy*dy)
        dx, dy = dx/len, dy/len

        local newX = self.player.x + dx * self.player.speed * dt
        local newY = self.player.y + dy * self.player.speed * dt

        -- Collision check
        if self:canMoveTo(newX, self.player.y) then
            self.player.x = newX
        end
        if self:canMoveTo(self.player.x, newY) then
            self.player.y = newY
        end
    end

    -- Clamp to bounds
    self.player.x = clamp(self.player.x, 20, self.width - 20)
    self.player.y = clamp(self.player.y, 20, self.height - 20)

    -- Update cursor position (mouse or player position)
    local mx, my = love.mouse.getPosition()
    self.cursorX = math.floor((mx + self.camera.x) / self.gridSize) + 1
    self.cursorY = math.floor((my + self.camera.y) / self.gridSize) + 1

    -- Camera follow
    local sw, sh = love.graphics.getDimensions()
    self.camera.x = clamp(self.player.x - sw/2, 0, math.max(0, self.width - sw))
    self.camera.y = clamp(self.player.y - sh/2, 0, math.max(0, self.height - sh))
end

function BaseBuilding:canMoveTo(x, y)
    local gx = math.floor(x / self.gridSize) + 1
    local gy = math.floor(y / self.gridSize) + 1

    if gx < 1 or gx > self.cols or gy < 1 or gy > self.rows then
        return false
    end

    local obj = self.objects[gy] and self.objects[gy][gx]
    if obj then
        local def = BUILDINGS[obj]
        if def and def.solid then
            return false
        end
    end

    return true
end

function BaseBuilding:placeBuilding(gx, gy)
    if not self.selectedBuilding then return end
    if gx < 1 or gx > self.cols or gy < 1 or gy > self.rows then return end

    local def = BUILDINGS[self.selectedBuilding]
    if not def then return end

    -- Check resources
    if def.cost then
        for res, amount in pairs(def.cost) do
            if (self.resources[res] or 0) < amount then
                return  -- Not enough resources
            end
        end
    end

    -- Check if space is clear (for non-floor items)
    if def.category ~= "floor" then
        if self.objects[gy][gx] then
            return  -- Space occupied
        end
    end

    -- Deduct resources
    if def.cost then
        for res, amount in pairs(def.cost) do
            self.resources[res] = self.resources[res] - amount
        end
    end

    -- Place it
    if def.category == "floor" then
        self.floors[gy][gx] = self.selectedBuilding
    else
        self.objects[gy][gx] = self.selectedBuilding
    end
end

function BaseBuilding:removeBuilding(gx, gy)
    if gx < 1 or gx > self.cols or gy < 1 or gy > self.rows then return end

    -- Try to remove object first
    local obj = self.objects[gy][gx]
    if obj then
        local def = BUILDINGS[obj]
        -- Harvest resources
        if def and def.harvestable and def.gives then
            for res, amount in pairs(def.gives) do
                self.resources[res] = (self.resources[res] or 0) + amount
            end
        end
        -- Refund partial cost for placed items
        if def and def.cost and not def.harvestable then
            for res, amount in pairs(def.cost) do
                self.resources[res] = (self.resources[res] or 0) + math.floor(amount / 2)
            end
        end
        self.objects[gy][gx] = nil
        return
    end

    -- Then try floor
    local floor = self.floors[gy][gx]
    if floor then
        local def = BUILDINGS[floor]
        if def and def.cost then
            for res, amount in pairs(def.cost) do
                self.resources[res] = (self.resources[res] or 0) + math.floor(amount / 2)
            end
        end
        self.floors[gy][gx] = nil
    end
end

function BaseBuilding:draw()
    local sw, sh = love.graphics.getDimensions()

    -- Background based on level type
    self:drawBackground()

    love.graphics.push()
    love.graphics.translate(-self.camera.x, -self.camera.y)

    -- Draw grid
    self:drawGrid()

    -- Draw floors
    for y = 1, self.rows do
        for x = 1, self.cols do
            local floor = self.floors[y][x]
            if floor then
                self:drawTile(x, y, floor)
            end
        end
    end

    -- Draw objects
    for y = 1, self.rows do
        for x = 1, self.cols do
            local obj = self.objects[y][x]
            if obj then
                self:drawObject(x, y, obj)
            end
        end
    end

    -- Draw player
    self:drawPlayer()

    -- Build cursor
    if self.buildMode and self.selectedBuilding then
        self:drawBuildCursor()
    end

    love.graphics.pop()

    -- UI
    self:drawUI()

    -- Wardrobe overlay
    if self.showWardrobe then
        self:drawWardrobe()
    end
end

function BaseBuilding:drawBackground()
    local sw, sh = love.graphics.getDimensions()
    local palette = PALETTES[self.levelType] or PALETTES.ruins
    local ground = palette.ground

    -- Draw textured background with dithering
    local tileSize = 8
    for py = 0, sh, tileSize do
        for px = 0, sw, tileSize do
            local worldX = px + self.camera.x
            local worldY = py + self.camera.y
            local noise = math.sin(worldX * 0.02) * math.cos(worldY * 0.02)
            local shade = 0.5 + noise * 0.3
            local color
            if shouldDither(worldX / tileSize, worldY / tileSize, shade) then
                color = ground[1]
            else
                color = ground[2]
            end
            -- Add occasional highlight
            if shouldDither(worldX / tileSize + 17, worldY / tileSize + 23, 0.15) then
                color = ground[3]
            end
            setColor(color[1], color[2], color[3], 1)
            love.graphics.rectangle("fill", px, py, tileSize, tileSize)
        end
    end
end

function BaseBuilding:drawGrid()
    local palette = PALETTES[self.levelType] or PALETTES.ruins
    local gridColor = lerpColor(palette.ground[2], {0, 0, 0}, 0.3)
    setColor(gridColor[1], gridColor[2], gridColor[3], 0.15)
    for y = 0, self.rows do
        love.graphics.line(0, y * self.gridSize, self.width, y * self.gridSize)
    end
    for x = 0, self.cols do
        love.graphics.line(x * self.gridSize, 0, x * self.gridSize, self.height)
    end
end

function BaseBuilding:drawTile(gx, gy, tileType)
    local def = BUILDINGS[tileType]
    if not def then return end

    local x, y = (gx - 1) * self.gridSize, (gy - 1) * self.gridSize
    local gs = self.gridSize

    if tileType == "wood_floor" then
        -- Wood planks with grain
        local base = {0.62, 0.48, 0.32}
        local dark = {0.52, 0.38, 0.25}
        local light = {0.72, 0.58, 0.42}
        -- Draw planks
        for py = 0, gs - 1, 8 do
            for px = 0, gs - 1 do
                local plankOffset = (math.floor(py / 8) % 2) * 4
                local grainNoise = math.sin((px + plankOffset) * 0.5 + py * 0.2)
                local color
                if grainNoise > 0.3 then
                    color = light
                elseif grainNoise < -0.3 then
                    color = dark
                else
                    color = base
                end
                -- Plank edges
                if py % 8 == 0 or py % 8 == 7 then
                    color = dark
                end
                setColor(color[1], color[2], color[3], 1)
                love.graphics.rectangle("fill", x + px, y + py, 1, 1)
            end
        end

    elseif tileType == "stone_floor" then
        -- Cobblestone pattern
        local base = {0.52, 0.52, 0.55}
        local dark = {0.42, 0.42, 0.45}
        local light = {0.62, 0.62, 0.65}
        local mortar = {0.35, 0.35, 0.38}
        -- Draw stones
        local stonePositions = {
            {0, 0, 14, 10}, {16, 0, 12, 12}, {14, 12, 14, 10},
            {0, 10, 13, 11}, {28, 10, 4, 12}, {0, 21, 10, 11},
            {10, 22, 12, 10}, {22, 22, 10, 10}
        }
        setColor(mortar[1], mortar[2], mortar[3], 1)
        love.graphics.rectangle("fill", x, y, gs, gs)
        for _, stone in ipairs(stonePositions) do
            local sx, sy, sw, sh = stone[1], stone[2], stone[3], stone[4]
            local shade = ((gx + gy + sx) % 3) / 3
            local color = lerpColor(dark, light, shade)
            setColor(color[1], color[2], color[3], 1)
            love.graphics.rectangle("fill", x + sx + 1, y + sy + 1, sw - 2, sh - 2)
            -- Highlight edge
            setColor(light[1], light[2], light[3], 0.5)
            love.graphics.line(x + sx + 1, y + sy + 1, x + sx + sw - 2, y + sy + 1)
        end

    elseif tileType == "grass_path" then
        -- Grass with worn path
        local grass = {0.35, 0.55, 0.30}
        local dirt = {0.50, 0.42, 0.30}
        local highlight = {0.45, 0.65, 0.38}
        for py = 0, gs - 1 do
            for px = 0, gs - 1 do
                local centerDist = math.abs(px - gs/2) + math.abs(py - gs/2)
                local pathBlend = clamp(1 - centerDist / (gs * 0.6), 0, 1)
                local color = lerpColor(grass, dirt, pathBlend * 0.7)
                if shouldDither(x + px, y + py, 0.2) and pathBlend < 0.3 then
                    color = highlight
                end
                setColor(color[1], color[2], color[3], 1)
                love.graphics.rectangle("fill", x + px, y + py, 1, 1)
            end
        end

    elseif tileType == "rug" then
        -- Decorative rug with pattern
        local base = {0.72, 0.28, 0.28}
        local accent = {0.85, 0.75, 0.35}
        local dark = {0.55, 0.18, 0.18}
        setColor(base[1], base[2], base[3], 1)
        love.graphics.rectangle("fill", x + 2, y + 2, gs - 4, gs - 4)
        -- Border
        setColor(accent[1], accent[2], accent[3], 1)
        love.graphics.rectangle("fill", x + 2, y + 2, gs - 4, 3)
        love.graphics.rectangle("fill", x + 2, y + gs - 5, gs - 4, 3)
        love.graphics.rectangle("fill", x + 2, y + 2, 3, gs - 4)
        love.graphics.rectangle("fill", x + gs - 5, y + 2, 3, gs - 4)
        -- Center pattern
        setColor(dark[1], dark[2], dark[3], 1)
        love.graphics.rectangle("fill", x + gs/2 - 4, y + gs/2 - 4, 8, 8)
        setColor(accent[1], accent[2], accent[3], 1)
        love.graphics.rectangle("fill", x + gs/2 - 2, y + gs/2 - 2, 4, 4)

    else
        -- Default tile with shading
        local base = def.color
        local dark = {base[1] * 0.8, base[2] * 0.8, base[3] * 0.8}
        local light = {math.min(base[1] * 1.2, 1), math.min(base[2] * 1.2, 1), math.min(base[3] * 1.2, 1)}
        setColor(base[1], base[2], base[3], 1)
        love.graphics.rectangle("fill", x + 1, y + 1, gs - 2, gs - 2)
        -- Top/left highlight
        setColor(light[1], light[2], light[3], 0.5)
        love.graphics.line(x + 1, y + 1, x + gs - 2, y + 1)
        love.graphics.line(x + 1, y + 1, x + 1, y + gs - 2)
        -- Bottom/right shadow
        setColor(dark[1], dark[2], dark[3], 0.5)
        love.graphics.line(x + 1, y + gs - 2, x + gs - 2, y + gs - 2)
        love.graphics.line(x + gs - 2, y + 1, x + gs - 2, y + gs - 2)
    end
end

function BaseBuilding:drawObject(gx, gy, objType)
    local def = BUILDINGS[objType]
    if not def then return end

    local x, y = (gx - 1) * self.gridSize, (gy - 1) * self.gridSize
    local gs = self.gridSize
    local time = love.timer.getTime()

    if objType == "tree" then
        -- Detailed tree with layered canopy
        local trunkBase = {0.48, 0.32, 0.22}
        local trunkDark = {0.35, 0.22, 0.15}
        local trunkLight = {0.58, 0.42, 0.30}
        local leafDark = {0.18, 0.42, 0.22}
        local leafBase = {0.25, 0.55, 0.28}
        local leafLight = {0.35, 0.68, 0.38}

        -- Shadow
        setColor(0, 0, 0, 0.2)
        love.graphics.ellipse("fill", x + gs/2 + 4, y + gs - 4, gs*0.35, gs*0.12)

        -- Trunk with bark texture
        for py = gs * 0.45, gs - 2, 1 do
            for px = gs * 0.35, gs * 0.65, 1 do
                local barkNoise = math.sin(py * 0.8 + px * 0.3)
                local color
                if barkNoise > 0.3 then color = trunkLight
                elseif barkNoise < -0.3 then color = trunkDark
                else color = trunkBase end
                setColor(color[1], color[2], color[3], 1)
                love.graphics.rectangle("fill", x + px, y + py, 1, 1)
            end
        end

        -- Layered canopy (back layer)
        setColor(leafDark[1], leafDark[2], leafDark[3], 1)
        love.graphics.circle("fill", x + gs*0.35, y + gs*0.32, gs*0.28)
        love.graphics.circle("fill", x + gs*0.65, y + gs*0.35, gs*0.25)

        -- Middle layer
        setColor(leafBase[1], leafBase[2], leafBase[3], 1)
        love.graphics.circle("fill", x + gs*0.5, y + gs*0.30, gs*0.35)
        love.graphics.circle("fill", x + gs*0.38, y + gs*0.40, gs*0.22)
        love.graphics.circle("fill", x + gs*0.62, y + gs*0.38, gs*0.22)

        -- Highlight layer
        setColor(leafLight[1], leafLight[2], leafLight[3], 1)
        love.graphics.circle("fill", x + gs*0.45, y + gs*0.25, gs*0.18)
        love.graphics.circle("fill", x + gs*0.58, y + gs*0.28, gs*0.15)

    elseif objType == "rock" then
        -- Detailed rock with facets
        local rockBase = {0.52, 0.50, 0.48}
        local rockDark = {0.38, 0.36, 0.35}
        local rockLight = {0.68, 0.65, 0.62}
        local rockHighlight = {0.78, 0.75, 0.72}

        -- Shadow
        setColor(0, 0, 0, 0.2)
        love.graphics.ellipse("fill", x + gs/2 + 3, y + gs*0.85, gs*0.38, gs*0.12)

        -- Main rock body (multi-faceted)
        setColor(rockBase[1], rockBase[2], rockBase[3], 1)
        love.graphics.polygon("fill",
            x + gs*0.15, y + gs*0.75,
            x + gs*0.25, y + gs*0.35,
            x + gs*0.55, y + gs*0.18,
            x + gs*0.80, y + gs*0.45,
            x + gs*0.85, y + gs*0.78,
            x + gs*0.50, y + gs*0.88)

        -- Light facet
        setColor(rockLight[1], rockLight[2], rockLight[3], 1)
        love.graphics.polygon("fill",
            x + gs*0.25, y + gs*0.35,
            x + gs*0.55, y + gs*0.18,
            x + gs*0.50, y + gs*0.50,
            x + gs*0.30, y + gs*0.55)

        -- Highlight
        setColor(rockHighlight[1], rockHighlight[2], rockHighlight[3], 1)
        love.graphics.polygon("fill",
            x + gs*0.35, y + gs*0.28,
            x + gs*0.50, y + gs*0.22,
            x + gs*0.45, y + gs*0.38)

        -- Dark facet
        setColor(rockDark[1], rockDark[2], rockDark[3], 1)
        love.graphics.polygon("fill",
            x + gs*0.50, y + gs*0.50,
            x + gs*0.80, y + gs*0.45,
            x + gs*0.85, y + gs*0.78,
            x + gs*0.55, y + gs*0.75)

    elseif objType == "bush" then
        -- Berry bush with detail
        local leafDark = {0.22, 0.48, 0.25}
        local leafBase = {0.32, 0.62, 0.35}
        local leafLight = {0.42, 0.72, 0.45}
        local berry = {0.85, 0.25, 0.28}

        -- Shadow
        setColor(0, 0, 0, 0.15)
        love.graphics.ellipse("fill", x + gs/2 + 2, y + gs*0.88, gs*0.35, gs*0.10)

        -- Bush layers
        setColor(leafDark[1], leafDark[2], leafDark[3], 1)
        love.graphics.circle("fill", x + gs*0.35, y + gs*0.65, gs*0.28)
        love.graphics.circle("fill", x + gs*0.65, y + gs*0.62, gs*0.25)

        setColor(leafBase[1], leafBase[2], leafBase[3], 1)
        love.graphics.circle("fill", x + gs*0.5, y + gs*0.58, gs*0.32)

        setColor(leafLight[1], leafLight[2], leafLight[3], 1)
        love.graphics.circle("fill", x + gs*0.45, y + gs*0.52, gs*0.18)
        love.graphics.circle("fill", x + gs*0.58, y + gs*0.55, gs*0.14)

        -- Berries
        setColor(berry[1], berry[2], berry[3], 1)
        love.graphics.circle("fill", x + gs*0.35, y + gs*0.55, 2)
        love.graphics.circle("fill", x + gs*0.62, y + gs*0.50, 2)
        love.graphics.circle("fill", x + gs*0.48, y + gs*0.68, 2)
        setColor(1, 0.8, 0.8, 0.8)
        love.graphics.circle("fill", x + gs*0.34, y + gs*0.54, 1)

    elseif objType == "campfire" then
        -- Detailed campfire with logs and flames
        local logDark = {0.32, 0.22, 0.15}
        local logBase = {0.45, 0.32, 0.22}
        local stoneDark = {0.35, 0.35, 0.38}
        local stoneBase = {0.48, 0.48, 0.52}

        -- Fire glow
        local glowSize = 0.5 + math.sin(time * 3) * 0.1
        setColor(1, 0.5, 0.1, 0.15)
        love.graphics.circle("fill", x + gs/2, y + gs*0.55, gs * glowSize)

        -- Stone ring
        for i = 0, 7 do
            local angle = i * math.pi / 4
            local sx = x + gs/2 + math.cos(angle) * gs * 0.35
            local sy = y + gs*0.65 + math.sin(angle) * gs * 0.20
            local shade = (i % 2 == 0) and stoneBase or stoneDark
            setColor(shade[1], shade[2], shade[3], 1)
            love.graphics.circle("fill", sx, sy, gs * 0.10)
        end

        -- Logs
        setColor(logBase[1], logBase[2], logBase[3], 1)
        love.graphics.polygon("fill",
            x + gs*0.25, y + gs*0.72,
            x + gs*0.30, y + gs*0.58,
            x + gs*0.65, y + gs*0.68,
            x + gs*0.60, y + gs*0.78)
        setColor(logDark[1], logDark[2], logDark[3], 1)
        love.graphics.polygon("fill",
            x + gs*0.35, y + gs*0.78,
            x + gs*0.42, y + gs*0.62,
            x + gs*0.78, y + gs*0.72,
            x + gs*0.70, y + gs*0.82)

        -- Flames (animated)
        local flicker1 = math.sin(time * 12) * 0.15 + 0.85
        local flicker2 = math.sin(time * 15 + 1) * 0.12 + 0.88
        local flicker3 = math.sin(time * 10 + 2) * 0.18 + 0.82

        -- Outer flame
        setColor(1, 0.35, 0.1, 0.9)
        love.graphics.polygon("fill",
            x + gs*0.35, y + gs*0.65,
            x + gs*0.50, y + gs*0.25 * flicker1,
            x + gs*0.65, y + gs*0.65)

        -- Middle flame
        setColor(1, 0.55, 0.15, 0.95)
        love.graphics.polygon("fill",
            x + gs*0.40, y + gs*0.62,
            x + gs*0.50, y + gs*0.32 * flicker2,
            x + gs*0.60, y + gs*0.62)

        -- Inner flame (yellow core)
        setColor(1, 0.90, 0.35, 1)
        love.graphics.polygon("fill",
            x + gs*0.44, y + gs*0.58,
            x + gs*0.50, y + gs*0.40 * flicker3,
            x + gs*0.56, y + gs*0.58)

        -- Sparks
        setColor(1, 0.8, 0.3, 0.8)
        local sparkY = (time * 30) % gs * 0.3
        love.graphics.circle("fill", x + gs*0.45, y + gs*0.35 - sparkY, 1)
        love.graphics.circle("fill", x + gs*0.55, y + gs*0.38 - sparkY * 0.8, 1)

    elseif objType == "torch" then
        -- Wall torch with flame
        local woodBase = {0.45, 0.32, 0.22}
        local woodDark = {0.32, 0.22, 0.15}

        -- Glow
        local glowSize = 0.35 + math.sin(time * 4) * 0.05
        setColor(1, 0.6, 0.2, 0.12)
        love.graphics.circle("fill", x + gs/2, y + gs*0.35, gs * glowSize)

        -- Torch handle
        setColor(woodBase[1], woodBase[2], woodBase[3], 1)
        love.graphics.rectangle("fill", x + gs*0.42, y + gs*0.45, gs*0.16, gs*0.50)
        setColor(woodDark[1], woodDark[2], woodDark[3], 1)
        love.graphics.rectangle("fill", x + gs*0.42, y + gs*0.45, gs*0.04, gs*0.50)

        -- Flame
        local flicker = math.sin(time * 14) * 0.1 + 0.9
        setColor(1, 0.4, 0.1, 0.9)
        love.graphics.polygon("fill",
            x + gs*0.35, y + gs*0.48,
            x + gs*0.50, y + gs*0.15 * flicker,
            x + gs*0.65, y + gs*0.48)
        setColor(1, 0.75, 0.25, 1)
        love.graphics.polygon("fill",
            x + gs*0.42, y + gs*0.45,
            x + gs*0.50, y + gs*0.25 * flicker,
            x + gs*0.58, y + gs*0.45)

    elseif objType == "bed" then
        -- Detailed bed
        local frameBase = {0.48, 0.35, 0.25}
        local frameDark = {0.35, 0.25, 0.18}
        local blanketBase = {0.65, 0.28, 0.28}
        local blanketLight = {0.78, 0.38, 0.38}
        local pillowBase = {0.92, 0.90, 0.85}

        -- Frame
        setColor(frameDark[1], frameDark[2], frameDark[3], 1)
        love.graphics.rectangle("fill", x + 2, y + gs - 8, gs - 4, 6)
        setColor(frameBase[1], frameBase[2], frameBase[3], 1)
        love.graphics.rectangle("fill", x + 2, y + 4, 4, gs - 10)
        love.graphics.rectangle("fill", x + gs - 6, y + 4, 4, gs - 10)

        -- Headboard
        setColor(frameBase[1], frameBase[2], frameBase[3], 1)
        love.graphics.rectangle("fill", x + 2, y + 2, gs - 4, 8)
        setColor(frameDark[1], frameDark[2], frameDark[3], 1)
        love.graphics.line(x + 4, y + 3, x + 4, y + 8)
        love.graphics.line(x + gs - 5, y + 3, x + gs - 5, y + 8)

        -- Blanket
        setColor(blanketBase[1], blanketBase[2], blanketBase[3], 1)
        love.graphics.rectangle("fill", x + 5, y + 12, gs - 10, gs - 20)
        setColor(blanketLight[1], blanketLight[2], blanketLight[3], 1)
        love.graphics.rectangle("fill", x + 5, y + 12, gs - 10, 4)

        -- Pillow
        setColor(pillowBase[1], pillowBase[2], pillowBase[3], 1)
        love.graphics.rectangle("fill", x + 6, y + 5, gs - 12, 8)
        setColor(0.85, 0.82, 0.78, 1)
        love.graphics.line(x + 8, y + 8, x + gs - 9, y + 8)

    elseif objType == "table" then
        -- Wooden table with grain
        local topBase = {0.58, 0.45, 0.32}
        local topLight = {0.68, 0.55, 0.42}
        local legDark = {0.42, 0.32, 0.22}

        -- Shadow
        setColor(0, 0, 0, 0.15)
        love.graphics.rectangle("fill", x + 6, y + gs - 4, gs - 10, 3)

        -- Legs
        setColor(legDark[1], legDark[2], legDark[3], 1)
        love.graphics.rectangle("fill", x + 4, y + gs*0.6, 4, gs*0.35)
        love.graphics.rectangle("fill", x + gs - 8, y + gs*0.6, 4, gs*0.35)

        -- Tabletop
        setColor(topBase[1], topBase[2], topBase[3], 1)
        love.graphics.rectangle("fill", x + 2, y + gs*0.25, gs - 4, gs*0.40)
        -- Wood grain
        setColor(topLight[1], topLight[2], topLight[3], 0.6)
        for i = 0, 4 do
            love.graphics.line(x + 4, y + gs*0.28 + i*5, x + gs - 5, y + gs*0.30 + i*5)
        end
        -- Edge highlight
        setColor(topLight[1], topLight[2], topLight[3], 1)
        love.graphics.rectangle("fill", x + 2, y + gs*0.25, gs - 4, 2)

    elseif objType == "chair" then
        -- Chair with cushion
        local frameBase = {0.52, 0.38, 0.28}
        local frameDark = {0.38, 0.28, 0.20}
        local cushion = {0.65, 0.32, 0.28}

        -- Back legs
        setColor(frameDark[1], frameDark[2], frameDark[3], 1)
        love.graphics.rectangle("fill", x + 6, y + 4, 3, gs - 8)
        love.graphics.rectangle("fill", x + gs - 9, y + 4, 3, gs - 8)

        -- Back
        setColor(frameBase[1], frameBase[2], frameBase[3], 1)
        love.graphics.rectangle("fill", x + 5, y + 4, gs - 10, 10)

        -- Seat
        setColor(cushion[1], cushion[2], cushion[3], 1)
        love.graphics.rectangle("fill", x + 4, y + gs*0.45, gs - 8, gs*0.30)

        -- Front legs
        setColor(frameDark[1], frameDark[2], frameDark[3], 1)
        love.graphics.rectangle("fill", x + 4, y + gs*0.70, 3, gs*0.25)
        love.graphics.rectangle("fill", x + gs - 7, y + gs*0.70, 3, gs*0.25)

    elseif objType == "chest" then
        -- Treasure chest
        local woodBase = {0.58, 0.42, 0.28}
        local woodDark = {0.42, 0.30, 0.20}
        local metalBase = {0.72, 0.65, 0.35}
        local metalDark = {0.55, 0.48, 0.25}

        -- Shadow
        setColor(0, 0, 0, 0.2)
        love.graphics.ellipse("fill", x + gs/2 + 2, y + gs - 3, gs*0.40, 4)

        -- Chest body
        setColor(woodBase[1], woodBase[2], woodBase[3], 1)
        love.graphics.rectangle("fill", x + 3, y + gs*0.35, gs - 6, gs*0.55)
        setColor(woodDark[1], woodDark[2], woodDark[3], 1)
        love.graphics.rectangle("fill", x + 3, y + gs*0.35, gs - 6, 3)

        -- Lid (arched)
        setColor(woodBase[1], woodBase[2], woodBase[3], 1)
        love.graphics.arc("fill", x + gs/2, y + gs*0.38, gs*0.47, math.pi, 0)

        -- Metal bands
        setColor(metalBase[1], metalBase[2], metalBase[3], 1)
        love.graphics.rectangle("fill", x + 3, y + gs*0.50, gs - 6, 3)
        love.graphics.rectangle("fill", x + 3, y + gs*0.75, gs - 6, 3)
        love.graphics.rectangle("fill", x + gs/2 - 2, y + gs*0.18, 4, gs*0.35)

        -- Lock
        setColor(metalDark[1], metalDark[2], metalDark[3], 1)
        love.graphics.rectangle("fill", x + gs/2 - 4, y + gs*0.55, 8, 10)
        setColor(0.2, 0.2, 0.22, 1)
        love.graphics.circle("fill", x + gs/2, y + gs*0.62, 2)

    elseif objType == "workbench" then
        -- Crafting workbench with tools
        local benchBase = {0.52, 0.42, 0.32}
        local benchDark = {0.38, 0.30, 0.22}
        local metalBase = {0.55, 0.55, 0.58}

        -- Legs
        setColor(benchDark[1], benchDark[2], benchDark[3], 1)
        love.graphics.rectangle("fill", x + 3, y + gs*0.55, 4, gs*0.40)
        love.graphics.rectangle("fill", x + gs - 7, y + gs*0.55, 4, gs*0.40)

        -- Top surface
        setColor(benchBase[1], benchBase[2], benchBase[3], 1)
        love.graphics.rectangle("fill", x + 2, y + gs*0.25, gs - 4, gs*0.35)
        -- Wear marks
        setColor(benchDark[1], benchDark[2], benchDark[3], 0.4)
        love.graphics.rectangle("fill", x + gs*0.3, y + gs*0.30, 8, 3)
        love.graphics.rectangle("fill", x + gs*0.55, y + gs*0.42, 6, 2)

        -- Tools
        -- Hammer
        setColor(0.5, 0.4, 0.3, 1)
        love.graphics.rectangle("fill", x + 5, y + gs*0.28, 2, 12)
        setColor(metalBase[1], metalBase[2], metalBase[3], 1)
        love.graphics.rectangle("fill", x + 3, y + gs*0.28, 6, 5)

        -- Saw
        setColor(metalBase[1], metalBase[2], metalBase[3], 1)
        love.graphics.rectangle("fill", x + gs - 14, y + gs*0.30, 10, 3)
        setColor(0.5, 0.4, 0.3, 1)
        love.graphics.rectangle("fill", x + gs - 8, y + gs*0.28, 5, 7)

    elseif objType == "wood_wall" then
        -- Wooden wall with planks
        local plankBase = {0.52, 0.38, 0.25}
        local plankDark = {0.40, 0.28, 0.18}
        local plankLight = {0.62, 0.48, 0.35}

        for i = 0, 3 do
            local shade = (i % 2 == 0) and plankBase or lerpColor(plankBase, plankLight, 0.3)
            setColor(shade[1], shade[2], shade[3], 1)
            love.graphics.rectangle("fill", x + 1, y + i * 8, gs - 2, 7)
            setColor(plankDark[1], plankDark[2], plankDark[3], 1)
            love.graphics.line(x + 1, y + i * 8 + 7, x + gs - 2, y + i * 8 + 7)
        end
        -- Nail details
        setColor(0.4, 0.4, 0.42, 1)
        love.graphics.circle("fill", x + 4, y + 4, 1)
        love.graphics.circle("fill", x + gs - 5, y + 4, 1)
        love.graphics.circle("fill", x + 4, y + gs - 5, 1)
        love.graphics.circle("fill", x + gs - 5, y + gs - 5, 1)

    elseif objType == "stone_wall" then
        -- Stone wall with mortar
        local stoneBase = {0.45, 0.45, 0.48}
        local stoneDark = {0.35, 0.35, 0.38}
        local stoneLight = {0.58, 0.58, 0.62}
        local mortar = {0.30, 0.30, 0.32}

        setColor(mortar[1], mortar[2], mortar[3], 1)
        love.graphics.rectangle("fill", x, y, gs, gs)

        -- Draw irregular stones
        local stones = {
            {1, 1, 14, 8}, {16, 1, 14, 10},
            {1, 10, 10, 10}, {12, 12, 12, 8},
            {1, 21, 12, 10}, {14, 21, 16, 10},
            {25, 10, 6, 10}
        }
        for _, stone in ipairs(stones) do
            local sx, sy, sw, sh = stone[1], stone[2], stone[3], stone[4]
            local shade = ((gx + gy + sx) % 3)
            local color
            if shade == 0 then color = stoneDark
            elseif shade == 1 then color = stoneBase
            else color = stoneLight end
            setColor(color[1], color[2], color[3], 1)
            love.graphics.rectangle("fill", x + sx, y + sy, sw - 1, sh - 1)
            -- Highlight
            setColor(stoneLight[1], stoneLight[2], stoneLight[3], 0.4)
            love.graphics.line(x + sx, y + sy, x + sx + sw - 2, y + sy)
        end

    elseif objType == "fence" then
        -- Picket fence
        local woodBase = {0.58, 0.45, 0.30}
        local woodDark = {0.45, 0.35, 0.22}
        local woodLight = {0.68, 0.55, 0.40}

        -- Horizontal rails
        setColor(woodBase[1], woodBase[2], woodBase[3], 1)
        love.graphics.rectangle("fill", x, y + gs*0.30, gs, 4)
        love.graphics.rectangle("fill", x, y + gs*0.70, gs, 4)

        -- Pickets
        for i = 0, 4 do
            local px = x + 2 + i * 6
            local shade = (i % 2 == 0) and woodBase or woodLight
            setColor(shade[1], shade[2], shade[3], 1)
            love.graphics.rectangle("fill", px, y + 2, 4, gs - 4)
            -- Pointed top
            love.graphics.polygon("fill",
                px, y + 2,
                px + 2, y - 2,
                px + 4, y + 2)
            -- Shadow
            setColor(woodDark[1], woodDark[2], woodDark[3], 1)
            love.graphics.line(px + 3, y + 2, px + 3, y + gs - 5)
        end

    elseif objType == "flower_pot" then
        -- Terracotta pot with flowers
        local potBase = {0.72, 0.45, 0.32}
        local potDark = {0.55, 0.35, 0.25}
        local dirtColor = {0.40, 0.32, 0.25}
        local flowerColors = {{0.95, 0.45, 0.55}, {0.95, 0.85, 0.40}, {0.65, 0.45, 0.85}}

        -- Shadow
        setColor(0, 0, 0, 0.15)
        love.graphics.ellipse("fill", x + gs/2 + 2, y + gs - 3, gs*0.35, 4)

        -- Pot
        setColor(potBase[1], potBase[2], potBase[3], 1)
        love.graphics.polygon("fill",
            x + gs*0.25, y + gs*0.45,
            x + gs*0.20, y + gs*0.95,
            x + gs*0.80, y + gs*0.95,
            x + gs*0.75, y + gs*0.45)
        -- Rim
        love.graphics.rectangle("fill", x + gs*0.22, y + gs*0.42, gs*0.56, 5)
        -- Shading
        setColor(potDark[1], potDark[2], potDark[3], 1)
        love.graphics.polygon("fill",
            x + gs*0.65, y + gs*0.45,
            x + gs*0.70, y + gs*0.95,
            x + gs*0.80, y + gs*0.95,
            x + gs*0.75, y + gs*0.45)

        -- Dirt
        setColor(dirtColor[1], dirtColor[2], dirtColor[3], 1)
        love.graphics.ellipse("fill", x + gs/2, y + gs*0.45, gs*0.25, 4)

        -- Flowers (use position-based selection)
        local flowerIdx = ((gx + gy) % 3) + 1
        local flower = flowerColors[flowerIdx]
        -- Stems
        setColor(0.25, 0.50, 0.28, 1)
        love.graphics.line(x + gs*0.35, y + gs*0.42, x + gs*0.38, y + gs*0.18)
        love.graphics.line(x + gs*0.50, y + gs*0.42, x + gs*0.50, y + gs*0.12)
        love.graphics.line(x + gs*0.65, y + gs*0.42, x + gs*0.62, y + gs*0.20)
        -- Petals
        setColor(flower[1], flower[2], flower[3], 1)
        love.graphics.circle("fill", x + gs*0.38, y + gs*0.15, 4)
        love.graphics.circle("fill", x + gs*0.50, y + gs*0.10, 5)
        love.graphics.circle("fill", x + gs*0.62, y + gs*0.18, 4)
        -- Centers
        setColor(0.95, 0.85, 0.35, 1)
        love.graphics.circle("fill", x + gs*0.38, y + gs*0.15, 2)
        love.graphics.circle("fill", x + gs*0.50, y + gs*0.10, 2)
        love.graphics.circle("fill", x + gs*0.62, y + gs*0.18, 2)

    else
        -- Generic object with enhanced shading
        local base = def.color
        local dark = {base[1] * 0.75, base[2] * 0.75, base[3] * 0.75}
        local light = {math.min(base[1] * 1.25, 1), math.min(base[2] * 1.25, 1), math.min(base[3] * 1.25, 1)}

        -- Shadow
        setColor(0, 0, 0, 0.15)
        love.graphics.ellipse("fill", x + gs/2 + 2, y + gs - 3, gs*0.35, 4)

        -- Main shape
        local margin = def.solid and 4 or 6
        setColor(base[1], base[2], base[3], 1)
        love.graphics.rectangle("fill", x + margin, y + margin, gs - margin*2, gs - margin*2)

        -- Highlight
        setColor(light[1], light[2], light[3], 0.6)
        love.graphics.rectangle("fill", x + margin, y + margin, gs - margin*2, 3)
        love.graphics.rectangle("fill", x + margin, y + margin, 3, gs - margin*2)

        -- Shadow edge
        setColor(dark[1], dark[2], dark[3], 0.6)
        love.graphics.rectangle("fill", x + margin, y + gs - margin - 3, gs - margin*2, 3)
        love.graphics.rectangle("fill", x + gs - margin - 3, y + margin, 3, gs - margin*2)
    end
end

function BaseBuilding:drawPlayer()
    local p = self.player
    if p.character then
        p.character:draw(p.x - 16, p.y - 40, 2.5, p.facing)
    else
        setColor(1, 1, 1, 1)
        love.graphics.circle("fill", p.x, p.y, 12)
    end
end

function BaseBuilding:drawBuildCursor()
    local gx, gy = self.cursorX, self.cursorY
    if gx < 1 or gx > self.cols or gy < 1 or gy > self.rows then return end

    local x, y = (gx - 1) * self.gridSize, (gy - 1) * self.gridSize
    local def = BUILDINGS[self.selectedBuilding]

    -- Check if can place
    local canPlace = true
    if def and def.cost then
        for res, amount in pairs(def.cost) do
            if (self.resources[res] or 0) < amount then
                canPlace = false
                break
            end
        end
    end
    if def and def.category ~= "floor" and self.objects[gy] and self.objects[gy][gx] then
        canPlace = false
    end

    -- Draw preview
    if canPlace then
        setColor(0.3, 0.9, 0.3, 0.5)
    else
        setColor(0.9, 0.3, 0.3, 0.5)
    end
    love.graphics.rectangle("fill", x, y, self.gridSize, self.gridSize)
    setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, self.gridSize, self.gridSize)
end

function BaseBuilding:drawUI()
    local sw, sh = love.graphics.getDimensions()

    -- Resources bar
    setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 10, 10, 200, 80)
    setColor(1, 1, 1, 1)
    love.graphics.print("Resources:", 20, 15)
    love.graphics.print("Wood: " .. self.resources.wood, 20, 32)
    love.graphics.print("Stone: " .. self.resources.stone, 110, 32)
    love.graphics.print("Metal: " .. self.resources.metal, 20, 49)
    love.graphics.print("Cloth: " .. self.resources.cloth, 110, 49)
    love.graphics.print(self.levelName, 20, 66)

    -- Controls
    setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 10, sh - 70, 350, 60)
    setColor(1, 1, 1, 1)
    love.graphics.print("WASD: Move | B: Build Mode | C: Wardrobe | ESC: Exit", 20, sh - 62)
    love.graphics.print("LClick: Place/Harvest | RClick: Remove", 20, sh - 45)
    if self.buildMode then
        love.graphics.print("1-6: Select Building | Q/E: Category", 20, sh - 28)
    end

    -- Build mode panel
    if self.buildMode then
        self:drawBuildPanel()
    end
end

function BaseBuilding:drawBuildPanel()
    local sw, sh = love.graphics.getDimensions()

    setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", sw - 220, 10, 210, 300)

    setColor(1, 1, 0.8, 1)
    love.graphics.print("BUILD MODE", sw - 210, 15)

    setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("Category: " .. self.buildCategory, sw - 210, 35)

    -- List buildings in category
    local y = 60
    local i = 1
    for id, def in pairs(BUILDINGS) do
        if def.category == self.buildCategory or
           (self.buildCategory == "all") then
            local selected = self.selectedBuilding == id
            if selected then
                setColor(0.3, 0.5, 0.8, 1)
                love.graphics.rectangle("fill", sw - 215, y - 2, 200, 18)
            end

            setColor(def.color[1], def.color[2], def.color[3], 1)
            love.graphics.rectangle("fill", sw - 210, y, 14, 14)

            setColor(1, 1, 1, selected and 1 or 0.7)
            love.graphics.print(i .. ". " .. def.name, sw - 190, y)

            y = y + 20
            i = i + 1
            if i > 9 then break end
        end
    end
end

function BaseBuilding:drawWardrobe()
    local sw, sh = love.graphics.getDimensions()

    -- Overlay
    setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Panel
    setColor(0.15, 0.15, 0.2, 1)
    love.graphics.rectangle("fill", sw/2 - 300, 50, 600, sh - 100)
    setColor(0.4, 0.4, 0.5, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", sw/2 - 300, 50, 600, sh - 100)

    -- Title
    setColor(1, 1, 0.9, 1)
    love.graphics.printf("WARDROBE", sw/2 - 290, 60, 580, "center")

    -- Character preview
    if self.player.character then
        self.player.character:draw(sw/2 - 40, 100, 5, 1)
    end

    -- Categories
    local categories = {"skin", "hair", "shirt", "pants", "shoes", "hat"}
    local catY = 250

    setColor(1, 1, 1, 1)
    love.graphics.print("Q/E: Category | A/D: Option | C: Close", sw/2 - 120, sh - 80)

    for i, cat in ipairs(categories) do
        local selected = self.wardrobeSelection.category == cat
        if selected then
            setColor(0.3, 0.5, 0.7, 1)
            love.graphics.rectangle("fill", sw/2 - 280, catY - 2, 250, 24)
        end

        setColor(1, 1, 1, selected and 1 or 0.6)
        love.graphics.print(cat:upper(), sw/2 - 270, catY)

        -- Current value
        local value = self:getWardrobeValue(cat)
        love.graphics.print(": " .. tostring(value), sw/2 - 180, catY)

        catY = catY + 30
    end
end

function BaseBuilding:getWardrobeValue(category)
    local c = self.player.character
    if not c then return "?" end

    if category == "skin" then return c.skinTone
    elseif category == "hair" then return c.hairStyle .. " (" .. c.hairColor .. ")"
    elseif category == "shirt" then return c.shirtStyle .. " (" .. c.shirtColor .. ")"
    elseif category == "pants" then return c.pantsStyle .. " (" .. c.pantsColor .. ")"
    elseif category == "shoes" then return c.shoesStyle .. " (" .. c.shoesColor .. ")"
    elseif category == "hat" then return c.hatStyle .. " (" .. c.hatColor .. ")"
    end
    return "?"
end

function BaseBuilding:cycleWardrobe(direction)
    local c = self.player.character
    if not c then return end

    local cat = self.wardrobeSelection.category
    local opts = Paperdoll.options

    local function cycleList(list, current, dir)
        local idx = 1
        for i, v in ipairs(list) do
            if v == current then idx = i break end
        end
        idx = idx + dir
        if idx < 1 then idx = #list end
        if idx > #list then idx = 1 end
        return list[idx]
    end

    if cat == "skin" then
        c.skinTone = cycleList(opts.skinTones, c.skinTone, direction)
    elseif cat == "hair" then
        c.hairStyle = cycleList(opts.hairStyles, c.hairStyle, direction)
    elseif cat == "shirt" then
        c.shirtStyle = cycleList(opts.shirtStyles, c.shirtStyle, direction)
    elseif cat == "pants" then
        c.pantsStyle = cycleList(opts.pantsStyles, c.pantsStyle, direction)
    elseif cat == "shoes" then
        c.shoesStyle = cycleList(opts.shoesStyles, c.shoesStyle, direction)
    elseif cat == "hat" then
        c.hatStyle = cycleList(opts.hatStyles, c.hatStyle, direction)
    end

    c:rebuildLayers()
end

function BaseBuilding:cycleWardrobeColor(direction)
    local c = self.player.character
    if not c then return end

    local cat = self.wardrobeSelection.category
    local opts = Paperdoll.options

    local function cycleList(list, current, dir)
        local idx = 1
        for i, v in ipairs(list) do
            if v == current then idx = i break end
        end
        idx = idx + dir
        if idx < 1 then idx = #list end
        if idx > #list then idx = 1 end
        return list[idx]
    end

    if cat == "hair" then
        c.hairColor = cycleList(opts.hairColors, c.hairColor, direction)
    elseif cat == "shirt" then
        c.shirtColor = cycleList(opts.colors, c.shirtColor, direction)
    elseif cat == "pants" then
        c.pantsColor = cycleList(opts.colors, c.pantsColor, direction)
    elseif cat == "shoes" then
        c.shoesColor = cycleList(opts.colors, c.shoesColor, direction)
    elseif cat == "hat" then
        c.hatColor = cycleList(opts.colors, c.hatColor, direction)
    end

    c:rebuildLayers()
end

function BaseBuilding:keypressed(key)
    if self.showWardrobe then
        if key == "c" or key == "escape" then
            self.showWardrobe = false
        elseif key == "q" then
            local cats = {"skin", "hair", "shirt", "pants", "shoes", "hat"}
            local idx = 1
            for i, c in ipairs(cats) do
                if c == self.wardrobeSelection.category then idx = i break end
            end
            idx = idx - 1
            if idx < 1 then idx = #cats end
            self.wardrobeSelection.category = cats[idx]
        elseif key == "e" then
            local cats = {"skin", "hair", "shirt", "pants", "shoes", "hat"}
            local idx = 1
            for i, c in ipairs(cats) do
                if c == self.wardrobeSelection.category then idx = i break end
            end
            idx = idx + 1
            if idx > #cats then idx = 1 end
            self.wardrobeSelection.category = cats[idx]
        elseif key == "a" or key == "left" then
            self:cycleWardrobe(-1)
        elseif key == "d" or key == "right" then
            self:cycleWardrobe(1)
        elseif key == "w" or key == "up" then
            self:cycleWardrobeColor(-1)
        elseif key == "s" or key == "down" then
            self:cycleWardrobeColor(1)
        end
        return
    end

    if key == "escape" then
        Gamestate:pop()
    elseif key == "b" then
        self.buildMode = not self.buildMode
    elseif key == "c" then
        self.showWardrobe = true
    elseif key == "q" and self.buildMode then
        local cats = {"floor", "wall", "furniture", "decor", "nature"}
        local idx = 1
        for i, c in ipairs(cats) do
            if c == self.buildCategory then idx = i break end
        end
        idx = idx - 1
        if idx < 1 then idx = #cats end
        self.buildCategory = cats[idx]
        self.selectedBuilding = nil
    elseif key == "e" and self.buildMode then
        local cats = {"floor", "wall", "furniture", "decor", "nature"}
        local idx = 1
        for i, c in ipairs(cats) do
            if c == self.buildCategory then idx = i break end
        end
        idx = idx + 1
        if idx > #cats then idx = 1 end
        self.buildCategory = cats[idx]
        self.selectedBuilding = nil
    elseif self.buildMode and tonumber(key) then
        local num = tonumber(key)
        local i = 1
        for id, def in pairs(BUILDINGS) do
            if def.category == self.buildCategory then
                if i == num then
                    self.selectedBuilding = id
                    break
                end
                i = i + 1
            end
        end
    end
end

function BaseBuilding:mousepressed(x, y, button)
    if self.showWardrobe then return end

    local gx = math.floor((x + self.camera.x) / self.gridSize) + 1
    local gy = math.floor((y + self.camera.y) / self.gridSize) + 1

    if button == 1 then  -- Left click
        if self.buildMode and self.selectedBuilding then
            self:placeBuilding(gx, gy)
        else
            -- Harvest/interact
            self:removeBuilding(gx, gy)
        end
    elseif button == 2 then  -- Right click
        self:removeBuilding(gx, gy)
    end
end

return BaseBuilding
