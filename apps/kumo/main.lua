-- apps/kumo/main.lua
local app = {}

app._meta = {
    name = "Kumo",
    slug = "kumo",
    author = "System",
    version = "1.1.0"
}

-- App management
local installedApps = {}
local selectedIndex = 1
local appLaunchRequested = false
local selectedApp = nil
local defaultIcon = nil

-- Grid configuration
local GRID_COLS = 4
local ICON_SIZE = 64
local PADDING = 20
local VISIBLE_ROWS = 2
local ROW_HEIGHT = ICON_SIZE + PADDING + 2

-- Scrolling variables
local scrollPosition = 0
local targetScrollPosition = 0
local scrollAnimationStart = 0
local scrollAnimationDuration = 0.3 -- アニメーション期間（秒）

-- Icon positioning
local startX = 24 + (320 - (GRID_COLS * (ICON_SIZE + PADDING))) / 2
local startY = 34

-- Icon sizes cache
local iconSizes = {}

-- Touch handling
local touchData = {
    startX = 0,
    startY = 0,
    startScroll = 0,
    isDragging = false,
    tapTime = 0
}

-- デバッグ用変数
local debug = {
    selectedRow = 0,
    totalRows = 0,
    maxScroll = 0,
    scrolling = false
}

-- ここに_G.loadAppのローカル版を追加（osga-sim/main.luaまたはosga-run/main.luaで定義されている関数）
local function loadApp(appPath)
    if _G.loadApp then
        return _G.loadApp(appPath) -- グローバル関数を呼び出し
    else
        print("Error: _G.loadApp function not found")
        return false
    end
end

-- Helper functions
local function getAbsolutePath(path)
    return osga.paths.root .. "/" .. path
end

local function readFile(path)
    local file = io.open(getAbsolutePath(path), "r")
    if not file then
        print("Failed to open file:", getAbsolutePath(path))
        return nil
    end
    local content = file:read("*all")
    file:close()
    return content
end

local function parseJSON(str)
    local orderedKeys = {}
    for key in str:gmatch('"([^"]+)"%s*:') do
        table.insert(orderedKeys, key)
    end

    str = str:gsub('"([^"]-)"%s*:%s*', "[%1]=")
    str = str:gsub('%[([^%]]-)%]', "['%1']")
    local chunk = load("return " .. str)
    if chunk then
        local data = chunk()
        return data, orderedKeys
    end
    return nil, nil
end

local function loadAppIcon(appPath)
    local iconPath = getAbsolutePath(appPath .. "/icon.png")
    print("Trying to load icon from:", iconPath)

    local file = io.open(iconPath, "rb")
    if file then
        print("File exists at:", iconPath)
        local data = file:read("*all")
        file:close()

        local success, fileData = pcall(love.filesystem.newFileData, data, "icon.png")
        if success then
            local success2, icon = pcall(love.graphics.newImage, fileData)
            if success2 then
                print("Successfully loaded icon:", iconPath)
                -- Save icon size
                iconSizes[appPath] = {
                    width = icon:getWidth(),
                    height = icon:getHeight()
                }
                return icon
            end
        end
    end

    print("Failed to load icon:", iconPath, ". Using default icon.")
    return defaultIcon
end

