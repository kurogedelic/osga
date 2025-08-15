-- api/sound/init.lua
-- Detect platform and load appropriate modules
local function isRPi3A()
    if love.system.getOS() ~= "Linux" then
        return false
    end
    
    local handle = io.popen("cat /proc/device-tree/model 2>/dev/null")
    if handle then
        local model = handle:read("*a")
        handle:close()
        if model and model:find("Raspberry Pi 3") then
            return true
        end
    end
    return false
end

-- Load optimized modules for RPi 3A
local Channel, Filter
local use_optimized = isRPi3A()

if use_optimized then
    -- Try to load optimized versions
    local ok_channel, opt_channel = pcall(require, 'api.sound.channel_optimized')
    local ok_config, config = pcall(require, "config.audio_rpi3a")
    
    if ok_channel then
        Channel = opt_channel
        print("Using optimized channel for RPi 3A")
    else
        Channel = require('api.sound.channel')
    end
    
    if ok_config and not config.filter.enabled then
        -- Dummy filter for RPi 3A
        Filter = {
            new = function(type, params) 
                return {
                    process = function(self, samples) return samples end,
                    setParameter = function(self, param, value) end,
                    getType = function(self) return type end
                }
            end,
            lowpass = function(samples, cutoff, resonance) return samples end,
            highpass = function(samples, cutoff, resonance) return samples end,
            bandpass = function(samples, low, high, resonance) return samples end
        }
        print("Filters disabled for performance")
    else
        Filter = require('api.sound.effects.filter')
    end
else
    -- Standard modules
    Channel = require('api.sound.channel')
    Filter = require('api.sound.effects.filter')
end

local synth = require('api.sound.synth')
local utils = require('api.sound.utils')
local sampler = require('api.sound.sampler')
local lfo = require('api.sound.lfo')

local sound = {
    channel = Channel,
    filter = Filter,
    synth = synth,
    utils = utils,
    sampler = sampler,
    lfo = lfo,
    activeChannels = {},
    optimized = use_optimized
}

function sound.addChannel(channel)
    table.insert(sound.activeChannels, channel)
end

function sound.removeChannel(channel)
    for i, ch in ipairs(sound.activeChannels) do
        if ch == channel then
            table.remove(sound.activeChannels, i)
            break
        end
    end
end

function sound.update()
    for _, channel in ipairs(sound.activeChannels) do
        channel:update()
    end
end

return sound
