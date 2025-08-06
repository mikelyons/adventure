local MainMenu = {}

function MainMenu:load()
    self.options = {"New Game", "Continue", "Options", "Quit"}
    self.selected = 1
end

function MainMenu:update(dt)
end

function MainMenu:draw()
    love.graphics.printf("Main Menu", 0, 100, 800, "center")

    for i, option in ipairs(self.options) do
        if i == self.selected then
            love.graphics.print("> " .. option, 350, 200 + i * 50)
        else
            love.graphics.print(option, 350, 200 + i * 50)
        end
    end
end

function MainMenu:keypressed(key)
    if key == "down" then
        self.selected = self.selected + 1
        if self.selected > #self.options then
            self.selected = 1
        end
    elseif key == "up" then
        self.selected = self.selected - 1
        if self.selected < 1 then
            self.selected = #self.options
        end
    elseif key == "return" or key == "kpenter" then
        if self.selected == 1 then
            -- Start new game
            Gamestate:push(require "states.newgame")
        elseif self.selected == 2 then
            -- Continue (placeholder)
        elseif self.selected == 3 then
            -- Go to options
        elseif self.selected == 4 then
            love.event.quit()
        end
    end
end

return MainMenu

