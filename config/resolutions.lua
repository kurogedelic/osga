-- config/resolutions.lua
-- Standard OSGA resolution configurations

return {
    -- Standard OSGA resolution (4:3 landscape)
    osga_standard = {
        width = 480,
        height = 320,
        name = "OSGA Standard",
        description = "Original OSGA resolution for osga-shield hardware"
    },

    -- Square formats
    square_small = {
        width = 320,
        height = 320,
        name = "Square Small",
        description = "Square format for certain applications"
    },

    square_medium = {
        width = 480,
        height = 480,
        name = "Square Medium",
        description = "Medium square format"
    },

    -- Portrait formats  
    portrait_small = {
        width = 240,
        height = 320,
        name = "Portrait Small",
        description = "Portrait orientation, mobile-like"
    },

    -- Modern display ratios
    hd_720p = {
        width = 720,
        height = 480,
        name = "HD 720p adapted",
        description = "3:2 ratio similar to classic computers"
    },

    -- Ultrawide
    ultrawide = {
        width = 640,
        height = 240,
        name = "Ultrawide",
        description = "Cinematic ultrawide format"
    },

    -- Development/debug resolutions
    dev_large = {
        width = 960,
        height = 640,
        name = "Development Large",
        description = "2x scaled version for development"
    },

    dev_xl = {
        width = 1440,
        height = 960,
        name = "Development XL",
        description = "3x scaled version for high-DPI development"
    }
}