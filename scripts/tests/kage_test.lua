-- kage_test.lua
function init()
    print("Starting OSGA Graphics Test")

    -- サイズ取得
    width, height = kage.getSize()
    print("Display size:", width, "x", height)
end

function update()
    -- 基本操作テスト
    kage.clear(1) -- 白で消去

    -- 図形描画テスト
    -- 左上: 基本図形
    kage.setColor(2) -- プライマリカラー
    kage.drawPixel(10, 10)
    kage.drawLine(20, 10, 50, 40)
    kage.drawRect(60, 10, 30, 30)
    kage.fillRect(100, 10, 30, 30)

    -- 右上: 円と三角形
    kage.setColor(0) -- 黒
    kage.fillCircle(200, 40, 20)
    kage.setColor(2)
    kage.drawCircle(250, 40, 20)
    kage.drawTriangle(280, 20, 310, 20, 295, 50)

    -- 中央: テキスト
    kage.setColor(0)
    kage.setFontSize(3)
    kage.drawText(100, 100, "OSGA Test")
    kage.setFontSize(2)
    kage.drawText(100, 130, "Graphics API")
    kage.setFontSize(1)
    kage.drawText(100, 150, "Version 0.1")

    -- 左下: 多角形
    pts = { { 20, 180 }, { 50, 180 }, { 60, 200 }, { 40, 220 }, { 10, 210 } }
    kage.setColor(2)
    kage.drawPolygon(pts)

    -- 右下: アークと楕円
    kage.drawArc(200, 200, 30, 0, math.pi)
    kage.drawEllipse(280, 200, 30, 20)

    -- バッファを更新
    kage.sendBuffer()
end
