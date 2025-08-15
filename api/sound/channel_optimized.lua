-- api/sound/channel_optimized.lua
-- Optimized channel for RPi 3A with buffer management

local Channel = {}
Channel.__index = Channel

function Channel.new()
    local self = setmetatable({}, Channel)
    self.sources = {}
    self.effects = {}
    self.volume = 1.0
    self.pan = 0
    self.active = true
    
    -- RPi 3A specific optimizations
    self.updateCounter = 0
    self.updateSkip = 2  -- Update every other frame to reduce CPU
    
    return self
end

function Channel:addSource(source)
    if source then
        table.insert(self.sources, source)
        -- Ensure proper buffer size on RPi
        if source.setBufferSize then
            source:setBufferSize(4096)
        end
    end
end

function Channel:removeSource(source)
    for i, s in ipairs(self.sources) do
        if s == source then
            table.remove(self.sources, i)
            break
        end
    end
end

function Channel:addEffect(effect)
    if effect then
        table.insert(self.effects, effect)
    end
end

function Channel:setVolume(volume)
    self.volume = math.max(0, math.min(1, volume))
end

function Channel:setPan(pan)
    self.pan = math.max(-1, math.min(1, pan))
end

function Channel:update()
    if not self.active then return end
    
    -- Skip some updates on RPi for performance
    self.updateCounter = self.updateCounter + 1
    if self.updateCounter % self.updateSkip ~= 0 then
        return
    end
    
    -- Update sources
    for _, source in ipairs(self.sources) do
        if source and source.update then
            source:update()
        end
        
        -- Apply volume
        if source.setVolume then
            source:setVolume(self.volume)
        end
    end
    
    -- Apply effects (skip if disabled for performance)
    -- Effects are handled by the dummy filter on RPi 3A
end

function Channel:play()
    for _, source in ipairs(self.sources) do
        if source and source.play then
            source:play()
        elseif source and source.isPlaying and not source:isPlaying() then
            if source.play then source:play() end
        end
    end
end

function Channel:stop()
    for _, source in ipairs(self.sources) do
        if source and source.stop then
            source:stop()
        end
    end
end

function Channel:pause()
    for _, source in ipairs(self.sources) do
        if source and source.pause then
            source:pause()
        end
    end
end

function Channel:isPlaying()
    for _, source in ipairs(self.sources) do
        if source and source.isPlaying and source:isPlaying() then
            return true
        end
    end
    return false
end

return Channel