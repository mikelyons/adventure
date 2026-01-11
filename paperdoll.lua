-- Paperdoll Character System
-- Enhanced layered sprite system for customizable characters
-- High-fidelity retro style with detailed pixel art

local Paperdoll = {}
local Utils = require("utils")
local Palettes = require("data.palettes")

-- Character dimensions
Paperdoll.width = 16
Paperdoll.height = 24
Paperdoll.scale = 2.5

-- Import character palettes from centralized location
Paperdoll.skinTones = Palettes.character.skinTones
Paperdoll.hairColors = Palettes.character.hairColors
Paperdoll.clothingColors = Palettes.character.clothingColors

-- Helper function aliases from Utils module
local setPixel = Utils.setPixel
local lerp = Utils.lerp
local lerpColor = Utils.lerpColor
local shouldDither = Utils.shouldDither

-- Create a blank transparent layer
function Paperdoll:createBlankLayer()
    local data = love.image.newImageData(self.width, self.height)
    for y = 0, self.height - 1 do
        for x = 0, self.width - 1 do
            data:setPixel(x, y, 0, 0, 0, 0)
        end
    end
    return data
end

-- BASE BODY LAYER --
function Paperdoll:createBody(skinTone)
    local palette = self.skinTones[skinTone] or self.skinTones.medium
    local base, shadow, highlight, dark = palette[1], palette[2], palette[3], palette[4]
    local data = self:createBlankLayer()

    -- Head shape (more defined oval with better shading)
    -- Row 1 - top of head
    for x = 6, 9 do
        local color = x < 8 and lerpColor(base, shadow, 0.3) or lerpColor(base, highlight, 0.2)
        setPixel(data, x, 1, color)
    end
    -- Row 2-3 - upper head
    for y = 2, 3 do
        for x = 5, 10 do
            local shade = (x - 5) / 5
            local color = lerpColor(shadow, highlight, shade * 0.8)
            setPixel(data, x, y, color)
        end
    end
    -- Row 4-5 - eye area (cheekbones)
    for y = 4, 5 do
        for x = 5, 10 do
            local shade = (x - 5) / 5
            local color = lerpColor(shadow, base, shade * 0.7 + 0.3)
            setPixel(data, x, y, color)
        end
    end
    -- Row 6 - lower face/jaw
    for x = 6, 9 do
        local shade = (x - 6) / 3
        local color = lerpColor(shadow, base, shade * 0.6 + 0.4)
        setPixel(data, x, 6, color)
    end
    -- Row 7 - chin
    setPixel(data, 7, 7, lerpColor(base, shadow, 0.2))
    setPixel(data, 8, 7, base)

    -- Neck (more defined)
    setPixel(data, 7, 8, shadow)
    setPixel(data, 8, 8, base)

    -- Torso (base for clothing)
    for y = 9, 15 do
        for x = 5, 10 do
            local shade = (x - 5) / 5
            local vshade = (y - 9) / 6
            local color = lerpColor(shadow, base, shade * 0.6 + vshade * 0.2)
            setPixel(data, x, y, color)
        end
    end

    -- Arms with better shaping
    for y = 10, 14 do
        local armShade = (y - 10) / 4
        setPixel(data, 4, y, lerpColor(shadow, dark, armShade * 0.3))
        setPixel(data, 11, y, lerpColor(base, highlight, (1 - armShade) * 0.2))
    end

    -- Hands (more defined)
    setPixel(data, 3, 14, dark)
    setPixel(data, 4, 14, shadow)
    setPixel(data, 4, 15, lerpColor(shadow, base, 0.5))
    setPixel(data, 11, 14, base)
    setPixel(data, 12, 14, lerpColor(base, highlight, 0.3))
    setPixel(data, 11, 15, lerpColor(base, highlight, 0.2))

    -- Legs (base for pants)
    for y = 16, 21 do
        -- Left leg
        setPixel(data, 6, y, dark)
        setPixel(data, 7, y, shadow)
        -- Right leg
        setPixel(data, 8, y, base)
        setPixel(data, 9, y, lerpColor(base, highlight, 0.2))
    end

    -- Feet
    for x = 5, 7 do setPixel(data, x, 22, shadow) end
    for x = 8, 10 do setPixel(data, x, 22, base) end
    setPixel(data, 5, 22, dark)
    setPixel(data, 10, 22, lerpColor(base, highlight, 0.3))

    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    return img
