local A = FonzAppraiser

A.module 'fa.session'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local abacus = AceLibrary("Abacus-2.0")

local util = A.requires(
  'util.string',
  'util.time',
  'util.item'
)

local notice = A.require 'fa.notice'
local gui_main = A.require 'fa.gui.main'

-- SESSION UPDATES --

local money_types = {
  [L["solo"]] = 0,
  [L["shared"]] = 1,
  [L["correction"]] = 2,
  [0] = L["solo"],
  [1] = L["shared"],
  [2] = L["correction"],
}
M.money_types = money_types

function M.lootMoney(money, money_type)
  local running, current = isCurrent()
  if not running then return end
  
  current.money = current.money + money
  
  if notice.checkMoney(money) then
    local zone_id = addZone(current.zones)
    local time_diff = diffTime(currentTime(), current.start)
    local type_id = money_types[money_type]
    tinsert(current.money_loots, { zone_id, time_diff, money, type_id })
  end
end

do
  local function addLoot(loots, zone_id, time_diff, code, item_count)
    tinsert(loots, {
      zone_id,
      time_diff,
      code,
      item_count,
    })
    return getn(loots)
  end
  
  local function addItem(items, code, item_count, loot_id)
    if not items[code] then items[code]= {} end
    local item = items[code]
    item.count = item.count and (item.count + item_count) or item_count
    if not item.loots then item.loots = {} end
    tinsert(item.loots, loot_id)
  end
  
  function M.lootItem(code, item_count, item_id)
    local running, current = isCurrent()
    if not running then return end
    
    local zone_id = addZone(current.zones)
    local time_diff = diffTime(currentTime(), current.start)
    local loot_id = addLoot(current.loots, zone_id, time_diff, code, 
      item_count)
    addItem(current.items, code, item_count, loot_id)
    
    local function addHotItem()
      addItem(current.hots, code, item_count, loot_id)
    end
    
    notice.checkItem(code, item_count, addHotItem)
  end
end

-- SESSION MANAGEMENT --

