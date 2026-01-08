-- Inventory Screen State
-- Diablo 2-style inventory with paperdoll and grid

local InventoryScreen = {}
local Color = require("color")
local Inventory = require("inventory")
local Paperdoll = require("paperdoll")

local CELL_SIZE = 40
local GRID_OFFSET_X = 420
local GRID_OFFSET_Y = 100

-- Equipment slot positions (relative to paperdoll center)
local EQUIP_SLOTS = {
    head = {x = 0, y = -100, width = 2, height = 2, label = "Head"},
    chest = {x = 0, y = -30, width = 2, height = 3, label = "Chest"},
    legs = {x = 0, y = 60, width = 2, height = 2, label = "Legs"},
    feet = {x = 0, y = 130, width = 2, height = 2, label = "Feet"},
    mainhand = {x = -90, y = 0, width = 2, height = 3, label = "Weapon"},
    offhand = {x = 90, y = 0, width = 2, height = 2, label = "Off-hand"},
    accessory1 = {x = -90, y = 100, width = 1, height = 1, label = "Ring"},
    accessory2 = {x = 90, y = 100, width = 1, height = 1, label = "Amulet"},
}

function InventoryScreen:load()
    self.selectedGridX = 1
    self.selectedGridY = 1
    self.selectedSlot = nil
    self.mode = "grid" -- "grid" or "equipment"
    self.hoverItem = nil
    self.cursorBlink = 0

    -- Get player inventory from worldmap or create new
    self.inventory = self.playerInventory or Inventory:new()

    -- Get paperdoll character if available
    self.character = self.playerCharacter or Paperdoll:newCharacter({
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
end

function InventoryScreen:enter(inventory, character)
    self.playerInventory = inventory
    self.playerCharacter = character
    self:load()
end

function InventoryScreen:update(dt)
    self.cursorBlink = self.cursorBlink + dt

    -- Update hover item
    if self.mode == "grid" then
        self.hoverItem = self.inventory:getItemAt(self.selectedGridX, self.selectedGridY)
    elseif self.mode == "equipment" and self.selectedSlot then
        self.hoverItem = self.inventory.equipped[self.selectedSlot]
    end
end

function InventoryScreen:draw()
    local screenW, screenH = love.graphics.getDimensions()

    -- Dark background
    Color.set(0.08, 0.10, 0.14, 0.95)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Title
    Color.set(0.90, 0.85, 0.70)
    love.graphics.printf("INVENTORY", 0, 20, screenW, "center")

    -- Draw equipment panel (left side)
    self:drawEquipmentPanel(screenW, screenH)

    -- Draw grid inventory (right side)
    self:drawGridInventory(screenW, screenH)

    -- Draw item tooltip
    self:drawTooltip(screenW, screenH)

    -- Draw controls hint
    self:drawControls(screenW, screenH)
end

function InventoryScreen:drawEquipmentPanel(screenW, screenH)
    local panelX = 40
    local panelY = 60
    local panelW = 340
    local panelH = 420

    -- Panel background
    Color.set(0.12, 0.14, 0.20, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 6, 6)
    Color.set(0.35, 0.40, 0.55, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 6, 6)

    -- Section title
    Color.set(0.70, 0.75, 0.85)
    love.graphics.printf("Equipment", panelX, panelY + 10, panelW, "center")

    -- Paperdoll center
    local centerX = panelX + panelW / 2
    local centerY = panelY + panelH / 2

    -- Draw paperdoll character (large scale)
    Color.set(1, 1, 1, 1)
    if self.character then
        self.character:draw(centerX - 40, centerY - 75, 5, 1)
    end

    -- Draw equipment slots
    for slotName, slotInfo in pairs(EQUIP_SLOTS) do
        local slotX = centerX + slotInfo.x - (slotInfo.width * CELL_SIZE / 2)
        local slotY = centerY + slotInfo.y - (slotInfo.height * CELL_SIZE / 2)
        local slotW = slotInfo.width * CELL_SIZE
        local slotH = slotInfo.height * CELL_SIZE

        -- Slot background
        Color.set(0.08, 0.10, 0.15, 0.9)
        love.graphics.rectangle("fill", slotX, slotY, slotW, slotH, 4, 4)

        -- Slot border (highlight if selected)
        local isSelected = self.mode == "equipment" and self.selectedSlot == slotName
        if isSelected then
            local pulse = math.sin(self.cursorBlink * 4) * 0.3 + 0.7
            Color.set(0.50, 0.70, 1.0, pulse)
            love.graphics.setLineWidth(3)
        else
            Color.set(0.30, 0.35, 0.45, 0.8)
            love.graphics.setLineWidth(1)
        end
        love.graphics.rectangle("line", slotX, slotY, slotW, slotH, 4, 4)

        -- Draw equipped item
        local equippedItem = self.inventory.equipped[slotName]
        if equippedItem then
            self:drawItem(equippedItem, slotX + 2, slotY + 2, slotW - 4, slotH - 4)
        else
            -- Empty slot label
            Color.set(0.30, 0.35, 0.45, 0.5)
            love.graphics.printf(slotInfo.label, slotX, slotY + slotH/2 - 6, slotW, "center")
        end
    end

    -- Draw stats summary
    local statsY = panelY + panelH - 80
    Color.set(0.25, 0.28, 0.35)
    love.graphics.rectangle("fill", panelX + 10, statsY, panelW - 20, 70, 4, 4)

    local stats = self.inventory:getEquippedStats()
    Color.set(0.70, 0.75, 0.85)
    love.graphics.print("Stats:", panelX + 20, statsY + 8)

    local statText = ""
    if stats.damage then statText = statText .. "DMG:" .. stats.damage .. "  " end
    if stats.defense then statText = statText .. "DEF:" .. stats.defense .. "  " end
    if stats.speed then statText = statText .. "SPD:" .. stats.speed .. "  " end
    if stats.magic then statText = statText .. "MAG:" .. stats.magic .. "  " end

    if statText == "" then statText = "No bonuses" end
    Color.set(0.55, 0.60, 0.70)
    love.graphics.print(statText, panelX + 20, statsY + 28)
end

function InventoryScreen:drawGridInventory(screenW, screenH)
    local gridW = Inventory.GRID_WIDTH * CELL_SIZE
    local gridH = Inventory.GRID_HEIGHT * CELL_SIZE
    local gridX = GRID_OFFSET_X
    local gridY = GRID_OFFSET_Y

    -- Panel background
    local panelX = gridX - 20
    local panelY = gridY - 40
    local panelW = gridW + 40
    local panelH = gridH + 80

    Color.set(0.12, 0.14, 0.20, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 6, 6)
    Color.set(0.35, 0.40, 0.55, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 6, 6)

    -- Section title
    Color.set(0.70, 0.75, 0.85)
    love.graphics.printf("Backpack", panelX, panelY + 10, panelW, "center")

    -- Draw grid cells
    for y = 1, Inventory.GRID_HEIGHT do
        for x = 1, Inventory.GRID_WIDTH do
            local cellX = gridX + (x - 1) * CELL_SIZE
            local cellY = gridY + (y - 1) * CELL_SIZE

            -- Cell background
            Color.set(0.08, 0.10, 0.15, 0.9)
            love.graphics.rectangle("fill", cellX, cellY, CELL_SIZE - 2, CELL_SIZE - 2, 2, 2)

            -- Cell border
            Color.set(0.25, 0.28, 0.35, 0.8)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", cellX, cellY, CELL_SIZE - 2, CELL_SIZE - 2, 2, 2)
        end
    end

    -- Draw items
    local drawnItems = {}
    for y = 1, Inventory.GRID_HEIGHT do
        for x = 1, Inventory.GRID_WIDTH do
            local item = self.inventory:getItemAt(x, y)
            if item and not drawnItems[item] then
                drawnItems[item] = true
                local itemX = gridX + (item.gridX - 1) * CELL_SIZE
                local itemY = gridY + (item.gridY - 1) * CELL_SIZE
                local itemW = item.width * CELL_SIZE - 2
                local itemH = item.height * CELL_SIZE - 2
                self:drawItem(item, itemX, itemY, itemW, itemH)
            end
        end
    end

    -- Draw selection cursor
    if self.mode == "grid" then
        local cursorX = gridX + (self.selectedGridX - 1) * CELL_SIZE
        local cursorY = gridY + (self.selectedGridY - 1) * CELL_SIZE
        local pulse = math.sin(self.cursorBlink * 4) * 0.3 + 0.7

        Color.set(0.50, 0.70, 1.0, pulse)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", cursorX - 2, cursorY - 2, CELL_SIZE + 2, CELL_SIZE + 2, 3, 3)
    end
end

function InventoryScreen:drawItem(item, x, y, w, h)
    if not item then return end

    local rarity = item.template.rarity or "common"
    local rarityColor = Inventory.RARITY_COLORS[rarity] or {0.7, 0.7, 0.7}

    -- Item background with rarity tint
    Color.set(rarityColor[1] * 0.3, rarityColor[2] * 0.3, rarityColor[3] * 0.3, 0.8)
    love.graphics.rectangle("fill", x, y, w, h, 3, 3)

    -- Item border with rarity color
    Color.set(rarityColor[1], rarityColor[2], rarityColor[3], 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 3, 3)

    -- Item icon (simple symbol based on category)
    Color.set(rarityColor[1], rarityColor[2], rarityColor[3], 1)
    local iconText = self:getItemIcon(item)
    local fontSize = math.min(w, h) * 0.5
    love.graphics.printf(iconText, x, y + h/2 - 8, w, "center")

    -- Quantity badge for stackable items
    if item.template.stackable and item.quantity > 1 then
        local badgeX = x + w - 16
        local badgeY = y + h - 14
        Color.set(0.15, 0.15, 0.20, 0.9)
        love.graphics.rectangle("fill", badgeX, badgeY, 14, 12, 2, 2)
        Color.set(1, 1, 1, 1)
        love.graphics.print(tostring(item.quantity), badgeX + 2, badgeY)
    end
end

function InventoryScreen:getItemIcon(item)
    local icons = {
        sword = "/",
        dagger = "-",
        axe = "P",
        staff = "|",
        bow = ")",
        helmet = "n",
        cap = "^",
        chestplate = "M",
        robe = "A",
        tunic = "T",
        leggings = "U",
        boots = "L",
        shoes = "u",
        shield = "O",
        buckler = "o",
        ring = "o",
        amulet = "@",
        potion_health = "+",
        potion_mana = "*",
        scroll = "~",
        gem = "<>",
        ore = "#",
        herb = "Y",
        key = "f",
        tome = "B"
    }
    return icons[item.typeInfo and item.template.type] or "?"
end

function InventoryScreen:drawTooltip(screenW, screenH)
    if not self.hoverItem then return end

    local item = self.hoverItem
    local tooltipW = 200
    local tooltipH = 120
    local tooltipX = screenW - tooltipW - 40
    local tooltipY = screenH - tooltipH - 80

    -- Tooltip background
    Color.set(0.10, 0.12, 0.18, 0.95)
    love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipW, tooltipH, 4, 4)

    local rarity = item.template.rarity or "common"
    local rarityColor = Inventory.RARITY_COLORS[rarity]
    Color.set(rarityColor[1], rarityColor[2], rarityColor[3], 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", tooltipX, tooltipY, tooltipW, tooltipH, 4, 4)

    -- Item name with rarity color
    Color.set(rarityColor[1], rarityColor[2], rarityColor[3], 1)
    love.graphics.print(item.template.name, tooltipX + 10, tooltipY + 10)

    -- Item type
    Color.set(0.50, 0.55, 0.65)
    love.graphics.print(item.template.type, tooltipX + 10, tooltipY + 28)

    -- Stats
    local statsY = tooltipY + 50
    if item.template.stats then
        for stat, value in pairs(item.template.stats) do
            Color.set(0.60, 0.75, 0.60)
            love.graphics.print("+" .. value .. " " .. stat, tooltipX + 10, statsY)
            statsY = statsY + 16
        end
    end

    -- Description
    if item.template.description then
        Color.set(0.55, 0.55, 0.60)
        love.graphics.printf(item.template.description, tooltipX + 10, tooltipH + tooltipY - 30, tooltipW - 20, "left")
    end
end

function InventoryScreen:drawControls(screenW, screenH)
    local hintY = screenH - 40

    Color.set(0.15, 0.17, 0.22)
    love.graphics.rectangle("fill", 0, hintY - 10, screenW, 50)

    Color.set(0.50, 0.55, 0.65)
    local hints = "Arrow Keys: Navigate | TAB: Switch Panel | ENTER: Equip/Use | Q: Unequip | ESC: Close"
    love.graphics.printf(hints, 0, hintY, screenW, "center")
end

function InventoryScreen:keypressed(key)
    if key == "escape" then
        Gamestate:pop()
        return
    end

    if key == "tab" then
        -- Toggle between grid and equipment
        if self.mode == "grid" then
            self.mode = "equipment"
            self.selectedSlot = "head"
        else
            self.mode = "grid"
            self.selectedSlot = nil
        end
        return
    end

    if self.mode == "grid" then
        self:handleGridInput(key)
    else
        self:handleEquipmentInput(key)
    end
end

function InventoryScreen:handleGridInput(key)
    if key == "left" then
        self.selectedGridX = math.max(1, self.selectedGridX - 1)
    elseif key == "right" then
        self.selectedGridX = math.min(Inventory.GRID_WIDTH, self.selectedGridX + 1)
    elseif key == "up" then
        self.selectedGridY = math.max(1, self.selectedGridY - 1)
    elseif key == "down" then
        self.selectedGridY = math.min(Inventory.GRID_HEIGHT, self.selectedGridY + 1)
    elseif key == "return" or key == "kpenter" then
        -- Equip or use item
        local item = self.inventory:getItemAt(self.selectedGridX, self.selectedGridY)
        if item then
            if item.typeInfo.slot then
                -- Equippable item
                self.inventory:equipItem(item)
            elseif item.typeInfo.category == "consumable" then
                -- Use consumable (just remove for now)
                self.inventory:removeFromGrid(item)
                for i, existing in ipairs(self.inventory.items) do
                    if existing == item then
                        table.remove(self.inventory.items, i)
                        break
                    end
                end
            end
        end
    end
end

function InventoryScreen:handleEquipmentInput(key)
    local slots = {"head", "mainhand", "chest", "offhand", "legs", "accessory1", "feet", "accessory2"}
    local currentIndex = 1
    for i, slot in ipairs(slots) do
        if slot == self.selectedSlot then
            currentIndex = i
            break
        end
    end

    if key == "left" then
        currentIndex = currentIndex - 1
        if currentIndex < 1 then currentIndex = #slots end
    elseif key == "right" then
        currentIndex = currentIndex + 1
        if currentIndex > #slots then currentIndex = 1 end
    elseif key == "up" then
        currentIndex = currentIndex - 2
        if currentIndex < 1 then currentIndex = currentIndex + #slots end
    elseif key == "down" then
        currentIndex = currentIndex + 2
        if currentIndex > #slots then currentIndex = currentIndex - #slots end
    elseif key == "q" then
        -- Unequip item
        if self.selectedSlot then
            self.inventory:unequipItem(self.selectedSlot)
        end
    end

    self.selectedSlot = slots[currentIndex]
end

return InventoryScreen
