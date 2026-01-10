-- Controls Help Panel
-- Toggleable overlay showing active controls for current game mode

local ControlsPanel = {}
local Color = require("color")

ControlsPanel.visible = false
ControlsPanel.currentMode = "worldmap"

-- Control definitions per mode
ControlsPanel.CONTROLS = {
    worldmap = {
        title = "World Map Controls",
        controls = {
            {"W / Up", "Move north"},
            {"A / Left", "Move west"},
            {"S / Down", "Move south"},
            {"D / Right", "Move east"},
            {"Space", "Enter location"},
            {"E", "Enter/Exit car"},
            {"I", "Open inventory"},
            {"F5", "Quick save"},
            {"Escape", "Pause menu"},
            {"?", "Toggle this help"},
        }
    },
    town = {
        title = "Town Controls",
        controls = {
            {"W / Up", "Move north"},
            {"A / Left", "Move west"},
            {"S / Down", "Move south"},
            {"D / Right", "Move east"},
            {"Space", "Talk / Enter building"},
            {"Escape", "Pause menu"},
            {"?", "Toggle this help"},
        }
    },
    building = {
        title = "Building Interior Controls",
        controls = {
            {"A / Left", "Move left"},
            {"D / Right", "Move right"},
            {"W / Space", "Jump"},
            {"S / Down", "Drop through platform"},
            {"E", "Interact"},
            {"Escape", "Exit building"},
            {"?", "Toggle this help"},
        }
    },
    inventory = {
        title = "Inventory Controls",
        controls = {
            {"W/A/S/D", "Navigate grid"},
            {"Arrow Keys", "Navigate grid"},
            {"Tab", "Switch panels"},
            {"Space / Enter", "Select / Equip item"},
            {"Escape", "Close inventory"},
            {"?", "Toggle this help"},
        }
    },
    level = {
        title = "Dungeon Controls",
        controls = {
            {"W / Up", "Move north"},
            {"A / Left", "Move west"},
            {"S / Down", "Move south"},
            {"D / Right", "Move east"},
            {"Space", "Attack / Interact"},
            {"Escape", "Pause menu"},
            {"?", "Toggle this help"},
        }
    },
    contra = {
        title = "Shooter Controls",
        controls = {
            {"A / Left", "Move left"},
            {"D / Right", "Move right"},
            {"W / Up", "Aim up"},
            {"S / Down", "Crouch / Aim down"},
            {"Space", "Jump"},
            {"J / Z", "Shoot"},
            {"Escape", "Pause menu"},
            {"?", "Toggle this help"},
        }
    },
    basebuilding = {
        title = "Base Building Controls",
        controls = {
            {"W/A/S/D", "Move cursor"},
            {"Space / Enter", "Place / Select"},
            {"Tab", "Cycle building types"},
            {"R", "Rotate"},
            {"Escape", "Pause menu"},
            {"?", "Toggle this help"},
        }
    },
    pause = {
        title = "Pause Menu Controls",
        controls = {
            {"W / Up", "Move selection up"},
            {"S / Down", "Move selection down"},
            {"Space / Enter", "Select option"},
            {"Escape", "Resume game"},
            {"?", "Toggle this help"},
        }
    },
    dialogue = {
        title = "Dialogue Controls",
        controls = {
            {"Space", "Continue / Skip text"},
            {"W / Up", "Select choice up"},
            {"S / Down", "Select choice down"},
            {"Enter", "Confirm choice"},
        }
    }
}

function ControlsPanel:toggle()
    self.visible = not self.visible
end

function ControlsPanel:show()
    self.visible = true
end

function ControlsPanel:hide()
    self.visible = false
end

function ControlsPanel:setMode(mode)
    self.currentMode = mode
end

function ControlsPanel:isVisible()
    return self.visible
end

function ControlsPanel:draw()
    if not self.visible then return end

    local screenW, screenH = love.graphics.getDimensions()
    local controls = self.CONTROLS[self.currentMode] or self.CONTROLS.worldmap

    -- Calculate panel size based on content
    local lineHeight = 24
    local panelPadding = 20
    local keyWidth = 120
    local descWidth = 200
    local panelW = keyWidth + descWidth + panelPadding * 3
    local panelH = (#controls.controls + 2) * lineHeight + panelPadding * 2

    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Dim background
    Color.set(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Panel shadow
    Color.set(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", panelX + 4, panelY + 4, panelW, panelH, 8, 8)

    -- Panel background
    Color.set(0.08, 0.10, 0.15, 0.98)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)

    -- Panel border
    love.graphics.setLineWidth(2)
    Color.set(0.45, 0.55, 0.70)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)

    -- Inner highlight
    love.graphics.setLineWidth(1)
    Color.set(0.55, 0.65, 0.80, 0.3)
    love.graphics.rectangle("line", panelX + 2, panelY + 2, panelW - 4, panelH - 4, 6, 6)

    -- Title
    Color.set(0.95, 0.90, 0.70)
    love.graphics.printf(controls.title, panelX, panelY + panelPadding, panelW, "center")

    -- Separator line
    local sepY = panelY + panelPadding + lineHeight + 5
    Color.set(0.35, 0.45, 0.55)
    love.graphics.rectangle("fill", panelX + panelPadding, sepY, panelW - panelPadding * 2, 2)

    -- Controls list
    local startY = sepY + 15
    for i, control in ipairs(controls.controls) do
        local y = startY + (i - 1) * lineHeight

        -- Key badge background
        Color.set(0.18, 0.22, 0.28)
        love.graphics.rectangle("fill", panelX + panelPadding, y, keyWidth, lineHeight - 4, 4, 4)

        -- Key badge border
        Color.set(0.40, 0.50, 0.60)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", panelX + panelPadding, y, keyWidth, lineHeight - 4, 4, 4)

        -- Key text
        Color.set(0.90, 0.95, 1.0)
        love.graphics.printf(control[1], panelX + panelPadding, y + 3, keyWidth, "center")

        -- Description
        Color.set(0.75, 0.80, 0.85)
        love.graphics.print(control[2], panelX + panelPadding + keyWidth + 15, y + 3)
    end

    -- Footer hint
    local footerY = panelY + panelH - panelPadding - 5
    Color.set(0.50, 0.55, 0.60)
    love.graphics.printf("Press ? to close", panelX, footerY, panelW, "center")
end

-- Handle keypress - returns true if handled
function ControlsPanel:keypressed(key)
    if key == "/" and love.keyboard.isDown("lshift", "rshift") then
        self:toggle()
        return true
    end

    -- If visible and any key pressed, close panel
    if self.visible then
        if key == "escape" or key == "space" or key == "return" then
            self:hide()
            return true
        end
    end

    return false
end

return ControlsPanel
