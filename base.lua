FonzAppraiser = {}
local A = FonzAppraiser

local D = FonzAppraiser_Locale_Data
A._locale = setmetatable(D[D.code] or {}, 
  { 
    -- Cache new items. Use the search key as the value. 
    -- Warn of missing locale data during development.
    __index = function(tab, key)
                local value = tostring(key)
                rawset(tab, key, value)
                if A.debug then A.debug("Unknown locale item: [%s]", value) end
                return value
              end
  })
A.locale = setmetatable({},
  {
    -- Read-only proxy to actual locale data. 
    -- Fallback to search key as the value when the value is true boolean.
    __index = function(tab, key)
                local value = A._locale[key]
                return value == true and tostring(key) or value
              end,
    __newindex = function() end
  })
local L = FonzAppraiser.locale

A.name = "FonzAppraiser"
A.folder_name = A.name
A.version = GetAddOnMetadata(A.folder_name, "Version")
A.addon_path = [[Interface\AddOns\]] .. A.folder_name

local _G = getfenv(0)

-- WoW Interface - keybinds (descriptions localized)
_G["BINDING_HEADER_FONZAPPRAISER"] = GetAddOnMetadata(A.folder_name, "Title")
_G["BINDING_NAME_FA_SHOWMAIN"] = L["BINDING_NAME_FA_SHOWMAIN"]
_G["BINDING_NAME_FA_STARTSESSION"] = L["BINDING_NAME_FA_STARTSESSION"]
_G["BINDING_NAME_FA_STOPSESSION"] = L["BINDING_NAME_FA_STOPSESSION"]