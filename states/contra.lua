-- Contra-style Side-Scrolling Shooter
-- Inspired by Contra: Alien Wars (SNES)
-- Enhanced with high-fidelity retro graphics

local Contra = {}

local function setColor(r, g, b, a)
    a = a or 1
    local getVersion = love.getVersion
    if getVersion then
        local major = getVersion()
        if type(major) == "number" then
            if major >= 11 then
                love.graphics.setColor(r, g, b, a)
                return
            end
        end
    end
    love.graphics.setColor(r * 255, g * 255, b * 255, a * 255)
end

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpColor(c1, c2, t)
    return {lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t), lerp(c1[3], c2[3], t)}
end

-- Color palettes for SNES-style graphics
local PALETTES = {
    player = {
        body = {{0.22, 0.52, 0.85}, {0.15, 0.38, 0.68}, {0.32, 0.62, 0.95}},
        skin = {{0.92, 0.78, 0.62}, {0.78, 0.62, 0.48}, {0.98, 0.88, 0.75}},
        hair = {{0.35, 0.25, 0.18}, {0.25, 0.18, 0.12}}
    },
    soldier = {
        body = {{0.75, 0.28, 0.28}, {0.55, 0.18, 0.18}, {0.88, 0.38, 0.38}},
        skin = {{0.72, 0.58, 0.45}, {0.58, 0.45, 0.35}}
    },
    turret = {
        metal = {{0.55, 0.55, 0.62}, {0.42, 0.42, 0.48}, {0.72, 0.72, 0.78}},
        accent = {{0.85, 0.35, 0.25}, {0.65, 0.25, 0.18}}
    },
    flyer = {
        body = {{0.92, 0.52, 0.22}, {0.72, 0.38, 0.15}, {0.98, 0.68, 0.35}},
        wing = {{0.82, 0.42, 0.18}, {0.62, 0.32, 0.12}}
    },
    boss = {
        body = {{0.72, 0.22, 0.52}, {0.52, 0.12, 0.38}, {0.85, 0.35, 0.65}},
        armor = {{0.45, 0.15, 0.35}, {0.32, 0.08, 0.25}},
        eye = {{0.95, 0.35, 0.45}, {0.78, 0.22, 0.32}}
    },
    ground = {
        rock = {{0.35, 0.30, 0.40}, {0.28, 0.24, 0.32}, {0.45, 0.38, 0.52}},
        metal = {{0.42, 0.38, 0.48}, {0.32, 0.28, 0.38}, {0.55, 0.50, 0.62}}
    }
}

function Contra:load()
    -- Level dimensions
    self.level = {
        width = 3200,  -- Long scrolling level
        height = 600,
        tileSize = 32
    }

    -- Player
    self.player = {
        x = 100,
        y = 400,
        width = 24,
        height = 32,
        vx = 0,
        vy = 0,
        speed = 200,
        jumpForce = -450,
        onGround = false,
        facing = 1,  -- 1 = right, -1 = left
        aimAngle = 0,  -- 0 = straight, up/down
        health = 3,
        maxHealth = 3,
        invincible = false,
        invincibleTimer = 0,
        shooting = false,
        shootTimer = 0,
        shootDelay = 0.15,
        animFrame = 1,
        animTimer = 0
    }

    -- Physics
    self.gravity = 1200

    -- Camera
    self.camera = { x = 0, y = 0 }

    -- Bullets
    self.bullets = {}
    self.bulletSpeed = 600

    -- Enemies
    self.enemies = {}

    -- Platforms/terrain
    self.platforms = {}

    -- Particles (explosions, etc)
    self.particles = {}

    -- Game state
    self.gameOver = false
    self.victory = false
    self.score = 0

    -- Level name
    self.levelName = "Mystic Portal"
end

function Contra:enter()
    if self.poiData then
        self.levelName = self.poiData.name or "Mystic Portal"
        love.math.setRandomSeed(self.poiData.levelSeed or 54321)
    end

    self:generateLevel()
    self:spawnEnemies()
end

function Contra:generateLevel()
    self.platforms = {}

    -- Ground floor
    table.insert(self.platforms, {
        x = 0, y = 520, width = 800, height = 80, color = {0.3, 0.25, 0.35}
    })
    table.insert(self.platforms, {
        x = 850, y = 520, width = 400, height = 80, color = {0.3, 0.25, 0.35}
    })
    table.insert(self.platforms, {
        x = 1300, y = 520, width = 600, height = 80, color = {0.3, 0.25, 0.35}
    })
    table.insert(self.platforms, {
        x = 1950, y = 520, width = 500, height = 80, color = {0.3, 0.25, 0.35}
    })
    table.insert(self.platforms, {
        x = 2500, y = 520, width = 700, height = 80, color = {0.3, 0.25, 0.35}
    })

    -- Floating platforms
    table.insert(self.platforms, {
        x = 300, y = 400, width = 150, height = 24, color = {0.4, 0.3, 0.5}
    })
    table.insert(self.platforms, {
        x = 500, y = 320, width = 120, height = 24, color = {0.4, 0.3, 0.5}
    })
    table.insert(self.platforms, {
        x = 700, y = 380, width = 100, height = 24, color = {0.4, 0.3, 0.5}
    })

    table.insert(self.platforms, {
        x = 1000, y = 400, width = 180, height = 24, color = {0.4, 0.3, 0.5}
    })
    table.insert(self.platforms, {
        x = 1250, y = 340, width = 140, height = 24, color = {0.4, 0.3, 0.5}
    })

    table.insert(self.platforms, {
        x = 1600, y = 420, width = 160, height = 24, color = {0.4, 0.3, 0.5}
    })
    table.insert(self.platforms, {
        x = 1800, y = 350, width = 120, height = 24, color = {0.4, 0.3, 0.5}
    })

    table.insert(self.platforms, {
        x = 2100, y = 400, width = 200, height = 24, color = {0.4, 0.3, 0.5}
    })
    table.insert(self.platforms, {
        x = 2400, y = 360, width = 150, height = 24, color = {0.4, 0.3, 0.5}
    })

    -- Elevated sections
    table.insert(self.platforms, {
        x = 2700, y = 420, width = 300, height = 100, color = {0.35, 0.28, 0.4}
    })

    -- Boss arena
    table.insert(self.platforms, {
        x = 2900, y = 520, width = 300, height = 80, color = {0.4, 0.2, 0.3}
    })
