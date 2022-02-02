local A = FonzAppraiser

A.module 'fa.session'

local L = AceLibrary("AceLocale-2.2"):new("FonzAppraiser")

local abacus = AceLibrary("Abacus-2.0")

local util = A.requires(
  'util.string',
  'util.time',
  'util.chat'
)

local source = A.require 'fa.value.source'
local filter = A.require 'fa.filter'
local notice = A.require 'fa.notice'
local palette = A.require 'fa.palette'

do
  local function codeStatus(status)
    local STATUS_RUNNING = palette.color.green("( $ )")
    local STATUS_STOPPED = palette.color.red("( x )")
    return status and STATUS_RUNNING or STATUS_STOPPED
  end
  
  function M.sessionStatus()
    local db = A.getCharConfig("fa.session")
    local sessions = db.sessions
    local status = {}
    for index, session in ipairs(sessions) do
      local value = getSessionTotalValue(session)
      tinsert(status, {
        code=codeStatus(isCurrent(session)),
        index=index,
        session=session,
        name=session.name,
        total=abacus:FormatMoneyFull(value, true)})
    end
    return status
  end

  function listSessions()
    A.trace("listSessions")
    local db = A.getCharConfig("fa.session")
    local sessions = db.sessions
    if not sessions or getn(sessions) < 1 then
      A:ePrint(L["No sessions found."])
      return
    end
    
    util.systemChat(L["Sessions:"])
    local session_status = sessionStatus()
    for i, status in ipairs(session_status) do
      util.systemChat('%s [%d] "%s" %s', 
        status.code, 
        status.index,
        status.name,
        status.total)
    end
  end

  function showSession(session_index)
    A.trace("showSession")
    local db = A.getCharConfig("fa.session")
    local sessions = db.sessions
    if not sessions or getn(sessions) < 1 then
      A.info("No sessions found.")
      return
    end

    local session
    if session_index then
      session = sessions[session_index]    
      if not session then
        A.warn("No session with index [%d] found.", session_index)
        return
      end
    end
    
    if not session then
      session, session_index = getLastSession()
    end
    
    local running = not session.stop
    
    util.systemChat(L["Detail of session%s:"], running and "" 
      or L[" (stopped)"])
    util.systemChat("%s [%d] %s", codeStatus(running), session_index, 
      session.name)
    
    local zone_text = sessionZone(session)
    local duration = sessionDuration(session)
    local currency = sessionMoney(session)
    
    util.systemChat(L["Zone: %s"], zone_text)
    util.systemChat(L["Duration: %s"], abacus:FormatDurationFull(duration))
    util.systemChat(L["Currency: %s"], abacus:FormatMoneyFull(currency, true))
    
    local desc = {
      items=L["Item"],
      hots=L["Hot item"],
    }
    
    local total_value = currency
    
    for _, store in ipairs({ "items", "hots" }) do
      local items_count = sessionItemsCount(session, store)
      local items_value = sessionItemsValue(session, store)
      util.systemChat(L["%s count: %d"], desc[store], items_count)
      util.systemChat(L["%s value: %s"], desc[store], 
        abacus:FormatMoneyFull(items_value, true))
      if store == "items" then total_value = total_value + items_value end
    end
    
    util.systemChat(L["Total value: %s"], 
      abacus:FormatMoneyFull(total_value, true))
      
    local gph = floor(total_value / (duration/3600))
    
    util.systemChat(L['"Gold Per Hour": %s'], 
      abacus:FormatMoneyFull(gph, true))
  end
  
  function showSessionItems(store, session_index, max_count, all)
    A.trace("showSessionItems")
    local db = A.getCharConfig("fa.session")
    local sessions = db.sessions
    if not sessions or getn(sessions) < 1 then
      A.warn("No sessions found.")
      return
    end
    
    local session
    if session_index then
      session = sessions[session_index]    
      if not session then
        A.warn("No session with index [%d] found.", session_index)
        return
      end
    end
    
    if not session then
      _, session = isCurrent()
      if not session then
        A.warn("No current session found.")
        return
      end
    end
    
    local stores = {
      all = {
        desc=L["All: "],
        items=session.items,      
      },
      top = {
        desc=L["Top: "],
        items=session.items,
      },
      hot = {
        desc=L["Hot: "],
        items=session.hots,
      }
    }
    
    local store_info = stores[store]
    local items = store_info.items
    
    if not items or not next(items, nil) then
      A.info("No items found.")
      return
    end
    
    util.systemChat(store_info.desc)
    
    local sorted_array = sortItemsByValue(items, true)
    
    if not all and not max_count then
      max_count = db.max_item_highlight_count or 10
    end
    
    local filter_quality = filter.qualityAsRarity()
    
    local total = 0
    
    local counter = 1
    for i, item in ipairs(sorted_array) do
      local rarity = item.rarity
      if not all or all and rarity and rarity >= filter_quality then
        local value = item.value
        util.systemChat("[%d] %dx %s = %s", counter, item.count, item.item_link, 
          abacus:FormatMoneyFull(value, true))
        total = total + value
        
        if not all and counter >= max_count then break end
        
        counter = counter + 1
      end
    end
    
    util.systemChat(L["Total: %s"], abacus:FormatMoneyFull(total, true))
  end
  
  function showSessionLoot(session_index, max_count)
    A.trace("showSessionLoot")
    local db = A.getCharConfig("fa.session")
    local sessions = db.sessions
    if not sessions or getn(sessions) < 1 then
      A.warn("No sessions found.")
      return
    end
    
    local session
    if session_index then
      session = sessions[session_index]    
      if not session then
        A.warn("No session with index [%d] found.", session_index)
        return
      end
    end
    
    if not session then
      _, session = isCurrent()
      if not session then
        A.warn("No current session found.")
        return
      end
    end
    
    local session_loot = getSessionLoot(session, max_count)
    if not session_loot then
      A.warn("No loot data found.")
      return
    end
    
    local n = getn(session_loot)
    max_count = max_count or 10
    local m = math.max(n - max_count + 1, 1)
    for i=m,n do
      local item = session_loot[i]
      local value = item["value"]
      util.systemChat("%s %s %sx %s %s", 
        isoDateTime(item["loot_time"]),
        util.strTrunc(item["zone"], 12, "..."), 
        item["count"],
        item["item_link"],
        abacus:FormatMoneyFull(value, true))
    end

    util.systemChat(L["Found %d results."], n - m + 1)
  end
  
  function searchSessions(msg)
    A.trace("searchSessions")
    local db = A.getCharConfig("fa.session")
    local sessions = db.sessions
    if not sessions or getn(sessions) < 1 then
      A.warn("No sessions found.")
      return
    end
    
    local filters = filter.makeFilter(msg)
    if not filters then 
      A.warn("Invalid search input.")
      return
    end
    
    local found = false
    for i, v in ipairs(sessions) do
      if getn(v.loots) > 0 then found = true end
    end
    
    if not found then
      A.warn("No loot data found.")
      return
    end
  
    local result = searchAllLoot(filters)
    for i, item in ipairs(result) do
      util.systemChat("%s %s %sx %s %s", 
        isoDateTime(item["loot_time"]),
        util.strTrunc(item["zone"], 12, "..."), 
        item["count"],
        item["item_link"],
        abacus:FormatMoneyFull(item["value"], true))
    end
    
    local n = result and getn(result)
    if n then
      local sum = lootSubtotal(result)
      util.systemChat(L["Results: %d loots, %d items, %s value"], 
        n, sum.count, abacus:FormatMoneyFull(sum.value, true))
    end
  end

  function detailSessions(msg)
    A.trace("detailSessions")
    local find, sub = string.find, string.sub
    msg = msg and util.strtrim(msg)
    
    if not msg or strlower(msg) == "list" or strlower(msg) == "show" then
      listSessions()
      return
    end
    
    if msg == "$" then
      showSession()
      return
    end
    
    local session_index = tonumber(msg)
    if session_index then
      showSession(session_index)
      return
    end
    
    local found, max_count
    found, _, session_index, max_count = find(msg, "^(%S*)%s*top%s*(%d*)$")
    if found then
      if session_index == "$" then session_index = nil end
      showSessionItems("top", tonumber(session_index), tonumber(max_count))
      return
    end
    
    found, _, session_index, max_count = find(msg, "^(%S*)%s*hot%s*(%d*)$")
    if found then
      if session_index == "$" then session_index = nil end
      showSessionItems("hot", tonumber(session_index), tonumber(max_count))
      return
    end
    
    local found
    found, _, session_index = find(msg, "^(%S*)%s*all$")
    if found then
      if session_index == "$" then session_index = nil end
      showSessionItems("all", tonumber(session_index), nil, true)
      return
    end
    
    found, _, session_index, max_count = find(msg, "^(%S*)%s*loot%s*(%d*)$")
    if found then
      if session_index == "$" then session_index = nil end
      showSessionLoot(tonumber(session_index), tonumber(max_count))
      return
    end
    
    if strlower(msg) == "purge" then
      purgeSessions()
      return
    end
    
    local name
    _, _, session_index, name = find(msg, "^name%s+(%d+)%s+(%S.*)$")
    if session_index and name then
      --Sanitize arbitary user input by escaping format specifiers
      name = util.strEscapeFormat(name)
      nameSession(tonumber(session_index), name)
      return
    end
    
    _, _, session_index = find(msg, "^del%s+(%d+)$")
    if session_index then
      deleteSession(tonumber(session_index))
      return
    end
    
    local query
    _, _, query = find(msg, "^search%s+(%S.*)$")
    if query then
      searchSessions(query)
      return
    end
  end
end