end

-- FACE FEATURES LAYER --
function Paperdoll:createFace(eyeColor, skinTone)
    local data = self:createBlankLayer()
    local color = eyeColor or {0.25, 0.38, 0.58}
    local skinPalette = self.skinTones[skinTone] or self.skinTones.medium
    local lipColor = lerpColor(skinPalette[1], {0.85, 0.45, 0.45}, 0.35)

    -- Eyebrows
    local browColor = {0.25, 0.20, 0.18}
    setPixel(data, 5, 3, browColor)
    setPixel(data, 6, 3, browColor)
    setPixel(data, 9, 3, browColor)
    setPixel(data, 10, 3, browColor)

    -- Eye whites
    setPixel(data, 5, 4, {0.98, 0.98, 1.0})
    setPixel(data, 6, 4, {0.95, 0.95, 0.98})
    setPixel(data, 9, 4, {0.95, 0.95, 0.98})
    setPixel(data, 10, 4, {0.98, 0.98, 1.0})

    -- Irises
    setPixel(data, 6, 4, color)
    setPixel(data, 9, 4, color)

    -- Pupils
    local pupil = {0.08, 0.08, 0.12}
    setPixel(data, 6, 4, lerpColor(color, pupil, 0.6))
    setPixel(data, 9, 4, lerpColor(color, pupil, 0.6))

    -- Eye shine
    setPixel(data, 5, 4, {0.98, 0.98, 1.0})
    setPixel(data, 10, 4, {0.98, 0.98, 1.0})

    -- Nose highlight
    setPixel(data, 8, 5, lerpColor(skinPalette[1], skinPalette[3], 0.4))

    -- Mouth
    setPixel(data, 7, 6, lipColor)
    setPixel(data, 8, 6, lipColor)

    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    return img
end