end

function Contra:spawnEnemies()
    self.enemies = {}

    -- Ground soldiers
    local soldierPositions = {400, 600, 900, 1100, 1400, 1700, 2000, 2300, 2600}
    for _, xPos in ipairs(soldierPositions) do
        table.insert(self.enemies, {
            type = "soldier",
            x = xPos,
            y = 480,
            width = 20,
            height = 28,
            health = 1,
            vx = 0,
            facing = -1,
            shootTimer = love.math.random() * 2,
            shootDelay = 2.0,
            color = {0.8, 0.3, 0.3}
        })
    end

    -- Turrets on platforms
    local turretPositions = {
        {x = 350, y = 370},
        {x = 1050, y = 370},
        {x = 1650, y = 390},
        {x = 2150, y = 370}
    }
    for _, pos in ipairs(turretPositions) do
        table.insert(self.enemies, {
            type = "turret",
            x = pos.x,
            y = pos.y,
            width = 28,
            height = 20,
            health = 3,
            shootTimer = love.math.random() * 1.5,
            shootDelay = 1.5,
            color = {0.6, 0.6, 0.7}
        })
    end

    -- Flying enemies
    local flyerPositions = {700, 1200, 1800, 2400}
    for _, xPos in ipairs(flyerPositions) do
        table.insert(self.enemies, {
            type = "flyer",
            x = xPos,
            y = 200,
            width = 24,
            height = 18,
            health = 1,
            vx = -80,
            baseY = 200,
            floatTimer = love.math.random() * math.pi * 2,
            color = {0.9, 0.5, 0.2}
        })
    end

    -- Boss at the end
    table.insert(self.enemies, {
        type = "boss",
        x = 3000,
        y = 380,
        width = 64,
        height = 80,
        health = 20,
        maxHealth = 20,
        phase = 1,
        shootTimer = 0,
        shootDelay = 0.8,
        moveTimer = 0,
        color = {0.7, 0.2, 0.5}
    })
end

function Contra:update(dt)
    if self.gameOver or self.victory then
        return
    end

    self:updatePlayer(dt)
    self:updateBullets(dt)
    self:updateEnemies(dt)
    self:updateParticles(dt)
    self:updateCamera()
    self:checkVictory()
end

function Contra:updatePlayer(dt)
    local p = self.player

    -- Invincibility timer
    if p.invincible then
        p.invincibleTimer = p.invincibleTimer - dt
        if p.invincibleTimer <= 0 then
            p.invincible = false
        end
    end

    -- Horizontal movement
    p.vx = 0
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        p.vx = -p.speed
        p.facing = -1
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        p.vx = p.speed
        p.facing = 1
    end

    -- Aiming
    p.aimAngle = 0
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        p.aimAngle = -1  -- Aim up
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        if not p.onGround then
            p.aimAngle = 1  -- Aim down (only in air)
        end
    end

    -- Jumping
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w") or love.keyboard.isDown("space")) and p.onGround then
        p.vy = p.jumpForce
        p.onGround = false
    end

    -- Gravity
    p.vy = p.vy + self.gravity * dt

    -- Apply velocity
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt

    -- Platform collision
    p.onGround = false
    for _, plat in ipairs(self.platforms) do
        if self:checkPlatformCollision(p, plat) then
            if p.vy > 0 then
                p.y = plat.y - p.height
                p.vy = 0
                p.onGround = true
            end
        end
    end

    -- Bounds
    p.x = clamp(p.x, 0, self.level.width - p.width)

    -- Fall death
    if p.y > self.level.height + 100 then
        self:playerHit()
        if not self.gameOver then
            p.x = math.max(100, self.camera.x + 100)
            p.y = 100
            p.vy = 0
        end
    end

    -- Shooting
    p.shootTimer = p.shootTimer - dt
    if love.keyboard.isDown("x") or love.keyboard.isDown("j") then
        if p.shootTimer <= 0 then
            self:playerShoot()
            p.shootTimer = p.shootDelay
        end
    end

    -- Animation
    if p.vx ~= 0 then
        p.animTimer = p.animTimer + dt
        if p.animTimer > 0.1 then
            p.animTimer = 0
            p.animFrame = p.animFrame % 4 + 1
        end
    else
        p.animFrame = 1
    end
end

function Contra:checkPlatformCollision(entity, plat)
    local ex, ey = entity.x, entity.y + entity.height - 10
    local ew, eh = entity.width, 20

    return ex < plat.x + plat.width and
           ex + ew > plat.x and
           ey < plat.y + plat.height and
           ey + eh > plat.y and
           entity.vy >= 0
end

