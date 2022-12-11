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
remap[KEY_ENTER] 		= 10
remap[KEY_SPACE] 		= " "
remap[KEY_BACKSPACE] 	= 127
remap[KEY_TAB] 			= 9
remap[KEY_CAPSLOCK] 	= 144
remap[KEY_NUMLOCK] 		= 145
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
--[[
	-- These are unused
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
]]

remap = Wire_Keyboard_Remap_default[KEY_LSHIFT]
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

remap = Wire_Keyboard_Remap.American.normal
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

remap = Wire_Keyboard_Remap.American[KEY_LSHIFT]
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
Wire_Keyboard_Remap.British[KEY_LCONTROL] = {}
Wire_Keyboard_Remap.British[KEY_RSHIFT] = Wire_Keyboard_Remap.British[KEY_LSHIFT]

remap = Wire_Keyboard_Remap.British.normal
remap[KEY_BACKQUOTE] = "`"
remap[KEY_BACKSLASH] = "#"

remap = Wire_Keyboard_Remap.British[KEY_LSHIFT]
remap[KEY_2] = '"'
remap[KEY_3] = "£"
remap[KEY_APOSTROPHE] = "@"
remap[KEY_BACKQUOTE] = "¬"
remap[KEY_BACKSLASH] = "~"

remap = Wire_Keyboard_Remap.British[KEY_LCONTROL]
remap[KEY_4] = "€"
remap[KEY_A] = "á"
remap[KEY_E] = "é"
remap[KEY_I] = "í"
remap[KEY_O] = "ó"
remap[KEY_U] = "ú"

----------------------------------------------------------------------
-- Russian/Русский
----------------------------------------------------------------------

Wire_Keyboard_Remap.Russian = {}
Wire_Keyboard_Remap.Russian = table.Copy(Wire_Keyboard_Remap_default)
Wire_Keyboard_Remap.Russian[KEY_RSHIFT] = Wire_Keyboard_Remap.Russian[KEY_LSHIFT]

remap = Wire_Keyboard_Remap.Russian.normal
remap[KEY_LBRACKET] 	= "х"
remap[KEY_RBRACKET] 	= "ъ"
remap[KEY_SEMICOLON] 	= "ж"
remap[KEY_APOSTROPHE] 	= "э"
remap[KEY_BACKQUOTE] 	= "ё"
remap[KEY_COMMA] 	= "б"
remap[KEY_PERIOD] 	= "ю"
remap[KEY_SLASH] 	= "."
remap[KEY_BACKSLASH] 	= "\\"
remap[KEY_MINUS] 	= "-"
remap[KEY_EQUAL] 	= "="

remap = Wire_Keyboard_Remap.Russian.normal
remap[KEY_A] 		= "ф"
remap[KEY_B] 		= "и"
remap[KEY_C] 		= "с"
remap[KEY_D] 		= "в"
remap[KEY_E] 		= "у"
remap[KEY_F] 		= "а"
remap[KEY_G] 		= "п"
remap[KEY_H] 		= "р"
remap[KEY_I] 		= "ш"
remap[KEY_J] 		= "о"
remap[KEY_K] 		= "л"
remap[KEY_L] 		= "д"
remap[KEY_M] 		= "ь"
remap[KEY_N] 		= "т"
remap[KEY_O] 		= "щ"
remap[KEY_P] 		= "з"
remap[KEY_Q] 		= "й"
remap[KEY_R] 		= "к"
remap[KEY_S] 		= "ы"
remap[KEY_T] 		= "е"
remap[KEY_U] 		= "г"
remap[KEY_V] 		= "м"
remap[KEY_W] 		= "ц"
remap[KEY_X] 		= "ч"
remap[KEY_Y] 		= "н"
remap[KEY_Z] 		= "я"


