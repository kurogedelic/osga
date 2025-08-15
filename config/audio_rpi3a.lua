-- config/audio_rpi3a.lua
-- Optimized audio configuration for Raspberry Pi 3A
-- Addresses audio dropouts and performance issues

return {
    -- Audio buffer settings
    buffer = {
        -- Increase buffer size to prevent underruns on RPi 3A
        -- Default is 1024, but RPi 3A needs larger buffer
        size = 4096,  -- Increased to prevent audio dropouts
        
        -- Number of buffers to queue
        count = 4,
        
        -- Sample rate (lower = less CPU usage)
        sample_rate = 22050,  -- Reduced from 44100 for RPi 3A
        
        -- Channels (1 = mono, 2 = stereo)
        channels = 1,  -- Mono to reduce CPU load
        
        -- Bit depth
        bit_depth = 16
    },
    
    -- Oscillator limits
    oscillator = {
        -- Maximum simultaneous oscillators
        max_voices = 6,  -- Further reduced for RPi 3A stability
        
        -- Voice stealing when limit reached
        voice_stealing = true,
        
        -- Simplify waveforms for performance
        use_simple_waves = true
    },
    
    -- Filter settings
    filter = {
        -- Disable expensive filters on RPi 3A
        enabled = false,  -- Set to false to bypass filters
        
        -- If enabled, use simplified version
        simple_mode = true,
        
        -- Update rate (Hz) - lower = less CPU
        update_rate = 30  -- Reduced from 60
    },
    
    -- Effects settings
    effects = {
        -- Disable resource-heavy effects
        reverb = false,
        delay = false,
        chorus = false,
        
        -- Keep only essential effects
        volume = true,
        pan = true
    },
    
    -- Performance optimizations
    performance = {
        -- Use integer math where possible
        use_integer_math = true,
        
        -- Cache waveform tables
        cache_waveforms = true,
        
        -- Lazy loading of samples
        lazy_load = true,
        
        -- Garbage collection tuning
        gc_step_size = 200,
        
        -- Audio thread priority (if supported)
        thread_priority = "high"
    },
    
    -- Debug settings
    debug = {
        -- Enable performance logging
        log_performance = true,
        
        -- Log to file
        log_file = "/tmp/osga_audio.log",
        
        -- Log interval (seconds)
        log_interval = 5.0,
        
        -- Show buffer underrun warnings
        show_underrun_warnings = true
    }
}