function Contra:playerShoot()
    local p = self.player
    local bx = p.x + p.width / 2
    local by = p.y + p.height / 2 - 5

    local bvx, bvy = self.bulletSpeed * p.facing, 0

    if p.aimAngle == -1 then
        -- Aiming up
        if p.vx == 0 then
            bvx, bvy = 0, -self.bulletSpeed
        else
            bvx = self.bulletSpeed * p.facing * 0.7
            bvy = -self.bulletSpeed * 0.7
        end
    elseif p.aimAngle == 1 then
        -- Aiming down
        bvx = self.bulletSpeed * p.facing * 0.7
        bvy = self.bulletSpeed * 0.7
    end

    table.insert(self.bullets, {
        x = bx,
        y = by,
        vx = bvx,
        vy = bvy,
        width = 8,
        height = 4,
        isPlayer = true,
        color = {1, 1, 0.5}
    })
end

function Contra:updateBullets(dt)
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt

        -- Off screen
        if b.x < self.camera.x - 50 or b.x > self.camera.x + 900 or
           b.y < -50 or b.y > self.level.height + 50 then
            table.remove(self.bullets, i)
        -- Player bullets hitting enemies
        elseif b.isPlayer then
            for j, e in ipairs(self.enemies) do
                if self:checkCollision(b, e) then
                    e.health = e.health - 1
                    table.remove(self.bullets, i)
                    if e.health <= 0 then
                        self:spawnExplosion(e.x + e.width/2, e.y + e.height/2)
                        if e.type == "boss" then
                            self.score = self.score + 1000
                        else
                            self.score = self.score + 100
                        end
                        table.remove(self.enemies, j)
                    end
                    break
                end
            end
        -- Enemy bullets hitting player
        elseif not b.isPlayer then
            if self:checkCollision(b, self.player) and not self.player.invincible then
                self:playerHit()
                table.remove(self.bullets, i)
            end
        end
    end
end

function Contra:checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end

function Contra:playerHit()
    local p = self.player
    p.health = p.health - 1
    p.invincible = true
    p.invincibleTimer = 2.0

    self:spawnExplosion(p.x + p.width/2, p.y + p.height/2)

    if p.health <= 0 then
        self.gameOver = true
    end
end

function Contra:updateEnemies(dt)
    local p = self.player

    for _, e in ipairs(self.enemies) do
        if e.type == "soldier" then
            -- Face player
            if p.x < e.x then
                e.facing = -1
            else
                e.facing = 1
            end

            -- Shoot at player
            e.shootTimer = e.shootTimer - dt
            if e.shootTimer <= 0 and math.abs(e.x - p.x) < 500 then
                self:enemyShoot(e)
                e.shootTimer = e.shootDelay
            end

        elseif e.type == "turret" then
            e.shootTimer = e.shootTimer - dt
            if e.shootTimer <= 0 and math.abs(e.x - p.x) < 400 then
                self:enemyShoot(e)
                e.shootTimer = e.shootDelay
            end

        elseif e.type == "flyer" then
            e.x = e.x + e.vx * dt
            e.floatTimer = e.floatTimer + dt * 3
            e.y = e.baseY + math.sin(e.floatTimer) * 40

            -- Reverse at edges
            if e.x < 100 then e.vx = 80 end
            if e.x > self.level.width - 100 then e.vx = -80 end

        elseif e.type == "boss" then
            self:updateBoss(e, dt)
        end

        -- Enemy collision with player
        if self:checkCollision(e, p) and not p.invincible then
            self:playerHit()
        end
    end
end

function Contra:updateBoss(boss, dt)
    local p = self.player

    -- Movement
    boss.moveTimer = boss.moveTimer + dt
    boss.y = 350 + math.sin(boss.moveTimer) * 50

    -- Shooting based on health
    boss.shootTimer = boss.shootTimer - dt
    if boss.shootTimer <= 0 then
        -- Fire pattern
        local angle = math.atan2(p.y - boss.y, p.x - boss.x)
        for i = -1, 1 do
            local a = angle + i * 0.3
            table.insert(self.bullets, {
                x = boss.x,
                y = boss.y + boss.height/2,
                vx = math.cos(a) * 300,
                vy = math.sin(a) * 300,
                width = 10,
                height = 10,
                isPlayer = false,
                color = {1, 0.3, 0.5}
            })
        end
        boss.shootDelay = 0.5 + (boss.health / boss.maxHealth) * 0.5
        boss.shootTimer = boss.shootDelay
    end
end

function Contra:enemyShoot(e)
    local p = self.player
    local angle = math.atan2(p.y + p.height/2 - e.y, p.x + p.width/2 - e.x)

    table.insert(self.bullets, {
        x = e.x + e.width/2,
        y = e.y + e.height/2,
        vx = math.cos(angle) * 250,
        vy = math.sin(angle) * 250,
        width = 6,
        height = 6,
        isPlayer = false,
        color = {1, 0.4, 0.4}
    })
end

function Contra:spawnExplosion(x, y)
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * 150,
            vy = math.sin(angle) * 150,
            life = 0.5,
            maxLife = 0.5,
            size = 8,
            color = {1, 0.8, 0.3}
        })
    end
end

function Contra:updateParticles(dt)
    for i = #self.particles, 1, -1 do
        local part = self.particles[i]
        part.x = part.x + part.vx * dt
        part.y = part.y + part.vy * dt
        part.life = part.life - dt
        part.size = part.size * 0.95

        if part.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function Contra:updateCamera()
    local screenW = love.graphics.getWidth()
    local targetX = self.player.x - screenW / 3

    self.camera.x = clamp(targetX, 0, self.level.width - screenW)
end

function Contra:checkVictory()
    -- Check if boss is defeated
    local bossAlive = false
    for _, e in ipairs(self.enemies) do
        if e.type == "boss" then
            bossAlive = true
            break
        end
    end

    if not bossAlive and self.player.x > 2900 then
        self.victory = true
    end
end

