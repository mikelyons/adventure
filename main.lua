Gamestate = require "gamestate"
ControlsPanel = require "controlspanel"

function love.load()
    love.filesystem.setIdentity("adventure")
    Gamestate:push(require "states.splash")
end

function love.update(dt)
    Gamestate:update(dt)
end

function love.draw()
    love.graphics.origin()
    love.graphics.clear(0.1, 0.2, 0.3, 1)
    Gamestate:draw()

    -- Draw controls panel on top of everything
    ControlsPanel:draw()
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

function love.quit()
    -- Auto-save current game state if in worldmap
    local currentState = Gamestate:current()
    if currentState and currentState.saveGame then
        currentState:saveGame()
    end
end