do
  local function untitled(zone_name, timestamp)
    return format("%s - %s", util.strTrunc(zone_name, 12, "..."),
      isoDateTime(timestamp, true))
  end
  
  local actions = {
    start = function()
      local zones = {}
      local zone_index, zone_name = addZone(zones)
      local t = currentTime()
      return { 
        zones=zones, 
        zone=zone_index, 
        start=t,
        name=untitled(zone_name, t),
        money=0,
        loots={},
        money_loots={},
        items={},
        hots={},
      }
    end,
    stop = function(current)
      current.stop = currentTime()
    end,
    delete = function(index)
      local db = A.getCharConfig("fa.session")
      local sessions = db.sessions
      local n = getn(sessions)
      table.remove(sessions, index)
      return getn(sessions) == (n - 1)
    end,
    name = function(session, name)
      session.name = name
    end,
  }

  function M.startSession()
    A.trace("Start session.")
    -- Stop any current session
    local _, current = isCurrent()
    if current then
      actions.stop(current)
    end
    -- Create a new session
    local db = A.getCharConfig("fa.session")
    local sessions = db.sessions
    
    -- Full sessions table already
    if getn(sessions) == db.max_sessions then
      -- Remove earliest session
      table.remove(sessions, 1)
    end
    
    tinsert(sessions, actions.start())
    setSessionsChecksum()
    A:ePrint(L["New session started!"])
    
    notice.resetTarget()
    A:guiUpdate()
  end
  A.startSession = startSession
  
  function M.stopSession()
    A.trace("Stop session.")
    local _, current = isCurrent()
    if not current then
      A.info("No current session found.")
      return
    end
    
    actions.stop(current)
    setSessionsChecksum()
    A:ePrint(L["Current session stopped."])
    
    notice.resetTarget()
    A:guiUpdate()
  end
  A.stopSession = stopSession
  
  function M.deleteSession(session_index)
    A.trace("Delete session.")
    local db = A.getCharConfig("fa.session")
    local sessions = db.sessions
    if not sessions then
      A.warn("No sessions found.")
      return
    end
    if not sessions[session_index] then
      A.warn("No session with index [%d] found.", session_index)
      return
    end
    
    local name = getSessionNameByIndex(session_index)
    if actions.delete(session_index) then
      setSessionsChecksum()
      A:ePrint(L['Session [%d] "%s" deleted.'], session_index, name)
      
      if not isCurrent() then notice.resetTarget() end
    else
      A.warn('Unable to delete session [%d] "%s"', session_index, name)
    end
    
    A:guiUpdate()
  end
  
  function M.deleteSessionByRef(session)
    A.trace("Delete session.")
    local sessions, n = getSessions()
    if not sessions then 
      A.warn("No sessions found.")
      return
    end
    
    local index
    for i=1,n do
      local s = sessions[i]
      if s == session then
        index = i
        break
      end
    end
    
    if index and index > 0 then
      local name = session.name
      
      table.remove(sessions, index)
      setSessionsChecksum()
      
      A:ePrint(L['Session deleted: "%s"'], name)
      
      if not isCurrent() then notice.resetTarget() end
    else
      A.error("Session reference not found in session list.")
    end
    
    A:guiUpdate()
  end
  
  function M.purgeSessions()
    A.trace("Purge sessions.")
    local db = A.getCharConfig("fa.session")
    if not db.sessions then
      A.warn("No sessions found.")
      return
    end
    
    db.sessions = {}
    setSessionsChecksum()
    A:ePrint(L["All sessions deleted."])
    
    notice.resetTarget()
    A:guiUpdate()
  end
  
  function M.nameSession(session_index, name)
    A.trace("Name session.")
    
    if not name or util.strtrim(name) == "" then
      A.warn("Invalid name: empty string.")
      return
    end
    
    local db = A.getCharConfig("fa.session")
    local sessions = db.sessions
    if not sessions then
      A.warn("No sessions found.")
      return
    end
    
    local session = sessions[session_index]
    if not session then
      A.warn("No session with index [%d] found.", session_index)
      return
    end
    
    actions.name(session, name)
    setSessionsChecksum()
    A:ePrint(L["Renamed session [%d] to %s."], session_index, name)
    
    A:guiUpdate()
  end
  
  do
    local warning_name = "FonzAppraiser_ReduceMaximumSessions"
    local target_num
    
    StaticPopupDialogs[warning_name] = {
      text = L["Reduce maximum number of sessions (destructive)?"],
      button1 = TEXT(YES),
      button2 = TEXT(NO),
      OnAccept = function()
        actuallyChangeMaxSessions()
      end,
      timeout = 0,
      whileDead = 1,
      hideOnEscape = 1,
    }
    
    function actuallyChangeMaxSessions(num)
      A.trace("actuallyChangeMaxSessions")
      
      num = num or target_num

      if not num or num < 1 then return end      
      local db = A.getCharConfig("fa.session")
      db.max_sessions = num

      local _, n = getSessions()
      if not n or n < 2 or num >= n then return end
      
      local diff = n - num
      for i=1,diff do
        deleteSession(1)
      end
    end
  
    function M.changeMaxSessions(num)
      A.trace("Change maximum number of sessions.")
      if not num or num < 1 then return end
      
      local db = A.getCharConfig("fa.session")
      if not db.max_sessions or not db.max_sessions_limit then return end
      
      if num > db.max_sessions then
        if num <= db.max_sessions_limit then
          A:ePrint(L["Increasing maximum number of sessions to %d."], num)
        else
          A:ePrint(L["%d exceeds number of possible sessions."], num)
          return
        end
      elseif num == db.max_sessions then
        A:ePrint(L["Maximum number of sessions is already %d."], num)
        return
      else
        local _, n = getSessions()
        if n and n > 0 and num < n then
          A:ePrint(L["%d is lower than the number of existing sessions. "
            .. "Oldest sessions will be deleted."], num)
          target_num = num
          StaticPopup_Show(warning_name)
          return
        end
      end
      
      actuallyChangeMaxSessions(num)
    end
  end
end
