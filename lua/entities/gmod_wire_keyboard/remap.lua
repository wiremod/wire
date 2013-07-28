Wire_Keyboard_Remap = {}

----------------------------------------------------------------------
-- Default - Keys that all layouts use
----------------------------------------------------------------------

local Wire_Keyboard_Remap_default = {}
Wire_Keyboard_Remap_default.normal = {}
Wire_Keyboard_Remap_default[KEY_LSHIFT] = {}
Wire_Keyboard_Remap_default[KEY_RSHIFT] = Wire_Keyboard_Remap_default[KEY_LSHIFT]
local remap = Wire_Keyboard_Remap_default.normal
remap[KEY_NONE] = ""
remap[KEY_0] = "0"
remap[KEY_1] = "1"
remap[KEY_2] = "2"
remap[KEY_3] = "3"
remap[KEY_4] = "4"
remap[KEY_5] = "5"
remap[KEY_6] = "6"
remap[KEY_7] = "7"
remap[KEY_8] = "8"
remap[KEY_9] = "9"
remap[KEY_A] = "a"
remap[KEY_B] = "b"
remap[KEY_C] = "c"
remap[KEY_D] = "d"
remap[KEY_E] = "e"
remap[KEY_F] = "f"
remap[KEY_G] = "g"
remap[KEY_H] = "h"
remap[KEY_I] = "i"
remap[KEY_J] = "j"
remap[KEY_K] = "k"
remap[KEY_L] = "l"
remap[KEY_M] = "m"
remap[KEY_N] = "n"
remap[KEY_O] = "o"
remap[KEY_P] = "p"
remap[KEY_Q] = "q"
remap[KEY_R] = "r"
remap[KEY_S] = "s"
remap[KEY_T] = "t"
remap[KEY_U] = "u"
remap[KEY_V] = "v"
remap[KEY_W] = "w"
remap[KEY_X] = "x"
remap[KEY_Y] = "y"
remap[KEY_Z] = "z"
remap[KEY_PAD_0] 		= 128
remap[KEY_PAD_1] 		= 129
remap[KEY_PAD_2] 		= 130
remap[KEY_PAD_3] 		= 131
remap[KEY_PAD_4] 		= 132
remap[KEY_PAD_5] 		= 133
remap[KEY_PAD_6] 		= 134
remap[KEY_PAD_7] 		= 135
remap[KEY_PAD_8] 		= 136
remap[KEY_PAD_9] 		= 137
remap[KEY_PAD_DIVIDE] 	= 138
remap[KEY_PAD_MULTIPLY] = 139
remap[KEY_PAD_MINUS] 	= 140
remap[KEY_PAD_PLUS] 	= 141
remap[KEY_PAD_ENTER] 	= 142
remap[KEY_PAD_DECIMAL]  = 143
remap[KEY_ENTER] 		= 13
remap[KEY_SPACE] 		= " "
remap[KEY_BACKSPACE] 	= 127
remap[KEY_TAB] 			= 9
remap[KEY_CAPSLOCK] 	= 144
remap[KEY_NUMLOCK] 		= 145
remap[KEY_ESCAPE] 		= 18
remap[KEY_SCROLLLOCK] 	= 146
remap[KEY_INSERT] 		= 147
remap[KEY_DELETE] 		= 148
remap[KEY_HOME] 		= 149
remap[KEY_END] 			= 150
remap[KEY_PAGEUP] 		= 151
remap[KEY_PAGEDOWN] 	= 152
remap[KEY_BREAK] 		= 153
remap[KEY_LSHIFT] 		= 154
remap[KEY_RSHIFT] 		= 155
remap[KEY_LALT] 		= 156
remap[KEY_RALT] 		= 157
remap[KEY_LCONTROL] 	= 158
remap[KEY_RCONTROL] 	= 159
remap[KEY_LWIN] 		= 160
remap[KEY_RWIN] 		= 161
remap[KEY_APP] 			= 162
remap[KEY_UP] 			= 17
remap[KEY_LEFT] 		= 19
remap[KEY_DOWN] 		= 18
remap[KEY_RIGHT] 		= 20
remap[KEY_F1] 			= 163
remap[KEY_F2] 			= 164
remap[KEY_F3] 			= 165
remap[KEY_F4] 			= 166
remap[KEY_F5] 			= 167
remap[KEY_F6] 			= 168
remap[KEY_F7] 			= 169
remap[KEY_F8] 			= 170
remap[KEY_F9] 			= 171
remap[KEY_F10] 			= 172
remap[KEY_F11] 			= 173
remap[KEY_F12] 				= 174
remap[KEY_CAPSLOCKTOGGLE]	= 175
remap[KEY_NUMLOCKTOGGLE]	= 176
remap[KEY_SCROLLLOCKTOGGLE]	= 177
remap[KEY_XBUTTON_UP] 		= 200
remap[KEY_XBUTTON_DOWN]		= 201
remap[KEY_XBUTTON_LEFT]		= 202
remap[KEY_XBUTTON_RIGHT]	= 203
remap[KEY_XBUTTON_START]	= 204
remap[KEY_XBUTTON_BACK]		= 205
remap[KEY_XBUTTON_STICK1]	= 206
remap[KEY_XBUTTON_STICK2]	= 207
remap[KEY_XBUTTON_A] 		= 208
remap[KEY_XBUTTON_B] 		= 209
remap[KEY_XBUTTON_X] 		= 210
remap[KEY_XBUTTON_Y] 		= 211
remap[KEY_XBUTTON_LTRIGGER] 	= 214
remap[KEY_XBUTTON_RTRIGGER] 	= 215
remap[KEY_XSTICK1_UP] 		= 216
remap[KEY_XSTICK1_DOWN] 	= 217
remap[KEY_XSTICK1_LEFT] 	= 218
remap[KEY_XSTICK1_RIGHT] 	= 219
remap[KEY_XSTICK2_UP] 		= 220
remap[KEY_XSTICK2_DOWN] 	= 221
remap[KEY_XSTICK2_LEFT] 	= 222
remap[KEY_XSTICK2_RIGHT] 	= 223

