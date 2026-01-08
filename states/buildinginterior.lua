-- Building Interior State
-- Metroid-style sidescroller for building interiors

local BuildingInterior = {}
local Color = require("color")

local TILE_SIZE = 32
local GRAVITY = 800
local JUMP_VELOCITY = -350
local PLAYER_SPEED = 180

-- Building type layouts
local BUILDING_LAYOUTS = {
    inn = {
        name = "The Rusty Anchor Inn",
        rooms = {
            {width = 12, height = 8, doors = {"left_exit"}, features = {"counter", "stairs_up"}},
            {width = 10, height = 6, doors = {"stairs_down"}, features = {"beds"}},
        }
    },
    shop = {
        name = "General Store",
        rooms = {
            {width = 14, height = 7, doors = {"left_exit"}, features = {"counter", "shelves"}},
        }
    },
    house = {
        name = "House",
        rooms = {
            {width = 10, height = 7, doors = {"left_exit"}, features = {"furniture"}},
            {width = 8, height = 6, doors = {"door_left"}, features = {"bed", "dresser"}},
        }
    },
    tavern = {
        name = "The Golden Mug Tavern",
        rooms = {
            {width = 16, height = 8, doors = {"left_exit"}, features = {"bar", "tables", "stairs_up"}},
            {width = 12, height = 6, doors = {"stairs_down"}, features = {"storage"}},
        }
    },
    blacksmith = {
        name = "Blacksmith",
        rooms = {
            {width = 12, height = 8, doors = {"left_exit"}, features = {"forge", "anvil", "weapons"}},
        }
    },
}

function BuildingInterior:load()
    self.buildingType = self.buildingType or "house"
    self.buildingName = self.buildingName or "Building"

    -- Get layout for this building type
    local layout = BUILDING_LAYOUTS[self.buildingType] or BUILDING_LAYOUTS.house
    self.layout = layout
    self.buildingName = layout.name

    -- Current room
    self.currentRoom = 1
    self:generateRoom(self.currentRoom)

    -- Player state
    self.player = {
        x = 80,
        y = 0,
        vx = 0,
        vy = 0,
        width = 16,
        height = 28,
        onGround = false,
        facing = 1,
        animTime = 0
    }

    -- Find ground for player
    self.player.y = (self.roomHeight - 3) * TILE_SIZE

    -- Exit door position (left side)
    self.exitDoor = {
        x = 0,
        y = (self.roomHeight - 3) * TILE_SIZE,
        width = TILE_SIZE,
        height = TILE_SIZE * 2
    }

    -- Camera
    self.camera = {x = 0, y = 0}

    -- Interaction
    self.nearExit = false
    self.interactionText = nil
end

function BuildingInterior:enter(buildingType, buildingName)
    self.buildingType = buildingType or "house"
    self.buildingName = buildingName
    self:load()
end

function BuildingInterior:generateRoom(roomIndex)
    local roomDef = self.layout.rooms[roomIndex] or self.layout.rooms[1]

    self.roomWidth = roomDef.width
    self.roomHeight = roomDef.height
    self.roomFeatures = roomDef.features or {}

    -- Generate tiles for the room
    self.tiles = {}
    for y = 1, self.roomHeight do
        self.tiles[y] = {}
        for x = 1, self.roomWidth do
            -- Walls and floor
            if y == 1 then
                self.tiles[y][x] = "ceiling"
            elseif y == self.roomHeight then
                self.tiles[y][x] = "floor"
            elseif x == 1 or x == self.roomWidth then
                self.tiles[y][x] = "wall"
            else
                self.tiles[y][x] = "air"
            end
        end
    end

    -- Add platforms based on features
    self:addFeatures(roomDef.features)
end

