-- Inventory System Module
-- Diablo 2-style grid inventory with equipment slots

local Inventory = {}

-- Grid dimensions (Diablo 2 was 10x4)
Inventory.GRID_WIDTH = 10
Inventory.GRID_HEIGHT = 4
Inventory.CELL_SIZE = 40

-- Equipment slot definitions
Inventory.EQUIPMENT_SLOTS = {
    "head",
    "chest",
    "legs",
    "feet",
    "mainhand",
    "offhand",
    "accessory1",
    "accessory2"
}

-- Item type definitions with default sizes
Inventory.ITEM_TYPES = {
    -- Weapons
    sword = {width = 1, height = 3, slot = "mainhand", category = "weapon"},
    dagger = {width = 1, height = 2, slot = "mainhand", category = "weapon"},
    axe = {width = 2, height = 3, slot = "mainhand", category = "weapon"},
    staff = {width = 1, height = 4, slot = "mainhand", category = "weapon"},
    bow = {width = 2, height = 3, slot = "mainhand", category = "weapon"},

    -- Armor
    helmet = {width = 2, height = 2, slot = "head", category = "armor"},
    cap = {width = 2, height = 1, slot = "head", category = "armor"},
    chestplate = {width = 2, height = 3, slot = "chest", category = "armor"},
    robe = {width = 2, height = 3, slot = "chest", category = "armor"},
    tunic = {width = 2, height = 2, slot = "chest", category = "armor"},
    leggings = {width = 2, height = 2, slot = "legs", category = "armor"},
    boots = {width = 2, height = 2, slot = "feet", category = "armor"},
    shoes = {width = 2, height = 1, slot = "feet", category = "armor"},

    -- Shields
    shield = {width = 2, height = 2, slot = "offhand", category = "shield"},
    buckler = {width = 1, height = 2, slot = "offhand", category = "shield"},

    -- Accessories
    ring = {width = 1, height = 1, slot = "accessory1", category = "accessory"},
    amulet = {width = 1, height = 1, slot = "accessory1", category = "accessory"},

    -- Consumables
    potion_health = {width = 1, height = 1, slot = nil, category = "consumable"},
    potion_mana = {width = 1, height = 1, slot = nil, category = "consumable"},
    scroll = {width = 1, height = 1, slot = nil, category = "consumable"},

    -- Materials
    gem = {width = 1, height = 1, slot = nil, category = "material"},
    ore = {width = 1, height = 1, slot = nil, category = "material"},
    herb = {width = 1, height = 1, slot = nil, category = "material"},

    -- Quest items
    key = {width = 1, height = 1, slot = nil, category = "quest"},
    tome = {width = 2, height = 2, slot = nil, category = "quest"},
}

-- Rarity colors
Inventory.RARITY_COLORS = {
    common = {0.75, 0.75, 0.75},
    uncommon = {0.30, 0.80, 0.30},
    rare = {0.30, 0.50, 1.00},
    epic = {0.70, 0.30, 0.90},
    legendary = {1.00, 0.60, 0.00},
}