local remap = Wire_Keyboard_Remap_default[KEY_LSHIFT]
remap[KEY_A] = "A"
remap[KEY_B] = "B"
remap[KEY_C] = "C"
remap[KEY_D] = "D"
remap[KEY_E] = "E"
remap[KEY_F] = "F"
remap[KEY_G] = "G"
remap[KEY_H] = "H"
remap[KEY_I] = "I"
remap[KEY_J] = "J"
remap[KEY_K] = "K"
remap[KEY_L] = "L"
remap[KEY_M] = "M"
remap[KEY_N] = "N"
remap[KEY_O] = "O"
remap[KEY_P] = "P"
remap[KEY_Q] = "Q"
remap[KEY_R] = "R"
remap[KEY_S] = "S"
remap[KEY_T] = "T"
remap[KEY_U] = "U"
remap[KEY_V] = "V"
remap[KEY_W] = "W"
remap[KEY_X] = "X"
remap[KEY_Y] = "Y"
remap[KEY_Z] = "Z"

----------------------------------------------------------------------
-- American
----------------------------------------------------------------------

Wire_Keyboard_Remap.American = {}
Wire_Keyboard_Remap.American = table.Copy(Wire_Keyboard_Remap_default)
Wire_Keyboard_Remap.American[KEY_RSHIFT] = Wire_Keyboard_Remap.American[KEY_LSHIFT]

local remap = Wire_Keyboard_Remap.American.normal
remap[KEY_LBRACKET] 	= "["
remap[KEY_RBRACKET] 	= "]"
remap[KEY_SEMICOLON] 	= ";"
remap[KEY_APOSTROPHE] 	= "'"
remap[KEY_BACKQUOTE] 	= "`"
remap[KEY_COMMA] 		= ","
remap[KEY_PERIOD] 		= "."
remap[KEY_SLASH] 		= "/"
remap[KEY_BACKSLASH] 	= "\\"
remap[KEY_MINUS] 		= "-"
remap[KEY_EQUAL] 		= "="

