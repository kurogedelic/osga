# src/kage/lua_binding.py
from lupa import LuaRuntime
import time


class KageLuaEngine:
    def __init__(self, kage_instance):
        self.kage = kage_instance
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.frame_interval = 1.0 / 30
        self.last_frame_time = time.time()
        self._setup_api()

    def _setup_api(self):
        # Luaのグローバル環境を取得
        g = self.lua.globals()

        # Kage APIをテーブルとして作成
        kage_table = self.lua.eval('''
        {
            clear = function(c)
                python.kage_clear(c or 0)
            end,
            draw_square = function(x, y, size, is_primary)
                python.kage_draw_square(x, y, size, is_primary or false)
            end
        }
        ''')

        # Python側の関数をLuaから呼び出せるようにする
        python_table = {
            'kage_clear': self.kage.clear,
            'kage_draw_square': self.kage.draw_square
        }
        g.python = python_table
        g.kage = kage_table

    def load_script(self, script_path):
        with open(script_path, 'r') as f:
            self.lua.execute(f.read())

    def run(self):
        if 'init' in self.lua.globals():
            self.lua.globals().init()

        try:
            while True:
                current_time = time.time()

                if 'update' in self.lua.globals():
                    self.lua.globals().update()

                elapsed = time.time() - current_time
                wait_time = self.frame_interval - elapsed
                if wait_time > 0:
                    time.sleep(wait_time)

        except KeyboardInterrupt:
            print("\nScript terminated by user")