-- HAIR STYLES --
function Paperdoll:createHair(style, colorName)
    local palette = self.hairColors[colorName] or self.hairColors.brown
    local base, shadow, highlight = palette[1], palette[2], palette[3]
    local data = self:createBlankLayer()

    if style == "short" then
        -- Short textured hair with volume
        for x = 5, 10 do
            setPixel(data, x, 0, shouldDither(x, 0, 0.5) and highlight or base)
        end
        for x = 4, 11 do
            setPixel(data, x, 1, shouldDither(x, 1, 0.3) and base or shadow)
        end
        for x = 4, 11 do
            local color = x < 7 and shadow or (x > 9 and base or highlight)
            if shouldDither(x, 2, 0.4) then color = lerpColor(color, highlight, 0.3) end
            setPixel(data, x, 2, color)
        end
        -- Sides
        setPixel(data, 4, 3, shadow)
        setPixel(data, 11, 3, base)
        -- Texture spikes
        setPixel(data, 5, 0, highlight)
        setPixel(data, 8, 0, highlight)
        setPixel(data, 10, 0, base)

    elseif style == "long" then
        -- Long flowing hair with layers
        -- Top
        for x = 4, 11 do
            setPixel(data, x, 0, shouldDither(x, 0, 0.4) and highlight or base)
        end
        for x = 3, 12 do
            local color = x < 7 and shadow or base
            if shouldDither(x, 1, 0.35) then color = lerpColor(color, highlight, 0.4) end
            setPixel(data, x, 1, color)
        end
        for x = 3, 12 do
            setPixel(data, x, 2, shouldDither(x, 2, 0.3) and base or shadow)
        end
        -- Side hair flowing down
        for y = 3, 14 do
            local waveOffset = math.sin(y * 0.8) * 0.3
            -- Left side
            setPixel(data, 3, y, shadow)
            setPixel(data, 4, y, shouldDither(4, y, 0.4 + waveOffset) and base or shadow)
            -- Right side
            setPixel(data, 11, y, shouldDither(11, y, 0.5 + waveOffset) and highlight or base)
            setPixel(data, 12, y, base)
        end
        -- Hair ends (tapered)
        for y = 12, 14 do
            if y == 14 then
                setPixel(data, 4, y, shadow)
                setPixel(data, 11, y, base)
            end
        end

    elseif style == "ponytail" then
        -- Sleek top with ponytail
        for x = 5, 10 do
            setPixel(data, x, 0, x < 8 and shadow or base)
            setPixel(data, x, 1, shouldDither(x, 1, 0.35) and highlight or base)
        end
        setPixel(data, 4, 1, shadow)
        setPixel(data, 11, 1, base)
        setPixel(data, 4, 2, shadow)
        setPixel(data, 11, 2, base)
        -- Ponytail tie
        setPixel(data, 12, 3, {0.3, 0.3, 0.35})
        -- Ponytail flowing
        for y = 2, 12 do
            local waveX = math.sin(y * 0.6) * 0.5
            setPixel(data, 12, y, shouldDither(12, y, 0.4 + waveX) and highlight or base)
            setPixel(data, 13, y, shouldDither(13, y, 0.3 + waveX) and base or shadow)
            if y > 8 then
                setPixel(data, 14, y, shadow)
            end
        end

    elseif style == "mohawk" then
        -- Punk mohawk with height
        -- Center spikes
        for y = 0, 3 do
            local spikeWidth = 3 - y
            for x = 7 - spikeWidth, 8 + spikeWidth do
                local color = shouldDither(x, y, 0.5) and highlight or base
                setPixel(data, x, y, color)
            end
        end
        -- Shaved sides (skin showing through)
        setPixel(data, 5, 2, shadow)
        setPixel(data, 10, 2, shadow)

    elseif style == "curly" then
        -- Voluminous curly hair
        for y = 0, 4 do
            for x = 3, 12 do
                -- Create curly pattern with noise
                local curl = (math.sin(x * 2 + y) + math.cos(y * 3 - x)) * 0.5
                if y < 4 or (x > 4 and x < 11) then
                    local color
                    if curl > 0.3 then
                        color = highlight
                    elseif curl > -0.2 then
                        color = base
                    else
                        color = shadow
                    end
                    setPixel(data, x, y, color)
                end
            end
        end
        -- Side volume
        for y = 3, 6 do
            setPixel(data, 3, y, shouldDither(3, y, 0.4) and base or shadow)
            setPixel(data, 12, y, shouldDither(12, y, 0.5) and highlight or base)
        end

    elseif style == "braided" then
        -- Braided style
        for x = 5, 10 do
            setPixel(data, x, 0, base)
            setPixel(data, x, 1, shouldDither(x, 1, 0.4) and highlight or shadow)
        end
        setPixel(data, 4, 1, shadow)
        setPixel(data, 11, 1, shadow)
        -- Braids on sides
        for y = 2, 12 do
            local braidPattern = (y % 3)
            if braidPattern == 0 then
                setPixel(data, 4, y, highlight)
                setPixel(data, 11, y, highlight)
            elseif braidPattern == 1 then
                setPixel(data, 3, y, base)
                setPixel(data, 4, y, shadow)
                setPixel(data, 11, y, shadow)
                setPixel(data, 12, y, base)
            else
                setPixel(data, 4, y, base)
                setPixel(data, 11, y, base)
            end
        end

    elseif style == "bald" then
        -- Clean bald head (no pixels needed)
    end

    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    return img
end

