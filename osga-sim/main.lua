-- osga-sim/main.lua
-- Osga Simulator
-- by Leo Kuroshita from Hugelton Instruments. 2025



package.path = "../?.lua;../?/init.lua;" .. package.path
local topbar = require('topbar')

require('api/init')


osga.configurePaths()
print("LOVE SourceDir:", love.filesystem.getSource())
print("Working Dir:", love.filesystem.getWorkingDirectory())
print("File exists?", love.filesystem.getInfo("../api/fonts/nada.png") ~= nil)
local canvas = nil
local currentApp = nil
local isLoading = false
local loadingDots = 0
local loadingTimer = 0
local pixelShader = nil
local pixelScale = 2



koto = {
    swA = false,
    swB = false,
    swC = false,
    swR = false,
    rotaryValue = 0,
    rotaryInc = false,
    rotaryDec = false,
    rotaryTicks = 0,
    gyroX = 0,
    gyroY = 0,
    gyroZ = 0.5,
    button = {
        back = false
    }
}


local rotaryState = {
    value = 0,
    ticks = 0,
    lastProcessedTick = 0,
    needsReset = false
}




function loadApp(appPath)
    isLoading = true
    print("Loading app from:", appPath)


    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    local dots = string.rep(".", loadingDots)
    love.graphics.print("Loading" .. dots, osga.system.width / 2 - 30, osga.system.height / 2)
    love.graphics.setCanvas()


    love.graphics.draw(canvas, 0, topbar.getScale() == 1 and 80 or 20)
    love.graphics.present()

    if currentApp and currentApp.cleanup then
        currentApp.cleanup()
    end


    local mainPath = appPath
    if not mainPath:match("%.lua$") then
        mainPath = appPath .. "/main.lua"
    end

    local fullPath = osga.paths.root .. "/" .. mainPath
    print("Loading from full path:", fullPath)


    local file = io.open(fullPath, "r")
    if not file then
        print("Error: Cannot read main.lua at " .. fullPath)
        isLoading = false
        return false
    end
    local content = file:read("*all")
    file:close()



    local chunk, err = load(content, fullPath, "t")
    if not chunk then
        print("Failed to load app:", err)
        isLoading = false
        return false
    end


    local ok, app = pcall(chunk)
    if not ok then
        print("Failed to run app:", app)
        isLoading = false
        return false
    end


    if type(app) ~= "table" or not app._meta then
        print("Invalid app structure: missing _meta")
        isLoading = false
        return false
    end


    currentApp = app
    if currentApp.init then
        local ok, err = pcall(currentApp.init)
        if not ok then
            print("Failed to initialize app:", err)
            isLoading = false
            return false
        end
    end


    topbar.setAppInfo(currentApp._meta)
    isLoading = false
    return true
end

function createPixelShader()
    local shader = [[
        extern float pixelSize;
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
        {
            vec2 size = vec2(pixelSize) / love_ScreenSize.xy;
            vec2 pixel = texture_coords - mod(texture_coords, size) + size * 0.5;
            vec4 texcolor = Texel(texture, pixel);
            
            // Reduce color depth for bitmap effect
            texcolor.r = floor(texcolor.r * 8.0 + 0.5) / 8.0;
            texcolor.g = floor(texcolor.g * 8.0 + 0.5) / 8.0;
            texcolor.b = floor(texcolor.b * 8.0 + 0.5) / 8.0;
            
            return texcolor * color;
        }
    ]]
    return love.graphics.newShader(shader)
end

function love.load(args)
    love.graphics.setBackgroundColor(20 / 255, 20 / 255, 20 / 255)
    canvas = love.graphics.newCanvas(osga.system.width, osga.system.height)
    love.graphics.setDefaultFilter('nearest', 'nearest')
    
    pixelShader = createPixelShader()
    pixelShader:send("pixelSize", pixelScale)

    topbar.init()

    if args[1] then
        loadApp(args[1])
    else
        loadApp("apps/kumo")
    end
end

