-- apps/hardtest/main.lua

-- osga hardware check test app
-- gyro : rotate cube x,y
-- rotary : rotate cube z
-- a/b/c button : play sound
-- rotary click : cube wire frame / fill change

local app = {}

app._meta = {
    name = "Hardware Test",
    slug = "hardtest",
    author = "Leo Kuroshita",
    version = "1.0.0"
}





-- State variables
local rotaryZ = 0
local sounds = {
    a = nil,
    b = nil,
    c = nil
}
local soundChannels = {
    a = nil,
    b = nil,
    c = nil
}
local recentRotaryTicks = 0
local fillMode = false
local prevSwR = false

-- 3D cube vertices and faces definition
local faces = {
    -- Each face defined by vertex indices and a normal vector
    { vertices = { 1, 2, 3, 4 }, normal = { 0, 0, 1 } },
    { vertices = { 5, 6, 7, 8 }, normal = { 0, 0, -1 } },
    { vertices = { 1, 2, 6, 5 }, normal = { 0, -1, 0 } },
    { vertices = { 3, 4, 8, 7 }, normal = { 0, 1, 0 } },
    { vertices = { 1, 4, 8, 5 }, normal = { -1, 0, 0 } },
    { vertices = { 2, 3, 7, 6 }, normal = { 1, 0, 0 } }
}

-- 3D transformation functions
local function rotatePoint(point, angleX, angleY, angleZ)
    local cos, sin = math.cos, math.sin
    local x, y, z = point[1], point[2], point[3]

    -- Rotate around X axis
    y, z = y * cos(angleX) - z * sin(angleX), y * sin(angleX) + z * cos(angleX)
    -- Rotate around Y axis
    x, z = x * cos(angleY) + z * sin(angleY), -x * sin(angleY) + z * cos(angleY)
    -- Rotate around Z axis
    x, y = x * cos(angleZ) - y * sin(angleZ), x * sin(angleZ) + y * cos(angleZ)

    return { x, y, z }
end

-- Project 3D point to 2D screen coordinates
local function project(point, width, height)
    local scale = 50
    local x = point[1] * scale + width / 2
    local y = point[2] * scale + height / 2
    return { x, y }
end

-- Calculate face normal after rotation
local function calculateNormal(face, rotatedVertices)
    local v1 = rotatedVertices[face.vertices[1]]
    local v2 = rotatedVertices[face.vertices[2]]
    local v3 = rotatedVertices[face.vertices[3]]

    local ax = v2[1] - v1[1]
    local ay = v2[2] - v1[2]
    local az = v2[3] - v1[3]
    local bx = v3[1] - v1[1]
    local by = v3[2] - v1[2]
    local bz = v3[3] - v1[3]

    local nx = ay * bz - az * by
    local ny = az * bx - ax * bz
    local nz = ax * by - ay * bx

    local length = math.sqrt(nx * nx + ny * ny + nz * nz)
    return { nx / length, ny / length, nz / length }
end

function app.init()
    print("Hardware Test app initialized")

    -- Create sound sources for each button
    sounds.a = osga.sound.synth.newOscillator('square', 261.63)   -- C4
    sounds.b = osga.sound.synth.newOscillator('square', 329.63)   -- E4
    sounds.c = osga.sound.synth.newOscillator('sawtooth', 392.00) -- G4

    -- Create channels for the sounds
    soundChannels.a = osga.sound.channel.new()
    soundChannels.b = osga.sound.channel.new()
    soundChannels.c = osga.sound.channel.new()

    -- Add sources to channels
    soundChannels.a:addSource(sounds.a)
    soundChannels.b:addSource(sounds.b)
    soundChannels.c:addSource(sounds.c)

    -- Add filters to make the sounds more interesting
    local filterA = osga.sound.filter.new('lowpass', { frequency = 500, q = 1.0 })
    local filterB = osga.sound.filter.new('bandpass', { frequency = 800, q = 2.0 })
    local filterC = osga.sound.filter.new('highpass', { frequency = 300, q = 1.5 })

    soundChannels.a:addEffect(filterA)
    soundChannels.b:addEffect(filterB)
    soundChannels.c:addEffect(filterC)

    -- Register channels with the sound system
    osga.sound.addChannel(soundChannels.a)
    osga.sound.addChannel(soundChannels.b)
    osga.sound.addChannel(soundChannels.c)

    print("Sounds initialized")
end

