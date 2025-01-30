# main.py 全修正
from src.kage import Kage
import time


def main():
    try:
        print("Initializing Kage...")
        kage = Kage()
        print("Kage initialized")

        kage.clear(0)  # 画面を黒でクリア

        # 白丸の描画
        kage.set_color(1)
        kage.fill_circle(160, 120, 100)

        # テキストの描画
        kage.set_font_size(0)
        kage.draw_text(100, 100, "osga")
        kage.send_buffer()

        time.sleep(3)  # 3秒間表示

        print("Test completed. Press Ctrl+C to exit.")
        while True:
            time.sleep(0.1)

    except KeyboardInterrupt:
        print("\nTest terminated by user")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
