local A = FonzAppraiser

A.module 'fa.session'

local util = A.requires(
  'util.table',
  'util.math',
  'util.string',
  'util.time',
  'util.item'
)

local pricing = A.require 'fa.value.pricing'
local filter = A.require 'fa.filter'

local lne = util.lne

-- SETTINGS --

local defaults = {
  max_sessions_limit = 10,
  max_sessions = 5,
  max_item_highlight_count = 10,
  sessions = {
  --[[Data structure:
    [1]={ 
      zones = {
        [1]=zone1=string
        zone1=1
        [2]=zone2=string
        zone2=2
      }
      loots={
        [1]={
          [1]=zone_id=zones<index>
          [2]=diff=number (loot timestamp - start timestamp)
          [3]=code=string
          [4]=count=number
        }
      }
      money_loots={
        [1]={
          [1]=zone_id=zones<index>
          [2]=diff=number (loot timestamp - start timestamp)
          [3]=amount=number
        }
      }
      name=string
      zone=zones<index>
      start=timestamp=number
      stop=timestamp=number
      money=number
      items={
        [code=string]={ 
          count=number
          loots={ loots<index>+ }
        }
      }
      hots={
        [code=string]={
          count=number
          loots={ loots<index>+ }
        }
      }
    }
  --]]
  },
  sessions_checksum = nil,
  confirm_delete_oldest = true,
}
A.registerCharConfigDefaults("fa.session", defaults)

-- HELPER FUNCTIONS --

-- General

function M.currentTime()
  return util.epochTime()
end

function M.diffTime(t1, t0)
  return util.diffTime(t1, t0, true)
end

function M.addTime(t, duration)
  return util.addTime(t, duration, true)
end

function M.isoTime(t)
  return util.isoTime(t, true)
end

function M.isoDateTime(t)
  return util.isoDateTime(t, true)
end

function currentZone()
  return GetRealZoneText()
end

-- [LEGACY] Re-export a widely-used old reference
M.safeItemLink = util.safeItemLink

-- Session-specific

do
  function M.getSessions()
    local db = A.getCharConfig("fa.session")
    local sessions = db.sessions
    local n = getn(sessions)
    if n < 1 then return end
    return sessions, n
  end
  
  function M.getSession(index)
    local db = A.getCharConfig("fa.session")
    local sessions = db.sessions
    return sessions and sessions[index]
  end

  function M.getLastSession()
    local db = A.getCharConfig("fa.session")
    local sessions = db.sessions
    local n = getn(sessions)
    if n < 1 then return end
    return sessions[n], n
  end

  function M.isCurrent(session)
    local current = session or getLastSession()
    if current and not current.stop then
      return true, current
    end
  end
  
  function M.isCurrentByIndex(index)
    local session = getSession(index)
    return isCurrent(session)
  end

  function M.isStopped(session)
    local current = session or getLastSession()
    if current and current.stop then
      return true, current
    end
  end
  
  function M.hasMaxSessions()
    local db = A.getCharConfig("fa.session")
    return getn(db.sessions) == db.max_sessions
  end
end

do
  function M.getSessionName(session)
    return session and session.name
  end
  
  function M.getSessionNameByIndex(index)
    local session = getSession(index)
    return session and session.name
  end
  
  function M.setSessionName(session, name)
    if not session or not name then return end
    session.name = name
    return session.name
  end
  
  function M.setSessionNameByIndex(index, name)
    local session = getSession(index)
    return setSessionName(session, name)
  end
  
  function M.getCurrentName()
    local _, current = isCurrent()
    return current and current.name
  end
  
  function M.setCurrentName(name)
    local _, current = isCurrent()
    if not current or not name then return end
    current.name = name
    return current.name
  end
  
  function setSessionsChecksum()
    local db = A.getCharConfig("fa.session")
    local sessions = db.sessions
    if not sessions or getn(sessions) < 1 then 
      db.sessions_checksum = nil
      return
    end
    
    local data = {}
    for index, session in ipairs(sessions) do
      tinsert(data, session.start)
      tinsert(data, index)
      tinsert(data, session.stop or 0)
    end
    local text = getn(data) > 0 and table.concat(data, "")
    if not text then 
      A.warn("Sessions checksum not possible.")
      return
    end
    
    db.sessions_checksum = util.adler32(text)
  end
  
  function M.getSessionsChecksum()
    local db = A.getCharConfig("fa.session")
    return db.sessions_checksum
  end