local remap = Wire_Keyboard_Remap.American[KEY_LSHIFT]
remap[KEY_0] = ")"
remap[KEY_1] = "!"
remap[KEY_2] = "@"
remap[KEY_3] = "#"
remap[KEY_4] = "$"
remap[KEY_5] = "%"
remap[KEY_6] = "^"
remap[KEY_7] = "&"
remap[KEY_8] = "*"
remap[KEY_9] = "("
remap[KEY_LBRACKET] 	= "{"
remap[KEY_RBRACKET] 	= "}"
remap[KEY_SEMICOLON] 	= ":"
remap[KEY_APOSTROPHE] 	= '"'
remap[KEY_COMMA] 		= "<"
remap[KEY_PERIOD] 		= ">"
remap[KEY_SLASH] 		= "?"
remap[KEY_BACKSLASH] 	= "|"
remap[KEY_MINUS] 		= "_"
remap[KEY_EQUAL] 		= "+"

----------------------------------------------------------------------
-- British
----------------------------------------------------------------------

Wire_Keyboard_Remap.British = {}
Wire_Keyboard_Remap.British = table.Copy(Wire_Keyboard_Remap.American)
Wire_Keyboard_Remap.British[83] = {}
Wire_Keyboard_Remap.British[KEY_RSHIFT] = Wire_Keyboard_Remap.British[KEY_LSHIFT]

local remap = Wire_Keyboard_Remap.British.normal
remap[KEY_BACKQUOTE] = "'"
remap[KEY_APOSTROPHE] = "#"

local remap = Wire_Keyboard_Remap.British[KEY_LSHIFT]
remap[KEY_2] = '"'
remap[KEY_3] = "�"
remap[KEY_APOSTROPHE] = "~"
remap[KEY_BACKQUOTE] = "@"

local remap = Wire_Keyboard_Remap.British[83]
remap[KEY_4] = "�"
remap[KEY_A] = "�"
remap[KEY_E] = "�"
remap[KEY_I] = "�"
remap[KEY_O] = "�"
remap[KEY_U] = "�"

----------------------------------------------------------------------
-- Swedish
----------------------------------------------------------------------

Wire_Keyboard_Remap.Swedish = {}
Wire_Keyboard_Remap.Swedish = table.Copy(Wire_Keyboard_Remap_default)
Wire_Keyboard_Remap.Swedish[83] = {} -- KEY_RALT = 82, but didn't work correctly
Wire_Keyboard_Remap.Swedish[KEY_RSHIFT] = Wire_Keyboard_Remap.Swedish[KEY_LSHIFT]

local remap = Wire_Keyboard_Remap.Swedish.normal
remap[KEY_LBRACKET] 	= "�"
remap[KEY_RBRACKET] 	= "�"
remap[KEY_SEMICOLON] 	= "�"
remap[KEY_APOSTROPHE] 	= "�"
remap[KEY_BACKQUOTE] 	= "�"
remap[KEY_COMMA] 		= ","
remap[KEY_PERIOD] 		= "."
remap[KEY_SLASH] 		= "'"
remap[KEY_BACKSLASH] 	= "�"
remap[KEY_MINUS] 		= "-"
remap[KEY_EQUAL] 		= "+"

local remap = Wire_Keyboard_Remap.Swedish[KEY_LSHIFT]
remap[KEY_0] = "="
remap[KEY_1] = "!"
remap[KEY_2] = '"'
remap[KEY_3] = "#"
remap[KEY_4] = "�"
remap[KEY_5] = "%"
remap[KEY_6] = "&"
remap[KEY_7] = "/"
remap[KEY_8] = "("
remap[KEY_9] = ")"
remap[KEY_LBRACKET] 	= "`"
remap[KEY_RBRACKET] 	= "�"
remap[KEY_BACKQUOTE] 	= "�"
remap[KEY_SEMICOLON] 	= "^"
remap[KEY_APOSTROPHE] 	= "�"
remap[KEY_COMMA] 		= ";"
remap[KEY_PERIOD] 		= ":"
remap[KEY_SLASH] 		= "*"
remap[KEY_BACKSLASH] 	= "�"
remap[KEY_MINUS] 		= "_"
remap[KEY_EQUAL] 		= "?"

