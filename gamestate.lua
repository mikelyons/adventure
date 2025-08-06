Gamestate = {
    stack = {}
}

function Gamestate:push(state)
    table.insert(self.stack, state)
    if self.stack[#self.stack].load then
        self.stack[#self.stack]:load()
    end
    if self.stack[#self.stack].enter then
        self.stack[#self.stack]:enter()
    end
end

function Gamestate:pop()
    table.remove(self.stack)
end

function Gamestate:current()
    return self.stack[#self.stack]
end

function Gamestate:update(dt)
    if self:current() and self:current().update then
        self:current():update(dt)
    end
end

function Gamestate:draw()
    if self:current() and self:current().draw then
        self:current():draw()
    end
end

function Gamestate:keypressed(key)
    if self:current() and self:current().keypressed then
        self:current():keypressed(key)
    end
end

return Gamestate

