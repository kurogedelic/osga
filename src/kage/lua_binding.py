# src/kage/lua_binding.py
from lupa import LuaRuntime
import time


class KageLuaEngine:
    def __init__(self, kage_instance):
        self.kage = kage_instance
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.setup_api()
        self.frame_interval = 1.0 / 30  # 30 FPS
        self.last_frame_time = time.time()

    def setup_api(self):
        g = self.lua.globals()
        g.print = print
        # Kage APIをテーブルとして提供
        kage_api = {
            'clear': self.kage.clear,
            'draw_square': self.kage.draw_square,
            'draw_text': self.kage.draw_text
        }
        g.kage = kage_api

    def load_script(self, script_path):
        with open(script_path, 'r') as f:
            self.lua.execute(f.read())

    def run(self):
        # 初期化関数の呼び出し
        if 'init' in self.lua.globals():
            self.lua.globals().init()

        try:
            while True:
                current_time = time.time()

                # updateの呼び出し
                if 'update' in self.lua.globals():
                    self.lua.globals().update()

                # フレームレート制御
                elapsed = time.time() - current_time
                wait_time = self.frame_interval - elapsed
                if wait_time > 0:
                    time.sleep(wait_time)

        except KeyboardInterrupt:
            print("\nScript terminated by user")
