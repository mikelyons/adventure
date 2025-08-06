Gamestate = require "gamestate"

function love.load()
    Gamestate:push(require "states.splash")
end

function love.update(dt)
    Gamestate:update(dt)
end

function love.draw()
    Gamestate:draw()
end

function love.keypressed(key)
    Gamestate:keypressed(key)
end