function BuildingInterior:addFeatures(features)
    if not features then return end

    for _, feature in ipairs(features) do
        if feature == "stairs_up" or feature == "stairs_down" then
            -- Add staircase platform
            local stairX = self.roomWidth - 4
            for i = 0, 3 do
                local y = self.roomHeight - 2 - i
                if y > 1 and y < self.roomHeight then
                    self.tiles[y][stairX + i] = "platform"
                end
            end
        elseif feature == "counter" or feature == "bar" then
            -- Add counter/bar
            local counterY = self.roomHeight - 1
            for x = 4, 7 do
                if x < self.roomWidth then
                    self.tiles[counterY][x] = "counter"
                end
            end
        elseif feature == "shelves" then
            -- Add wall shelves
            for shelfY = 3, self.roomHeight - 3, 2 do
                self.tiles[shelfY][self.roomWidth - 1] = "shelf"
                if self.roomWidth > 4 then
                    self.tiles[shelfY][self.roomWidth - 2] = "shelf"
                end
            end
        elseif feature == "tables" then
            -- Add tables as platforms
            local tableY = self.roomHeight - 1
            for x = 8, 10 do
                if x < self.roomWidth - 1 then
                    self.tiles[tableY][x] = "table"
                end
            end
        elseif feature == "beds" or feature == "bed" then
            -- Add bed platform
            local bedY = self.roomHeight - 1
            for x = 3, 5 do
                if x < self.roomWidth then
                    self.tiles[bedY][x] = "bed"
                end
            end
        elseif feature == "forge" then
            -- Add forge structure
            local forgeY = self.roomHeight - 1
            self.tiles[forgeY][self.roomWidth - 3] = "forge"
            self.tiles[forgeY - 1][self.roomWidth - 3] = "forge_top"
        elseif feature == "anvil" then
            self.tiles[self.roomHeight - 1][5] = "anvil"
        elseif feature == "weapons" then
            -- Weapon racks on wall
            for y = 3, 5 do
                self.tiles[y][2] = "weapon_rack"
            end
        elseif feature == "furniture" then
            -- Generic furniture
            self.tiles[self.roomHeight - 1][4] = "chair"
            self.tiles[self.roomHeight - 1][6] = "table"
        elseif feature == "dresser" then
            self.tiles[self.roomHeight - 1][self.roomWidth - 2] = "dresser"
        elseif feature == "storage" then
            -- Barrels and crates
            for x = 3, self.roomWidth - 2, 2 do
                self.tiles[self.roomHeight - 1][x] = "barrel"
            end
        end
    end
end

function BuildingInterior:update(dt)
    self.player.animTime = self.player.animTime + dt

    -- Handle input
    local moveX = 0
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        moveX = -1
        self.player.facing = -1
    elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        moveX = 1
        self.player.facing = 1
    end

    self.player.vx = moveX * PLAYER_SPEED

    -- Apply gravity
    self.player.vy = self.player.vy + GRAVITY * dt

    -- Move player
    local newX = self.player.x + self.player.vx * dt
    local newY = self.player.y + self.player.vy * dt

    -- Collision detection
    self.player.onGround = false

    -- Horizontal collision
    if not self:checkCollision(newX, self.player.y, self.player.width, self.player.height) then
        self.player.x = newX
    else
        self.player.vx = 0
    end

    -- Vertical collision
    if not self:checkCollision(self.player.x, newY, self.player.width, self.player.height) then
        self.player.y = newY
    else
        if self.player.vy > 0 then
            self.player.onGround = true
            -- Snap to ground
            local groundY = math.floor((newY + self.player.height) / TILE_SIZE) * TILE_SIZE - self.player.height
            self.player.y = groundY
        end
        self.player.vy = 0
    end

    -- Keep player in bounds
    self.player.x = math.max(0, math.min(self.player.x, self.roomWidth * TILE_SIZE - self.player.width))

    -- Update camera
    local screenW, screenH = love.graphics.getDimensions()
    self.camera.x = self.player.x - screenW / 2 + self.player.width / 2
    self.camera.y = self.player.y - screenH / 2 + self.player.height / 2

    -- Clamp camera
    self.camera.x = math.max(0, math.min(self.camera.x, self.roomWidth * TILE_SIZE - screenW))
    self.camera.y = math.max(0, math.min(self.camera.y, self.roomHeight * TILE_SIZE - screenH))

    -- Check for exit door proximity
    self.nearExit = self:isNearDoor()
    if self.nearExit then
        self.interactionText = "Press SPACE to exit"
    else
        self.interactionText = nil
    end
end