-- SHIRT/TOP STYLES --
function Paperdoll:createShirt(style, colorName)
    local palette = self.clothingColors[colorName] or self.clothingColors.blue
    local base, shadow, highlight, accent = palette[1], palette[2], palette[3], palette[4]
    local data = self:createBlankLayer()

    if style == "tshirt" then
        -- Detailed t-shirt with folds
        -- Collar
        setPixel(data, 7, 8, accent)
        setPixel(data, 8, 8, accent)
        -- Main body with shading
        for y = 9, 15 do
            for x = 5, 10 do
                local shade = (x - 5) / 5
                local vshade = math.abs(y - 12) / 6
                local color = lerpColor(shadow, base, shade * 0.7 + 0.3)
                -- Add fabric fold highlights
                if x == 7 or x == 8 then
                    color = lerpColor(color, highlight, vshade * 0.4)
                end
                setPixel(data, x, y, color)
            end
        end
        -- Sleeve edges
        for y = 10, 12 do
            setPixel(data, 4, y, shadow)
            setPixel(data, 11, y, base)
        end
        -- Hem
        for x = 5, 10 do
            setPixel(data, x, 15, lerpColor(base, shadow, 0.3))
        end

    elseif style == "tanktop" then
        -- Athletic tank top
        for y = 9, 15 do
            for x = 6, 9 do
                local shade = (x - 6) / 3
                local color = lerpColor(shadow, base, shade * 0.8)
                setPixel(data, x, y, color)
            end
        end
        -- Straps with detail
        setPixel(data, 6, 8, shadow)
        setPixel(data, 9, 8, base)
        setPixel(data, 6, 7, accent)
        setPixel(data, 9, 7, accent)
        -- Armhole shading
        setPixel(data, 5, 10, accent)
        setPixel(data, 10, 10, lerpColor(base, highlight, 0.3))

    elseif style == "longsleeve" then
        -- Long sleeve with cuffs
        -- Collar
        setPixel(data, 7, 8, accent)
        setPixel(data, 8, 8, accent)
        for y = 9, 15 do
            for x = 5, 10 do
                local shade = (x - 5) / 5
                local color = lerpColor(shadow, base, shade * 0.7 + 0.3)
                setPixel(data, x, y, color)
            end
        end
        -- Full sleeves with fold detail
        for y = 10, 14 do
            local sleeveShade = math.abs(y - 12) / 4
            setPixel(data, 4, y, lerpColor(shadow, base, sleeveShade * 0.4))
            setPixel(data, 3, y, shadow)
            setPixel(data, 11, y, lerpColor(base, highlight, sleeveShade * 0.3))
            setPixel(data, 12, y, base)
        end
        -- Cuffs
        setPixel(data, 3, 14, accent)
        setPixel(data, 4, 14, accent)
        setPixel(data, 11, 14, accent)
        setPixel(data, 12, 14, accent)

    elseif style == "jacket" then
        -- Layered jacket with detail
        for y = 9, 15 do
            for x = 3, 12 do
                local shade = (x - 3) / 9
                local color
                if x == 3 or x == 12 then
                    color = accent
                elseif x < 7 then
                    color = shadow
                elseif x > 9 then
                    color = lerpColor(base, highlight, 0.2)
                else
                    color = base
                end
                setPixel(data, x, y, color)
            end
        end
        -- Center seam/zipper
        for y = 9, 15 do
            setPixel(data, 7, y, accent)
            setPixel(data, 8, y, lerpColor(accent, shadow, 0.3))
        end
        -- Collar
        setPixel(data, 6, 8, base)
        setPixel(data, 9, 8, base)
        setPixel(data, 5, 9, shadow)
        setPixel(data, 10, 9, base)
        -- Pockets
        setPixel(data, 4, 13, accent)
        setPixel(data, 5, 13, accent)
        setPixel(data, 10, 13, accent)
        setPixel(data, 11, 13, accent)

    elseif style == "dress" then
        -- Elegant dress with flow
        -- Bodice
        for y = 9, 14 do
            for x = 5, 10 do
                local shade = (x - 5) / 5
                local color = lerpColor(shadow, base, shade * 0.6 + 0.4)
                if y == 9 then
                    color = lerpColor(color, highlight, 0.3)
                end
                setPixel(data, x, y, color)
            end
        end
        -- Skirt with flare
        for y = 15, 20 do
            local flare = 1 + (y - 15) * 0.5
            local startX = math.floor(7 - flare)
            local endX = math.ceil(8 + flare)
            for x = startX, endX do
                local shade = (x - startX) / (endX - startX)
                local color = lerpColor(shadow, base, shade * 0.7 + 0.3)
                -- Add fold highlights
                if shouldDither(x, y, 0.35) then
                    color = lerpColor(color, highlight, 0.4)
                end
                setPixel(data, x, y, color)
            end
        end
        -- Waist accent
        for x = 5, 10 do
            setPixel(data, x, 14, accent)
        end

    elseif style == "tunic" then
        -- Medieval-style tunic
        for y = 9, 17 do
            for x = 5, 10 do
                local shade = (x - 5) / 5
                local color = lerpColor(shadow, base, shade * 0.6 + 0.4)
                setPixel(data, x, y, color)
            end
        end
        -- V-neck
        setPixel(data, 7, 9, accent)
        setPixel(data, 8, 9, accent)
        setPixel(data, 7, 10, shadow)
        setPixel(data, 8, 10, shadow)
        -- Belt
        for x = 5, 10 do
            setPixel(data, x, 14, accent)
        end
        setPixel(data, 7, 14, {0.8, 0.7, 0.2}) -- Belt buckle
        -- Sleeves
        for y = 10, 13 do
            setPixel(data, 4, y, shadow)
            setPixel(data, 11, y, base)
        end
    end

    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    return img
