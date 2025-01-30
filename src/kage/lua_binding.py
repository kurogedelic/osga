# src/kage/lua_binding.py
from lupa import LuaRuntime
import time


def create_kage_env(kage_instance):
    lua = LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()

    def clear():
        kage_instance.clear()

    def draw_square(x, y, size, is_primary=False):
        kage_instance.draw_square(x, y, size, is_primary)
        kage_instance.draw_buffer()

    def draw_text(text, x=None, y=None, center=False):
        kage_instance.draw_text(text, x, y, center)
        kage_instance.draw_buffer()

    def sleep(seconds):
        time.sleep(float(seconds))

    # グローバル関数として登録
    g.clear = clear
    g.draw_square = draw_square
    g.draw_text = draw_text
    g.sleep = sleep  # sleep関数を追加

    return lua
