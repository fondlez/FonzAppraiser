local A = FonzAppraiser

A.module 'util.time'

function M.epochTime()
  return time()
end

function M.unitTime()
  local t = date("*t")
  return t.hour, t.min, t.sec
end

function M.serverTime()
	local hours, minutes = GetGameTime()
  local seconds = date("*t").sec --assumes time sync of machine and server (!)
  return hours, minutes, seconds
end

function M.unitDate()
  local t = date("*t")
  return t.year, t.month, t.day, t.wday, t.yday, t.isdst
end

function M.dateTime()
  local t = date("*t")
  return t
end

function M.minDateTime()
  local t = date("*t")
  t.wday = nil
  t.yday = nil
  return t
end

function M.isoDate(t, epoch)
  return not epoch and date("%Y-%m-%d", time(t)) or date("%Y-%m-%d", t)
end

function M.isoTime(t, epoch)
  return not epoch and date("%H:%M:%S", time(t)) or date("%H:%M:%S", t)
end

function M.isoDateTime(t, epoch)
  return not epoch and date("%Y-%m-%d %H:%M:%S", time(t)) 
    or date("%Y-%m-%d %H:%M:%S", t)
end

function M.diffTime(t2, t1, epoch)
  return not epoch and (time(t2) - time(t1)) 
    or t2 and t1 and (t2 - t1)
end

function M.addTime(t, duration, epoch)
  duration = duration or 0
  if epoch then
    t = t or time()
    return t + duration
  end
  t = t or dateTime()
  t.sec = t.sec + duration
  return date("*t", time(t))
end

do
  local find, sub, min, slen = string.find, string.sub, math.min, string.len
  
  local PATTERN_DATE_4Y2M2D = "(%d%d%d%d)-?(%d%d)-?(%d%d)"
  local PATTERN_DATE_4Y2M = "(%d%d%d%d)-(%d%d)"
  local PATTERN_DATE_4Y = "(%d%d%d%d)"
  
  local PATTERN_DATE_TIME_SEP = "[ T]?"
  
  local PATTERN_TIME_2H2M2S = "(%d%d):?(%d%d):?(%d%d)"
  local PATTERN_TIME_2H2M = "(%d%d):?(%d%d)"
  local PATTERN_TIME_2H = "(%d%d)"
  
  local function parseDate(str, epoch, complexity)
    if epoch then
      --Lua time() function incompatible with patterns missing month or day
      local i1, i2, year, month, day = find(str, PATTERN_DATE_4Y2M2D)
      if i1 then
        local substring = sub(str, i2 + 1)
        return tonumber(year), tonumber(month), tonumber(day), 
          substring~="" and substring
      end
      if strlower(complexity) == "simple" then
        --Assume in simplest parse mode that missing month or day implies
        --the first of each period. This allows calling Lua time()
        for i, pattern in ipairs({PATTERN_DATE_4Y2M, PATTERN_DATE_4Y}) do
          local i1, i2, year, month, day = find(str, pattern)
          if i1 then
            month = month or 1
            day = day or 1
            local substring = sub(str, i2 + 1)
            return tonumber(year), tonumber(month), tonumber(day), 
              substring~="" and substring
          end
        end
      end
    else
      for i, pattern in ipairs({PATTERN_DATE_4Y2M2D, PATTERN_DATE_4Y2M, 
          PATTERN_DATE_4Y}) do
        local i1, i2, year, month, day = find(str, pattern)
        if i1 then
          local substring = sub(str, i2 + 1)
          return tonumber(year), tonumber(month), tonumber(day), 
            substring~="" and substring
        end
      end
    end
  end
  
  local function parseTime(str)
    for i, pattern in ipairs({PATTERN_TIME_2H2M2S, PATTERN_TIME_2H2M,
        PATTERN_TIME_2H}) do
      pattern = PATTERN_DATE_TIME_SEP .. pattern
      local i1, i2, hour, minute, second = find(str, pattern)
      if i1 then
        return tonumber(hour), tonumber(minute), tonumber(second)
      end
    end
  end
  
  --Parses ISO 8601 international format for human-readable timestamps.
  function M.parseIso8601(str, epoch, complexity)
    if epoch == nil then epoch = true end
    complexity = complexity or "simple"
    
    if strlower(complexity) == "simple" then
      local year, month, day, substring = parseDate(str, epoch, complexity)
      if not year then return end
      
      local hour, minute, second
      if substring then
        hour, minute, second = parseTime(substring)
      end
      
      local t = {
        year = year,
        month = month,
        day = day,
        hour = hour,
        ["min"] = minute,
        sec = second,
      }
      return epoch and time(t) or t
    end
  end