end

-- PANTS/BOTTOM STYLES --
function Paperdoll:createPants(style, colorName)
    local palette = self.clothingColors[colorName] or self.clothingColors.blue
    local base, shadow, highlight, accent = palette[1], palette[2], palette[3], palette[4]
    local data = self:createBlankLayer()

    if style == "pants" then
        -- Detailed trousers with seams
        -- Waistband
        for x = 5, 10 do
            setPixel(data, x, 15, accent)
        end
        -- Legs with shading
        for y = 16, 21 do
            -- Left leg
            setPixel(data, 5, y, accent) -- outer seam
            setPixel(data, 6, y, shadow)
            setPixel(data, 7, y, lerpColor(shadow, base, 0.5))
            -- Right leg
            setPixel(data, 8, y, lerpColor(base, shadow, 0.3))
            setPixel(data, 9, y, base)
            setPixel(data, 10, y, accent) -- outer seam
        end
        -- Knee highlights
        setPixel(data, 6, 18, lerpColor(shadow, base, 0.4))
        setPixel(data, 9, 18, lerpColor(base, highlight, 0.3))
        -- Cuffs
        for x = 5, 7 do setPixel(data, x, 21, lerpColor(shadow, accent, 0.5)) end
        for x = 8, 10 do setPixel(data, x, 21, lerpColor(base, accent, 0.5)) end

    elseif style == "shorts" then
        -- Athletic shorts
        for x = 5, 10 do
            setPixel(data, x, 15, accent)
        end
        for y = 16, 18 do
            for x = 5, 10 do
                local shade = (x - 5) / 5
                local color = lerpColor(shadow, base, shade * 0.7 + 0.3)
                setPixel(data, x, y, color)
            end
        end
        -- Hem
        for x = 5, 10 do
            setPixel(data, x, 18, lerpColor(base, highlight, 0.2))
        end

    elseif style == "skirt" then
        -- Pleated skirt
        for y = 15, 19 do
            local flare = (y - 15) * 0.6
            local startX = math.floor(6 - flare)
            local endX = math.ceil(9 + flare)
            for x = startX, endX do
                -- Create pleats
                local pleatPhase = (x + y) % 3
                local color
                if pleatPhase == 0 then
                    color = shadow
                elseif pleatPhase == 1 then
                    color = base
                else
                    color = highlight
                end
                setPixel(data, x, y, color)
            end
        end
        -- Waistband
        for x = 5, 10 do
            setPixel(data, x, 15, accent)
        end

    elseif style == "longskirt" then
        -- Floor-length skirt
        for y = 15, 21 do
            local flare = (y - 15) * 0.5
            local startX = math.floor(6 - flare)
            local endX = math.ceil(9 + flare)
            for x = startX, endX do
                local shade = (x - startX) / (endX - startX)
                local color = lerpColor(shadow, base, shade * 0.6 + 0.4)
                if shouldDither(x, y, 0.4) then
                    color = lerpColor(color, highlight, 0.3)
                end
                setPixel(data, x, y, color)
            end
        end
        for x = 5, 10 do setPixel(data, x, 15, accent) end

    elseif style == "none" then
        -- No pants (for dress)
    end

    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    return img
