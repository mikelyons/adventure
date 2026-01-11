# CLAUDE.md

This file provides context for Claude Code when working on this project.

## Project Overview

This is a retro-style RPG adventure game built with Love2D (LÖVE) framework in Lua. The game features procedural world generation, day/night cycles, NPC schedules, and multiple gameplay modes.

## Tech Stack

- **Language**: Lua 5.1+
- **Framework**: Love2D 11.x
- **State Management**: Custom gamestate stack (push/pop pattern)

## Key Files and Architecture

### Core Systems
- `main.lua` - Entry point, global state setup, main loop
- `gamestate.lua` - Stack-based game state management
- `gameclock.lua` - In-game time system (1 real min = 1 game hour)
- `worldgen.lua` - Procedural continent/town generation
- `inventory.lua` - Grid-based inventory with equipment slots
- `sprites.lua` - Procedural sprite generation
- `color.lua` - Love2D version color compatibility

### Shared Modules (IMPORTANT - Use These!)
- `utils.lua` - **Shared math/helper functions** (clamp, lerp, lerpColor, hash, shouldDither, simpleNoise, setPixel)
- `config.lua` - **Centralized game constants** (tile sizes, speeds, grid dimensions)
- `data/palettes.lua` - **All color palettes** (terrain, character, town, NPC, etc.)

### State Files (in `states/`)
- `worldmap.lua` - Main overworld exploration, POI management, home base placement
- `town.lua` - Town exploration with NPCs and buildings
- `buildinginterior.lua` - Metroid-style sidescroller interiors
- `inventoryscreen.lua` - Inventory UI with paperdoll
- `pause.lua` - Pause menu with options
- `basebuilding.lua` - Base building mode (used only for Home Base POI)
- `contra.lua` - Side-scrolling shooter mode (used for portal POIs)
- `dungeon.lua` - Dungeon exploration (used for all other POIs: ruins, cave, forest, etc.)

## Common Patterns

### Using Shared Utilities (REQUIRED)
**Always use the Utils module for common math functions. Never redefine these locally:**

```lua
local Utils = require("utils")

-- Use these aliases for cleaner code
local clamp = Utils.clamp
local lerp = Utils.lerp
local lerpColor = Utils.lerpColor
local shouldDither = Utils.shouldDither
local simpleNoise = Utils.simpleNoise
local hash = Utils.hash
local setPixel = Utils.setPixel

-- Example usage
local value = clamp(x, 0, 100)
local color = lerpColor(colorA, colorB, 0.5)
if shouldDither(px, py, 0.4) then ... end
```

### Using Centralized Palettes (REQUIRED)
**Always use palettes from data/palettes.lua. Never define colors inline:**

```lua
local Palettes = require("data.palettes")

-- Available palette categories:
-- Palettes.terrain     - World map terrain colors (grass, water, sand, etc.)
-- Palettes.character   - Skin tones, hair colors, clothing colors
-- Palettes.town        - Town tile colors (water, grass, path, building, market)
-- Palettes.npc         - NPC type colors (elder, merchant, guard, villager)
-- Palettes.basebuilding - Base building terrain palettes
-- Palettes.contra      - SNES-style game palettes
-- Palettes.poi         - Point of interest marker colors

-- Example usage
local grassPalette = Palettes.terrain.grass
local waterColor = Palettes.town.water.base[1]
local skinTone = Palettes.character.skinTones.medium
```

### Using Game Configuration
**Use config.lua for game constants instead of hardcoding values:**

```lua
local Config = require("config")

-- Available configuration sections:
-- Config.world      - World map settings (tileSize, scale)
-- Config.town       - Town settings (tileSize, npcSize, defaultSize)
-- Config.player     - Player settings (walkSpeed, runSpeed, size)
-- Config.vehicle    - Vehicle settings (speed, highwaySpeed)
-- Config.inventory  - Inventory grid settings
-- Config.ui         - UI timing settings (messageDuration, fadeTime)
-- Config.time       - Game clock settings
-- Config.level      - Dungeon settings
-- Config.contra     - Side-scroller settings
-- Config.paperdoll  - Character sprite settings
```

### Color Compatibility
Use `Color.set(r, g, b, a)` instead of `love.graphics.setColor()` for compatibility across Love2D versions.

```lua
local Color = require("color")
Color.set(1, 0, 0, 1)  -- Set color to red
```

### State Transitions
```lua
-- Push new state
local newState = {}
for k, v in pairs(require("states.statename")) do newState[k] = v end
newState.someData = data
Gamestate:push(newState)

-- Pop state
Gamestate:pop()
```

### Drawing Tiles
Tiles are drawn pixel-by-pixel for retro aesthetic. Each tile type has a dedicated draw function (e.g., `drawGrassTile`, `drawRoadTile`).

## Best Practices

### DO:
- Use `Utils` module for math functions (clamp, lerp, lerpColor, etc.)
- Use `Palettes` module for all color definitions
- Use `Config` module for game constants
- Use `Color.set()` for setting graphics colors
- Keep state files focused on their specific gameplay mode
- Add new palettes to `data/palettes.lua` under the appropriate category
- Add new constants to `config.lua` under the appropriate section

### DON'T:
- Define local clamp/lerp/lerpColor/dither functions (use Utils instead)
- Hardcode color values in state files (add to Palettes instead)
- Hardcode game constants like tile sizes or speeds (add to Config instead)
- Use `love.graphics.setColor()` directly (use Color.set instead)

## Development Commands

```bash
# Run the game
love .

# Or with explicit path
/Applications/love.app/Contents/MacOS/love /path/to/adventure
```

## Current Features

- Procedural world with continents and oceans
- Multiple towns per continent based on size
- Day/night cycle with ambient lighting
- NPCs with schedules (work, home, tavern, market)
- Building interiors (Metroid-style sidescroller)
- Grid inventory system (Diablo 2-style)
- Save/load system with multiple slots
- Controls help panel (toggle with ?)
- Home Base - Player's personal building area that saves/loads with game
- Dungeons - Explorable POIs (ruins, caves, forests, etc.)
- Contra-style side-scrolling shooter mode (portal POIs)

## POI (Point of Interest) System

POIs are locations on the world map the player can enter:
- **Home Base** - Spawns next to player start, uses basebuilding state, saves buildings to `homebase.lua`
- **Towns** - Use town state with NPCs and buildings
- **Portals** - Use contra (shooter) state
- **All other POIs** (ruins, cave, forest, oasis, dungeon, tower, shrine) - Use dungeon state

Home base is placed in `worldmap.lua` (not worldgen) to ensure it spawns adjacent to the player's actual starting position.

## File Locations

- Save files: `love.filesystem.getSaveDirectory()/saves/`
- Config: Uses Love2D's save directory
- Palettes: `data/palettes.lua`
- Utilities: `utils.lua`
- Game Config: `config.lua`

## Notes

- All graphics are procedurally generated (no external assets)
- The game uses a pixel-art aesthetic with 24x24 tile size in towns
- World map uses 32x32 tile size
- NPC size is typically 20 pixels

## Development Workflow

- **Testing**: The user will run `love .` to test the game. Do not launch the game automatically.
- **Git**: Only perform git operations (commit, status, etc.) when explicitly asked by the user.
- **State leave()**: When a state is popped via `Gamestate:pop()`, the `leave()` function is called if it exists. Use this for cleanup/saving.