-- Item database (some example items)
Inventory.ITEMS = {
    -- Swords
    rusty_sword = {
        type = "sword",
        name = "Rusty Sword",
        rarity = "common",
        stats = {damage = 3},
        description = "A worn blade, still sharp enough."
    },
    iron_sword = {
        type = "sword",
        name = "Iron Sword",
        rarity = "common",
        stats = {damage = 6},
        description = "A reliable iron blade."
    },
    knights_blade = {
        type = "sword",
        name = "Knight's Blade",
        rarity = "uncommon",
        stats = {damage = 10, defense = 2},
        description = "A well-crafted blade favored by knights."
    },

    -- Daggers
    small_knife = {
        type = "dagger",
        name = "Small Knife",
        rarity = "common",
        stats = {damage = 2, speed = 1},
        description = "Quick but weak."
    },

    -- Helmets
    leather_cap = {
        type = "cap",
        name = "Leather Cap",
        rarity = "common",
        stats = {defense = 1},
        description = "Basic head protection."
    },
    iron_helm = {
        type = "helmet",
        name = "Iron Helm",
        rarity = "common",
        stats = {defense = 4},
        description = "Sturdy iron headgear."
    },

    -- Chest armor
    cloth_shirt = {
        type = "tunic",
        name = "Cloth Shirt",
        rarity = "common",
        stats = {defense = 1},
        description = "Simple cloth garment."
    },
    leather_armor = {
        type = "chestplate",
        name = "Leather Armor",
        rarity = "common",
        stats = {defense = 3},
        description = "Flexible leather protection."
    },
    chainmail = {
        type = "chestplate",
        name = "Chainmail",
        rarity = "uncommon",
        stats = {defense = 6},
        description = "Interlocking metal rings."
    },

    -- Boots
    sandals = {
        type = "shoes",
        name = "Sandals",
        rarity = "common",
        stats = {speed = 1},
        description = "Light footwear."
    },
    leather_boots = {
        type = "boots",
        name = "Leather Boots",
        rarity = "common",
        stats = {defense = 2},
        description = "Sturdy traveling boots."
    },

    -- Shields
    wooden_shield = {
        type = "shield",
        name = "Wooden Shield",
        rarity = "common",
        stats = {defense = 3, block = 10},
        description = "A simple wooden shield."
    },

    -- Potions
    health_potion = {
        type = "potion_health",
        name = "Health Potion",
        rarity = "common",
        stats = {heal = 25},
        description = "Restores 25 health.",
        stackable = true,
        maxStack = 10
    },
    mana_potion = {
        type = "potion_mana",
        name = "Mana Potion",
        rarity = "common",
        stats = {mana = 25},
        description = "Restores 25 mana.",
        stackable = true,
        maxStack = 10
    },

    -- Accessories
    copper_ring = {
        type = "ring",
        name = "Copper Ring",
        rarity = "common",
        stats = {luck = 1},
        description = "A simple copper band."
    },
    silver_amulet = {
        type = "amulet",
        name = "Silver Amulet",
        rarity = "uncommon",
        stats = {magic = 3},
        description = "Enhances magical ability."
    },
}

-- Create a new inventory instance
function Inventory:new()
    local inv = {
        -- Grid storage: 2D array, nil = empty, otherwise item reference
        grid = {},
        -- Equipped items by slot name
        equipped = {},
        -- Item instances with position data
        items = {}
    }

    -- Initialize empty grid
    for y = 1, self.GRID_HEIGHT do
        inv.grid[y] = {}
        for x = 1, self.GRID_WIDTH do
            inv.grid[y][x] = nil
        end
    end

    -- Initialize empty equipment slots
    for _, slot in ipairs(self.EQUIPMENT_SLOTS) do
        inv.equipped[slot] = nil
    end

    setmetatable(inv, {__index = self})
    return inv
end

-- Create an item instance from template
function Inventory:createItem(itemId, quantity)
    local template = self.ITEMS[itemId]
    if not template then return nil end

    local typeInfo = self.ITEM_TYPES[template.type]
    if not typeInfo then return nil end

    return {
        id = itemId,
        template = template,
        typeInfo = typeInfo,
        quantity = quantity or 1,
        width = typeInfo.width,
        height = typeInfo.height,
        gridX = nil,
        gridY = nil
    }
end

-- Check if item fits at position
function Inventory:canPlaceAt(item, gridX, gridY)
    -- Check bounds
    if gridX < 1 or gridY < 1 then return false end
    if gridX + item.width - 1 > self.GRID_WIDTH then return false end
    if gridY + item.height - 1 > self.GRID_HEIGHT then return false end

    -- Check if all cells are empty
    for dy = 0, item.height - 1 do
        for dx = 0, item.width - 1 do
            local cell = self.grid[gridY + dy][gridX + dx]
            if cell ~= nil and cell ~= item then
                return false
            end
        end
    end

    return true
end

-- Find first available position for item
function Inventory:findSpace(item)
    for y = 1, self.GRID_HEIGHT do
        for x = 1, self.GRID_WIDTH do
            if self:canPlaceAt(item, x, y) then
                return x, y
            end
        end
    end
    return nil, nil
end

-- Place item at grid position
function Inventory:placeAt(item, gridX, gridY)
    if not self:canPlaceAt(item, gridX, gridY) then
        return false
    end

    -- Remove from old position if any
    if item.gridX and item.gridY then
        self:removeFromGrid(item)
    end

    -- Place in new position
    item.gridX = gridX
    item.gridY = gridY

    for dy = 0, item.height - 1 do
        for dx = 0, item.width - 1 do
            self.grid[gridY + dy][gridX + dx] = item
        end
    end

    -- Add to items list if not already there
    local found = false
    for _, existing in ipairs(self.items) do
        if existing == item then
            found = true
            break
        end
    end
    if not found then
        table.insert(self.items, item)
    end

    return true
end