end

do
  local sub, find = string.sub, string.find
  
  --Original constants from Blizzard's GlobalStrings.lua.
  
  --Source: library "Abacus-2.0" constant references
  ---[[
  local L_DAY_ONELETTER_ABBR    = sub(DAY_ONELETTER_ABBR, 4)
  local L_HOUR_ONELETTER_ABBR   = sub(HOUR_ONELETTER_ABBR, 4) 
  local L_MINUTE_ONELETTER_ABBR = sub(MINUTE_ONELETTER_ABBR, 4)
  local L_SECOND_ONELETTER_ABBR = sub(SECOND_ONELETTER_ABBR, 4)
  
  local L_UNDETERMINED = "Undetermined"

  if GetLocale() =="koKR" then
    L_DAY_ONELETTER_ABBR    = sub(DAY_ONELETTER_ABBR, 3)
    L_HOUR_ONELETTER_ABBR   = sub(HOUR_ONELETTER_ABBR, 3) 
    L_MINUTE_ONELETTER_ABBR = sub(MINUTE_ONELETTER_ABBR, 3)
    L_SECOND_ONELETTER_ABBR = sub(SECOND_ONELETTER_ABBR, 3)
    
    L_UNDETERMINED = "측정불가"
  end
  --]]
  
  local PATTERN_DAY = "(%d+)%s*"..L_DAY_ONELETTER_ABBR
  local PATTERN_HOUR = "(%d+)%s*"..L_HOUR_ONELETTER_ABBR
  local PATTERN_MINUTE = "(%d+)%s*"..L_MINUTE_ONELETTER_ABBR
  local PATTERN_SECOND = "(%d+)%s*"..L_SECOND_ONELETTER_ABBR
  
  local units = {
    { name=DAYS, pattern=PATTERN_DAY, multiplier=24*60*60 }, 
    { name=HOURS, pattern=PATTERN_HOUR, multiplier=60*60 },
    { name=MINUTES, pattern=PATTERN_MINUTE, multiplier=60 },
    { name=SECONDS, pattern=PATTERN_SECOND, multiplier=1 },
  }
  
  --Parse known durations, e.g. 132d 42h 33m 26s
  function M.parseDuration(str, epoch)
    if epoch == nil then epoch = true end
    local duration, t = 0, {}
    for i, unit in ipairs(units) do
      local i1, i2, period = find(str, unit.pattern)
      if i1 then
        local n = tonumber(period)
        duration = duration + n * unit.multiplier
        t[unit.name] = n
      end
    end
    if duration == 0 then return end
    if epoch then
      return duration
    else
      return t
    end
  end

  --Source: library "Abacus-2.0"
  function M.formatDurationFull(duration, colorize, hideSeconds)
    local negative = ""
    if duration ~= duration then
      duration = 0
    end
    if duration < 0 then
      negative = "-"
      duration = -duration
    end
    if not colorize then
      if not hideSeconds then
        if not duration or duration > 86400*365 then
          return L_UNDETERMINED
        elseif duration >= 86400 then
          return format("%s%d%s %02d%s %02d%s %02d%s", negative, duration/86400, 
          L_DAY_ONELETTER_ABBR, mod(duration/3600, 24), L_HOUR_ONELETTER_ABBR, 
          mod(duration/60, 60), L_MINUTE_ONELETTER_ABBR, mod(duration, 60), 
          L_SECOND_ONELETTER_ABBR)
        elseif duration >= 3600 then
          return format("%s%d%s %02d%s %02d%s", negative, duration/3600, 
          L_HOUR_ONELETTER_ABBR, mod(duration/60, 60), L_MINUTE_ONELETTER_ABBR, 
          mod(duration, 60), L_SECOND_ONELETTER_ABBR)
        elseif duration >= 120 then
          return format("%s%d%s %02d%s", negative, duration/60, 
          L_MINUTE_ONELETTER_ABBR, mod(duration, 60), L_SECOND_ONELETTER_ABBR)
        else
          return format("%s%d%s", negative, duration, L_SECOND_ONELETTER_ABBR)
        end
      else
        if not duration or duration > 86400*365 then
          return L_UNDETERMINED
        elseif duration >= 86400 then
          return format("%s%d%s %02d%s %02d%s", negative, duration/86400, 
          L_DAY_ONELETTER_ABBR, mod(duration/3600, 24), L_HOUR_ONELETTER_ABBR, 
          mod(duration/60, 60), L_MINUTE_ONELETTER_ABBR)
        elseif duration >= 3600 then
          return format("%s%d%s %02d%s", negative, duration/3600, 
          L_HOUR_ONELETTER_ABBR, mod(duration/60, 60), L_MINUTE_ONELETTER_ABBR)
        else
          return format("%s%d%s", negative, duration/60, 
          L_MINUTE_ONELETTER_ABBR)
        end
      end
    else
      if not hideSeconds then
        if not duration or duration > 86400*365 then
          return "|cffffffff"..L_UNDETERMINED.."|r"
        elseif duration >= 86400 then
          return format("|cffffffff%s%d|r%s |cffffffff%02d|r%s |cffffffff%02d|r%s |cffffffff%02d|r%s", 
          negative, duration/86400, L_DAY_ONELETTER_ABBR, 
          mod(duration/3600, 24), L_HOUR_ONELETTER_ABBR, mod(duration/60, 60), 
          L_MINUTE_ONELETTER_ABBR, mod(duration, 60), L_SECOND_ONELETTER_ABBR)
        elseif duration >= 3600 then
          return format("|cffffffff%s%d|r%s |cffffffff%02d|r%s |cffffffff%02d|r%s", 
          negative, duration/3600, L_HOUR_ONELETTER_ABBR, mod(duration/60, 60), 
          L_MINUTE_ONELETTER_ABBR, mod(duration, 60), L_SECOND_ONELETTER_ABBR)
        elseif duration >= 120 then
          return format("|cffffffff%s%d|r%s |cffffffff%02d|r%s", negative, 
          duration/60, L_MINUTE_ONELETTER_ABBR, mod(duration, 60), 
          L_SECOND_ONELETTER_ABBR)
        else
          return format("|cffffffff%s%d|r%s", negative, duration, 
          L_SECOND_ONELETTER_ABBR)
        end
      else
        if not duration or duration > 86400*365 then
          return "|cffffffff"..L_UNDETERMINED.."|r"
        elseif duration >= 86400 then
          return format("|cffffffff%s%d|r%s |cffffffff%02d|r%s |cffffffff%02d|r%s", 
          negative, duration/86400, L_DAY_ONELETTER_ABBR, 
          mod(duration/3600, 24), L_HOUR_ONELETTER_ABBR, mod(duration/60, 60), 
          L_MINUTE_ONELETTER_ABBR)
        elseif duration >= 3600 then
          return format("|cffffffff%s%d|r%s |cffffffff%02d|r%s", negative, 
          duration/3600, L_HOUR_ONELETTER_ABBR, mod(duration/60, 60), 
          L_MINUTE_ONELETTER_ABBR)
        else
          return format("|cffffffff%s%d|r%s", negative, duration/60, 
          L_MINUTE_ONELETTER_ABBR)
        end
      end
    end
  end
end