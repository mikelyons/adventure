-- World Generation Module
-- Creates continents, towns, and points of interest

local WorldGen = {}

-- World configuration
WorldGen.CONFIG = {
    -- World size (20x20 tiles * 64px = 1280px, fits well on screen with room to explore)
    worldCols = 20,
    worldRows = 20,
    tileSize = 64,  -- Larger tiles for higher resolution graphics
    oceanBorderSize = 1, -- Tiles of ocean around the border

    -- Continent generation (adjusted for smaller world)
    numContinents = 1,
    continentMinSize = 50,  -- minimum tiles (20x20 = 400 total, 18x18 = 324 playable)
    continentMaxSize = 180, -- maximum tiles

    -- Town generation
    townsPerSmallContinent = {1, 1},   -- min, max
    townsPerMediumContinent = {1, 2},
    townsPerLargeContinent = {2, 3},

    -- Terrain thresholds
    deepWater = 0.30,
    shallowWater = 0.38,
    sand = 0.42,
    grass = 0.65,
    forest = 0.78,
    mountain = 0.88,
}

-- Town name components for procedural generation
local TOWN_PREFIXES = {
    "River", "Oak", "Stone", "Iron", "Silver", "Golden", "Shadow", "Sun",
    "Moon", "Star", "Wind", "Storm", "Frost", "Ember", "Crystal", "Ancient",
    "New", "Old", "East", "West", "North", "South", "High", "Low", "Green",
    "Red", "Blue", "White", "Black", "Gray", "Bright", "Dark", "Clear"
}

local TOWN_SUFFIXES = {
    "town", "ville", "burg", "ford", "port", "haven", "holm", "dale",
    "vale", "wood", "field", "bridge", "gate", "keep", "hold", "watch",
    "rest", "fall", "spring", "creek", "brook", "hill", "peak", "marsh"
}

-- Building types for towns
WorldGen.BUILDING_TYPES = {
    -- Essential buildings (every town has these)
    essential = {
        {type = "inn", name = "Inn", minSize = "small"},
        {type = "shop", name = "General Store", minSize = "small"},
    },
    -- Common buildings (most towns)
    common = {
        {type = "tavern", name = "Tavern", minSize = "small"},
        {type = "blacksmith", name = "Blacksmith", minSize = "medium"},
        {type = "temple", name = "Temple", minSize = "medium"},
    },
    -- Uncommon buildings (larger towns)
    uncommon = {
        {type = "guild", name = "Adventurer's Guild", minSize = "medium"},
        {type = "library", name = "Library", minSize = "medium"},
        {type = "alchemist", name = "Alchemist", minSize = "medium"},
        {type = "armory", name = "Armory", minSize = "large"},
    },
    -- Rare buildings (only large towns/cities)
    rare = {
        {type = "castle", name = "Castle", minSize = "large"},
        {type = "academy", name = "Academy", minSize = "large"},
        {type = "arena", name = "Arena", minSize = "large"},
    },
    -- Residential
    residential = {
        {type = "house", name = "House"},
        {type = "cottage", name = "Cottage"},
        {type = "manor", name = "Manor", minSize = "large"},
    }
}

-- POI types for dungeons/exploration
WorldGen.POI_TYPES = {
    {type = "ruins", name = "Ancient Ruins", color = {0.8, 0.6, 0.2}},
    {type = "cave", name = "Cave", color = {0.5, 0.4, 0.3}},
    {type = "forest", name = "Sacred Grove", color = {0.2, 0.8, 0.3}},
    {type = "dungeon", name = "Dungeon", color = {0.4, 0.3, 0.5}},
    {type = "tower", name = "Tower", color = {0.6, 0.6, 0.7}},
    {type = "shrine", name = "Shrine", color = {0.9, 0.8, 0.4}},
    {type = "portal", name = "Mystic Portal", color = {0.8, 0.2, 0.8}},
}