end

-- SHOES STYLES --
function Paperdoll:createShoes(style, colorName)
    local palette = self.clothingColors[colorName] or self.clothingColors.brown
    local base, shadow, highlight, accent = palette[1], palette[2], palette[3], palette[4]
    local data = self:createBlankLayer()

    if style == "boots" then
        -- Detailed boots with laces
        for y = 19, 21 do
            setPixel(data, 5, y, accent)
            setPixel(data, 6, y, shadow)
            setPixel(data, 7, y, lerpColor(shadow, base, 0.5))
            setPixel(data, 8, y, lerpColor(base, shadow, 0.3))
            setPixel(data, 9, y, base)
            setPixel(data, 10, y, accent)
        end
        -- Boot sole
        for x = 4, 7 do setPixel(data, x, 22, shadow) end
        for x = 8, 11 do setPixel(data, x, 22, base) end
        setPixel(data, 4, 22, accent)
        setPixel(data, 11, 22, lerpColor(base, highlight, 0.3))
        -- Sole bottom
        for x = 4, 11 do setPixel(data, x, 23, accent) end
        -- Boot top trim
        for x = 5, 10 do setPixel(data, x, 19, lerpColor(base, highlight, 0.2)) end
        -- Laces detail
        setPixel(data, 6, 20, highlight)
        setPixel(data, 9, 20, highlight)

    elseif style == "sneakers" then
        -- Modern sneakers with detail
        -- Upper
        setPixel(data, 5, 21, shadow)
        setPixel(data, 6, 21, base)
        setPixel(data, 7, 21, base)
        setPixel(data, 8, 21, base)
        setPixel(data, 9, 21, base)
        setPixel(data, 10, 21, lerpColor(base, highlight, 0.3))
        -- Toe box
        for x = 4, 7 do setPixel(data, x, 22, base) end
        for x = 8, 11 do setPixel(data, x, 22, base) end
        -- White sole
        for x = 4, 11 do setPixel(data, x, 23, {0.95, 0.95, 0.95}) end
        -- Accent stripe
        setPixel(data, 5, 22, accent)
        setPixel(data, 10, 22, accent)
        -- Laces
        setPixel(data, 6, 21, highlight)
        setPixel(data, 9, 21, highlight)

    elseif style == "sandals" then
        -- Strappy sandals
        -- Sole
        for x = 5, 7 do setPixel(data, x, 22, shadow) end
        for x = 8, 10 do setPixel(data, x, 22, base) end
        -- Straps
        setPixel(data, 5, 21, accent)
        setPixel(data, 7, 21, accent)
        setPixel(data, 8, 21, accent)
        setPixel(data, 10, 21, accent)
        -- Ankle strap
        setPixel(data, 5, 20, shadow)
        setPixel(data, 10, 20, base)

    elseif style == "heels" then
        -- High heels
        -- Shoe upper
        for x = 5, 7 do setPixel(data, x, 21, shadow) end
        for x = 8, 10 do setPixel(data, x, 21, base) end
        -- Toe
        setPixel(data, 4, 22, shadow)
        setPixel(data, 5, 22, base)
        setPixel(data, 10, 22, base)
        setPixel(data, 11, 22, lerpColor(base, highlight, 0.3))
        -- Heel
        setPixel(data, 5, 23, accent)
        setPixel(data, 10, 23, accent)

    elseif style == "barefoot" then
        -- No shoes
    end

    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    return img
end

