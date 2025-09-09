-- osga/osga-sim/api/system.lua

-- Detect screen resolution based on Love2D configuration
local function detectResolution()
    -- Default resolution
    local width, height = 480, 320
    
    -- Check if Love2D has been initialized with different resolution
    if love.graphics then
        local w, h = love.graphics.getDimensions()
        -- If dimensions are available and reasonable
        if w > 0 and h > 0 and w <= 4096 and h <= 4096 then
            width, height = w, h
        end
    end
    
    return width, height
end

local system = {
    -- Display constants (will be updated dynamically)
    width = 480,
    height = 320,

    -- System info
    name = "OSGA",
    version = "1.0.0",
    model = "simulator",
    fps = 60,

    -- System utilities
    getTime = function()
        return love.timer.getTime()
    end,

    sleep = function(s)
        love.timer.sleep(s)
    end,

    getFPS = function()
        return love.timer.getFPS()
    end,

    getDelta = function()
        return love.timer.getDelta()
    end,

    -- Placeholder functions (will be defined after table creation)
    updateResolution = nil,
    getAspectRatio = nil,
    isLandscape = nil,
    scale = nil,
    scaleSize = nil
}

-- Define all functions after system table is created
system.updateResolution = function()
    system.width, system.height = detectResolution()
    return system.width, system.height
end

system.getAspectRatio = function()
    return system.width / system.height
end

system.isLandscape = function()
    return system.width > system.height
end

system.scale = function(x, y)
    local scaleX = system.width / 480
    local scaleY = system.height / 320
    return x * scaleX, y and (y * scaleY) or scaleX
end

system.scaleSize = function(w, h)
    local scale = math.min(system.width / 480, system.height / 320)
    return w * scale, h * scale
end

-- Initialize resolution on load
system.updateResolution()

return system
