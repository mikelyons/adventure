-- Color compatibility module
-- Handles differences between Love2D versions (0.10.x uses 0-255, 11.x uses 0-1)

local Color = {}

function Color.set(r, g, b, a)
    a = a or 1
    local getVersion = love.getVersion
    if getVersion then
        local major = getVersion()
        if type(major) == "number" and major >= 11 then
            love.graphics.setColor(r, g, b, a)
            return
        end
    end
    love.graphics.setColor(r * 255, g * 255, b * 255, a * 255)
end

return Color