remap = Wire_Keyboard_Remap.Russian[KEY_LSHIFT]
remap[KEY_A] 		= "Ф"
remap[KEY_B] 		= "И"
remap[KEY_C] 		= "С"
remap[KEY_D] 		= "В"
remap[KEY_E] 		= "У"
remap[KEY_F] 		= "А"
remap[KEY_G] 		= "П"
remap[KEY_H] 		= "Р"
remap[KEY_I] 		= "Ш"
remap[KEY_J] 		= "О"
remap[KEY_K] 		= "Л"
remap[KEY_L] 		= "Д"
remap[KEY_M] 		= "Ь"
remap[KEY_N] 		= "Т"
remap[KEY_O] 		= "Щ"
remap[KEY_P] 		= "З"
remap[KEY_Q] 		= "Й"
remap[KEY_R] 		= "К"
remap[KEY_S] 		= "Ы"
remap[KEY_T] 		= "Е"
remap[KEY_U] 		= "Г"
remap[KEY_V] 		= "М"
remap[KEY_W] 		= "Ц"
remap[KEY_X] 		= "Ч"
remap[KEY_Y] 		= "Н"
remap[KEY_Z]		= "Я"
remap[KEY_1] 		= '!'
remap[KEY_2] 		= '"'
remap[KEY_3] 		= "№"
remap[KEY_5] 		= '%'
remap[KEY_4] 		= ";"
remap[KEY_6] 		= ":"
remap[KEY_7] 		= "?"
remap[KEY_8] 		= "*"
remap[KEY_9] 		= "("
remap[KEY_0] 		= ")"
remap[KEY_MINUS] 	= "_"
remap[KEY_EQUAL] 	= "+"
remap[KEY_BACKSLASH] 	= "/"
remap[KEY_LBRACKET] 	= "Х"
remap[KEY_RBRACKET] 	= "Ъ"
remap[KEY_SEMICOLON] 	= "Ж"
remap[KEY_APOSTROPHE] 	= "Э"
remap[KEY_BACKQUOTE] 	= "Ё"
remap[KEY_COMMA] 	= "Б"
remap[KEY_PERIOD] 	= "Ю"
remap[KEY_SLASH] 	= ","

----------------------------------------------------------------------
-- Swedish
----------------------------------------------------------------------

Wire_Keyboard_Remap.Swedish = {}
Wire_Keyboard_Remap.Swedish = table.Copy(Wire_Keyboard_Remap_default)
Wire_Keyboard_Remap.Swedish[KEY_LCONTROL] = {} -- Should be KEY_RALT, but that didn't work correctly
Wire_Keyboard_Remap.Swedish[KEY_RSHIFT] = Wire_Keyboard_Remap.Swedish[KEY_LSHIFT]

remap = Wire_Keyboard_Remap.Swedish.normal
remap[KEY_LBRACKET] 	= "´"
remap[KEY_RBRACKET] 	= "å"
remap[KEY_BACKQUOTE] 	= "¨"
remap[KEY_APOSTROPHE] 	= "ä"
remap[KEY_SEMICOLON] 	= "ö"
remap[KEY_COMMA] 		= ","
remap[KEY_PERIOD] 		= "."
remap[KEY_SLASH] 		= "'"
remap[KEY_BACKSLASH] 	= "§"
remap[KEY_MINUS] 		= "-"
remap[KEY_EQUAL] 		= "+"

remap = Wire_Keyboard_Remap.Swedish[KEY_LSHIFT]
remap[KEY_0] = "="
remap[KEY_1] = "!"
remap[KEY_2] = '"'
remap[KEY_3] = "#"
remap[KEY_4] = "¤"
remap[KEY_5] = "%"
remap[KEY_6] = "&"
remap[KEY_7] = "/"
remap[KEY_8] = "("
remap[KEY_9] = ")"
remap[KEY_LBRACKET] 	= "`"
remap[KEY_RBRACKET] 	= "Å"
remap[KEY_SEMICOLON] 	= 214 --"Ö"
remap[KEY_BACKQUOTE] 	= "^" -- doesn't work because garry
remap[KEY_APOSTROPHE] 	= "Ä"
remap[KEY_COMMA] 		= ";"
remap[KEY_PERIOD] 		= ":"
remap[KEY_SLASH] 		= "*"
remap[KEY_BACKSLASH] 	= "½"
remap[KEY_MINUS] 		= "_"
remap[KEY_EQUAL] 		= "?"

remap = Wire_Keyboard_Remap.Swedish[KEY_LCONTROL]
remap[KEY_2] = "@"
remap[KEY_3] = "£"
remap[KEY_4] = "$"
remap[KEY_7] = "{"
remap[KEY_8] = "["
remap[KEY_9] = "]"
remap[KEY_0] = "}"
remap[KEY_EQUAL] = "\\"
remap[KEY_SEMICOLON] = "~"
remap[KEY_E] = "€"