-- Generate a complete world
function WorldGen:generate(seed, cols, rows)
    seed = seed or os.time()
    cols = cols or self.CONFIG.worldCols
    rows = rows or self.CONFIG.worldRows
    love.math.setRandomSeed(seed)

    local world = {
        seed = seed,
        cols = cols,
        rows = rows,
        tileSize = self.CONFIG.tileSize,
        tiles = {},
        continents = {},
        towns = {},
        pointsOfInterest = {},
        scale = 0.04,
    }

    -- Generate base terrain with multiple noise octaves
    self:generateTerrain(world)

    -- Identify and label continents
    self:identifyContinents(world)

    -- Place towns on continents
    self:placeTowns(world)

    -- Place dungeons and POIs
    self:placePOIs(world)

    -- Generate highways connecting towns
    self:generateHighways(world)

    -- Find player start position (on largest continent near a town)
    self:setPlayerStart(world)

    -- Place home base near player start
    self:placeHomeBase(world)

    return world
end

-- Generate terrain using layered noise
function WorldGen:generateTerrain(world)
    world.tiles = {}
    world.heightMap = {}

    for row = 1, world.rows do
        world.tiles[row] = {}
        world.heightMap[row] = {}
        for col = 1, world.cols do
            -- Multi-octave noise for more interesting terrain
            local nx = col / world.cols
            local ny = row / world.rows

            local height = 0
            height = height + love.math.noise(nx * 3, ny * 3) * 1.0
            height = height + love.math.noise(nx * 6, ny * 6) * 0.5
            height = height + love.math.noise(nx * 12, ny * 12) * 0.25
            height = height / 1.75

            -- Add continent-scale variation
            local continentNoise = love.math.noise(nx * 1.5 + 100, ny * 1.5 + 100)
            height = height * 0.6 + continentNoise * 0.4

            world.heightMap[row][col] = height

            -- Determine tile type from height
            local tile
            if height < self.CONFIG.deepWater then
                tile = "deep_water"
            elseif height < self.CONFIG.shallowWater then
                tile = "water"
            elseif height < self.CONFIG.sand then
                tile = "sand"
            elseif height < self.CONFIG.grass then
                tile = "grass"
            elseif height < self.CONFIG.forest then
                tile = "forest"
            elseif height < self.CONFIG.mountain then
                tile = "hills"
            else
                tile = "mountain"
            end

            -- Force ocean border around edges
            local borderSize = self.CONFIG.oceanBorderSize
            if row <= borderSize or row > world.rows - borderSize or
               col <= borderSize or col > world.cols - borderSize then
                tile = "deep_water"
            end

            world.tiles[row][col] = tile
        end
    end
end