function app.draw(koto)
    osga.gfx.clear(0, 0, 0)
    osga.gfx.color(1, 1, 1)

    -- Check for rotary button press to toggle fill mode
    if koto.swR and not prevSwR then
        fillMode = not fillMode
    end
    prevSwR = koto.swR

    local width = osga.system.width
    local height = osga.system.height

    -- Calculate rotation angle from rotary encoder value
    rotaryZ = (koto.rotaryValue / 180 - 1) * math.pi

    -- Get rotation angles from gyro input
    local angleX = koto.gyroY * math.pi / 2
    local angleY = koto.gyroX * math.pi / 2
    local angleZ = rotaryZ

    -- Define cube vertices
    local vertices = {
        { -1, -1, 1 }, { 1, -1, 1 }, { 1, 1, 1 }, { -1, 1, 1 },
        { -1, -1, -1 }, { 1, -1, -1 }, { 1, 1, -1 }, { -1, 1, -1 }
    }

    -- Rotate all vertices
    local rotatedVertices = {}
    for _, vertex in ipairs(vertices) do
        table.insert(rotatedVertices, rotatePoint(vertex, angleX, angleY, angleZ))
    end

    -- Set base color, change when buttons are pressed
    local baseColor = { 1, 1, 1 }

    -- Handle button A (red)
    if koto.swA then
        baseColor = { 1, 0, 0 }
        if not soundChannels.a:isPlaying() then
            soundChannels.a:play()
        end
    else
        soundChannels.a:stop()
    end

    -- Handle button B (green)
    if koto.swB then
        baseColor = { 0, 1, 0 }
        if not soundChannels.b:isPlaying() then
            soundChannels.b:play()
        end
    else
        soundChannels.b:stop()
    end

    -- Handle button C (blue)
    if koto.swC then
        baseColor = { 0, 0, 1 }
        if not soundChannels.c:isPlaying() then
            soundChannels.c:play()
        end
    else
        soundChannels.c:stop()
    end

    -- Draw the cube
    if fillMode then
        -- Sort faces by depth for correct rendering
        local facesWithDepth = {}
        for i, face in ipairs(faces) do
            local centerZ = 0
            for _, vIdx in ipairs(face.vertices) do
                centerZ = centerZ + rotatedVertices[vIdx][3]
            end
            centerZ = centerZ / #face.vertices
            table.insert(facesWithDepth, { face = face, depth = centerZ, index = i })
        end
        table.sort(facesWithDepth, function(a, b) return a.depth < b.depth end)

        -- Draw filled faces
        for _, faceData in ipairs(facesWithDepth) do
            local face = faceData.face
            local normal = calculateNormal(face, rotatedVertices)
            -- Basic lighting calculation
            local lightIntensity = math.abs(normal[3]) * 0.8 + 0.2

            osga.gfx.color(
                baseColor[1] * lightIntensity,
                baseColor[2] * lightIntensity,
                baseColor[3] * lightIntensity
            )

            local points = {}
            for _, vIdx in ipairs(face.vertices) do
                local projected = project(rotatedVertices[vIdx], width, height)
                table.insert(points, projected[1])
                table.insert(points, projected[2])
            end
            osga.gfx.polygon(points, "fill")
        end
    else
        -- Draw wireframe cube
        osga.gfx.color(baseColor)
        local edges = {
            { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 },
            { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
            { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 }
        }

        osga.gfx.lineWidth(2)
        for _, edge in ipairs(edges) do
            local start = project(rotatedVertices[edge[1]], width, height)
            local finish = project(rotatedVertices[edge[2]], width, height)
            osga.gfx.line(start[1], start[2], finish[1], finish[2])
        end
    end

    -- Display debug information
    osga.gfx.color(1, 1, 1)
    osga.gfx.text(string.format("gyroX = %.1f", koto.gyroX), 10, 10)
    osga.gfx.text(string.format("gyroY = %.1f", koto.gyroY), 10, 30)
    osga.gfx.text(string.format("rotary = %.1f", rotaryZ), 10, 50)
    osga.gfx.text("mode = " .. (fillMode and "fill" or "wireframe"), 10, 70)

    -- Show which buttons are pressed
    if koto.swA then osga.gfx.text("A button", 10, 120) end
    if koto.swB then osga.gfx.text("B button", 10, 140) end
    if koto.swC then osga.gfx.text("C button", 10, 160) end
    if koto.swR then osga.gfx.text("R button", 10, 180) end
end

function app.cleanup()
    -- Stop all sounds and remove channels
    if soundChannels.a then
        soundChannels.a:stop()
        osga.sound.removeChannel(soundChannels.a)
    end

    if soundChannels.b then
        soundChannels.b:stop()
        osga.sound.removeChannel(soundChannels.b)
    end

    if soundChannels.c then
        soundChannels.c:stop()
        osga.sound.removeChannel(soundChannels.c)
    end

    print("Hardware Test app cleaned up")
end

return app