end

do
  function addZone(zones)
    local name = currentZone()
    if not zones[name] then
      tinsert(zones, name)
      zones[name]= getn(zones)
    end
    return zones[name], name
  end
  
  function M.getCurrentZone()
    local _, current = isCurrent()
    return current and current.zones[current.zone]
  end
  
  function M.sessionZone(session)
    return session and session.zones[session.zone]
  end
  M.getSessionZone = sessionZone
  
  function M.sessionZoneByIndex(index)
    local session = getSession(index)
    return sessionZone(session)
  end
  M.getSessionZoneByIndex = sessionZoneByIndex
end

do
  function M.getSessionStart(session)
    return session and session.start
  end
  
  function M.getCurrentStart()
    local _, current = isCurrent()
    return current and current.start    
  end
  
  function M.getSessionStartByIndex(index)
    local session = getSession(index)
    return getSessionStart(session)
  end
  
  function M.sessionDuration(session)
    return session 
      and session.stop and diffTime(session.stop, session.start)
      or diffTime(currentTime(), session.start)
  end
  M.getSessionDuration = sessionDuration
  
  function M.getSessionDurationByIndex(index)
    local session = getSession(index)
    return sessionDuration(session)
  end
end

do
  function countItems(items)
    if not items then return end
    local count = 0
    for _, v in pairs(items) do
      count = count + v.count
    end
    return count
  end
  
  function M.sessionItemsCount(session, store)
    local items = session and session[store or "items"]
    return items and countItems(items)
  end
  M.getSessionItemsCount = sessionItemsCount
  
  function M.getCurrentItemsCount(store)
    local _, current = isCurrent()
    return current and sessionItemsCount(current, store)
  end
  
  function M.getSessionItemsCountByIndex(index, store)
    local session = getSession(index)
    return sessionItemsCount(session, store)
  end
  
  function M.getSessionItems(session, store)
    return session and session[store or "items"]
  end
  
  function M.getSessionItemsByIndex(index, store)
    local session = getSession(index)
    return getSessionItems(session, store)
  end
  
  function M.getCurrentItems(store)
    local _, current = isCurrent()
    return current and current[store or "items"]
  end
end

do
  do
    function M.sessionMoney(session)
      return session and session.money
    end
    M.getSessionMoney = sessionMoney
    
    function M.getCurrentMoney()
      local _, current = isCurrent()
      return current and current.money
    end
    
    function M.getSessionMoneyByIndex(index)
      local session = getSession(index)
      return sessionMoney(session)
    end
  end
  
  local parseItemCode = util.parseItemCode
  local pricingValue = pricing.value
  
  function M.sessionItemsValue(session, store)
    local items = session and session[store or "items"]
    if not items then return end
    
    local total = 0
    for code, v in pairs(items) do
      local value = pricingValue(code) or 0
      total = total + v.count * value
    end  
    return total
  end
  M.getSessionItemsValue = sessionItemsValue
  
  function M.getSessionItemsValueByIndex(index, store)
    local session = getSession(index)
    return sessionItemsValue(session, store)
  end
  
  function M.getCurrentItemsValue()
    local _, current = isCurrent()
    if not current then return end
    return getSessionItemsValue(current, "items")
  end

  function M.getCurrentHotsValue(session)
    local _, current = isCurrent()
    if not current then return end
    return getSessionItemsValue(current, "hots")
  end

  function M.getSessionTotalValue(session)
    if not session then return end
    local money = sessionMoney(session)
    local itemsValue = getSessionItemsValue(session, "items")
    return money and itemsValue and (money + itemsValue) or 0
  end
  
  function M.getCurrentTotalValue()
    local _, current = isCurrent()
    if not current then return end
    return getSessionTotalValue(current)
  end
  
  do
    local PERIOD = 60*60
    local pricingValue = pricing.value
    
    function M.isValidPerHourValue(session, money_loot_time, item_loot_time)
      local _, current = isCurrent()
      if not current or not session or current ~= session then return end
      if not money_loot_time and not item_loot_time then return end
      
      if money_loot_time and 
          diffTime(currentTime(), money_loot_time) > PERIOD then
        return false
      end
      
      if item_loot_time and
          diffTime(currentTime(), item_loot_time) > PERIOD then
        return false
      end
      
      return true
    end
    
    function M.getCurrentPerHourValue()
      local _, current = isCurrent()
      if not current then return end
      
      local start_time = current.start
      local item_loots = current.loots
      local money_loots = current.money_loots
      local item_loots_count = getn(item_loots)
      local money_loots_count = getn(money_loots)
      
      if item_loots_count < 1 and money_loots_count < 1 then
        return 0
      end
      
      local value = 0
      local money_loot_index, money_loot_time
      if money_loots_count > 0 then
        for i=1,money_loots_count do
          money_loot_index = money_loots_count + 1 - i
          local loot = money_loots[money_loot_index]
          local loot_time = addTime(start_time, loot[2])
          
          if diffTime(currentTime(), loot_time) <= PERIOD then
            value = value + loot[3]
            money_loot_time = loot_time
          else
            break
          end
        end
      end
      
      local item_loot_index, item_loot_time
      if item_loots_count > 0 then
        for i=1,item_loots_count do
          item_loot_index = item_loots_count + 1 - i
          local loot = item_loots[item_loot_index]
          local loot_time = addTime(start_time, loot[2])
          
          if diffTime(currentTime(), loot_time) <= PERIOD then
            local code = loot[3]
            local count = loot[4]
            local item_value = pricingValue(code)
            value = value + (item_value or 0) * count
            item_loot_time = loot_time
          else
            break
          end
        end
      end

      return value, current, money_loot_time, item_loot_time
    end
  end
