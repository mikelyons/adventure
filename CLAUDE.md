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

### State Files (in `states/`)
- `worldmap.lua` - Main overworld exploration (largest file)
- `town.lua` - Town exploration with NPCs and buildings
- `buildinginterior.lua` - Metroid-style sidescroller interiors
- `inventoryscreen.lua` - Inventory UI with paperdoll
- `pause.lua` - Pause menu with options

## Common Patterns

### Color Compatibility
Use `Color.set(r, g, b, a)` instead of `love.graphics.setColor()` for compatibility across Love2D versions.

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

## File Locations

- Save files: `love.filesystem.getSaveDirectory()/saves/`
- Config: Uses Love2D's save directory

## Notes

- All graphics are procedurally generated (no external assets)
- The game uses a pixel-art aesthetic with 24x24 tile size in towns
- World map uses 32x32 tile size
- NPC size is typically 20 pixels
