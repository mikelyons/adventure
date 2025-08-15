Gamestate = require "gamestate"

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
end

function love.keypressed(key)
    Gamestate:keypressed(key)
end

function love.quit()
    -- Auto-save current game state if in worldmap
    local currentState = Gamestate:current()
    if currentState and currentState.saveGame then
        currentState:saveGame()
    end
end