function love.update(dt)
    if love.timer then love.timer.sleep(0.006) end

    if isLoading then
        loadingTimer = loadingTimer + 1
        if loadingTimer > 10 then
            loadingTimer = 0
            loadingDots = (loadingDots + 1) % 4
        end
    end
    osga.sound.update()

    local mx, my = love.mouse.getPosition()
    local scale = topbar.getScale()
    if topbar.isGyroEnabled() then
        if scale == 1 then
            if mx >= 0 and mx <= osga.system.width and my >= 80 and my <= 320 then
                koto.gyroX = ((mx / (osga.system.width / 2)) - 1) * 2
                koto.gyroY = (((my - 80) / 120) - 1) * 2
                koto.gyroX = math.max(-2.0, math.min(2.0, koto.gyroX))
                koto.gyroY = math.max(-2.0, math.min(2.0, koto.gyroY))
            end
        else
            local centerX = osga.system.width
            local centerY = 280
            local gyroArea = 260
            if mx >= centerX - gyroArea and mx <= centerX + gyroArea and
                my >= centerY - gyroArea and my <= centerY + gyroArea then
                koto.gyroX = ((mx - (centerX - gyroArea)) / (gyroArea * 2) - 0.5) * 4
                koto.gyroY = ((my - (centerY - gyroArea)) / (gyroArea * 2) - 0.5) * 4
                koto.gyroX = math.max(-2.0, math.min(2.0, koto.gyroX))
                koto.gyroY = math.max(-2.0, math.min(2.0, koto.gyroY))
            end
        end
    else
        koto.gyroX, koto.gyroY = 0.0, 0.0
    end

    topbar.setGyroValues(koto.gyroX, koto.gyroY)


    if rotaryState.ticks ~= rotaryState.lastProcessedTick then
        if rotaryState.ticks > rotaryState.lastProcessedTick then
            koto.rotaryInc = true
            koto.rotaryDec = false
            koto.rotaryTicks = 1
        else
            koto.rotaryInc = false
            koto.rotaryDec = true
            koto.rotaryTicks = -1
        end
        rotaryState.needsReset = true
        rotaryState.lastProcessedTick = rotaryState.ticks
    elseif rotaryState.needsReset then
        koto.rotaryInc = false
        koto.rotaryDec = false
        koto.rotaryTicks = 0
        rotaryState.needsReset = false
    end


    if koto.button.back then
        if currentApp and currentApp._meta.slug ~= "kumo" then
            loadApp("apps/kumo")
        end
    end
end

function drawLoadingScreen()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    
    local scale = topbar.getScale()
    local dots = string.rep(".", loadingDots)
    love.graphics.print(
        "Loading" .. dots,
        osga.system.width / 2 - (30 * scale),
        osga.system.height / 2,
        0,
        scale, scale
    )
    love.graphics.setCanvas()
    
    love.graphics.push()
    love.graphics.scale(scale, scale)
    local yOffset = scale == 1 and 80 or 20
    love.graphics.setShader(pixelShader)
    love.graphics.draw(canvas, 0, yOffset)
    love.graphics.setShader()
    love.graphics.pop()
end

function drawCurrentApp()
    if currentApp and currentApp.draw then
        local ok, err = pcall(currentApp.draw, koto)
        if not ok then
            love.graphics.setColor(1, 0, 0)
            love.graphics.printf("Error in app.draw: " .. err, 10, 10, 300, "left")
            print("Error in app.draw: " .. err)
        end
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            "No app loaded\nUsage: love sim path/to/app",
            0, 100, osga.system.width, "center"
        )
    end
end

function love.draw()
    if isLoading then
        drawLoadingScreen()
        return
    end

    local scale = topbar.getScale()
    
    topbar.draw()
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setFont(osga.font.getNada())
    
    drawCurrentApp()
    
    love.graphics.setCanvas()
    
    love.graphics.push()
    love.graphics.scale(scale, scale)
    
    local yOffset = scale == 1 and 80 or 20
    love.graphics.setShader(pixelShader)
    love.graphics.draw(canvas, 0, yOffset)
    love.graphics.setShader()
    
    love.graphics.pop()
    love.graphics.setFont(osga.font.getNada())
end

function love.keypressed(key)
    if key == 'a' then
        koto.swA = true
    elseif key == 's' then
        koto.swB = true
    elseif key == 'd' then
        koto.swC = true
    elseif key == 'space' then
        koto.swR = true
    elseif key == 'escape' then
        koto.button.back = true
    elseif key == 'p' then
        -- Toggle pixel effect
        pixelScale = pixelScale == 2 and 4 or 2
        pixelShader:send("pixelSize", pixelScale)
    end
end

function love.keyreleased(key)
    if key == 'a' then
        koto.swA = false
    elseif key == 's' then
        koto.swB = false
    elseif key == 'd' then
        koto.swC = false
    elseif key == 'space' then
        koto.swR = false
    elseif key == 'escape' then
        koto.button.back = false
    elseif key == 'left' then
        rotaryState.ticks = rotaryState.ticks - 1
    elseif key == 'right' then
        rotaryState.ticks = rotaryState.ticks + 1
    end
end

function love.wheelmoved(x, y)
    rotaryState.value = (rotaryState.value + y) % 360
    if rotaryState.value < 0 then
        rotaryState.value = rotaryState.value + 360
    end
    koto.rotaryValue = rotaryState.value

    if y > 0 then
        rotaryState.ticks = rotaryState.ticks + 1
    elseif y < 0 then
        rotaryState.ticks = rotaryState.ticks - 1
    end
end

function love.mousemoved(x, y)
    topbar.mousemoved(x, y)
end

function love.mousepressed(x, y, button)
    if y < 80 then
        topbar.mousepressed(x, y, button)
    end
end

function love.quit()
    if currentApp and currentApp.cleanup then
        currentApp.cleanup()
    end
end
