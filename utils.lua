-- Shared Utility Functions
-- Centralized math and helper functions used across the codebase

local Utils = {}

-- Clamp a value between min and max
function Utils.clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

-- Linear interpolation between two values
function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Linear interpolation between two colors (RGB arrays)
function Utils.lerpColor(c1, c2, t)
    return {
        Utils.lerp(c1[1], c2[1], t),
        Utils.lerp(c1[2], c2[2], t),
        Utils.lerp(c1[3], c2[3], t)
    }
end

-- 4x4 Bayer dithering matrix for retro-style shading
Utils.DITHER_MATRIX = {
    {0.0, 0.5, 0.125, 0.625},
    {0.75, 0.25, 0.875, 0.375},
    {0.1875, 0.6875, 0.0625, 0.5625},
    {0.9375, 0.4375, 0.8125, 0.3125}
}

-- Check if a pixel should be dithered based on position and threshold
function Utils.shouldDither(x, y, threshold)
    local mx = (math.floor(x) % 4) + 1
    local my = (math.floor(y) % 4) + 1
    return Utils.DITHER_MATRIX[my][mx] < threshold
end

-- Hash function for procedural generation
function Utils.hash(x, y, seed)
    local n = x + y * 57 + (seed or 0) * 131
    n = bit.bxor(bit.lshift(n, 13), n)
    return bit.band(n * (n * n * 15731 + 789221) + 1376312589, 0x7FFFFFFF) / 0x7FFFFFFF
end

-- Simple noise function for texture variation
function Utils.simpleNoise(x, y, seed)
    local n = math.sin(x * 12.9898 + y * 78.233 + (seed or 0)) * 43758.5453
    return n - math.floor(n)
end

-- Safely set a pixel on image data with bounds checking
function Utils.setPixel(imageData, x, y, color, alpha)
    alpha = alpha or 1
    if x >= 0 and x < imageData:getWidth() and y >= 0 and y < imageData:getHeight() then
        imageData:setPixel(x, y, color[1], color[2], color[3], alpha)
    end
end

-- Distance between two points
function Utils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Normalize a value from one range to another
function Utils.normalize(value, inMin, inMax, outMin, outMax)
    outMin = outMin or 0
    outMax = outMax or 1
    return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
end

return Utils
