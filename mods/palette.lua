local A = FonzAppraiser

A.module 'fa.palette'

function M.c(r, g, b, a)
  if not a then a = 1 end
  
  local mt = {
    __metatable=false,
    __newindex=pass,
    color={ r, g, b, a },
  }
  
  function mt:__call(text)
		local r, g, b, a = unpack(mt.color)
		if text then
			return format("|c%02X%02X%02X%02X", a, r, g, b) 
        .. tostring(text) .. FONT_COLOR_CODE_CLOSE
		else
			return r/255, g/255, b/255, a
		end
  end
  
  function mt:__concat(text)
		local r, g, b, a = unpack(mt.color)
		return format("|c%02X%02X%02X%02X", a, r, g, b) .. tostring(text)
  end
  
  return setmetatable({}, mt)
end

--[[
  Globals from FrameXML/Fonts.xml:
  
  NORMAL_FONT_COLOR = {r=1.0, g=0.82, b=0};
  HIGHLIGHT_FONT_COLOR = {r=1.0, g=1.0, b=1.0};
  GRAY_FONT_COLOR = {r=0.5, g=0.5, b=0.5};
  GREEN_FONT_COLOR = {r=0.1, g=1.0, b=0.1};
  RED_FONT_COLOR = {r=1.0, g=0.1, b=0.1};
  PASSIVE_SPELL_FONT_COLOR = {r=0.77, g=0.64, b=0};
--]]

M.color = {
  transparent = c(0, 0, 0, 0),
  original = c(255, 255, 255),
  
  black = c(0, 0, 0),
  white = c(255, 255, 255),
	red = c(255, 0, 0),
	green = c(0, 255, 0),
	blue = c(0, 0, 255),
  blue1 = c(102, 178, 255),
  blue2 = c(153, 204, 255),
  
  black_trans10 = c(0, 0, 0, 0.1),
  black_trans50 = c(0, 0, 0, 0.5),
  brown = c(179, 38, 13),
	gold = c(255, 255, 154),
	gray = c(187, 187, 187),
  grey = c(187, 187, 187),
  nero1 = c(24, 24, 24),
  nero2 = c(30, 30, 30),
  nero3 = c(42, 42, 42),
  orange = c(255, 146, 24),
	yellow = c(255, 255, 13),
  
  gold_text = c(255, 209, 0),
  white_text = c(255, 255, 255),
  
  backdrop = {
    none = {},
    window = { background = c(24, 24, 24, .93), border = c(30, 30, 30, 1) },
    panel = { background = c(24, 24, 24, 1), border = c(255, 255, 255, .03) },
    content = { background = c(42, 42, 42, 1), border = c(0, 0, 0, 0) },
  },
  
  rarity = {
    poor = c(157, 157, 157),
    common = c(255, 255, 255),
    uncommon = c(30, 255, 0),
    rare = c(0, 112, 221),
    epic = c(163, 53, 238),
    legendary = c(255, 128, 0),
  },
}