-- Remove item from grid
function Inventory:removeFromGrid(item)
    if not item.gridX or not item.gridY then return end

    for dy = 0, item.height - 1 do
        for dx = 0, item.width - 1 do
            local y = item.gridY + dy
            local x = item.gridX + dx
            if self.grid[y] and self.grid[y][x] == item then
                self.grid[y][x] = nil
            end
        end
    end

    item.gridX = nil
    item.gridY = nil
end

-- Add item to inventory (auto-find space)
function Inventory:addItem(itemId, quantity)
    local item = self:createItem(itemId, quantity)
    if not item then return false end

    -- Try to stack with existing item if stackable
    if item.template.stackable then
        for _, existing in ipairs(self.items) do
            if existing.id == itemId and existing.quantity < (existing.template.maxStack or 99) then
                local space = (existing.template.maxStack or 99) - existing.quantity
                local toAdd = math.min(space, item.quantity)
                existing.quantity = existing.quantity + toAdd
                item.quantity = item.quantity - toAdd
                if item.quantity <= 0 then
                    return true
                end
            end
        end
    end

    -- Find space and place
    local x, y = self:findSpace(item)
    if x and y then
        return self:placeAt(item, x, y)
    end

    return false
end

-- Get item at grid position
function Inventory:getItemAt(gridX, gridY)
    if gridX < 1 or gridX > self.GRID_WIDTH then return nil end
    if gridY < 1 or gridY > self.GRID_HEIGHT then return nil end
    return self.grid[gridY][gridX]
end

-- Equip item from inventory
function Inventory:equipItem(item)
    if not item.typeInfo.slot then return false end

    local slot = item.typeInfo.slot

    -- Handle accessory slots specially
    if item.typeInfo.category == "accessory" then
        if self.equipped.accessory1 == nil then
            slot = "accessory1"
        elseif self.equipped.accessory2 == nil then
            slot = "accessory2"
        else
            slot = "accessory1" -- Default to slot 1, will swap
        end
    end

    -- Unequip current item in slot
    local oldItem = self.equipped[slot]
    if oldItem then
        -- Find space for old item
        local x, y = self:findSpace(oldItem)
        if not x then return false end -- No room
        self:placeAt(oldItem, x, y)
    end

    -- Remove new item from grid and equip
    self:removeFromGrid(item)

    -- Remove from items list
    for i, existing in ipairs(self.items) do
        if existing == item then
            table.remove(self.items, i)
            break
        end
    end

    self.equipped[slot] = item
    return true
end

-- Unequip item to inventory
function Inventory:unequipItem(slot)
    local item = self.equipped[slot]
    if not item then return false end

    local x, y = self:findSpace(item)
    if not x then return false end -- No room

    self.equipped[slot] = nil
    self:placeAt(item, x, y)
    return true
end

-- Get total stats from equipped items
function Inventory:getEquippedStats()
    local stats = {}
    for _, slot in ipairs(self.EQUIPMENT_SLOTS) do
        local item = self.equipped[slot]
        if item and item.template.stats then
            for stat, value in pairs(item.template.stats) do
                stats[stat] = (stats[stat] or 0) + value
            end
        end
    end
    return stats
end

-- Serialize inventory for saving
function Inventory:serialize()
    local data = {
        items = {},
        equipped = {}
    }

    for _, item in ipairs(self.items) do
        table.insert(data.items, {
            id = item.id,
            quantity = item.quantity,
            gridX = item.gridX,
            gridY = item.gridY
        })
    end

    for slot, item in pairs(self.equipped) do
        if item then
            data.equipped[slot] = {
                id = item.id,
                quantity = item.quantity
            }
        end
    end

    return data
end

-- Load inventory from saved data
function Inventory:deserialize(data)
    if not data then return end

    -- Clear current inventory
    self.items = {}
    self.equipped = {}
    for y = 1, self.GRID_HEIGHT do
        for x = 1, self.GRID_WIDTH do
            self.grid[y][x] = nil
        end
    end

    -- Load items
    if data.items then
        for _, itemData in ipairs(data.items) do
            local item = self:createItem(itemData.id, itemData.quantity)
            if item and itemData.gridX and itemData.gridY then
                self:placeAt(item, itemData.gridX, itemData.gridY)
            end
        end
    end

    -- Load equipped
    if data.equipped then
        for slot, itemData in pairs(data.equipped) do
            local item = self:createItem(itemData.id, itemData.quantity)
            if item then
                self.equipped[slot] = item
            end
        end
    end
end

return Inventory
