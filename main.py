from src.kage import Kage
import time


def main():
    try:
        print("Initializing Kage...")
        kage = Kage()
        print("Kage initialized")

        # 基本的な描画テスト
        print("Starting display test...")

        # 画面クリア（黒）
        kage.clear(0)
        time.sleep(1)

        # 赤い四角形
        kage.set_color(1)  # 修正: setColor → set_color
        kage.fill_rect(10, 10, 50, 50)  # 修正: drawBox → fill_rect
        kage.send_buffer()
        time.sleep(1)

        # 緑の四角形
        kage.set_color(2)  # カラーパレット2番を緑に設定（後述の注意点参照）
        kage.fill_rect(70, 10, 50, 50)
        kage.send_buffer()
        time.sleep(1)

        print("Test completed. Press Ctrl+C to exit.")
        while True:
            time.sleep(0.1)

    except KeyboardInterrupt:
        print("\nTest terminated by user")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