end

do
  local parseItemCode = util.parseItemCode
  local pricingValue = pricing.value
  local sortRecords1 = util.sortRecords1
  local safeItemLink = util.safeItemLink
  
  function getSessionLoot(session)    
    local loots = session.loots
    local start_time = session.start
    local zones = session.zones
    local filter_quality = filter.qualityAsRarity()
    
    local n = getn(loots)
    if n < 1 then return end
    
    local result = {}
    for i, loot in ipairs(loots) do
      local item = {}
      item["loot_id"] = i
      local zone_id = loot[1]
      local start_delta = loot[2]
      local code = loot[3]
      item["code"] = code
      local item_id = parseItemCode(code)
      item["id"] = item_id
      item["count"] = loot[4]
      
      item["loot_time"] = addTime(start_time, start_delta)
      item["zone"] = zones[zone_id]
      
      item["item_link"], 
      item["name"], item["item_string"], item["rarity"], 
      item["level"], item["type"], item["subtype"], 
      _, item["slot"] = safeItemLink(code)
      
      local value, system = pricingValue(code)
      item["value"] = (value or 0) * item["count"]
      item["pricing"] = system
      
      if item["rarity"] and item["rarity"] >= filter_quality then
        tinsert(result, item)
      end
    end
    return result
  end
  
  function M.getCurrentLoot()
    local _, current = isCurrent()
    if not current then return end
    return getSessionLoot(current)
  end
  
  function M.getCurrentLootAndMoney()
    local _, current = isCurrent()
    if not current then return end
    
    local records = getSessionLoot(current)
    
    local money_loots = current.money_loots
    
    -- Only list money records if there is a current non-zero money threshold
    local db = A.getCharConfig("fa.notice")
    local threshold = db.money_threshold or NONE
    if getn(money_loots) > 0 and lne(threshold, NONE) and threshold > 0 then
      local start_time = current.start
      local zones = current.zones
      
      if not records then records = {} end
      for i, loot in ipairs(money_loots) do
        local record = {}
        record["loot_id"] = i
        local zone_id = loot[1]
        local start_delta = loot[2]
        local money = loot[3]
        local type_id = loot[4]
        
        if money >= threshold then
          record["loot_time"] = addTime(start_time, start_delta)
          record["zone"] = zones[zone_id]
          record["money"] = money
          record["type"] = money_types[type_id]
          tinsert(records, record)
        end
      end
    end
    
    local sorted_records = sortRecords1(records, "loot_time")
    
    return sorted_records
  end
  
  do    
    function M.lootSubtotal(loots)
      local counter = {}
      for i, item in ipairs(loots) do
        local code = item["code"]
        local count = item["count"]
        local value = item["value"]
        if not counter[code] then
          counter[code] = { 
            count = count,
            value = value,
          }
        else
          counter[code] = {
            count = counter[code].count + count,
            value = counter[code].value + value,
          }
        end
      end
      local total = {
        count = 0,
        value = 0,
      }
      for k, v in pairs(counter) do
        total.count = total.count + v.count
        total.value = total.value + v.value
      end
      return total
    end  
  
    --Item field remapping metatable: maps filter keywords to data keywords
    --when they do not match.
    local remap = {
      quality = "rarity",
      lmin = "level",
      lmax = "level",
      from = "loot_time",
      to = "loot_time",
      since = "loot_time",
      ["until"] = "loot_time",
    }
    remap.mt = {__index=function(t, k)
      local field = remap[k] or k
      return rawget(t, field)
    end}
    
    local safeItemLink = util.safeItemLink
    
    function M.searchAllLoot(filters)
      local searchByFilter = filter.searchByFilter
      
      local sessions = getSessions()  
      if not sessions then return end    
      
      --Insert default quality filter always, if no quality or rarity filter
      if not filters then
        filters = {}
      end
      if not filters["quality"] and not filters["rarity"] then
        filters["quality"] = filter.qualityAsRarity()
      end
      
      local result = {}
      for session_index, session in ipairs(sessions) do
        local start_time = session.start
        local loots = session.loots
        
        for i, loot in ipairs(loots) do
          local item = setmetatable({}, remap.mt)
          local zone_id = loot[1]
          local start_delta = loot[2]
          local code = loot[3]
          item["code"] = code
          local item_id = parseItemCode(code)
          item["id"] = item_id
          item["count"] = loot[4]
          item["session"] = session_index
          
          item["loot_time"] = addTime(start_time, start_delta)
          item["zone"] = session.zones[zone_id]
          
          item["item_link"], 
          item["name"], item["item_string"], item["rarity"], 
          item["level"], item["type"], item["subtype"], 
          _, item["slot"] = safeItemLink(code)
          
          local value, system = pricingValue(code)
          item["value"] = (value or 0) * item["count"]
          item["pricing"] = system
          
          local matched = true
          --Check that the item name is in at least one group, if filter groups
          local groups = filters["group"]
          if groups then
            local found = false
            for i,name in ipairs(groups) do
              local group = filter.getFilterGroup(name)
              if group[item["id"]] then
                found = true
                break
              end
            end
            matched = found
          end
          
          if matched then
            --Every filter must match, otherwise no point continuing
            for filter_keyword, filter_arg in pairs(filters) do
              if filter_keyword ~= "group" then
                matched = searchByFilter(filter_keyword, item[filter_keyword],
                  filter_arg)
                if not matched then break end
              end
            end
          end
          
          if matched then 
            --Still matched so accept for output
            tinsert(result, item)
          end
        end
      end
      return result
    end
  end