function Contra:draw()
    local screenW, screenH = love.graphics.getDimensions()
    local time = love.timer.getTime()

    -- Background
    self:drawBackground()

    love.graphics.push()
    love.graphics.translate(-self.camera.x, 0)

    -- Platforms with detailed textures
    for _, plat in ipairs(self.platforms) do
        self:drawPlatform(plat)
    end

    -- Particles with glow effect
    for _, part in ipairs(self.particles) do
        local alpha = part.life / part.maxLife
        -- Outer glow
        setColor(part.color[1], part.color[2], part.color[3], alpha * 0.3)
        love.graphics.circle("fill", part.x, part.y, part.size * 1.5)
        -- Core
        setColor(part.color[1], part.color[2], part.color[3], alpha)
        love.graphics.circle("fill", part.x, part.y, part.size)
        -- Hot center
        setColor(1, 1, 0.9, alpha * 0.8)
        love.graphics.circle("fill", part.x, part.y, part.size * 0.4)
    end

    -- Enemies with detailed sprites
    for _, e in ipairs(self.enemies) do
        self:drawEnemy(e, time)
    end

    -- Bullets with trails
    for _, b in ipairs(self.bullets) do
        self:drawBullet(b, time)
    end

    -- Player with detailed sprite
    self:drawPlayer(time)

    love.graphics.pop()

    -- HUD
    self:drawHUD()

    -- Game over / Victory with enhanced styling
    if self.gameOver then
        setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
        -- Red glow effect
        setColor(0.8, 0.1, 0.1, 0.3)
        love.graphics.rectangle("fill", 0, screenH/2 - 80, screenW, 160)
        -- Text
        setColor(1, 0.3, 0.3, 1)
        love.graphics.printf("GAME OVER", 0, screenH/2 - 40, screenW, "center")
        setColor(0.8, 0.2, 0.2, 1)
        love.graphics.printf("GAME OVER", 2, screenH/2 - 38, screenW, "center")
        setColor(1, 1, 1, 1)
        love.graphics.printf("Press ESC to return", 0, screenH/2 + 30, screenW, "center")
    elseif self.victory then
        setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
        -- Green glow
        setColor(0.1, 0.6, 0.2, 0.3)
        love.graphics.rectangle("fill", 0, screenH/2 - 80, screenW, 160)
        -- Text
        setColor(0.3, 1, 0.5, 1)
        love.graphics.printf("VICTORY!", 0, screenH/2 - 40, screenW, "center")
        setColor(0.2, 0.8, 0.4, 1)
        love.graphics.printf("VICTORY!", 2, screenH/2 - 38, screenW, "center")
        setColor(1, 1, 0.6, 1)
        love.graphics.printf("Score: " .. self.score, 0, screenH/2 + 15, screenW, "center")
        setColor(1, 1, 1, 1)
        love.graphics.printf("Press ESC to return", 0, screenH/2 + 50, screenW, "center")
    end
end

function Contra:drawPlatform(plat)
    local x, y, w, h = plat.x, plat.y, plat.width, plat.height
    local pal = PALETTES.ground

    -- Main surface with texture
    if h > 50 then
        -- Large ground platforms - rock texture
        for py = 0, h - 1, 8 do
            for px = 0, w - 1, 8 do
                local noise = math.sin(px * 0.1 + py * 0.15) * 0.5 + 0.5
                local color
                if noise > 0.65 then
                    color = pal.rock[3]
                elseif noise < 0.35 then
                    color = pal.rock[2]
                else
                    color = pal.rock[1]
                end
                setColor(color[1], color[2], color[3], 1)
                love.graphics.rectangle("fill", x + px, y + py, 8, 8)
            end
        end

        -- Top edge with grass/moss detail
        for px = 0, w - 1, 4 do
            local grassHeight = 3 + math.sin(px * 0.2) * 2
            setColor(0.28, 0.45, 0.32, 1)
            love.graphics.rectangle("fill", x + px, y - grassHeight, 4, grassHeight + 2)
        end

        -- Edge highlight
        setColor(0.52, 0.45, 0.58, 0.8)
        love.graphics.rectangle("fill", x, y, w, 3)

    else
        -- Floating platforms - metal texture
        for py = 0, h - 1, 4 do
            for px = 0, w - 1, 4 do
                local shade = ((px + py) % 8 < 4) and pal.metal[1] or pal.metal[2]
                setColor(shade[1], shade[2], shade[3], 1)
                love.graphics.rectangle("fill", x + px, y + py, 4, 4)
            end
        end

        -- Top highlight
        setColor(pal.metal[3][1], pal.metal[3][2], pal.metal[3][3], 1)
        love.graphics.rectangle("fill", x, y, w, 2)

        -- Bottom shadow
        setColor(0.2, 0.18, 0.25, 0.8)
        love.graphics.rectangle("fill", x + 2, y + h, w - 4, 3)

        -- Edge rivets
        setColor(0.35, 0.32, 0.42, 1)
        for px = 8, w - 8, 16 do
            love.graphics.circle("fill", x + px, y + h/2, 2)
        end
    end
end

