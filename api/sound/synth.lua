-- api/sound/synth.lua
-- Sound synthesis module for OSGA
-- Oscillator implementations inspired by denver.lua
local Source = require('api.sound.source')

local synth = {}

-- Audio settings
local SAMPLE_RATE = 44100
local BITS = 16
local CHANNELS = 1

-- Note to frequency conversion (A4 = 440Hz)
local BASE_FREQ = 440


function synth.newNoise(type, params)
    params = params or {}


    return Source.new(function()
        if type == 'white' then
            return math.random() * 2 - 1
        elseif type == 'pink' then
            local white = math.random() * 2 - 1
            local b0 = 0
            local b1 = 0
            local b2 = 0
            local b3 = 0
            local b4 = 0
            local b5 = 0
            local b6 = 0


            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            b4 = 0.55000 * b4 + white * 0.5329522
            b5 = -0.7616 * b5 - white * 0.0168980
            local pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
            b6 = white * 0.115926

            return pink * 0.11
        end
        return 0
    end)
end

-- Convert note string to frequency (e.g. "A4" -> 440, "C#5" -> 554.37)
function synth.noteToFrequency(note_str)
    if not note_str or type(note_str) ~= 'string' then
        return nil
    end
    
    local note_semitones = { C = -9, D = -7, E = -5, F = -4, G = -2, A = 0, B = 2 }
    
    local semitones = note_semitones[note_str:sub(1, 1)]
    if not semitones then return nil end
    
    local octave = 4
    
    if note_str:len() == 2 then
        octave = tonumber(note_str:sub(2, 2)) or 4
    elseif note_str:len() == 3 then
        if note_str:sub(2, 2) == '#' then
            semitones = semitones + 1
        elseif note_str:sub(2, 2) == 'b' then
            semitones = semitones - 1
        end
        octave = tonumber(note_str:sub(3, 3)) or 4
    end
    
    semitones = semitones + 12 * (octave - 4)
    return BASE_FREQ * math.pow(2, semitones / 12)
end

local function sineOscillator(frequency)
    local phase = 0
    local phaseIncrement = 2 * math.pi * frequency / SAMPLE_RATE

    return function()
        phase = phase + phaseIncrement
        if phase >= 2 * math.pi then
            phase = phase - 2 * math.pi
        end
        return math.sin(phase)
    end
end

local function sawtoothOscillator(frequency)
    local phase = 0
    local phaseIncrement = frequency / SAMPLE_RATE

    return function()
        phase = phase + phaseIncrement
        if phase >= 1.0 then
            phase = phase - 1.0
        end
        return 2.0 * phase - 1.0
    end
end

local function triangleOscillator(frequency)
    local phase = 0
    local phaseIncrement = frequency / SAMPLE_RATE

    return function()
        phase = phase + phaseIncrement
        if phase >= 1.0 then
            phase = phase - 1.0
        end

        local value = 4.0 * math.abs(phase - 0.5) - 1.0
        return value
    end
end

local function squareOscillator(frequency, pulseWidth)
    pulseWidth = pulseWidth or 0.5
    local phase = 0
    local phaseIncrement = frequency / SAMPLE_RATE

    return function()
        phase = phase + phaseIncrement
        if phase >= 1.0 then
            phase = phase - 1.0
        end
        return phase < pulseWidth and 1.0 or -1.0
    end
end


function synth.newOscillator(waveform, frequency)
    local generator
    
    -- Handle note strings (e.g., "A4", "C#5")
    if type(frequency) == 'string' then
        frequency = synth.noteToFrequency(frequency)
    end
    frequency = frequency or 440

    print("Creating oscillator:", waveform, frequency)

    if waveform == 'sine' or waveform == 'sinus' then
        generator = sineOscillator(frequency)
    elseif waveform == 'sawtooth' then
        generator = sawtoothOscillator(frequency)
    elseif waveform == 'triangle' then
        generator = triangleOscillator(frequency)
    elseif waveform == 'square' then
        generator = squareOscillator(frequency)
    else
        print("Unknown waveform:", waveform)
        generator = sineOscillator(frequency)
    end

    return Source.new(generator)
end

return synth
