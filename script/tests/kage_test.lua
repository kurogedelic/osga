-- バッファ消去
clear()

-- スクロールテスト
for x = 0, 320 - 8, 4 do
    clear()
    draw_square(x, 100, 8, true) -- primary color
    sleep(0.05)
end

-- 二つの四角形表示
clear()
draw_square(100, 100, 10, false) -- base color
draw_square(120, 100, 10, true)  -- primary color
sleep(1)

-- テキスト表示
clear()
draw_text("Hello osga", nil, nil, true) -- 中央揃え