function BuildingInterior:checkCollision(x, y, w, h)
    -- Check all corners and edges
    local points = {
        {x, y},
        {x + w - 1, y},
        {x, y + h - 1},
        {x + w - 1, y + h - 1},
        {x + w / 2, y + h - 1}, -- Bottom center
    }

    for _, point in ipairs(points) do
        local tileX = math.floor(point[1] / TILE_SIZE) + 1
        local tileY = math.floor(point[2] / TILE_SIZE) + 1

        if tileX < 1 or tileX > self.roomWidth or tileY < 1 or tileY > self.roomHeight then
            return true
        end

        local tile = self.tiles[tileY] and self.tiles[tileY][tileX]
        if tile and tile ~= "air" and self:isSolidTile(tile) then
            return true
        end
    end

    return false
end

function BuildingInterior:isSolidTile(tile)
    local solidTiles = {
        ceiling = true,
        floor = true,
        wall = true,
        platform = true,
        counter = true,
        table = true,
        bed = true,
        anvil = true,
        dresser = true,
        barrel = true,
        chair = true,
    }
    return solidTiles[tile] or false
end

function BuildingInterior:isNearDoor()
    local doorX = 0
    local doorY = (self.roomHeight - 3) * TILE_SIZE

    local dx = self.player.x - doorX
    local dy = self.player.y - doorY

    return dx < TILE_SIZE * 2 and dx > -TILE_SIZE and
           math.abs(dy) < TILE_SIZE * 2
end

function BuildingInterior:draw()
    local screenW, screenH = love.graphics.getDimensions()

    -- Background
    Color.set(0.12, 0.10, 0.15)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    love.graphics.push()
    love.graphics.translate(-self.camera.x, -self.camera.y)

    -- Draw room background
    self:drawBackground()

    -- Draw tiles
    self:drawTiles()

    -- Draw exit door
    self:drawExitDoor()

    -- Draw player
    self:drawPlayer()

    love.graphics.pop()

    -- Draw HUD
    self:drawHUD()
end

function BuildingInterior:drawBackground()
    local roomPixelW = self.roomWidth * TILE_SIZE
    local roomPixelH = self.roomHeight * TILE_SIZE

    -- Interior wall background with wood paneling effect
    for y = 0, roomPixelH, 8 do
        local shade = 0.18 + math.sin(y * 0.1) * 0.02
        Color.set(shade, shade * 0.85, shade * 0.7)
        love.graphics.rectangle("fill", 0, y, roomPixelW, 8)
    end

    -- Add some decorative elements
    for x = TILE_SIZE, roomPixelW - TILE_SIZE, TILE_SIZE * 2 do
        Color.set(0.25, 0.20, 0.18, 0.3)
        love.graphics.rectangle("fill", x, TILE_SIZE, 2, roomPixelH - TILE_SIZE * 2)
    end
end

function BuildingInterior:drawTiles()
    for y = 1, self.roomHeight do
        for x = 1, self.roomWidth do
            local tile = self.tiles[y][x]
            if tile and tile ~= "air" then
                self:drawTile(x, y, tile)
            end
        end
    end
end

