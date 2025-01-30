-- kage_test.lua
x = 0
y = 0
speed = 4

function init()
    print("Starting test script")
    kage.clear(1) -- 白で初期化
end

function update()
    x = x + speed
    if x > 320 - 8 then
        x = 0
    end

    kage.clear(0) -- 黒背景
    kage.draw_square(x, y, 8, true)
end
