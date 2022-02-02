local A = AceLibrary("AceAddon-2.0"):new("AceDebug-2.0", "AceConsole-2.0",
  "AceDB-2.0", "AceEvent-2.0", "AceHook-2.1", "FuBarPlugin-2.0")
FonzAppraiser = A

A:RegisterDB("FonzAppraiserDB", "FonzAppraiserCDB", "char")

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local _G = getfenv(0)

-- WoW Interface - keybinds (localized)
_G["BINDING_HEADER_FONZAPPRAISER"] = "FonzAppraiser"
_G["BINDING_NAME_FA_SHOWMAIN"] = L["BINDING_NAME_FA_SHOWMAIN"]
_G["BINDING_NAME_FA_STARTSESSION"] = L["BINDING_NAME_FA_STARTSESSION"]
_G["BINDING_NAME_FA_STOPSESSION"] = L["BINDING_NAME_FA_STOPSESSION"]

A.ver = "1.0.0"
A.addon_path = [[Interface\AddOns\FonzAppraiser]]
A.loglevels = {
  FATAL=0, -- kills the service [very rare in a hosted application like WoW]
  ERROR=1, -- kills the application [minimum logging for releases]
  WARN=2,  -- unwanted, but potentially recoverable, state
  INFO=3,  -- configuration or administration detail
  TRACE=4, -- developer: path detail
  DEBUG=5, -- developer: state detail
}
A.loglevel = A.loglevels["ERROR"]

function A.logging(level)
  return A.loglevel >= A.loglevels[level]
end