end

do
  local safeItemLink = util.safeItemLink
  local sortRecords = util.sortRecords
  local parseItemCode = util.parseItemCode
  local pricingValue = pricing.value
  
  local function preSort(items)
    local sort_array = {}
    
    for code, v in pairs(items) do
      local id = parseItemCode(code)
      local count = v.count
      local item_link, name, _, rarity = safeItemLink(code)
      local item_value, system = pricingValue(code)
      
      tinsert(sort_array, {code=code, id=id, count=count, item_link=item_link,
        name=name, rarity=rarity, value=(item_value or 0)*count, 
        pricing=system})
    end
    
    return sort_array
  end
  
  function M.sortItemsByValue(items, reverse)
    local records = preSort(items)
    local fields = {
      { field="value", reverse=reverse },
      { field="count", reverse=(not reverse) },
      { field="name", reverse=false },
      { field="code", reverse=false },
    }
    return sortRecords(records, fields)
  end
  
  function M.sortItemsByCount(items, reverse)
    local records = preSort(items)
    local fields = {
      { field="count", reverse=reverse },
      { field="value", reverse=true },
      { field="name", reverse=false },
      { field="code", reverse=false },
    }
    return sortRecords(records, fields)
  end
  
  function M.sortItemsByName(items, reverse)
    local records = preSort(items)
    local fields = {
      { field="name", reverse=reverse },
      { field="code", reverse=false },
    }
    return sortRecords(records, fields)
  end
end