-- apps/ambient/main.lua

local app = {}
app._meta = {
    name = "Ambient Meter",
    slug = "ambient",
    author = "OSGA Developer",
    author_url = "https://example.com/",
    app_url = "https://github.com/example/ambientmeter/",
    version = "1.0.0"
}

-- Configuration
local config = {
    colorBar = {
        count = 6,
        width = 240,
        height = 40
    },
    paramArea = {
        x = 240,
        y = 0,
        width = 80,
        height = 240
    }
}

-- Environmental parameters (simulated)
local environment = {
    temperature = 25, -- 0-40°C
    humidity = 50,    -- 0-100%
    time = 12         -- 0-24 hours
}

-- Convert rotary value (0-360) to time (0-24)
local function rotaryToTime(rotaryValue)
    return (rotaryValue / 360) * 24
end

-- Convert gyroX (-2 to 2) to temperature (0-40°C)
local function gyroXToTemperature(gyroX)
    return ((gyroX + 2) / 4) * 40
end

-- Convert gyroY (-2 to 2) to humidity (0-100%)
local function gyroYToHumidity(gyroY)
    return ((gyroY + 2) / 4) * 100
end

-- Color utility functions
local function hsvToRgb(h, s, v)
    local h_i = math.floor(h * 6)
    local f = h * 6 - h_i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    if h_i == 0 then
        return v, t, p
    elseif h_i == 1 then
        return q, v, p
    elseif h_i == 2 then
        return p, v, t
    elseif h_i == 3 then
        return p, q, v
    elseif h_i == 4 then
        return t, p, v
    else
        return v, p, q
    end
end

-- Generate colors for the bars based on environmental parameters
local function generateBarColors()
    local colors = {}

    -- Map temperature to hue (cold to warm: blue to red)
    -- 0°C -> 0.6 (blue), 40°C -> 0 (red)
    local tempHue = 0.6 - (environment.temperature / 40) * 0.6

    -- Map humidity to saturation
    -- 0% -> 0.2 (less saturated), 100% -> 1.0 (fully saturated)
    local humidSaturation = 0.2 + (environment.humidity / 100) * 0.8

    -- Map time to brightness
    -- Dawn/dusk brightness curve (brightest at noon, darkest at midnight)
    local timeNormalized = environment.time / 24
    local timeBrightness

    if timeNormalized < 0.5 then
        -- 0 (midnight) to 0.5 (noon): increasing brightness
        timeBrightness = 0.3 + (timeNormalized * 2) * 0.7
    else
        -- 0.5 (noon) to 1.0 (midnight): decreasing brightness
        timeBrightness = 0.3 + ((1 - timeNormalized) * 2) * 0.7
    end

    -- Generate 6 color bars with variations
    for i = 1, config.colorBar.count do
        -- Adjust hue slightly for each bar to create a gradient
        local barHueOffset = (i - 1) / config.colorBar.count * 0.2
        local barHue = (tempHue + barHueOffset) % 1.0

        -- Convert HSV to RGB
        local r, g, b = hsvToRgb(barHue, humidSaturation, timeBrightness)

        colors[i] = { r, g, b }
    end

    return colors
end

-- Draw color bars
local function drawColorBars()
    local barColors = generateBarColors()

    for i = 1, config.colorBar.count do
        local y = (i - 1) * config.colorBar.height

        -- Draw the color bar
        osga.gfx.color(unpack(barColors[i]))
        osga.gfx.rect(0, y, config.colorBar.width, config.colorBar.height, "fill")

        -- Draw a subtle border
        osga.gfx.color(0.2, 0.2, 0.2, 0.3)
        osga.gfx.rect(0, y, config.colorBar.width, config.colorBar.height, "line")
    end
end

local function drawParameterArea()
    -- Background
    osga.gfx.color(0, 0, 0)
    osga.gfx.rect(
        config.paramArea.x,
        config.paramArea.y,
        config.paramArea.width,
        config.paramArea.height,
        "fill"
    )

    -- Border
    osga.gfx.color(0.3, 0.3, 0.3)
    osga.gfx.rect(
        config.paramArea.x,
        config.paramArea.y,
        config.paramArea.width,
        config.paramArea.height,
        "line"
    )

    -- Parameter values with labels
    osga.gfx.color(1, 1, 1)

    -- Temperature
    local tempX = config.paramArea.x + 10
    local tempY = config.paramArea.y + 30
    osga.gfx.text("TEMP", tempX, tempY)

    -- Temperature color indicator (blue to red)
    local tempHue = 0.6 - (environment.temperature / 40) * 0.6
    local r, g, b = hsvToRgb(tempHue, 1, 1)
    osga.gfx.color(r, g, b)
    osga.gfx.text(string.format("%.1f°C", environment.temperature), tempX, tempY + 20)

    -- Humidity
    local humidX = config.paramArea.x + 10
    local humidY = config.paramArea.y + 80
    osga.gfx.color(1, 1, 1)
    osga.gfx.text("HUMID", humidX, humidY)

    -- Humidity color indicator (saturation)
    local humidSat = 0.2 + (environment.humidity / 100) * 0.8
    r, g, b = hsvToRgb(0.6, humidSat, 1) -- Blue with varying saturation
    osga.gfx.color(r, g, b)
    osga.gfx.text(string.format("%.1f%%", environment.humidity), humidX, humidY + 20)

    -- Time
    local timeX = config.paramArea.x + 10
    local timeY = config.paramArea.y + 130
    osga.gfx.color(1, 1, 1)
    osga.gfx.text("TIME", timeX, timeY)

    -- Time color indicator (brightness)
    local timeNormalized = environment.time / 24
    local timeBrightness
    if timeNormalized < 0.5 then
        timeBrightness = 0.3 + (timeNormalized * 2) * 0.7
    else
        timeBrightness = 0.3 + ((1 - timeNormalized) * 2) * 0.7
    end
    r, g, b = hsvToRgb(0.6, 0.5, timeBrightness) -- Medium blue with varying brightness
    osga.gfx.color(r, g, b)

    -- Format time as HH:MM
    local hours = math.floor(environment.time)
    local minutes = math.floor((environment.time - hours) * 60)
    osga.gfx.text(string.format("%02d:%02d", hours, minutes), timeX, timeY + 20)

    -- Legend
    osga.gfx.color(0.7, 0.7, 0.7)
    osga.gfx.text("Parameters:", tempX, timeY + 60)
    osga.gfx.text("Temp → Color", tempX, timeY + 80)
    osga.gfx.text("Humid → Sat", tempX, timeY + 100)
    osga.gfx.text("Time → Bright", tempX, timeY + 120)

    -- Controls
    osga.gfx.text("Controls:", tempX, timeY + 150)
    osga.gfx.text("Rotate: Time", tempX, timeY + 170)
    osga.gfx.text("Gyro X: Temp", tempX, timeY + 190)
    osga.gfx.text("Gyro Y: Humid", tempX, timeY + 210)
end

-- App lifecycle functions
function app.init()
    print("Ambient Meter initialized")
    osga.gfx.setFont(osga.gfx.getNada())
end

function app.draw(koto)
    osga.gfx.clear(0, 0, 0)

    -- Update simulated environment parameters
    environment.time = rotaryToTime(koto.rotaryValue)
    environment.temperature = gyroXToTemperature(koto.gyroX)
    environment.humidity = gyroYToHumidity(koto.gyroY)

    -- Draw the color bars
    drawColorBars()

    -- Draw parameter area
    drawParameterArea()
end

function app.cleanup()
    -- Nothing to clean up
end

return app