function BuildingInterior:drawTile(x, y, tile)
    local px = (x - 1) * TILE_SIZE
    local py = (y - 1) * TILE_SIZE

    if tile == "floor" then
        -- Wooden floor
        Color.set(0.45, 0.32, 0.22)
        love.graphics.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
        -- Planks
        Color.set(0.35, 0.25, 0.18)
        for i = 0, TILE_SIZE - 1, 8 do
            love.graphics.line(px + i, py, px + i, py + TILE_SIZE)
        end
        -- Highlight
        Color.set(0.55, 0.42, 0.32)
        love.graphics.line(px, py, px + TILE_SIZE, py)

    elseif tile == "ceiling" then
        -- Dark ceiling beams
        Color.set(0.25, 0.18, 0.12)
        love.graphics.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
        Color.set(0.20, 0.14, 0.10)
        love.graphics.rectangle("fill", px, py + TILE_SIZE - 6, TILE_SIZE, 6)

    elseif tile == "wall" then
        -- Stone/brick wall
        Color.set(0.35, 0.30, 0.28)
        love.graphics.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
        -- Brick pattern
        Color.set(0.28, 0.24, 0.22)
        for by = 0, TILE_SIZE - 1, 8 do
            local offset = (by / 8) % 2 == 0 and 0 or 8
            for bx = offset, TILE_SIZE - 1, 16 do
                love.graphics.rectangle("line", px + bx, py + by, 14, 6)
            end
        end

    elseif tile == "platform" or tile == "stairs" then
        -- Wooden platform/stairs
        Color.set(0.50, 0.38, 0.28)
        love.graphics.rectangle("fill", px, py, TILE_SIZE, 8)
        Color.set(0.40, 0.30, 0.22)
        love.graphics.rectangle("fill", px, py + 8, TILE_SIZE, 4)

    elseif tile == "counter" or tile == "bar" then
        -- Counter/bar top
        Color.set(0.55, 0.40, 0.28)
        love.graphics.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
        Color.set(0.65, 0.50, 0.35)
        love.graphics.rectangle("fill", px, py, TILE_SIZE, 6)

    elseif tile == "shelf" then
        -- Wall shelf
        Color.set(0.45, 0.35, 0.25)
        love.graphics.rectangle("fill", px, py + TILE_SIZE - 8, TILE_SIZE, 8)
        -- Items on shelf
        Color.set(0.60, 0.55, 0.45)
        love.graphics.rectangle("fill", px + 4, py + TILE_SIZE - 16, 8, 8)
        Color.set(0.50, 0.40, 0.60)
        love.graphics.rectangle("fill", px + 16, py + TILE_SIZE - 14, 6, 6)

    elseif tile == "table" then
        -- Table
        Color.set(0.50, 0.38, 0.26)
        love.graphics.rectangle("fill", px, py, TILE_SIZE, 6)
        Color.set(0.40, 0.30, 0.20)
        love.graphics.rectangle("fill", px + 4, py + 6, 4, TILE_SIZE - 6)
        love.graphics.rectangle("fill", px + TILE_SIZE - 8, py + 6, 4, TILE_SIZE - 6)

    elseif tile == "bed" then
        -- Bed
        Color.set(0.40, 0.30, 0.22)
        love.graphics.rectangle("fill", px, py + 8, TILE_SIZE, TILE_SIZE - 8)
        Color.set(0.70, 0.55, 0.55)
        love.graphics.rectangle("fill", px + 2, py, TILE_SIZE - 4, 10)
        Color.set(0.80, 0.75, 0.70)
        love.graphics.rectangle("fill", px + 2, py + 10, TILE_SIZE - 4, 8)

    elseif tile == "forge" then
        -- Forge base
        Color.set(0.30, 0.28, 0.26)
        love.graphics.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
        -- Fire glow
        Color.set(0.90, 0.40, 0.10)
        love.graphics.rectangle("fill", px + 8, py + 8, 16, 16)
        Color.set(1.0, 0.70, 0.20)
        love.graphics.rectangle("fill", px + 12, py + 12, 8, 8)

    elseif tile == "forge_top" then
        -- Chimney
        Color.set(0.25, 0.22, 0.20)
        love.graphics.rectangle("fill", px + 8, py, 16, TILE_SIZE)

    elseif tile == "anvil" then
        Color.set(0.35, 0.35, 0.38)
        love.graphics.rectangle("fill", px + 4, py + TILE_SIZE - 16, 24, 16)
        Color.set(0.45, 0.45, 0.48)
        love.graphics.rectangle("fill", px + 8, py + TILE_SIZE - 20, 16, 4)

    elseif tile == "weapon_rack" then
        -- Weapon rack
        Color.set(0.40, 0.30, 0.22)
        love.graphics.rectangle("fill", px, py + 4, 8, TILE_SIZE - 8)
        -- Weapons
        Color.set(0.55, 0.55, 0.60)
        love.graphics.rectangle("fill", px + 10, py + 2, 3, 28)
        Color.set(0.50, 0.45, 0.40)
        love.graphics.rectangle("fill", px + 18, py + 4, 4, 24)

    elseif tile == "barrel" then
        -- Barrel
        Color.set(0.45, 0.32, 0.20)
        love.graphics.rectangle("fill", px + 4, py + 4, 24, 28)
        Color.set(0.35, 0.30, 0.25)
        love.graphics.rectangle("fill", px + 4, py + 10, 24, 4)
        love.graphics.rectangle("fill", px + 4, py + 22, 24, 4)

    elseif tile == "dresser" then
        Color.set(0.50, 0.38, 0.28)
        love.graphics.rectangle("fill", px + 2, py + 8, 28, 24)
        Color.set(0.40, 0.30, 0.22)
        love.graphics.rectangle("fill", px + 6, py + 12, 20, 8)
        love.graphics.rectangle("fill", px + 6, py + 22, 20, 8)

    elseif tile == "chair" then
        Color.set(0.45, 0.35, 0.25)
        love.graphics.rectangle("fill", px + 8, py + 12, 16, 20)
        love.graphics.rectangle("fill", px + 8, py, 16, 14)
    end