-- Identify separate continents using flood fill
function WorldGen:identifyContinents(world)
    local visited = {}
    local continentId = 0

    world.continentMap = {}
    for row = 1, world.rows do
        world.continentMap[row] = {}
        visited[row] = {}
        for col = 1, world.cols do
            world.continentMap[row][col] = 0
            visited[row][col] = false
        end
    end

    print("[WorldGen] Starting continent identification for " .. world.cols .. "x" .. world.rows .. " world")

    -- Flood fill to find continents
    for row = 1, world.rows do
        for col = 1, world.cols do
            local tile = world.tiles[row][col]
            if not visited[row][col] and tile ~= "water" and tile ~= "deep_water" then
                continentId = continentId + 1
                local size = self:floodFillContinent(world, row, col, continentId, visited)

                if size >= self.CONFIG.continentMinSize then -- Minimum size to count as continent
                    table.insert(world.continents, {
                        id = continentId,
                        size = size,
                        tiles = {},
                        centerX = 0,
                        centerY = 0,
                        towns = {}
                    })
                    print("[WorldGen] Found continent #" .. continentId .. " with " .. size .. " tiles")
                end
            end
        end
    end

    -- Calculate continent centers and collect tiles
    for row = 1, world.rows do
        for col = 1, world.cols do
            local cid = world.continentMap[row][col]
            if cid > 0 then
                for _, cont in ipairs(world.continents) do
                    if cont.id == cid then
                        table.insert(cont.tiles, {row = row, col = col})
                        cont.centerX = cont.centerX + col
                        cont.centerY = cont.centerY + row
                        break
                    end
                end
            end
        end
    end

    -- Finalize centers
    for _, cont in ipairs(world.continents) do
        if #cont.tiles > 0 then
            cont.centerX = math.floor(cont.centerX / #cont.tiles)
            cont.centerY = math.floor(cont.centerY / #cont.tiles)
        end
    end

    -- Sort continents by size (largest first)
    table.sort(world.continents, function(a, b) return a.size > b.size end)

    -- Keep only significant continents (already filtered by continentMinSize above)
    -- For smaller worlds, we keep all continents that met the minimum size
    local significantContinents = {}
    local maxContinents = self.CONFIG.numContinents or 3
    for i, cont in ipairs(world.continents) do
        if i <= maxContinents then
            table.insert(significantContinents, cont)
            print("[WorldGen] Keeping continent #" .. i .. " with " .. cont.size .. " tiles")
        end
    end
    world.continents = significantContinents

    print("Found " .. #world.continents .. " continents")
end

function WorldGen:floodFillContinent(world, startRow, startCol, continentId, visited)
    local stack = {{row = startRow, col = startCol}}
    local size = 0

    while #stack > 0 do
        local current = table.remove(stack)
        local row, col = current.row, current.col

        if row >= 1 and row <= world.rows and col >= 1 and col <= world.cols then
            if not visited[row][col] then
                local tile = world.tiles[row][col]
                if tile ~= "water" and tile ~= "deep_water" then
                    visited[row][col] = true
                    world.continentMap[row][col] = continentId
                    size = size + 1

                    -- Add neighbors
                    table.insert(stack, {row = row - 1, col = col})
                    table.insert(stack, {row = row + 1, col = col})
                    table.insert(stack, {row = row, col = col - 1})
                    table.insert(stack, {row = row, col = col + 1})
                end
            end
        end
    end

    return size
end

-- Place towns on continents
function WorldGen:placeTowns(world)
    world.towns = {}

    for _, continent in ipairs(world.continents) do
        -- Determine number of towns based on continent size
        local numTowns
        if continent.size < 500 then
            numTowns = love.math.random(self.CONFIG.townsPerSmallContinent[1], self.CONFIG.townsPerSmallContinent[2])
        elseif continent.size < 1500 then
            numTowns = love.math.random(self.CONFIG.townsPerMediumContinent[1], self.CONFIG.townsPerMediumContinent[2])
        else
            numTowns = love.math.random(self.CONFIG.townsPerLargeContinent[1], self.CONFIG.townsPerLargeContinent[2])
        end

        -- Try to place towns
        local placedTowns = 0
        local attempts = 0
        local maxAttempts = 100

        while placedTowns < numTowns and attempts < maxAttempts do
            attempts = attempts + 1

            -- Pick a random tile from the continent
            local tileIdx = love.math.random(1, #continent.tiles)
            local tile = continent.tiles[tileIdx]
            local row, col = tile.row, tile.col

            -- Check if suitable for town (grass or sand, not too close to water or mountains)
            if self:isSuitableForTown(world, row, col) then
                -- Check distance from other towns
                local tooClose = false
                local minDist = 20 -- minimum tiles between towns

                for _, existingTown in ipairs(world.towns) do
                    local dist = math.sqrt((col - existingTown.col)^2 + (row - existingTown.row)^2)
                    if dist < minDist then
                        tooClose = true
                        break
                    end
                end

                if not tooClose then
                    local town = self:createTown(world, row, col, continent, placedTowns == 0)
                    table.insert(world.towns, town)
                    table.insert(continent.towns, town)
                    placedTowns = placedTowns + 1
                end
            end
        end
    end

    print("Placed " .. #world.towns .. " towns")
end

function WorldGen:isSuitableForTown(world, row, col)
    local tile = world.tiles[row][col]
    if tile ~= "grass" and tile ~= "sand" then
        return false
    end

    -- Check surrounding area
    local grassCount = 0
    local waterCount = 0
    local mountainCount = 0

    for dr = -2, 2 do
        for dc = -2, 2 do
            local r, c = row + dr, col + dc
            if r >= 1 and r <= world.rows and c >= 1 and c <= world.cols then
                local t = world.tiles[r][c]
                if t == "grass" then grassCount = grassCount + 1 end
                if t == "water" or t == "deep_water" then waterCount = waterCount + 1 end
                if t == "mountain" then mountainCount = mountainCount + 1 end
            end
        end
    end

    -- Need mostly grass, some water nearby is OK (ports), not too many mountains
    return grassCount >= 15 and mountainCount <= 3
end

function WorldGen:createTown(world, row, col, continent, isCapital)
    -- Generate town name
    local prefix = TOWN_PREFIXES[love.math.random(1, #TOWN_PREFIXES)]
    local suffix = TOWN_SUFFIXES[love.math.random(1, #TOWN_SUFFIXES)]
    local name = prefix .. suffix

    -- Determine town size based on whether it's a capital
    local size = "small"
    if isCapital then
        size = continent.size > 1000 and "large" or "medium"
    else
        local roll = love.math.random()
        if roll > 0.85 then size = "large"
        elseif roll > 0.5 then size = "medium"
        end
    end

    -- Generate buildings for the town
    local buildings = self:generateTownBuildings(size)

    -- Generate NPCs with schedules
    local npcs = self:generateTownNPCs(size, buildings)

    local town = {
        name = name,
        row = row,
        col = col,
        x = col * world.tileSize,
        y = row * world.tileSize,
        size = size,
        isCapital = isCapital,
        continentId = continent.id,
        buildings = buildings,
        npcs = npcs,
        seed = love.math.random(1, 999999),
        -- POI data for world map
        radius = size == "large" and 28 or (size == "medium" and 22 or 18),
        color = isCapital and {0.9, 0.7, 0.3} or {0.7, 0.5, 0.3},
        discovered = false,
        visited = false,
        levelType = "town",
        message = "You approach " .. name .. ", a " .. size .. " " .. (isCapital and "capital " or "") .. "town."
    }

    return town
end

function WorldGen:generateTownBuildings(size)
    local buildings = {}

    -- Add essential buildings
    for _, bldg in ipairs(self.BUILDING_TYPES.essential) do
        table.insert(buildings, {type = bldg.type, name = bldg.name})
    end

    -- Add common buildings based on size
    local commonCount = size == "large" and 3 or (size == "medium" and 2 or 1)
    local shuffledCommon = self:shuffleTable(self.BUILDING_TYPES.common)
    for i = 1, math.min(commonCount, #shuffledCommon) do
        local bldg = shuffledCommon[i]
        if not bldg.minSize or self:sizeAtLeast(size, bldg.minSize) then
            table.insert(buildings, {type = bldg.type, name = bldg.name})
        end
    end

    -- Add uncommon buildings for medium+ towns
    if size == "medium" or size == "large" then
        local uncommonCount = size == "large" and 2 or 1
        local shuffledUncommon = self:shuffleTable(self.BUILDING_TYPES.uncommon)
        for i = 1, math.min(uncommonCount, #shuffledUncommon) do
            local bldg = shuffledUncommon[i]
            if not bldg.minSize or self:sizeAtLeast(size, bldg.minSize) then
                table.insert(buildings, {type = bldg.type, name = bldg.name})
            end
        end
    end

    -- Add rare buildings for large towns
    if size == "large" then
        local shuffledRare = self:shuffleTable(self.BUILDING_TYPES.rare)
        if #shuffledRare > 0 then
            local bldg = shuffledRare[1]
            table.insert(buildings, {type = bldg.type, name = bldg.name})
        end
    end

    -- Add residential buildings
    local houseCount = size == "large" and 8 or (size == "medium" and 5 or 3)
    for i = 1, houseCount do
        local bldg = self.BUILDING_TYPES.residential[love.math.random(1, #self.BUILDING_TYPES.residential - 1)]
        if size == "large" and love.math.random() > 0.8 then
            bldg = self.BUILDING_TYPES.residential[#self.BUILDING_TYPES.residential] -- Manor
        end
        table.insert(buildings, {type = bldg.type, name = bldg.name .. " " .. i})
    end

    return buildings
end

function WorldGen:generateTownNPCs(size, buildings)
    local npcs = {}

    -- NPC types and their typical schedules
    local npcTemplates = {
        {name = "Elder", type = "elder", home = "house", work = "temple", schedule = {
            {hour = 6, location = "home"},
            {hour = 8, location = "work"},
            {hour = 12, location = "tavern"},
            {hour = 14, location = "work"},
            {hour = 18, location = "home"},
            {hour = 22, location = "home", sleeping = true}
        }},
        {name = "Merchant", type = "merchant", home = "house", work = "shop", schedule = {
            {hour = 6, location = "home"},
            {hour = 7, location = "work"},
            {hour = 19, location = "tavern"},
            {hour = 21, location = "home"},
            {hour = 22, location = "home", sleeping = true}
        }},
        {name = "Guard", type = "guard", home = "house", work = "patrol", schedule = {
            {hour = 6, location = "patrol"},
            {hour = 14, location = "tavern"},
            {hour = 15, location = "home"},
            {hour = 22, location = "patrol"}
        }},
        {name = "Blacksmith", type = "villager", home = "house", work = "blacksmith", schedule = {
            {hour = 5, location = "work"},
            {hour = 12, location = "tavern"},
            {hour = 13, location = "work"},
            {hour = 18, location = "home"},
            {hour = 21, location = "home", sleeping = true}
        }},
        {name = "Innkeeper", type = "merchant", home = "inn", work = "inn", schedule = {
            {hour = 6, location = "work"},
            {hour = 23, location = "home", sleeping = true}
        }},
        {name = "Villager", type = "villager", home = "house", work = "roam", schedule = {
            {hour = 6, location = "home"},
            {hour = 8, location = "roam"},
            {hour = 12, location = "tavern"},
            {hour = 14, location = "roam"},
            {hour = 18, location = "home"},
            {hour = 21, location = "home", sleeping = true}
        }},
    }

    -- Determine NPC count based on town size
    local npcCount = size == "large" and 15 or (size == "medium" and 10 or 6)

    -- Always add some key NPCs
    table.insert(npcs, self:createNPCFromTemplate(npcTemplates[1], buildings, 1)) -- Elder
    table.insert(npcs, self:createNPCFromTemplate(npcTemplates[2], buildings, 2)) -- Merchant
    table.insert(npcs, self:createNPCFromTemplate(npcTemplates[5], buildings, 3)) -- Innkeeper

    -- Add guards based on size
    local guardCount = size == "large" and 3 or (size == "medium" and 2 or 1)
    for i = 1, guardCount do
        table.insert(npcs, self:createNPCFromTemplate(npcTemplates[3], buildings, #npcs + 1))
    end

    -- Check if town has blacksmith
    for _, bldg in ipairs(buildings) do
        if bldg.type == "blacksmith" then
            table.insert(npcs, self:createNPCFromTemplate(npcTemplates[4], buildings, #npcs + 1))
            break
        end
    end

    -- Fill with villagers
    while #npcs < npcCount do
        table.insert(npcs, self:createNPCFromTemplate(npcTemplates[6], buildings, #npcs + 1))
    end

    return npcs
end

function WorldGen:createNPCFromTemplate(template, buildings, index)
    local firstNames = {"Marcus", "Elena", "Thomas", "Sarah", "William", "Anna", "James", "Mary", "Robert", "Elizabeth"}
    local name = template.name
    if template.name == "Villager" or template.name == "Guard" then
        name = firstNames[love.math.random(1, #firstNames)]
    end

    return {
        name = name,
        type = template.type,
        homeBuilding = template.home,
        workBuilding = template.work,
        schedule = template.schedule,
        id = index,
        dialogue = self:generateNPCDialogue(template.type)
    }
end

function WorldGen:generateNPCDialogue(npcType)
    local dialogues = {
        elder = {
            "Welcome, traveler. Our town has stood for generations.",
            "The old ways are not forgotten here.",
            "Seek wisdom, and you shall find it."
        },
        merchant = {
            "Fine goods for sale! Best prices in the region!",
            "Looking to buy or sell?",
            "I've got just what you need, friend."
        },
        guard = {
            "Stay out of trouble, citizen.",
            "The roads have been dangerous lately.",
            "Move along."
        },
        villager = {
            "Nice weather we're having.",
            "Have you visited the tavern yet?",
            "Welcome to our humble town."
        }
    }
    return dialogues[npcType] or dialogues.villager
end

-- Place dungeons and other POIs
function WorldGen:placePOIs(world)
    -- Add towns as POIs first
    for _, town in ipairs(world.towns) do
        table.insert(world.pointsOfInterest, {
            x = town.x,
            y = town.y,
            row = town.row,
            col = town.col,
            radius = town.radius,
            name = town.name,
            message = town.message,
            discovered = false,
            color = town.color,
            levelType = "town",
            levelSeed = town.seed,
            visited = false,
            townData = town
        })
    end

    -- Track which POI types have been placed
    local placedTypes = {}

    -- Helper function to place a POI
    local function placePOI(continent, poiType, forcedName)
        local attempts = 0
        while attempts < 100 do
            attempts = attempts + 1

            local tileIdx = love.math.random(1, #continent.tiles)
            local tile = continent.tiles[tileIdx]
            local row, col = tile.row, tile.col

            local tileType = world.tiles[row][col]
            if tileType ~= "water" and tileType ~= "deep_water" then
                local tooClose = false
                for _, poi in ipairs(world.pointsOfInterest) do
                    local dist = math.sqrt((col * world.tileSize - poi.x)^2 + (row * world.tileSize - poi.y)^2)
                    if dist < 64 then  -- 2 tiles minimum distance
                        tooClose = true
                        break
                    end
                end

                if not tooClose then
                    local poiName = forcedName or poiType.name
                    if not forcedName and love.math.random() > 0.5 then
                        local adjectives = {"Ancient", "Forgotten", "Hidden", "Mysterious", "Dark", "Sacred"}
                        poiName = adjectives[love.math.random(1, #adjectives)] .. " " .. poiType.name
                    end

                    table.insert(world.pointsOfInterest, {
                        x = col * world.tileSize,
                        y = row * world.tileSize,
                        row = row,
                        col = col,
                        radius = love.math.random(15, 22),
                        name = poiName,
                        message = "You discover " .. poiName .. ". Adventure awaits within.",
                        discovered = false,
                        color = poiType.color,
                        levelType = poiType.type,
                        levelSeed = love.math.random(1, 999999),
                        visited = false
                    })
                    placedTypes[poiType.type] = true
                    return true
                end
            end
        end
        return false
    end

    -- Ensure at least one of each POI type spawns
    if #world.continents > 0 then
        local mainContinent = world.continents[1]

        -- Place one of each POI type guaranteed
        for _, poiType in ipairs(self.POI_TYPES) do
            placePOI(mainContinent, poiType, poiType.name)
        end

        -- Place additional random POIs
        local extraCount = math.floor(mainContinent.size / 50)
        for i = 1, extraCount do
            local poiType = self.POI_TYPES[love.math.random(1, #self.POI_TYPES)]
            placePOI(mainContinent, poiType)
        end
    end

    print("Total POIs: " .. #world.pointsOfInterest)
    print("POI types placed: " .. table.concat(self:getPlacedTypes(world), ", "))
end

function WorldGen:getPlacedTypes(world)
    local types = {}
    local seen = {}
    for _, poi in ipairs(world.pointsOfInterest) do
        if poi.levelType and not seen[poi.levelType] then
            table.insert(types, poi.levelType)
            seen[poi.levelType] = true
        end
    end
    return types
end

function WorldGen:setPlayerStart(world)
    -- Start player near first town on largest continent
    if #world.towns > 0 then
        local town = world.towns[1]
        world.playerStartX = town.x + 50
        world.playerStartY = town.y + 50
    else
        -- Fallback to center of largest continent
        if #world.continents > 0 then
            local cont = world.continents[1]
            world.playerStartX = cont.centerX * world.tileSize
            world.playerStartY = cont.centerY * world.tileSize
        else
            world.playerStartX = world.cols * world.tileSize / 2
            world.playerStartY = world.rows * world.tileSize / 2
        end
    end
end

-- Place home base POI near player start
function WorldGen:placeHomeBase(world)
    -- Home base is always placed 2 tiles to the left and 1 tile down from player start
    local homeX = world.playerStartX - (world.tileSize * 2)
    local homeY = world.playerStartY + world.tileSize

    -- Ensure it's within bounds
    homeX = math.max(world.tileSize * 2, math.min(homeX, (world.cols - 2) * world.tileSize))
    homeY = math.max(world.tileSize * 2, math.min(homeY, (world.rows - 2) * world.tileSize))

    -- Store home base position in world for save/load
    world.homeBaseX = homeX
    world.homeBaseY = homeY

    -- Add home base as a special POI (insert at beginning so it's first)
    table.insert(world.pointsOfInterest, 1, {
        x = homeX,
        y = homeY,
        row = math.floor(homeY / world.tileSize),
        col = math.floor(homeX / world.tileSize),
        radius = 20,
        name = "Home Base",
        message = "Your home base. Build and store your treasures here.",
        discovered = true,  -- Always discovered from the start
        color = {0.9, 0.7, 0.4},  -- Warm house color
        levelType = "homebase",
        levelSeed = world.seed,  -- Use world seed for consistency
        visited = false,
        isHomeBase = true  -- Special flag to identify this POI
    })

    print("Home Base placed at: " .. homeX .. ", " .. homeY)
end

-- Helper functions
function WorldGen:shuffleTable(tbl)
    local shuffled = {}
    for i, v in ipairs(tbl) do shuffled[i] = v end
    for i = #shuffled, 2, -1 do
        local j = love.math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end

function WorldGen:sizeAtLeast(size, minSize)
    local sizes = {small = 1, medium = 2, large = 3}
    return (sizes[size] or 0) >= (sizes[minSize] or 0)
end

-- Generate highways connecting towns
function WorldGen:generateHighways(world)
    world.highways = {}

    if #world.towns < 2 then return end

    -- Connect each town to its nearest neighbor (create a network)
    local connected = {[1] = true}
    local connections = {}

    -- Use Prim's algorithm to create a minimum spanning tree
    while true do
        local bestDist = math.huge
        local bestFrom, bestTo = nil, nil

        for fromIdx, _ in pairs(connected) do
            local fromTown = world.towns[fromIdx]
            for toIdx, toTown in ipairs(world.towns) do
                if not connected[toIdx] then
                    local dist = math.sqrt((fromTown.col - toTown.col)^2 + (fromTown.row - toTown.row)^2)
                    if dist < bestDist then
                        bestDist = dist
                        bestFrom = fromIdx
                        bestTo = toIdx
                    end
                end
            end
        end

        if not bestTo then break end

        connected[bestTo] = true
        table.insert(connections, {from = bestFrom, to = bestTo})
    end

    -- Draw highways for each connection
    for _, conn in ipairs(connections) do
        local fromTown = world.towns[conn.from]
        local toTown = world.towns[conn.to]
        self:drawHighway(world, fromTown.col, fromTown.row, toTown.col, toTown.row)
    end

    -- Add a few extra connections for larger networks (loop roads)
    if #world.towns > 3 then
        for i = 1, math.min(2, #world.towns - 3) do
            local t1 = love.math.random(1, #world.towns)
            local t2 = love.math.random(1, #world.towns)
            if t1 ~= t2 then
                local town1 = world.towns[t1]
                local town2 = world.towns[t2]
                local dist = math.sqrt((town1.col - town2.col)^2 + (town1.row - town2.row)^2)
                if dist < 80 then -- Only connect relatively close towns
                    self:drawHighway(world, town1.col, town1.row, town2.col, town2.row)
                end
            end
        end
    end

    print("Generated highway network connecting " .. #world.towns .. " towns")
end

-- Draw a highway between two points using Bresenham's line with curves
function WorldGen:drawHighway(world, x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Add some curvature to make roads more interesting
    local midX = (x1 + x2) / 2 + love.math.random(-10, 10)
    local midY = (y1 + y2) / 2 + love.math.random(-10, 10)

    -- Draw road in two segments (start to mid, mid to end)
    self:drawRoadSegment(world, x1, y1, midX, midY)
    self:drawRoadSegment(world, midX, midY, x2, y2)
end

function WorldGen:drawRoadSegment(world, x1, y1, x2, y2)
    local dx = math.abs(x2 - x1)
    local dy = math.abs(y2 - y1)
    local sx = x1 < x2 and 1 or -1
    local sy = y1 < y2 and 1 or -1
    local err = dx - dy

    local x, y = math.floor(x1), math.floor(y1)
    local endX, endY = math.floor(x2), math.floor(y2)

    local roadWidth = 1 -- Width of road in tiles
    local maxIterations = world.cols * world.rows * 2 -- Safety limit
    local iterations = 0

    while true do
        iterations = iterations + 1
        if iterations > maxIterations then
            print("Warning: Road drawing exceeded max iterations, breaking loop")
            break
        end
        -- Place road tile and adjacent tiles for width
        for w = -roadWidth, roadWidth do
            local rx, ry = x, y

            -- Determine road direction for proper tile orientation
            local isHorizontal = dx > dy

            if isHorizontal then
                ry = y + w
            else
                rx = x + w
            end

            if rx >= 1 and rx <= world.cols and ry >= 1 and ry <= world.rows then
                local currentTile = world.tiles[ry][rx]
                -- Only place road on land tiles (not water/deep_water)
                if currentTile ~= "water" and currentTile ~= "deep_water" then
                    if isHorizontal then
                        world.tiles[ry][rx] = "highway_h"
                    else
                        world.tiles[ry][rx] = "highway_v"
                    end
                end
            end
        end

        if x == endX and y == endY then break end

        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x = x + sx
        end
        if e2 < dx then
            err = err + dx
            y = y + sy
        end
    end
end

return WorldGen