function Contra:drawEnemy(e, time)
    local pal

    if e.type == "boss" then
        self:drawBoss(e, time)
        return
    elseif e.type == "soldier" then
        pal = PALETTES.soldier

        -- Shadow
        setColor(0, 0, 0, 0.3)
        love.graphics.ellipse("fill", e.x + e.width/2, e.y + e.height + 2, e.width/2, 4)

        -- Legs (animated)
        local legAnim = math.sin(time * 8) * 3
        setColor(pal.body[2][1], pal.body[2][2], pal.body[2][3], 1)
        love.graphics.rectangle("fill", e.x + 2, e.y + 18 + legAnim, 6, 10)
        love.graphics.rectangle("fill", e.x + 12, e.y + 18 - legAnim, 6, 10)

        -- Body
        setColor(pal.body[1][1], pal.body[1][2], pal.body[1][3], 1)
        love.graphics.rectangle("fill", e.x + 2, e.y + 8, 16, 12)

        -- Highlight
        setColor(pal.body[3][1], pal.body[3][2], pal.body[3][3], 1)
        love.graphics.rectangle("fill", e.x + 2, e.y + 8, 16, 3)

        -- Head
        setColor(pal.skin[1][1], pal.skin[1][2], pal.skin[1][3], 1)
        love.graphics.circle("fill", e.x + 10, e.y + 5, 6)

        -- Helmet
        setColor(0.35, 0.35, 0.38, 1)
        love.graphics.arc("fill", e.x + 10, e.y + 4, 7, math.pi, 0)

        -- Gun
        setColor(0.28, 0.28, 0.32, 1)
        local gunX = e.facing == 1 and e.x + e.width or e.x - 10
        love.graphics.rectangle("fill", gunX, e.y + 12, 10, 4)
        setColor(0.45, 0.45, 0.50, 1)
        love.graphics.rectangle("fill", gunX + (e.facing == 1 and 0 or 6), e.y + 11, 4, 6)

    elseif e.type == "turret" then
        pal = PALETTES.turret

        -- Base
        setColor(pal.metal[2][1], pal.metal[2][2], pal.metal[2][3], 1)
        love.graphics.rectangle("fill", e.x, e.y + 10, e.width, 10)

        -- Turret body
        setColor(pal.metal[1][1], pal.metal[1][2], pal.metal[1][3], 1)
        love.graphics.arc("fill", e.x + e.width/2, e.y + 12, 12, math.pi, 0)

        -- Highlight
        setColor(pal.metal[3][1], pal.metal[3][2], pal.metal[3][3], 1)
        love.graphics.arc("fill", e.x + e.width/2, e.y + 10, 8, math.pi + 0.3, -0.3)

        -- Barrel
        local barrelAngle = math.atan2(self.player.y - e.y, self.player.x - e.x)
        love.graphics.push()
        love.graphics.translate(e.x + e.width/2, e.y + 8)
        love.graphics.rotate(clamp(barrelAngle, -0.8, 0.8))
        setColor(pal.accent[1][1], pal.accent[1][2], pal.accent[1][3], 1)
        love.graphics.rectangle("fill", 0, -3, 18, 6)
        setColor(pal.accent[2][1], pal.accent[2][2], pal.accent[2][3], 1)
        love.graphics.rectangle("fill", 0, -3, 18, 2)
        -- Muzzle
        setColor(0.25, 0.25, 0.28, 1)
        love.graphics.circle("fill", 18, 0, 4)
        love.graphics.pop()

        -- Warning light
        local blink = math.sin(time * 6) > 0 and 1 or 0.4
        setColor(0.95 * blink, 0.25, 0.25, 1)
        love.graphics.circle("fill", e.x + e.width/2, e.y + 4, 3)

    elseif e.type == "flyer" then
        pal = PALETTES.flyer

        -- Wings (animated)
        local wingFlap = math.sin(time * 15) * 0.3
        setColor(pal.wing[1][1], pal.wing[1][2], pal.wing[1][3], 1)
        love.graphics.polygon("fill",
            e.x + e.width/2, e.y + 8,
            e.x - 8, e.y + 4 + wingFlap * 10,
            e.x, e.y + 12)
        love.graphics.polygon("fill",
            e.x + e.width/2, e.y + 8,
            e.x + e.width + 8, e.y + 4 - wingFlap * 10,
            e.x + e.width, e.y + 12)

        -- Body
        setColor(pal.body[1][1], pal.body[1][2], pal.body[1][3], 1)
        love.graphics.ellipse("fill", e.x + e.width/2, e.y + e.height/2, e.width/2, e.height/2)

        -- Highlight
        setColor(pal.body[3][1], pal.body[3][2], pal.body[3][3], 1)
        love.graphics.ellipse("fill", e.x + e.width/2 - 2, e.y + e.height/2 - 3, 6, 4)

        -- Eye
        setColor(0.95, 0.85, 0.35, 1)
        love.graphics.circle("fill", e.x + e.width/2, e.y + e.height/2, 4)
        setColor(0.15, 0.15, 0.18, 1)
        love.graphics.circle("fill", e.x + e.width/2 + 1, e.y + e.height/2, 2)

        -- Engine glow
        local glow = 0.7 + math.sin(time * 10) * 0.3
        setColor(1, 0.6 * glow, 0.2, 0.8)
        love.graphics.circle("fill", e.x + e.width/2, e.y + e.height, 3)
    end
end