local remap = Wire_Keyboard_Remap.Swedish[83]
remap[KEY_2] = "@"
remap[KEY_3] = "�"
remap[KEY_4] = "$"
remap[KEY_7] = "{"
remap[KEY_8] = "["
remap[KEY_9] = "]"
remap[KEY_0] = "}"
remap[KEY_EQUAL] = "\\"
remap[KEY_SEMICOLON] = "~"
remap[KEY_E] = "�"

----------------------------------------------------------------------
-- Norwegian
----------------------------------------------------------------------

Wire_Keyboard_Remap.Norwegian = {}
Wire_Keyboard_Remap.Norwegian = table.Copy(Wire_Keyboard_Remap.Swedish)
Wire_Keyboard_Remap.Norwegian[KEY_RSHIFT] = Wire_Keyboard_Remap.Norwegian[KEY_LSHIFT]

local remap = Wire_Keyboard_Remap.Norwegian.normal
remap[KEY_BACKQUOTE] 	= "�"
remap[KEY_APOSTROPHE] 	= "�"
remap[KEY_BACKSLASH] 	= "|"
remap[KEY_LBRACKET] 	= "\\"

local remap = Wire_Keyboard_Remap.Norwegian[KEY_LSHIFT]
remap[KEY_BACKQUOTE] 	= "�"
remap[KEY_APOSTROPHE] 	= "�"
remap[KEY_BACKSLASH] 	= "�"

local remap = Wire_Keyboard_Remap.Norwegian[83]
remap[KEY_EQUAL] = nil
remap[KEY_M] = "�"
remap[KEY_LBRACKET] 		= "�"

----------------------------------------------------------------------
-- German
----------------------------------------------------------------------

Wire_Keyboard_Remap.German				= {}
Wire_Keyboard_Remap.German				= table.Copy(Wire_Keyboard_Remap_default)
Wire_Keyboard_Remap.German[83]			= {} -- KEY_RALT	= 82, but didn't work correctly
Wire_Keyboard_Remap.German[KEY_RSHIFT]	= Wire_Keyboard_Remap.German[KEY_LSHIFT]

local remap = Wire_Keyboard_Remap.German.normal
remap[KEY_LBRACKET]		= "�"
remap[KEY_RBRACKET]		= "�"
remap[KEY_SEMICOLON]	= "�"
remap[KEY_APOSTROPHE]	= "�"
remap[KEY_BACKQUOTE]	= "�"
remap[KEY_COMMA]		= ","
remap[KEY_PERIOD]		= "."
remap[KEY_SLASH]		= "#"
remap[KEY_BACKSLASH]	= "^"
remap[KEY_MINUS]		= "-"
remap[KEY_EQUAL]		= "+"

local remap = Wire_Keyboard_Remap.German[KEY_LSHIFT]
remap[KEY_0]	= "="
remap[KEY_1]	= "!"
remap[KEY_2]	= '"'
remap[KEY_3]	= "�"
remap[KEY_4]	= "$"
remap[KEY_5]	= "%"
remap[KEY_6]	= "&"
remap[KEY_7]	= "/"
remap[KEY_8]	= "("
remap[KEY_9]	= ")"
remap[KEY_LBRACKET]		= "?"
remap[KEY_RBRACKET]		= "`"
remap[KEY_SEMICOLON]	= "�"
remap[KEY_APOSTROPHE]	= '�'
remap[KEY_BACKQUOTE]	= "�"
remap[KEY_COMMA]		= ";"
remap[KEY_PERIOD]		= ":"
remap[KEY_SLASH]		= "'"
remap[KEY_BACKSLASH]	= "�"
remap[KEY_MINUS]		= "_"
remap[KEY_EQUAL]		= "*"

local remap = Wire_Keyboard_Remap.German[83]
remap[KEY_0]	= "}"
remap[KEY_2]	= '�'
remap[KEY_3]	= "�"
remap[KEY_7]	= "{"
remap[KEY_8]	= "["
remap[KEY_9]	= "]"
remap[KEY_E]	= "�"
remap[KEY_M]	= "�"
remap[KEY_Q]	= "@"
remap[KEY_LBRACKET]		= '\\'
remap[KEY_EQUAL]		= "~"
remap[KEY_COMMA]		= "<"
remap[KEY_PERIOD]		= ">"
remap[KEY_MINUS]		= "|"
