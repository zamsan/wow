"""Run isolated Lua tests through the system Lua shared library."""

import ctypes
import sys


# Run a Lua file with the installed shared library and return its status.
def main(path):
	lua = ctypes.CDLL("liblua5.4.so.0")
	lua.luaL_newstate.restype = ctypes.c_void_p
	lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
	lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
	lua.luaL_loadfilex.restype = ctypes.c_int
	lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
	lua.lua_pcallk.restype = ctypes.c_int
	lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
	lua.lua_tolstring.restype = ctypes.c_char_p
	lua.lua_close.argtypes = [ctypes.c_void_p]
	state = lua.luaL_newstate()
	try:
		lua.luaL_openlibs(state)
		status = lua.luaL_loadfilex(state, path.encode(), None)
		if status == 0:
			status = lua.lua_pcallk(state, 0, -1, 0, 0, None)
		if status != 0:
			message = lua.lua_tolstring(state, -1, None)
			print(message.decode() if message else "Lua error", file=sys.stderr)
		return status
	finally:
		lua.lua_close(state)


if __name__ == "__main__":
	sys.exit(main(sys.argv[1]))