-- Calculate total number of rows needed
local function calculateTotalRows()
    return math.ceil(#installedApps / GRID_COLS)
end

-- Calculate maximum scroll position
local function getMaxScrollPosition()
    local totalRows = calculateTotalRows()
    local maxScroll = math.max(0, totalRows - VISIBLE_ROWS)
    return maxScroll * ROW_HEIGHT
end

-- 簡易版スクロール位置更新
local function updateScrollPositionForSelection(force)
    local row = math.floor((selectedIndex - 1) / GRID_COLS)
    local totalRows = calculateTotalRows()

    -- デバッグ情報の更新
    debug.selectedRow = row
    debug.totalRows = totalRows
    debug.maxScroll = getMaxScrollPosition()

    print("Selected Row: " .. row .. ", Total Rows: " .. totalRows)

    -- スクロールが必要かどうかを確認
    if totalRows > VISIBLE_ROWS then
        debug.scrolling = true

        -- 1行目は常にトップに固定
        if row == 0 then
            targetScrollPosition = 0
            -- 2行目もトップに表示
        elseif row == 1 then
            targetScrollPosition = 0
            -- 3行目以降は2行目に表示されるように調整
        elseif row >= 2 then
            targetScrollPosition = (row - 1) * ROW_HEIGHT
            print("Scrolling to row " .. row .. ", Target position: " .. targetScrollPosition)
        end

        -- 最大スクロール位置を超えないように調整
        local maxScroll = getMaxScrollPosition()
        targetScrollPosition = math.max(0, math.min(targetScrollPosition, maxScroll))

        -- 強制更新または位置変更があった場合にアニメーション開始
        if force or scrollPosition ~= targetScrollPosition then
            scrollAnimationStart = love.timer.getTime()
            print("Animation started, target: " .. targetScrollPosition)
        end
    else
        debug.scrolling = false
        targetScrollPosition = 0
    end
end

function app.init()
    print("Initializing Kumo")

    -- Initialize tables
    iconSizes = {}
    installedApps = {}
    selectedIndex = 1
    scrollPosition = 0
    targetScrollPosition = 0

    -- Load default icon
    local defaultIconPath = getAbsolutePath("osga-sim/assets/default_icon.png")
    local file = io.open(defaultIconPath, "rb")
    if file then
        local data = file:read("*all")
        file:close()
        local fileData = love.filesystem.newFileData(data, "default_icon.png")
        defaultIcon = love.graphics.newImage(fileData)
        -- Save default icon size
        iconSizes["default"] = {
            width = defaultIcon:getWidth(),
            height = defaultIcon:getHeight()
        }
        print("Default icon loaded successfully")
    else
        print("Error: Could not load default icon from", defaultIconPath)
        return
    end

    -- Load app list
    local content = readFile("apps/installed.json")
    if not content then
        print("Error: Could not read installed.json")
        return
    end

    print("Read installed.json content:", content)

    -- Parse app list
    local apps, orderedKeys = parseJSON(content)
    if not apps or not orderedKeys then
        print("Error: Could not parse installed.json")
        return
    end

    -- Load app icons and metadata
    for _, shortcode in ipairs(orderedKeys) do
        if shortcode ~= "kumo" then
            local appPath = "apps/" .. shortcode
            local icon = loadAppIcon(appPath)
            table.insert(installedApps, {
                shortcode = shortcode,
                name = apps[shortcode],
                icon = icon,
                path = appPath
            })
            print("Loaded app:", shortcode)
        end
    end

    -- 初期化時にスクロール位置を計算
    updateScrollPositionForSelection(true)
end

function app.draw(koto)
    love.graphics.clear(0.1, 0.1, 0.1, 1)

    -- スクロールアニメーションの更新（シンプル化）
    local currentTime = love.timer.getTime()
    local elapsed = currentTime - scrollAnimationStart
    local t = math.min(1.0, elapsed / scrollAnimationDuration)

    -- シンプルなアニメーション（線形補間）
    local oldPosition = scrollPosition
    scrollPosition = oldPosition + (targetScrollPosition - oldPosition) * t

    -- アニメーションが終了したらピッタリに合わせる
    if t >= 1.0 then
        scrollPosition = targetScrollPosition
    end

    -- スクロール可能かどうかを確認
    local totalRows = calculateTotalRows()
    local isScrollable = totalRows > VISIBLE_ROWS

    -- アプリアイコンの描画（スクロール範囲内のみ）
    love.graphics.setScissor(0, startY, 320, VISIBLE_ROWS * ROW_HEIGHT)

    for i, app in ipairs(installedApps) do
        local row = math.floor((i - 1) / GRID_COLS)
        local col = (i - 1) % GRID_COLS
        local x = startX + col * (ICON_SIZE + 8)
        local y = startY + (row * ROW_HEIGHT) - scrollPosition

        -- 表示域付近のアイコンのみ描画
        if y > -ROW_HEIGHT and y < startY + (VISIBLE_ROWS + 1) * ROW_HEIGHT then
            -- 選択中のアイコンのハイライト
            if i == selectedIndex then
                love.graphics.setColor(0.3, 0.3, 0.3)
                love.graphics.rectangle("fill",
                    x - 4, y - 4,
                    ICON_SIZE + 8, ICON_SIZE + 20
                )
            end

            -- アイコン描画
            love.graphics.setColor(1, 1, 1, 1.0)
            if app.icon then
                -- アイコンの有効性チェック
                local valid = pcall(function() return app.icon:type() == "Image" end)

                if valid then
                    local iconWidth, iconHeight
                    if pcall(function()
                            iconWidth = app.icon:getWidth()
                            iconHeight = app.icon:getHeight()
                            return true
                        end) then
                        -- サイズ取得成功
                        love.graphics.draw(app.icon, x, y, 0,
                            ICON_SIZE / iconWidth,
                            ICON_SIZE / iconHeight
                        )
                    elseif iconSizes[app.path] then
                        -- キャッシュしたサイズを使用
                        love.graphics.draw(app.icon, x, y, 0,
                            ICON_SIZE / iconSizes[app.path].width,
                            ICON_SIZE / iconSizes[app.path].height
                        )
                    else
                        -- 必要に応じてアイコン再ロード
                        app.icon = loadAppIcon(app.path)
                        if app.icon then
                            love.graphics.draw(app.icon, x, y, 0,
                                ICON_SIZE / iconSizes[app.path].width,
                                ICON_SIZE / iconSizes[app.path].height
                            )
                        end
                    end
                else
                    -- 無効なアイコンは再ロード
                    app.icon = loadAppIcon(app.path)
                    if app.icon then
                        love.graphics.draw(app.icon, x, y, 0,
                            ICON_SIZE / iconSizes[app.path].width,
                            ICON_SIZE / iconSizes[app.path].height
                        )
                    end
                end
            end

            -- アプリ名の描画
            love.graphics.printf(
                app.name,
                x - PADDING / 2,
                y + ICON_SIZE + 2,
                ICON_SIZE + PADDING,
                "center"
            )
        end
    end

    -- スクリッサ終了
    love.graphics.setScissor()

    -- スクロール可能な場合のインジケータ表示
    if isScrollable then
        local maxScroll = getMaxScrollPosition()
        if maxScroll <= 0 then
            maxScroll = 1 -- ゼロ除算防止
        end

        -- スクロールバー背景
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        love.graphics.rectangle("fill",
            315,
            startY,
            5,
            VISIBLE_ROWS * ROW_HEIGHT
        )

        -- スクロールバーハンドル
        local scrollRatio = scrollPosition / maxScroll
        local handleHeight = (VISIBLE_ROWS * ROW_HEIGHT) * (VISIBLE_ROWS / totalRows)
        local handleY = startY + scrollRatio * ((VISIBLE_ROWS * ROW_HEIGHT) - handleHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill",
            315,
            handleY,
            5,
            handleHeight
        )

        -- 上下スクロール可能インジケータ
        if scrollPosition > 0 then
            -- 上スクロール可能インジケータ
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.polygon("fill",
                300, startY + 10,
                310, startY + 20,
                290, startY + 20
            )
        end

        if scrollPosition < maxScroll - 1 then
            -- 下スクロール可能インジケータ
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.polygon("fill",
                300, startY + VISIBLE_ROWS * ROW_HEIGHT - 10,
                310, startY + VISIBLE_ROWS * ROW_HEIGHT - 20,
                290, startY + VISIBLE_ROWS * ROW_HEIGHT - 20
            )
        end
    end
    love.graphics.setColor(1, 1, 1, 1.0)
    -- デバッグ情報の表示（オプション）
    --[[
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print(
        "Row: " .. debug.selectedRow ..
        " Total: " .. debug.totalRows ..
        " Scroll: " .. math.floor(scrollPosition) ..
        "/" .. math.floor(debug.maxScroll),
        10, 5
    )
    --]]

    -- ロータリーエンコーダの処理
    local oldIndex = selectedIndex
    if koto.rotaryInc then
        -- 下に移動
        selectedIndex = selectedIndex + 1
        if selectedIndex > #installedApps then
            selectedIndex = 1
        end
    elseif koto.rotaryDec then
        -- 上に移動
        selectedIndex = selectedIndex - 1
        if selectedIndex < 1 then
            selectedIndex = #installedApps
        end
    end

    -- インデックスが変更された場合のみスクロール位置を更新
    if oldIndex ~= selectedIndex then
        updateScrollPositionForSelection(false)
    end

    -- アプリ起動リクエスト処理
    if koto.swA and not appLaunchRequested then
        selectedApp = installedApps[selectedIndex]
        if selectedApp then
            print("Requesting app launch:", selectedApp.shortcode)
            appLaunchRequested = true
            return
        end
    end

    -- ボタンリリース時のアプリ起動
    if appLaunchRequested and not koto.swA then
        print("Launching app:", selectedApp.shortcode)
        loadApp(selectedApp.path)
        appLaunchRequested = false
        selectedApp = nil
    end
end

function app.cleanup()
    -- 参照のみクリア、リソースは解放しない
    installedApps = {}
    -- iconSizesはキャッシュとして保持
    print("Kumo app cleaned up")
end

-- Touch support functions
function app.touchpressed(id, x, y, dx, dy, pressure)
    touchData.startX = x
    touchData.startY = y
    touchData.startScroll = scrollPosition
    touchData.isDragging = false
    touchData.tapTime = love.timer.getTime()
end

function app.touchmoved(id, x, y, dx, dy, pressure)
    if touchData.startY then
        local deltaY = y - touchData.startY
        
        -- Start dragging if moved enough
        if math.abs(deltaY) > 5 then
            touchData.isDragging = true
        end
        
        -- Update scroll position while dragging
        if touchData.isDragging then
            local newScroll = touchData.startScroll - deltaY
            local maxScroll = getMaxScrollPosition()
            scrollPosition = math.max(0, math.min(newScroll, maxScroll))
            targetScrollPosition = scrollPosition
        end
    end
end

function app.touchreleased(id, x, y, dx, dy, pressure)
    local tapDuration = love.timer.getTime() - touchData.tapTime
    
    -- Check if it's a tap (not a drag and quick)
    if not touchData.isDragging and tapDuration < 0.3 then
        -- Check which app was tapped
        for i, appData in ipairs(installedApps) do
            local row = math.floor((i - 1) / GRID_COLS)
            local col = (i - 1) % GRID_COLS
            local iconX = startX + col * (ICON_SIZE + 8)
            local iconY = startY + (row * ROW_HEIGHT) - scrollPosition
            
            -- Check if tap is within icon bounds
            if x >= iconX and x <= iconX + ICON_SIZE and
               y >= iconY and y <= iconY + ICON_SIZE + 20 then
                selectedIndex = i
                -- Launch the app
                selectedApp = installedApps[selectedIndex]
                if selectedApp then
                    loadApp(selectedApp.path)
                end
                break
            end
        end
    end
    
    -- Reset touch data
    touchData.startX = 0
    touchData.startY = 0
    touchData.isDragging = false
end

return app
