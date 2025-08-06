local Splash = {}

function Splash:load()
    self.timer = 0
end

function Splash:update(dt)
    self.timer = self.timer + dt
    if self.timer > 0.5 then
        Gamestate:pop()
        Gamestate:push(require "states.mainmenu")
    end
end

function Splash:draw()
    love.graphics.printf("ADVENTURE", 0, 250, 800, "center")
end

return Splash

