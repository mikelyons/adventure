function love.conf(t)
    t.identity = "adventure"
    t.window.title = "Adventure"
    t.window.width = 800
    t.window.height = 600
    t.window.vsync = 1  -- Enable vsync for smooth rendering

    -- Set default filter mode to nearest for crisp pixel art
    t.window.minwidth = 400
    t.window.minheight = 300
end
