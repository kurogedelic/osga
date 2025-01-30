-- kage_test.lua
function init()
    print("Initializing script...")
    x = 0
    y = 0
    speed = 4
    kage.clear(1)
end

function update()
    print("Running update... x=" .. x)
    -- 更新処理
    x = x + speed
    if x > 320 - 8 then
        x = 0
    end

    -- 描画処理
    kage.clear(0) -- 黒背景
    kage.draw_square(x, y, 8, true)
end