----------------------------------------------------------------------
-- Norwegian
----------------------------------------------------------------------

Wire_Keyboard_Remap.Norwegian = {}
Wire_Keyboard_Remap.Norwegian = table.Copy(Wire_Keyboard_Remap.Swedish)
Wire_Keyboard_Remap.Norwegian[KEY_RSHIFT] = Wire_Keyboard_Remap.Norwegian[KEY_LSHIFT]

remap = Wire_Keyboard_Remap.Norwegian.normal
remap[KEY_BACKQUOTE] 	= "ø"
remap[KEY_APOSTROPHE] 	= "æ"
remap[KEY_BACKSLASH] 	= "|"
remap[KEY_LBRACKET] 	= "\\"

remap = Wire_Keyboard_Remap.Norwegian[KEY_LSHIFT]
remap[KEY_BACKQUOTE] 	= "Ø"
remap[KEY_APOSTROPHE] 	= "Æ"
remap[KEY_BACKSLASH] 	= "§"

remap = Wire_Keyboard_Remap.Norwegian[KEY_LCONTROL]
remap[KEY_EQUAL] = nil
remap[KEY_M] = "µ"
remap[KEY_LBRACKET] 		= "´"

----------------------------------------------------------------------
-- German
----------------------------------------------------------------------

Wire_Keyboard_Remap.German				= {}
Wire_Keyboard_Remap.German				= table.Copy(Wire_Keyboard_Remap_default)
Wire_Keyboard_Remap.German[KEY_LCONTROL]			= {} -- Should be KEY_RALT, but that didn't work correctly
Wire_Keyboard_Remap.German[KEY_RSHIFT]	= Wire_Keyboard_Remap.German[KEY_LSHIFT]

remap = Wire_Keyboard_Remap.German.normal
remap[KEY_LBRACKET]		= "ß"
remap[KEY_RBRACKET]		= "´"
remap[KEY_SEMICOLON]	= "ü"
remap[KEY_APOSTROPHE]	= "ä"
remap[KEY_BACKQUOTE]	= "ö"
remap[KEY_COMMA]		= ","
remap[KEY_PERIOD]		= "."
remap[KEY_SLASH]		= "#"
remap[KEY_BACKSLASH]	= "^"
remap[KEY_MINUS]		= "-"
remap[KEY_EQUAL]		= "+"

remap = Wire_Keyboard_Remap.German[KEY_LSHIFT]
remap[KEY_0]	= "="
remap[KEY_1]	= "!"
remap[KEY_2]	= '"'
remap[KEY_3]	= "§"
remap[KEY_4]	= "$"
remap[KEY_5]	= "%"
remap[KEY_6]	= "&"
remap[KEY_7]	= "/"
remap[KEY_8]	= "("
remap[KEY_9]	= ")"
remap[KEY_LBRACKET]		= "?"
remap[KEY_RBRACKET]		= "`"
remap[KEY_SEMICOLON]	= "Ü"
remap[KEY_APOSTROPHE]	= 'Ä'
remap[KEY_BACKQUOTE]	= "Ö"
remap[KEY_COMMA]		= ";"
remap[KEY_PERIOD]		= ":"
remap[KEY_SLASH]		= "'"
remap[KEY_BACKSLASH]	= "°"
remap[KEY_MINUS]		= "_"
remap[KEY_EQUAL]		= "*"

remap = Wire_Keyboard_Remap.German[KEY_LCONTROL]
remap[KEY_0]	= "}"
remap[KEY_2]	= '²'
remap[KEY_3]	= "³"
remap[KEY_7]	= "{"
remap[KEY_8]	= "["
remap[KEY_9]	= "]"
remap[KEY_E]	= "€"
remap[KEY_M]	= "µ"
remap[KEY_Q]	= "@"
remap[KEY_LBRACKET]		= '\\'
remap[KEY_EQUAL]		= "~"
remap[KEY_COMMA]		= "<"
remap[KEY_PERIOD]		= ">"
remap[KEY_MINUS]		= "|"