end

function BuildingInterior:drawExitDoor()
    local doorX = 0
    local doorY = (self.roomHeight - 3) * TILE_SIZE

    -- Door frame
    Color.set(0.35, 0.25, 0.18)
    love.graphics.rectangle("fill", doorX, doorY - TILE_SIZE, TILE_SIZE + 8, TILE_SIZE * 3)

    -- Door
    local isNear = self.nearExit
    if isNear then
        Color.set(0.55, 0.40, 0.28)
    else
        Color.set(0.45, 0.32, 0.22)
    end
    love.graphics.rectangle("fill", doorX + 4, doorY, TILE_SIZE, TILE_SIZE * 2 - 4)

    -- Door handle
    Color.set(0.70, 0.60, 0.30)
    love.graphics.circle("fill", doorX + TILE_SIZE - 4, doorY + TILE_SIZE, 4)

    -- Exit sign/arrow
    if isNear then
        Color.set(0.90, 0.85, 0.50)
        love.graphics.polygon("fill",
            doorX + 8, doorY + TILE_SIZE - 8,
            doorX + 20, doorY + TILE_SIZE,
            doorX + 8, doorY + TILE_SIZE + 8
        )
    end
end

function BuildingInterior:drawPlayer()
    local p = self.player

    -- Shadow
    Color.set(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", p.x + p.width / 2, p.y + p.height + 2, p.width / 2, 4)

    -- Body
    Color.set(0.35, 0.55, 0.75)
    love.graphics.rectangle("fill", p.x + 2, p.y + 10, p.width - 4, p.height - 14)

    -- Head
    Color.set(0.85, 0.70, 0.55)
    love.graphics.rectangle("fill", p.x + 3, p.y, p.width - 6, 12)

    -- Hair
    Color.set(0.35, 0.25, 0.18)
    love.graphics.rectangle("fill", p.x + 3, p.y, p.width - 6, 5)

    -- Eyes
    local eyeX = p.facing > 0 and p.x + p.width - 6 or p.x + 4
    Color.set(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", eyeX, p.y + 5, 2, 2)

    -- Legs
    Color.set(0.40, 0.32, 0.25)
    local legOffset = p.onGround and math.sin(p.animTime * 10) * 2 or 0
    love.graphics.rectangle("fill", p.x + 3, p.y + p.height - 6, 4, 6)
    love.graphics.rectangle("fill", p.x + p.width - 7, p.y + p.height - 6, 4, 6)
end

function BuildingInterior:drawHUD()
    local screenW, screenH = love.graphics.getDimensions()

    -- Building name
    Color.set(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, screenW, 40)

    Color.set(0.90, 0.85, 0.70)
    love.graphics.print(self.buildingName, 15, 12)

    -- Interaction prompt
    if self.interactionText then
        local promptW = 200
        local promptX = (screenW - promptW) / 2
        local promptY = screenH - 80

        Color.set(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", promptX - 10, promptY - 5, promptW + 20, 30, 4, 4)

        Color.set(0.95, 0.90, 0.70)
        love.graphics.printf(self.interactionText, promptX, promptY, promptW, "center")
    end

    -- Controls hint
    Color.set(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, screenH - 35, screenW, 35)

    Color.set(0.50, 0.55, 0.65)
    love.graphics.printf("A/D: Move  |  SPACE: Jump/Exit  |  ESC: Menu", 0, screenH - 25, screenW, "center")
end

function BuildingInterior:keypressed(key)
    if key == "escape" then
        Gamestate:push(require("states.pause"))
    elseif key == "space" or key == "w" or key == "up" then
        if self.nearExit then
            -- Exit building
            Gamestate:pop()
        elseif self.player.onGround then
            -- Jump
            self.player.vy = JUMP_VELOCITY
            self.player.onGround = false
        end
    end
end

return BuildingInterior