-- HAT/ACCESSORY STYLES --
function Paperdoll:createHat(style, colorName)
    local palette = self.clothingColors[colorName] or self.clothingColors.red
    local base, shadow, highlight, accent = palette[1], palette[2], palette[3], palette[4]
    local data = self:createBlankLayer()

    if style == "cap" then
        -- Baseball cap with detail
        for x = 4, 11 do
            setPixel(data, x, 0, x < 7 and shadow or (x > 9 and highlight or base))
        end
        for x = 4, 11 do
            setPixel(data, x, 1, x < 7 and shadow or base)
        end
        -- Brim with shading
        for x = 2, 8 do
            local shade = (x - 2) / 6
            setPixel(data, x, 2, lerpColor(accent, shadow, shade * 0.5))
        end
        -- Button on top
        setPixel(data, 7, 0, highlight)
        setPixel(data, 8, 0, highlight)

    elseif style == "beanie" then
        -- Knit beanie with ribbing
        for x = 4, 11 do
            local ribPattern = x % 2 == 0
            setPixel(data, x, 0, ribPattern and highlight or base)
            setPixel(data, x, 1, ribPattern and base or shadow)
        end
        setPixel(data, 3, 1, shadow)
        setPixel(data, 12, 1, base)
        -- Pom pom
        setPixel(data, 7, 0, highlight)
        setPixel(data, 8, 0, highlight)

    elseif style == "wizardhat" then
        -- Wizard hat with stars
        -- Point
        setPixel(data, 7, 0, shadow)
        setPixel(data, 8, 0, base)
        -- Cone
        for x = 6, 9 do
            setPixel(data, x, 1, x < 8 and shadow or base)
        end
        for x = 5, 10 do
            setPixel(data, x, 2, x < 8 and shadow or base)
        end
        -- Brim
        for x = 2, 13 do
            setPixel(data, x, 3, x < 7 and accent or (x > 9 and highlight or base))
        end
        -- Star decorations
        setPixel(data, 6, 1, {0.95, 0.90, 0.40})
        setPixel(data, 9, 2, {0.95, 0.90, 0.40})

    elseif style == "crown" then
        -- Royal crown with gems
        -- Crown points
        local gold = {0.95, 0.85, 0.30}
        local goldShadow = {0.75, 0.65, 0.20}
        local goldHighlight = {1.0, 0.95, 0.50}

        setPixel(data, 5, 0, gold)
        setPixel(data, 7, 0, goldHighlight)
        setPixel(data, 8, 0, goldHighlight)
        setPixel(data, 10, 0, gold)
        -- Crown band
        for x = 4, 11 do
            local shade = (x - 4) / 7
            setPixel(data, x, 1, lerpColor(goldShadow, gold, shade))
            setPixel(data, x, 2, lerpColor(goldShadow, goldHighlight, shade * 0.6))
        end
        -- Gems
        setPixel(data, 5, 1, {0.9, 0.2, 0.2})  -- Ruby
        setPixel(data, 7, 1, {0.2, 0.8, 0.3})  -- Emerald
        setPixel(data, 9, 1, {0.2, 0.4, 0.9})  -- Sapphire

    elseif style == "bandana" then
        -- Tied bandana
        for x = 4, 11 do
            setPixel(data, x, 1, x < 8 and shadow or base)
        end
        setPixel(data, 3, 2, base)
        setPixel(data, 12, 2, base)
        -- Knot at back
        setPixel(data, 12, 3, shadow)
        setPixel(data, 13, 3, base)
        setPixel(data, 13, 4, shadow)
        -- Pattern dots
        setPixel(data, 5, 1, highlight)
        setPixel(data, 8, 1, highlight)
        setPixel(data, 10, 1, highlight)

    elseif style == "none" then
        -- No hat
    end

    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    return img
end

-- CHARACTER CLASS --
Paperdoll.Character = {}
Paperdoll.Character.__index = Paperdoll.Character

function Paperdoll:newCharacter(config)
    local char = setmetatable({}, self.Character)

    config = config or {}

    char.skinTone = config.skinTone or "medium"
    char.eyeColor = config.eyeColor or {0.28, 0.42, 0.62}
    char.hairStyle = config.hairStyle or "short"
    char.hairColor = config.hairColor or "brown"
    char.shirtStyle = config.shirtStyle or "tshirt"
    char.shirtColor = config.shirtColor or "blue"
    char.pantsStyle = config.pantsStyle or "pants"
    char.pantsColor = config.pantsColor or "brown"
    char.shoesStyle = config.shoesStyle or "sneakers"
    char.shoesColor = config.shoesColor or "black"
    char.hatStyle = config.hatStyle or "none"
    char.hatColor = config.hatColor or "red"

    char.layers = {}
    char:rebuildLayers()

    return char
end

