# Adventure

A retro-style RPG adventure game built with Love2D (LÖVE framework).

## Features

- **Procedural World Generation**: Multiple continents with varying sizes, each populated with towns based on landmass size
- **Day/Night Cycle**: Real-time game clock (1 real minute = 1 game hour) with ambient lighting transitions
- **Living Towns**: NPCs with schedules that move between work, home, market, and tavern based on time of day
- **Building Interiors**: Metroid-style sidescroller interiors for shops, inns, taverns, and homes
- **Inventory System**: Diablo 2-style grid inventory with equipment slots and paperdoll display
- **Multiple Game Modes**: World exploration, town navigation, building interiors, dungeon crawling
- **Save System**: Multiple save slots with character progression

## Requirements

- [Love2D](https://love2d.org/) 11.x or later

## Installation

### macOS (Homebrew)
```bash
brew install love
```

### Windows
Download from [love2d.org](https://love2d.org/)

### Linux
```bash
# Ubuntu/Debian
sudo apt install love

# Arch
sudo pacman -S love
```

## Running the Game

```bash
# From the project directory
love .

# Or specify the path
love /path/to/adventure
```

## Controls

Press `?` at any time to toggle the controls help panel.

### World Map
| Key | Action |
|-----|--------|
| W/A/S/D or Arrow Keys | Move |
| Space | Enter location |
| I | Open inventory |
| F5 | Quick save |
| Escape | Pause menu |

### Town
| Key | Action |
|-----|--------|
| W/A/S/D or Arrow Keys | Move |
| Space | Talk to NPC / Enter building |
| Escape | Pause menu |

### Building Interior
| Key | Action |
|-----|--------|
| A/D | Move left/right |
| W/Space | Jump |
| S | Drop through platform |
| E | Interact |
| Escape | Exit building |

### Inventory
| Key | Action |
|-----|--------|
| W/A/S/D or Arrow Keys | Navigate |
| Tab | Switch panels |
| Space/Enter | Select/Equip item |
| Escape | Close |

## Project Structure

```
adventure/
├── main.lua              # Entry point
├── gamestate.lua         # State management
├── gameclock.lua         # Day/night cycle and NPC schedules
├── worldgen.lua          # Procedural world generation
├── inventory.lua         # Inventory system
├── controls.lua          # Key bindings
├── controlspanel.lua     # Controls help overlay
├── color.lua             # Color compatibility utilities
├── sprites.lua           # Sprite generation
├── states/
│   ├── splash.lua        # Splash screen
│   ├── mainmenu.lua      # Main menu
│   ├── newgame.lua       # Character creation
│   ├── continue.lua      # Load game
│   ├── worldmap.lua      # World exploration
│   ├── town.lua          # Town navigation
│   ├── buildinginterior.lua  # Metroid-style building interiors
│   ├── inventoryscreen.lua   # Inventory UI
│   ├── pause.lua         # Pause menu
│   ├── controlsconfig.lua    # Controls configuration
│   ├── level.lua         # Dungeon exploration
│   ├── contra.lua        # Shooter mode
│   └── basebuilding.lua  # Base building mode
└── saves/                # Save files (created at runtime)
```

## Game Systems

### World Generation
The world is procedurally generated using layered Perlin noise to create realistic continents with varied terrain (deep water, shallow water, sand, grass, forest, mountains). Towns are automatically placed on suitable terrain, with larger continents getting more towns.

### Game Clock
Time passes in-game at an accelerated rate (1 real minute = 1 game hour, so a full day is 24 minutes). The time of day affects:
- Ambient lighting (dawn, morning, afternoon, evening, dusk, night)
- NPC locations and behaviors
- Some shop availability

### NPC Schedules
NPCs follow daily routines:
- **Night (10pm-5am)**: Home, sleeping
- **Morning (6am-8am)**: At home, waking up
- **Day (8am-6pm)**: At work or roaming
- **Evening (6pm-10pm)**: Tavern or heading home

### Towns
Each town features:
- Central plaza with fountain
- Main streets in a cross pattern
- Commercial buildings (inn, shop, tavern, blacksmith) around the plaza
- Residential buildings along secondary streets
- NPCs with homes and workplaces

## Development

This game was developed using Claude Code as an AI pair programmer.

## License

MIT License
