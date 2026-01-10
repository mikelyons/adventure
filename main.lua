Gamestate = require "gamestate"
ControlsPanel = require "controlspanel"
DebugUI = require "debugui"

function love.load()
    love.filesystem.setIdentity("adventure")

    -- Set point filter for crisp pixel art (no blurring)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)

    Gamestate:push(require "states.splash")
end

function love.update(dt)
    Gamestate:update(dt)
    DebugUI:update(dt)
end

function love.draw()
    love.graphics.origin()
    love.graphics.clear(0.1, 0.2, 0.3, 1)
    Gamestate:draw()

    -- Draw controls panel on top of everything
    ControlsPanel:draw()

    -- Draw debug UI on top of everything
    DebugUI:draw()
end

function love.keypressed(key)
    -- Check for controls panel toggle first (? = shift + /)
    if ControlsPanel:keypressed(key) then
        return
    end

    -- Don't pass input to game if controls panel is open
    if ControlsPanel:isVisible() then
        return
    end

    Gamestate:keypressed(key)
end

function love.mousemoved(x, y, dx, dy)
    -- Update debug UI hover state
    DebugUI:mousemoved(x, y)

    -- Don't pass mouse input to game if controls panel is open
    if ControlsPanel:isVisible() then
        return
    end

    Gamestate:mousemoved(x, y, dx, dy)
end

function love.mousepressed(x, y, button)
    -- Check debug UI first
    if DebugUI:mousepressed(x, y, button) then
        return
    end

    -- Don't pass mouse input to game if controls panel is open
    if ControlsPanel:isVisible() then
        return
    end

    Gamestate:mousepressed(x, y, button)
end

function love.quit()
    -- Auto-save current game state if in worldmap
    local currentState = Gamestate:current()
    if currentState and currentState.saveGame then
        currentState:saveGame()
    end
end
