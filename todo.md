# todo.md

This file is a checklist of ideas to implement that I thought of while offline, if claude hasn't checked off having done at least one pass at the task if not completing it, then these tasks are next up.

Prompt me to ask for confirmation everytime claude selects a task from this file, with a short sentence explaining why this should be next.

## Bugs/Issues

- [x] example completed item/
- [x] choppy movement in town mode
- [x] world map is too big so it's hard to find any dungeons of POIs
- [x] new game freezes when you press Y to confirm character name (fixed by reducing world size)
- [ ] any pop up text box should be dismissable with the escape key when it's open and should disappear immediately when dismissed

## New Features

- [ ] the inventory screen should have a graphical representation next to the slotted version of the characters body so we can see how each item we equip looks on the character and with the rest of the outfit
- [ ] The controls option in the start menu options screen has tabs that allow me to configure the controls for each mode and saves when exited. also includes a reset defaults button that reads from a DEFAULT_CONTROLS.lua

## practices to maintain the codebase

### Controls
- any new key control that is added should be updated and maintained in the configure controls pause menu item so we can always know what controls are available to us

## Tweaks, Toggles and Feature Flags

None yet