function Contra:drawBoss(e, time)
    local pal = PALETTES.boss
    local healthPct = e.health / e.maxHealth
    local pulse = math.sin(time * 4) * 0.1 + 0.9

    -- Shadow
    setColor(0, 0, 0, 0.4)
    love.graphics.ellipse("fill", e.x + e.width/2, e.y + e.height + 5, e.width/2, 10)

    -- Health bar background
    setColor(0.15, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", e.x - 15, e.y - 30, e.width + 30, 16)
    setColor(0.3, 0.3, 0.35, 1)
    love.graphics.rectangle("line", e.x - 15, e.y - 30, e.width + 30, 16)

    -- Health bar with gradient effect
    local barWidth = (e.width + 26) * healthPct
    for i = 0, barWidth, 2 do
        local t = i / (e.width + 26)
        local r = lerp(0.95, 0.75, t)
        local g = lerp(0.25, 0.15, t)
        local b = lerp(0.35, 0.45, t)
        setColor(r, g, b, 1)
        love.graphics.rectangle("fill", e.x - 13 + i, e.y - 28, 2, 12)
    end

    -- Boss label
    setColor(1, 0.9, 0.5, 1)
    love.graphics.print("OVERLORD", e.x + e.width/2 - 35, e.y - 48)

    -- Armor plates (back layer)
    setColor(pal.armor[1][1], pal.armor[1][2], pal.armor[1][3], 1)
    love.graphics.rectangle("fill", e.x - 8, e.y + 20, e.width + 16, e.height - 25)

    -- Main body
    setColor(pal.body[1][1] * pulse, pal.body[1][2] * pulse, pal.body[1][3] * pulse, 1)
    love.graphics.rectangle("fill", e.x, e.y + 10, e.width, e.height - 15)

    -- Body segments
    setColor(pal.body[2][1], pal.body[2][2], pal.body[2][3], 1)
    for i = 0, 3 do
        love.graphics.rectangle("fill", e.x + 5, e.y + 25 + i * 15, e.width - 10, 3)
    end

    -- Highlight strips
    setColor(pal.body[3][1], pal.body[3][2], pal.body[3][3], 1)
    love.graphics.rectangle("fill", e.x + 3, e.y + 10, 5, e.height - 20)

    -- Head/dome
    setColor(pal.armor[2][1], pal.armor[2][2], pal.armor[2][3], 1)
    love.graphics.arc("fill", e.x + e.width/2, e.y + 15, 25, math.pi, 0)
    setColor(pal.armor[1][1], pal.armor[1][2], pal.armor[1][3], 1)
    love.graphics.arc("fill", e.x + e.width/2, e.y + 12, 18, math.pi, 0)

    -- Eyes (animated)
    local eyeGlow = 0.8 + math.sin(time * 5) * 0.2
    local eyeOffset = math.sin(time * 2) * 3

    -- Left eye
    setColor(0.15, 0.08, 0.12, 1)
    love.graphics.circle("fill", e.x + 18, e.y + 30, 12)
    setColor(pal.eye[1][1] * eyeGlow, pal.eye[1][2] * eyeGlow, pal.eye[1][3] * eyeGlow, 1)
    love.graphics.circle("fill", e.x + 18, e.y + 30, 10)
    setColor(0.12, 0.05, 0.08, 1)
    love.graphics.circle("fill", e.x + 18 + eyeOffset, e.y + 30, 5)
    setColor(1, 0.9, 0.9, 0.9)
    love.graphics.circle("fill", e.x + 15, e.y + 27, 2)

    -- Right eye
    setColor(0.15, 0.08, 0.12, 1)
    love.graphics.circle("fill", e.x + 46, e.y + 30, 12)
    setColor(pal.eye[1][1] * eyeGlow, pal.eye[1][2] * eyeGlow, pal.eye[1][3] * eyeGlow, 1)
    love.graphics.circle("fill", e.x + 46, e.y + 30, 10)
    setColor(0.12, 0.05, 0.08, 1)
    love.graphics.circle("fill", e.x + 46 + eyeOffset, e.y + 30, 5)
    setColor(1, 0.9, 0.9, 0.9)
    love.graphics.circle("fill", e.x + 43, e.y + 27, 2)

    -- Cannons on sides
    for side = -1, 1, 2 do
        local cx = e.x + (side == -1 and -12 or e.width + 4)
        setColor(0.38, 0.35, 0.42, 1)
        love.graphics.rectangle("fill", cx, e.y + 45, 10, 25)
        setColor(0.28, 0.25, 0.32, 1)
        love.graphics.circle("fill", cx + 5, e.y + 70, 6)

        -- Cannon glow when shooting
        if e.shootTimer < 0.2 then
            setColor(1, 0.5, 0.6, 0.6)
            love.graphics.circle("fill", cx + 5, e.y + 72, 8)
        end
    end
end

function Contra:drawBullet(b, time)
    if b.isPlayer then
        -- Player bullet with energy trail
        local angle = math.atan2(b.vy, b.vx)

        -- Trail
        setColor(1, 0.9, 0.4, 0.3)
        love.graphics.push()
        love.graphics.translate(b.x, b.y)
        love.graphics.rotate(angle)
        love.graphics.ellipse("fill", -8, 0, 12, 3)
        love.graphics.pop()

        -- Core
        setColor(1, 1, 0.6, 1)
        love.graphics.ellipse("fill", b.x, b.y, b.width/2, b.height/2)

        -- Hot center
        setColor(1, 1, 0.95, 1)
        love.graphics.circle("fill", b.x, b.y, 2)
    else
        -- Enemy bullet with menacing glow
        -- Outer glow
        setColor(b.color[1], b.color[2], b.color[3], 0.4)
        love.graphics.circle("fill", b.x, b.y, b.width)

        -- Core
        setColor(b.color[1], b.color[2], b.color[3], 1)
        love.graphics.circle("fill", b.x, b.y, b.width/2)

        -- Inner bright spot
        setColor(1, 0.8, 0.8, 0.9)
        love.graphics.circle("fill", b.x - 1, b.y - 1, b.width/4)
    end
end

function Contra:drawPlayer(time)
    local p = self.player
    local pal = PALETTES.player

    if p.invincible and math.floor(time * 10) % 2 == 0 then
        return
    end

    local runAnim = p.vx ~= 0 and math.sin(time * 12) or 0

    -- Shadow
    setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", p.x + p.width/2, p.y + p.height + 2, 10, 4)

    -- Legs with animation
    setColor(pal.body[2][1], pal.body[2][2], pal.body[2][3], 1)
    local legOffset = runAnim * 4
    love.graphics.rectangle("fill", p.x + 4, p.y + 22 + legOffset, 6, 10)
    love.graphics.rectangle("fill", p.x + 14, p.y + 22 - legOffset, 6, 10)

    -- Boots
    setColor(0.25, 0.22, 0.28, 1)
    love.graphics.rectangle("fill", p.x + 3, p.y + 30 + legOffset, 8, 4)
    love.graphics.rectangle("fill", p.x + 13, p.y + 30 - legOffset, 8, 4)

    -- Body armor
    setColor(pal.body[1][1], pal.body[1][2], pal.body[1][3], 1)
    love.graphics.rectangle("fill", p.x + 2, p.y + 10, 20, 14)

    -- Armor highlight
    setColor(pal.body[3][1], pal.body[3][2], pal.body[3][3], 1)
    love.graphics.rectangle("fill", p.x + 2, p.y + 10, 20, 3)
    love.graphics.rectangle("fill", p.x + 2, p.y + 10, 3, 14)

    -- Belt
    setColor(0.55, 0.45, 0.32, 1)
    love.graphics.rectangle("fill", p.x + 2, p.y + 20, 20, 4)
    setColor(0.75, 0.65, 0.35, 1)
    love.graphics.rectangle("fill", p.x + 10, p.y + 20, 6, 4)

    -- Head
    setColor(pal.skin[1][1], pal.skin[1][2], pal.skin[1][3], 1)
    love.graphics.circle("fill", p.x + 12, p.y + 6, 7)

    -- Skin shadow
    setColor(pal.skin[2][1], pal.skin[2][2], pal.skin[2][3], 1)
    love.graphics.arc("fill", p.x + 12, p.y + 6, 7, 0, math.pi)

    -- Hair
    setColor(pal.hair[1][1], pal.hair[1][2], pal.hair[1][3], 1)
    love.graphics.arc("fill", p.x + 12, p.y + 4, 8, math.pi, 0)
    -- Hair spikes
    love.graphics.polygon("fill", p.x + 6, p.y + 2, p.x + 8, p.y - 3, p.x + 10, p.y + 2)
    love.graphics.polygon("fill", p.x + 12, p.y + 1, p.x + 14, p.y - 4, p.x + 16, p.y + 1)

    -- Eyes
    setColor(0.12, 0.12, 0.15, 1)
    love.graphics.circle("fill", p.x + 9, p.y + 5, 2)
    love.graphics.circle("fill", p.x + 15, p.y + 5, 2)
    setColor(1, 1, 1, 0.9)
    love.graphics.circle("fill", p.x + 9, p.y + 4, 1)
    love.graphics.circle("fill", p.x + 15, p.y + 4, 1)

    -- Gun arm
    local armY = p.y + 14
    local armAngle = 0
    if p.aimAngle == -1 then
        armAngle = p.vx == 0 and -math.pi/2 or -math.pi/4
    elseif p.aimAngle == 1 then
        armAngle = math.pi/4
    end

    love.graphics.push()
    love.graphics.translate(p.x + p.width/2, armY)
    love.graphics.rotate(armAngle * p.facing)

    -- Arm
    setColor(pal.skin[1][1], pal.skin[1][2], pal.skin[1][3], 1)
    love.graphics.rectangle("fill", 0, -2, 10 * p.facing, 5)

    -- Gun
    setColor(0.32, 0.32, 0.38, 1)
    love.graphics.rectangle("fill", 8 * p.facing, -4, 12 * p.facing, 8)
    setColor(0.45, 0.45, 0.52, 1)
    love.graphics.rectangle("fill", 8 * p.facing, -4, 12 * p.facing, 2)

    -- Muzzle flash when shooting
    if p.shootTimer > p.shootDelay - 0.05 then
        setColor(1, 0.9, 0.5, 0.8)
        love.graphics.circle("fill", 22 * p.facing, 0, 6)
        setColor(1, 1, 0.8, 1)
        love.graphics.circle("fill", 22 * p.facing, 0, 3)
    end

    love.graphics.pop()
end

function Contra:drawBackground()
    local screenW, screenH = love.graphics.getDimensions()
    local time = love.timer.getTime()

    -- Sky gradient with rich colors
    for y = 0, screenH, 2 do
        local t = y / screenH
        local r = lerp(0.08, 0.18, t)
        local g = lerp(0.02, 0.12, t)
        local b = lerp(0.18, 0.28, t)
        setColor(r, g, b, 1)
        love.graphics.rectangle("fill", 0, y, screenW, 2)
    end

    -- Distant stars
    for i = 1, 40 do
        local twinkle = math.sin(time * 2 + i * 0.7) * 0.3 + 0.7
        local sx = ((i * 137 + self.camera.x * 0.05) % screenW)
        local sy = (i * 53) % 250
        local size = (i % 3) + 1
        setColor(0.8, 0.7, 1, 0.4 * twinkle)
        love.graphics.circle("fill", sx, sy, size)
    end

    -- Nebula clouds (very back layer)
    local nebulaParallax = self.camera.x * 0.1
    setColor(0.35, 0.15, 0.45, 0.15)
    for i = 0, 3 do
        local nx = i * 400 - nebulaParallax % 400
        love.graphics.ellipse("fill", nx + 150, 120, 180, 80)
    end
    setColor(0.45, 0.25, 0.35, 0.12)
    for i = 0, 3 do
        local nx = i * 350 + 100 - nebulaParallax % 350
        love.graphics.ellipse("fill", nx + 120, 180, 140, 60)
    end

    -- Far mountains
    local parallax1 = self.camera.x * 0.2
    setColor(0.15, 0.12, 0.22, 1)
    for i = 0, 6 do
        local mx = i * 280 - parallax1 % 280
        local mh = 150 + (i % 3) * 50
        love.graphics.polygon("fill",
            mx, 450,
            mx + 100, 450 - mh,
            mx + 140, 450 - mh + 30,
            mx + 180, 450 - mh - 20,
            mx + 280, 450)
    end

    -- Near mountains with detail
    local parallax2 = self.camera.x * 0.35
    setColor(0.22, 0.18, 0.30, 1)
    for i = 0, 5 do
        local mx = i * 350 - parallax2 % 350
        love.graphics.polygon("fill",
            mx, 480,
            mx + 80, 320,
            mx + 150, 380,
            mx + 200, 280,
            mx + 280, 360,
            mx + 350, 480)
    end

    -- Mountain highlights
    setColor(0.32, 0.28, 0.42, 0.5)
    for i = 0, 5 do
        local mx = i * 350 - parallax2 % 350
        love.graphics.polygon("fill",
            mx + 80, 320,
            mx + 110, 320,
            mx + 150, 380)
        love.graphics.polygon("fill",
            mx + 200, 280,
            mx + 225, 280,
            mx + 280, 360)
    end

    -- Alien structures in distance
    local structParallax = self.camera.x * 0.25
    setColor(0.18, 0.15, 0.25, 0.8)
    for i = 0, 3 do
        local sx = i * 600 + 200 - structParallax % 600
        -- Tower
        love.graphics.rectangle("fill", sx, 350, 25, 130)
        love.graphics.rectangle("fill", sx - 15, 340, 55, 15)
        -- Window lights
        local windowGlow = math.sin(time * 2 + i) * 0.3 + 0.7
        setColor(0.85 * windowGlow, 0.45 * windowGlow, 0.55 * windowGlow, 0.9)
        for wy = 0, 4 do
            love.graphics.rectangle("fill", sx + 8, 360 + wy * 22, 10, 8)
        end
        setColor(0.18, 0.15, 0.25, 0.8)
    end

    -- Floating particles/embers
    setColor(0.95, 0.65, 0.45, 0.4)
    for i = 1, 15 do
        local px = ((i * 97 + time * 20 + self.camera.x * 0.3) % screenW)
        local py = (i * 41 + math.sin(time + i) * 30) % 400 + 100
        love.graphics.circle("fill", px, py, 1.5)
    end
end

function Contra:drawHUD()
    local screenW, screenH = love.graphics.getDimensions()

    -- Health panel with bevel effect
    setColor(0.12, 0.10, 0.18, 0.9)
    love.graphics.rectangle("fill", 8, 8, 160, 38)
    setColor(0.35, 0.30, 0.45, 1)
    love.graphics.rectangle("line", 8, 8, 160, 38)

    -- Inner bevel
    setColor(0.22, 0.18, 0.30, 1)
    love.graphics.rectangle("fill", 10, 10, 156, 2)
    love.graphics.rectangle("fill", 10, 10, 2, 34)

    setColor(0.08, 0.06, 0.12, 1)
    love.graphics.rectangle("fill", 10, 42, 156, 2)
    love.graphics.rectangle("fill", 164, 10, 2, 34)

    -- Life label
    setColor(0.85, 0.80, 0.95, 1)
    love.graphics.print("LIFE", 18, 14)

    -- Health hearts/bars
    for i = 1, self.player.maxHealth do
        local hx = 58 + (i-1) * 34
        if i <= self.player.health then
            -- Full heart
            setColor(0.85, 0.25, 0.30, 1)
            love.graphics.rectangle("fill", hx, 14, 28, 24)
            setColor(0.95, 0.35, 0.40, 1)
            love.graphics.rectangle("fill", hx, 14, 28, 6)
            -- Heart icon
            setColor(1, 0.5, 0.55, 1)
            love.graphics.circle("fill", hx + 9, 22, 5)
            love.graphics.circle("fill", hx + 19, 22, 5)
            love.graphics.polygon("fill", hx + 4, 24, hx + 14, 35, hx + 24, 24)
        else
            -- Empty heart
            setColor(0.25, 0.22, 0.30, 1)
            love.graphics.rectangle("fill", hx, 14, 28, 24)
            setColor(0.35, 0.30, 0.40, 0.5)
            love.graphics.rectangle("line", hx + 2, 16, 24, 20)
        end
    end

    -- Score panel
    setColor(0.12, 0.10, 0.18, 0.9)
    love.graphics.rectangle("fill", screenW - 175, 8, 167, 38)
    setColor(0.35, 0.30, 0.45, 1)
    love.graphics.rectangle("line", screenW - 175, 8, 167, 38)

    -- Score text with glow
    setColor(1, 0.9, 0.4, 0.3)
    love.graphics.printf("SCORE", screenW - 168, 11, 155, "left")
    setColor(1, 0.95, 0.5, 1)
    love.graphics.printf("SCORE", screenW - 170, 12, 155, "left")

    -- Score value
    local scoreStr = string.format("%08d", self.score)
    setColor(1, 1, 0.85, 1)
    love.graphics.printf(scoreStr, screenW - 170, 26, 155, "right")

    -- Controls hint with subtle styling
    setColor(0.12, 0.10, 0.18, 0.7)
    love.graphics.rectangle("fill", 8, screenH - 28, 500, 22)
    setColor(0.75, 0.70, 0.85, 0.9)
    love.graphics.print("WASD: Move/Aim  |  SPACE: Jump  |  X/J: Shoot  |  ESC: Exit", 15, screenH - 24)
end

function Contra:keypressed(key)
    if key == "escape" then
        Gamestate:pop()
    end

    -- Restart on game over
    if self.gameOver and key == "r" then
        self:load()
        self:enter()
    end
end

return Contra