function Paperdoll.Character:rebuildLayers()
    self.layers = {
        body = Paperdoll:createBody(self.skinTone),
        face = Paperdoll:createFace(self.eyeColor, self.skinTone),
        pants = Paperdoll:createPants(self.pantsStyle, self.pantsColor),
        shirt = Paperdoll:createShirt(self.shirtStyle, self.shirtColor),
        shoes = Paperdoll:createShoes(self.shoesStyle, self.shoesColor),
        hair = Paperdoll:createHair(self.hairStyle, self.hairColor),
        hat = Paperdoll:createHat(self.hatStyle, self.hatColor),
    }
end

function Paperdoll.Character:setAppearance(part, style, color)
    if part == "skin" then
        self.skinTone = style
    elseif part == "eyes" then
        self.eyeColor = style
    elseif part == "hair" then
        self.hairStyle = style
        if color then self.hairColor = color end
    elseif part == "shirt" then
        self.shirtStyle = style
        if color then self.shirtColor = color end
    elseif part == "pants" then
        self.pantsStyle = style
        if color then self.pantsColor = color end
    elseif part == "shoes" then
        self.shoesStyle = style
        if color then self.shoesColor = color end
    elseif part == "hat" then
        self.hatStyle = style
        if color then self.hatColor = color end
    end
    self:rebuildLayers()
end

function Paperdoll.Character:draw(x, y, scale, direction)
    scale = scale or Paperdoll.scale
    direction = direction or 1  -- 1 = right, -1 = left

    local ox = direction == -1 and Paperdoll.width or 0
    local sx = scale * direction
    local sy = scale

    -- Draw layers in order (bottom to top)
    love.graphics.setColor(1, 1, 1, 1)

    if self.layers.body then
        love.graphics.draw(self.layers.body, x, y, 0, sx, sy, ox, 0)
    end
    if self.layers.face then
        love.graphics.draw(self.layers.face, x, y, 0, sx, sy, ox, 0)
    end
    if self.layers.pants then
        love.graphics.draw(self.layers.pants, x, y, 0, sx, sy, ox, 0)
    end
    if self.layers.shirt then
        love.graphics.draw(self.layers.shirt, x, y, 0, sx, sy, ox, 0)
    end
    if self.layers.shoes then
        love.graphics.draw(self.layers.shoes, x, y, 0, sx, sy, ox, 0)
    end
    if self.layers.hair then
        love.graphics.draw(self.layers.hair, x, y, 0, sx, sy, ox, 0)
    end
    if self.layers.hat then
        love.graphics.draw(self.layers.hat, x, y, 0, sx, sy, ox, 0)
    end
end

-- Get config for saving
function Paperdoll.Character:getConfig()
    return {
        skinTone = self.skinTone,
        eyeColor = self.eyeColor,
        hairStyle = self.hairStyle,
        hairColor = self.hairColor,
        shirtStyle = self.shirtStyle,
        shirtColor = self.shirtColor,
        pantsStyle = self.pantsStyle,
        pantsColor = self.pantsColor,
        shoesStyle = self.shoesStyle,
        shoesColor = self.shoesColor,
        hatStyle = self.hatStyle,
        hatColor = self.hatColor,
    }
end

-- Available options for UI
Paperdoll.options = {
    skinTones = {"light", "medium", "tan", "dark", "ebony"},
    hairStyles = {"short", "long", "ponytail", "mohawk", "curly", "braided", "bald"},
    hairColors = {"black", "brown", "blonde", "red", "auburn", "white", "gray", "blue", "green", "purple", "pink"},
    shirtStyles = {"tshirt", "tanktop", "longsleeve", "jacket", "dress", "tunic"},
    pantsStyles = {"pants", "shorts", "skirt", "longskirt", "none"},
    shoesStyles = {"boots", "sneakers", "sandals", "heels", "barefoot"},
    hatStyles = {"none", "cap", "beanie", "wizardhat", "crown", "bandana"},
    colors = {"white", "black", "red", "crimson", "blue", "navy", "green", "forest", "yellow", "gold", "purple", "brown", "tan", "orange", "pink", "teal", "gray"},
}

return Paperdoll
