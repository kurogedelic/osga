-- debug/runtime-debug.lua
-- Remote debugging utility for RPi 3A runtime issues
-- by kurogedelic 2025

local debug = {}

-- Performance monitoring
debug.performance = {
    audio_buffer_underruns = 0,
    frame_drops = 0,
    cpu_usage = 0,
    memory_usage = 0,
    last_update = 0,
    log_interval = 1.0,  -- Log every second
    log_file = nil
}

-- Initialize debug logging
function debug.init()
    -- Create log file with timestamp
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local log_path = "/tmp/osga_debug_" .. timestamp .. ".log"
    debug.performance.log_file = io.open(log_path, "w")
    
    if debug.performance.log_file then
        debug.log("Debug session started: " .. os.date())
        debug.log("Platform: " .. love.system.getOS())
        debug.log("Love2D: " .. love.getVersion())
        
        -- Log system info for RPi
        if love.system.getOS() == "Linux" then
            local handle = io.popen("cat /proc/device-tree/model 2>/dev/null")
            if handle then
                local model = handle:read("*a")
                handle:close()
                debug.log("Device: " .. (model or "Unknown"))
            end
            
            -- Check CPU info
            handle = io.popen("cat /proc/cpuinfo | grep 'model name' | head -1")
            if handle then
                local cpu = handle:read("*a")
                handle:close()
                debug.log("CPU: " .. (cpu or "Unknown"))
            end
            
            -- Check memory
            handle = io.popen("free -m | grep Mem:")
            if handle then
                local mem = handle:read("*a")
                handle:close()
                debug.log("Memory: " .. (mem or "Unknown"))
            end
        end
        
        debug.log("----------------------------------------")
    else
        print("Warning: Could not create debug log file")
    end
end

-- Log message to file and console
function debug.log(message)
    local timestamp = os.date("%H:%M:%S.%03d", os.time())
    local log_line = string.format("[%s] %s", timestamp, message)
    
    print(log_line)
    
    if debug.performance.log_file then
        debug.performance.log_file:write(log_line .. "\n")
        debug.performance.log_file:flush()
    end
end

-- Monitor audio performance
function debug.checkAudioBuffer(sound_api)
    if not sound_api then return end
    
    -- Check if audio queue is keeping up
    local active_count = 0
    local queued_count = 0
    
    -- Count active sources (simplified check)
    if sound_api.sources then
        for _, source in pairs(sound_api.sources) do
            if source and source:isPlaying() then
                active_count = active_count + 1
            end
        end
    end
    
    return active_count, queued_count
end

-- Update performance metrics
function debug.update(dt)
    debug.performance.last_update = debug.performance.last_update + dt
    
    if debug.performance.last_update >= debug.performance.log_interval then
        -- Get FPS
        local fps = love.timer.getFPS()
        
        -- Get memory usage
        local mem_kb = collectgarbage("count")
        
        -- Get audio stats
        local active_sources, queued = debug.checkAudioBuffer(osga and osga.sound)
        
        -- Log performance data
        local perf_msg = string.format(
            "PERF: FPS=%d, Mem=%.1fMB, Audio=%d active",
            fps, mem_kb/1024, active_sources or 0
        )
        
        -- Detect issues
        if fps < 25 then
            perf_msg = perf_msg .. " [LOW FPS!]"
            debug.performance.frame_drops = debug.performance.frame_drops + 1
        end
        
        if mem_kb > 100000 then  -- Over 100MB
            perf_msg = perf_msg .. " [HIGH MEM!]"
        end
        
        debug.log(perf_msg)
        
        -- Log filter status if available
        if osga and osga.sound and osga.sound.filter then
            debug.logFilterStatus()
        end
        
        debug.performance.last_update = 0
    end
end

-- Log filter debug info
function debug.logFilterStatus()
    if not osga or not osga.sound or not osga.sound.filter then
        debug.log("Filter: Not available")
        return
    end
    
    local filter = osga.sound.filter
    
    -- Try to get filter parameters
    local status = "Filter: "
    
    -- Check if filter functions exist
    if filter.lowpass then
        status = status .. "lowpass=OK "
    else
        status = status .. "lowpass=MISSING "
    end
    
    if filter.highpass then
        status = status .. "highpass=OK "
    else
        status = status .. "highpass=MISSING "
    end
    
    if filter.bandpass then
        status = status .. "bandpass=OK"
    else
        status = status .. "bandpass=MISSING"
    end
    
    debug.log(status)
end

-- Draw debug overlay
function debug.draw()
    if not debug.show_overlay then return end
    
    love.graphics.push()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 320, 80)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(10))
    
    local y = 5
    love.graphics.print("FPS: " .. love.timer.getFPS(), 5, y)
    y = y + 12
    
    local mem_mb = collectgarbage("count") / 1024
    love.graphics.print(string.format("Mem: %.1f MB", mem_mb), 5, y)
    y = y + 12
    
    love.graphics.print("Underruns: " .. debug.performance.audio_buffer_underruns, 5, y)
    y = y + 12
    
    love.graphics.print("Frame drops: " .. debug.performance.frame_drops, 5, y)
    y = y + 12
    
    -- Show audio buffer size recommendation
    if debug.performance.audio_buffer_underruns > 5 then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.print("! Increase audio buffer size", 5, y)
    end
    
    love.graphics.pop()
end

-- Cleanup
function debug.cleanup()
    if debug.performance.log_file then
        debug.log("Debug session ended")
        debug.performance.log_file:close()
    end
end

-- Toggle overlay with key press
function debug.keypressed(key)
    if key == "f12" then
        debug.show_overlay = not debug.show_overlay
        debug.log("Debug overlay: " .. (debug.show_overlay and "ON" or "OFF"))
    end
end

return debug