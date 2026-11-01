"""Run Lua 5.4 contracts and syntax checks using the system shared library.

Domain boundaries are simulated; this does not claim SQL/FiveM acceptance.
Run: python3 tests/run.py
"""
import ctypes
import ctypes.util
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FEATHER = ROOT.parents[1] / '[feather]'
os.chdir(ROOT)
lua = ctypes.CDLL(ctypes.util.find_library('lua5.4'))
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]

def run(path, execute=False):
    state = lua.luaL_newstate()
    try:
        lua.luaL_openlibs(state)
        status = lua.luaL_loadfilex(state, str(path).encode(), None)
        if status == 0 and execute:
            status = lua.lua_pcallk(state, 0, 0, 0, 0, None)
        if status:
            raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
    finally:
        lua.lua_close(state)

files = list(ROOT.rglob('*.lua')) + [
    FEATHER / 'feather-inventory/config.lua',
    FEATHER / 'feather-jobs/config.lua',
    FEATHER / 'feather-weapons/fivem/config.lua',
]
for path in files:
    run(path)
print(f'Syntax: {len(files)} Lua files passed', flush=True)
for name in ('service_spec.lua', 'client_spec.lua', 'rpc_contract_spec.lua', 'interaction_spec.lua', 'diagnostics_spec.lua'):
    run(ROOT / 'tests' / name, execute=True)
