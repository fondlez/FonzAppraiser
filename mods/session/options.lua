local A = FonzAppraiser
local L = A.locale

A.module 'fa.session'

local util = A.requires(
  'util.string',
  'util.money'
)

if not A.options then
  A.options = {
    type = "group",
    args = {},
  }
end

A.options.args["Start"] = {
  type = "execute",
  name = L["Session start"],
  desc = L["Starts a session"],
  func = startSessionConfirm,
}
A.options.args["Stop"] = {
  type = "execute",
  name = L["Session stop"],
  desc = L["Stops and terminates a session"],
  func = stopSession,
}
A.options.args["List"] = {
  type = "execute",
  name = L["Sessions list"],
  desc = L["Lists sessions"],
  func = listSessions,
  guiHidden = true,
}
A.options.args["Purge"] = {
  type = "execute",
  name = L["Sessions purge"],
  desc = L["Purge all sessions"],
  func = purgeSessions,
  guiHidden = true,
}
A.options.args["Search"] = {
  type = "text",
  name = L["Search sessions"],
  desc = L["Search loot from all sessions"],
  get = nil,
  set = function(msg)
    searchSessions(msg)
  end,
  message = string.rep("=", 10),  
  usage = L["<string>"],
  validate = function(msg)
    msg = msg and util.isNotSpaceOrEmpty(msg)
    return not not msg
  end,
  guiHidden = true,
}
A.options.args["MaxSessions"] = {
  type = "text",
  name = L["Maximum sessions number"],
  desc = L["Change maximum number of sessions "],
  get = function() 
    local db = A.getCharConfig("fa.session")
    return db.max_sessions
  end,
  set = function(msg)
    changeMaxSessions(tonumber(msg))
  end,
  message = string.rep("=", 10),  
  usage = L["<number:1-10>"],
  validate = function(msg)
    local n = tonumber(msg)
    return n and n > 0
  end,
  guiHidden = true,
}
A.options.args["Session"] = {
  type = "text",
  name = L["Session"],
  desc = L["Shows detail of sessions"],
  get = function() 
    local running, current = isCurrent()
    return running and util.formatMoneyFull(
      sessionItemsValue(current) + sessionMoney(current), true)
  end,
  set = detailSessions,
  message = string.rep("=", 10),
  usage = L["$ | <number> | name <number> <string> | del <number>" ..
    " | [number] top [1-10] | [number] hot [1-10] | [number] all" ..
    " | [number] loot | list | purge | search <string>"],
  validate = function(msg)
    msg = msg and util.strtrim(msg)
    local n = tonumber(msg)
    local commands = { ['$']=true, list=true, show=true, purge=true }
    return not msg or commands[strlower(msg)]
      or n and n >= 1
      or string.find(msg, "^%d*%s*top%s*%d*$")
      or string.find(msg, "^%$%s+top%s*%d*$")
      or string.find(msg, "^%d*%s*hot%s*%d*$")
      or string.find(msg, "^%$%s+hot%s*%d*$")
      or string.find(msg, "^%d*%s*all$")
      or string.find(msg, "^%$%s+all$")
      or string.find(msg, "^%d*%s*loot%s*%d*$")
      or string.find(msg, "^%$%s+loot%s*%d*$")
      or string.find(msg, "^name%s+%d+%s+%S.*$")
      or string.find(msg, "^del%s+%d+$")
      or string.find(msg, "^search%s+%S.*$")
  end,
  guiHidden = true,
}