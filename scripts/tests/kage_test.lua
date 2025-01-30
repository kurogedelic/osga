-- kage_test.lua
function init()
    x = 0
    y = 0
    speed = 4
end

function update()
    -- 更新処理
    x = x + speed
    if x > 320 - 8 then
        x = 0
    end

    -- 描画処理
    kage.clear()
    kage.draw_square(x, y, 8, true)
end
