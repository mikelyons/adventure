-- Controls configuration module
-- Stores and manages key bindings for each game mode

local Controls = {}

-- Default key bindings for each mode
Controls.defaults = {
    worldmap = {
        move_left = {"left", "a"},
        move_right = {"right", "d"},
        move_up = {"up", "w"},
        move_down = {"down", "s"},
        interact = {"space"},
        save = {"f5"},
    },
    town = {
        move_left = {"left", "a"},
        move_right = {"right", "d"},
        move_up = {"up", "w"},
        move_down = {"down", "s"},
        interact = {"space"},
    },
    level = {
        move_left = {"left", "a"},
        move_right = {"right", "d"},
        move_up = {"up", "w"},
        move_down = {"down", "s"},
        interact = {"space"},
    },
    contra = {
        move_left = {"left", "a"},
        move_right = {"right", "d"},
        aim_up = {"up", "w"},
        aim_down = {"down", "s"},
        jump = {"up", "w", "space"},
        shoot = {"x", "j"},
        restart = {"r"},
    },
    basebuilding = {
        move_left = {"left", "a"},
        move_right = {"right", "d"},
        move_up = {"up", "w"},
        move_down = {"down", "s"},
        toggle_build = {"b"},
        toggle_wardrobe = {"c"},
        prev_category = {"q"},
        next_category = {"e"},
    },
}

-- Action display names for UI
Controls.actionNames = {
    move_left = "Move Left",
    move_right = "Move Right",
    move_up = "Move Up",
    move_down = "Move Down",
    interact = "Interact",
    save = "Quick Save",
    aim_up = "Aim Up",
    aim_down = "Aim Down",
    jump = "Jump",
    shoot = "Shoot",
    restart = "Restart",
    toggle_build = "Toggle Build Mode",
    toggle_wardrobe = "Open Wardrobe",
    prev_category = "Previous Category",
    next_category = "Next Category",
}

-- Mode display names
Controls.modeNames = {
    worldmap = "World Map",
    town = "Town",
    level = "Level",
    contra = "Contra",
    basebuilding = "Base Building",
}

-- Current bindings (start with defaults)
Controls.bindings = {}

function Controls:init()
    -- Deep copy defaults to bindings
    for mode, actions in pairs(self.defaults) do
        self.bindings[mode] = {}
        for action, keys in pairs(actions) do
            self.bindings[mode][action] = {}
            for i, key in ipairs(keys) do
                self.bindings[mode][action][i] = key
            end
        end
    end
end

-- Get all keys bound to an action in a mode
function Controls:getKeys(mode, action)
    if self.bindings[mode] and self.bindings[mode][action] then
        return self.bindings[mode][action]
    end
    return {}
end

-- Check if a key is bound to an action
function Controls:isKeyBound(mode, action, key)
    local keys = self:getKeys(mode, action)
    for _, k in ipairs(keys) do
        if k == key then
            return true
        end
    end
    return false
end

-- Check if any key for an action is currently pressed (for continuous input)
function Controls:isDown(mode, action)
    local keys = self:getKeys(mode, action)
    for _, key in ipairs(keys) do
        if love.keyboard.isDown(key) then
            return true
        end
    end
    return false
end

-- Check if a pressed key matches an action
function Controls:matches(mode, action, pressedKey)
    return self:isKeyBound(mode, action, pressedKey)
end

-- Set a key binding (replaces first key in the list)
function Controls:setKey(mode, action, key, slot)
    slot = slot or 1
    if self.bindings[mode] and self.bindings[mode][action] then
        self.bindings[mode][action][slot] = key
    end
end

-- Get actions for a mode
function Controls:getActions(mode)
    local actions = {}
    if self.bindings[mode] then
        for action, _ in pairs(self.bindings[mode]) do
            table.insert(actions, action)
        end
    end
    -- Sort for consistent ordering
    table.sort(actions)
    return actions
end

-- Get key display name
function Controls:getKeyDisplayName(key)
    local names = {
        space = "SPACE",
        ["return"] = "ENTER",
        escape = "ESC",
        lshift = "L-SHIFT",
        rshift = "R-SHIFT",
        lctrl = "L-CTRL",
        rctrl = "R-CTRL",
        lalt = "L-ALT",
        ralt = "R-ALT",
        tab = "TAB",
        backspace = "BACKSPACE",
        left = "LEFT",
        right = "RIGHT",
        up = "UP",
        down = "DOWN",
    }
    return names[key] or string.upper(key)
end

-- Format keys for display
function Controls:formatKeys(mode, action)
    local keys = self:getKeys(mode, action)
    local display = {}
    for _, key in ipairs(keys) do
        table.insert(display, self:getKeyDisplayName(key))
    end
    return table.concat(display, " / ")
end

-- Reset a mode to defaults
function Controls:resetMode(mode)
    if self.defaults[mode] then
        self.bindings[mode] = {}
        for action, keys in pairs(self.defaults[mode]) do
            self.bindings[mode][action] = {}
            for i, key in ipairs(keys) do
                self.bindings[mode][action][i] = key
            end
        end
    end
end

-- Reset all to defaults
function Controls:resetAll()
    self:init()
end

-- Initialize on load
Controls:init()

return Controls
