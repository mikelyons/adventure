-- Centralized Game Configuration
-- All game constants and configuration values in one place

local Config = {}

-- ============================================================================
-- WORLD MAP SETTINGS
-- ============================================================================
Config.world = {
    tileSize = 32,          -- Pixel size of world map tiles
    scale = 2,              -- World map tile scale
}

-- ============================================================================
-- TOWN SETTINGS
-- ============================================================================
Config.town = {
    tileSize = 24,          -- Pixel size of town tiles
    npcSize = 20,           -- NPC sprite size in pixels
    defaultSize = 10,       -- Default town grid size
}

-- ============================================================================
-- PLAYER SETTINGS
-- ============================================================================
Config.player = {
    walkSpeed = 220,        -- Normal walking speed (pixels/sec)
    runSpeed = 450,         -- Running speed (pixels/sec)
    size = 14,              -- Player sprite size in world map
}

-- ============================================================================
-- VEHICLE SETTINGS
-- ============================================================================
Config.vehicle = {
    speed = 450,            -- Normal vehicle speed (pixels/sec)
    highwaySpeed = 600,     -- Speed on highways (pixels/sec)
}

-- ============================================================================
-- INVENTORY SETTINGS (Diablo 2-style grid)
-- ============================================================================
Config.inventory = {
    gridWidth = 10,         -- Grid columns
    gridHeight = 4,         -- Grid rows
    cellSize = 40,          -- Cell size in pixels
}

-- ============================================================================
-- UI SETTINGS
-- ============================================================================
Config.ui = {
    messageDuration = 4.0,  -- How long messages display (seconds)
    fadeInTime = 0.5,       -- Message fade in time (seconds)
    fadeOutTime = 0.5,      -- Message fade out time (seconds)
}

-- ============================================================================
-- TIME SETTINGS (Game Clock)
-- ============================================================================
Config.time = {
    realMinutesPerGameHour = 1,  -- 1 real minute = 1 game hour
    dayStartHour = 6,            -- Hour when day begins
    nightStartHour = 20,         -- Hour when night begins
    dawnStartHour = 5,           -- Hour when dawn begins
    duskStartHour = 19,          -- Hour when dusk begins
}

-- ============================================================================
-- LEVEL/DUNGEON SETTINGS
-- ============================================================================
Config.level = {
    tileSize = 32,          -- Dungeon tile size
    cols = 40,              -- Default dungeon columns
    rows = 30,              -- Default dungeon rows
}

-- ============================================================================
-- CONTRA (Side-Scroller) SETTINGS
-- ============================================================================
Config.contra = {
    levelWidth = 3200,      -- Level width in pixels
    levelHeight = 600,      -- Level height in pixels
    tileSize = 32,          -- Tile size
    playerSpeed = 200,      -- Player movement speed
    jumpForce = -450,       -- Jump velocity
    gravity = 1200,         -- Gravity acceleration
    bulletSpeed = 600,      -- Bullet speed
    shootDelay = 0.15,      -- Time between shots
}

-- ============================================================================
-- BASE BUILDING SETTINGS
-- ============================================================================
Config.basebuilding = {
    tileSize = 32,          -- Building tile size
    gridWidth = 50,         -- Building area width
    gridHeight = 50,        -- Building area height
}

-- ============================================================================
-- PAPERDOLL (Character) SETTINGS
-- ============================================================================
Config.paperdoll = {
    width = 16,             -- Character sprite width
    height = 24,            -- Character sprite height
    scale = 2.5,            -- Default display scale
}

-- ============================================================================
-- ANIMATION SETTINGS
-- ============================================================================
Config.animation = {
    walkFrameTime = 0.15,   -- Time per walk animation frame
    idleFrameTime = 0.5,    -- Time per idle animation frame
}

return Config
