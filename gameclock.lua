-- Game Clock System
-- Manages in-game time for NPC schedules and day/night cycle

local GameClock = {}

-- Time configuration
GameClock.CONFIG = {
    -- Real seconds per game hour
    secondsPerHour = 60,  -- 1 real minute = 1 game hour, so 24 min = 1 day

    -- Starting time
    startHour = 8,
    startMinute = 0,
    startDay = 1,
}

-- Time state
GameClock.hour = 8
GameClock.minute = 0
GameClock.day = 1
GameClock.totalSeconds = 0
GameClock.paused = false

-- Time periods
GameClock.PERIODS = {
    {name = "Night", startHour = 0, endHour = 5, ambient = {0.15, 0.15, 0.25}},
    {name = "Dawn", startHour = 5, endHour = 7, ambient = {0.6, 0.5, 0.5}},
    {name = "Morning", startHour = 7, endHour = 12, ambient = {1.0, 1.0, 0.95}},
    {name = "Afternoon", startHour = 12, endHour = 17, ambient = {1.0, 1.0, 1.0}},
    {name = "Evening", startHour = 17, endHour = 20, ambient = {0.9, 0.75, 0.6}},
    {name = "Dusk", startHour = 20, endHour = 22, ambient = {0.5, 0.4, 0.5}},
    {name = "Night", startHour = 22, endHour = 24, ambient = {0.15, 0.15, 0.25}},
}

function GameClock:init(startHour, startMinute, startDay)
    self.hour = startHour or self.CONFIG.startHour
    self.minute = startMinute or self.CONFIG.startMinute
    self.day = startDay or self.CONFIG.startDay
    self.totalSeconds = 0
    self.paused = false
end

function GameClock:update(dt)
    if self.paused then return end

    -- Accumulate time
    self.totalSeconds = self.totalSeconds + dt

    -- Convert to game time
    local gameSecondsElapsed = dt * (3600 / self.CONFIG.secondsPerHour)
    local gameMinutesElapsed = gameSecondsElapsed / 60

    self.minute = self.minute + gameMinutesElapsed

    -- Handle minute overflow
    while self.minute >= 60 do
        self.minute = self.minute - 60
        self.hour = self.hour + 1

        -- Handle hour overflow
        if self.hour >= 24 then
            self.hour = 0
            self.day = self.day + 1
        end
    end
end

function GameClock:getTime()
    return self.hour, math.floor(self.minute)
end

function GameClock:getTimeString()
    local h = self.hour
    local m = math.floor(self.minute)
    local ampm = h >= 12 and "PM" or "AM"
    local displayHour = h % 12
    if displayHour == 0 then displayHour = 12 end
    return string.format("%d:%02d %s", displayHour, m, ampm)
end

function GameClock:get24HourString()
    return string.format("%02d:%02d", self.hour, math.floor(self.minute))
end

function GameClock:getDay()
    return self.day
end

function GameClock:getPeriod()
    for _, period in ipairs(self.PERIODS) do
        if self.hour >= period.startHour and self.hour < period.endHour then
            return period.name, period.ambient
        end
    end
    return "Night", {0.15, 0.15, 0.25}
end

function GameClock:getAmbientColor()
    local _, ambient = self:getPeriod()
    return ambient
end

-- Get interpolated ambient for smooth transitions
function GameClock:getInterpolatedAmbient()
    local currentPeriod = nil
    local nextPeriod = nil

    for i, period in ipairs(self.PERIODS) do
        if self.hour >= period.startHour and self.hour < period.endHour then
            currentPeriod = period
            nextPeriod = self.PERIODS[(i % #self.PERIODS) + 1]
            break
        end
    end

    if not currentPeriod then
        return {0.15, 0.15, 0.25}
    end

    -- Calculate progress through current period
    local periodDuration = currentPeriod.endHour - currentPeriod.startHour
    local progress = (self.hour + self.minute / 60 - currentPeriod.startHour) / periodDuration

    -- Only blend in last 30% of period
    if progress < 0.7 then
        return currentPeriod.ambient
    end

    local blendProgress = (progress - 0.7) / 0.3

    -- Interpolate colors
    local r = currentPeriod.ambient[1] + (nextPeriod.ambient[1] - currentPeriod.ambient[1]) * blendProgress
    local g = currentPeriod.ambient[2] + (nextPeriod.ambient[2] - currentPeriod.ambient[2]) * blendProgress
    local b = currentPeriod.ambient[3] + (nextPeriod.ambient[3] - currentPeriod.ambient[3]) * blendProgress

    return {r, g, b}
end

function GameClock:isNight()
    return self.hour >= 22 or self.hour < 5
end

function GameClock:isDawn()
    return self.hour >= 5 and self.hour < 7
end

function GameClock:isDay()
    return self.hour >= 7 and self.hour < 20
end

function GameClock:isDusk()
    return self.hour >= 20 and self.hour < 22
end

-- Set time directly
function GameClock:setTime(hour, minute, day)
    self.hour = hour or self.hour
    self.minute = minute or self.minute
    self.day = day or self.day
end

-- Advance time by hours
function GameClock:advanceHours(hours)
    self.hour = self.hour + hours
    while self.hour >= 24 do
        self.hour = self.hour - 24
        self.day = self.day + 1
    end
    while self.hour < 0 do
        self.hour = self.hour + 24
        self.day = self.day - 1
    end
end

-- Pause/resume
function GameClock:pause()
    self.paused = true
end

function GameClock:resume()
    self.paused = false
end

function GameClock:isPaused()
    return self.paused
end

-- Get NPC location based on schedule
function GameClock:getNPCLocation(npc)
    if not npc.schedule then return "roam" end

    local currentLocation = "home"
    local isSleeping = false

    for _, entry in ipairs(npc.schedule) do
        if self.hour >= entry.hour then
            currentLocation = entry.location
            isSleeping = entry.sleeping or false
        end
    end

    return currentLocation, isSleeping
end

-- Serialize for saving
function GameClock:serialize()
    return {
        hour = self.hour,
        minute = self.minute,
        day = self.day,
        totalSeconds = self.totalSeconds
    }
end

-- Load from saved data
function GameClock:deserialize(data)
    if data then
        self.hour = data.hour or 8
        self.minute = data.minute or 0
        self.day = data.day or 1
        self.totalSeconds = data.totalSeconds or 0
    end
end

return GameClock
