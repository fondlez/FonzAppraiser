local A = FonzAppraiser

A.module 'util.table'

local client = A.require 'util.client'
local compat = client.compatibility

function wipe(t)
  local mt = getmetatable(t) or {}
  if not mt.__mode or mt.__mode ~= "kv" then
    mt.__mode = "kv"
    t = setmetatable(t, mt)
  end
  for k in pairs(t) do
    t[k] = nil
  end
  return t
end

if compat.version > compat.TBC then
  M.wipe = _G.wipe
  M.unpack = _G.unpack
  M.select = _G.select
elseif compat.version == compat.TBC then
  M.wipe = wipe
  M.unpack = _G.unpack
  M.select = _G.select
else
  M.wipe = wipe
  
  -- Vanilla/Lua 5.0 unpack() does not accept second and third arguments
  function M.unpack(t, start, stop)    
    start = start or 1
    stop = stop or getn(t)
    
    if type(start) ~= "number" then return end
    if type(stop) ~= "number" then return end
    
    if start == stop then
      return t[start]
    else
      return t[start], unpack(t, start + 1, stop)
    end
  end
  
  -- Vanilla-specific code, so 'arg' global safe to assume present for ...
  -- ... is Lua foward-compatible only when used as a function parameter
  -- 'arg' global for variadic arguments is not foward-compatible in the WoW API
  function M.select(index, ...)
    if index == "#" then return getn(arg) end
    return unpack(arg, index)
  end
end

function M.insertUnique(t, value)
  if not value then return end
  
  local found = false
  for i,v in ipairs(t) do
    if v == value then
      found = true
      break
    end
  end
  if not found then
    tinsert(t, value)
  end
  return t
end

do
  local sort = table.sort
  
  function M.keys(t)
    if not t then return end
    local result = {}
    for k,v in pairs(t) do
      tinsert(result, k)
    end
    return result
  end

  function M.sortedKeys(t, cmp)
    if not t then return end
    local result = keys(t)
    sort(result, cmp)
    return result
  end
  
  function M.sortedPairs(t, cmp)
    if not t then return end
    local result = keys(t)
    sort(result, cmp)
    local i = 0
    local iterator = function()
      i = i + 1
      local key = result[i]        
      return key, key and t[key]
    end
    return iterator
  end
end

do
  local tolower = string.lower

  function M.keyslower(t)
    local l = {}
    for k, v in pairs(t) do
      if type(k) == "string" then
        l[tolower(k)] = v
      end
    end
    return l
  end
end

do
  local sort = table.sort
  
  function M.sortRecords1(records, field1, reverse1)
    if not records or type(records) ~= "table" then return end
    if not field1 then return end
    
    sort(records, function(a, b)
      if not reverse1 then
        return a[field1] < b[field1]
      else
        return a[field1] > b[field1]
      end
    end)
    
    return records
  end
  
  function M.sortRecords2(records, field1, reverse1, field2, reverse2)
    if not records or type(records) ~= "table" then return end
    if not field1 then return end
    
    sort(records, function(a, b)
      if a[field1] ~= b[field1] then
        if not reverse1 then
          return a[field1] < b[field1]
        else
          return a[field1] > b[field1]
        end
      end
      if field2 and a[field2] ~= b[field2] then
        if not reverse2 then
          return a[field2] < b[field2]
        else
          return a[field2] > b[field2]
        end
      end
    end)
    
    return records
  end
  
  function M.sortRecords3(records, field1, reverse1, field2, reverse2, 
      field3, reverse3)
    if not records or type(records) ~= "table" then return end
    if not field1 then return end
    
    sort(records, function(a, b)
      if a[field1] ~= b[field1] then
        if not reverse1 then
          return a[field1] < b[field1]
        else
          return a[field1] > b[field1]
        end
      end
      if field2 and a[field2] ~= b[field2] then
        if not reverse2 then
          return a[field2] < b[field2]
        else
          return a[field2] > b[field2]
        end
      end
      if field3 and a[field3] ~= b[field3] then
        if not reverse3 then
          return a[field3] < b[field3]
        else
          return a[field3] > b[field3]
        end
      end
    end)
    
    return records
  end
  
  function M.sortRecords4(records, field1, reverse1, field2, reverse2, 
      field3, reverse3, field4, reverse4)
    if not records or type(records) ~= "table" then return end
    if not field1 then return end
    
    sort(records, function(a, b)
      if a[field1] ~= b[field1] then
        if not reverse1 then
          return a[field1] < b[field1]
        else
          return a[field1] > b[field1]
        end
      end
      if field2 and a[field2] ~= b[field2] then
        if not reverse2 then
          return a[field2] < b[field2]
        else
          return a[field2] > b[field2]
        end
      end
      if field3 and a[field3] ~= b[field3] then
        if not reverse3 then
          return a[field3] < b[field3]
        else
          return a[field3] > b[field3]
        end
      end
      if field4 and a[field4] ~= b[field4] then
        if not reverse4 then
          return a[field4] < b[field4]
        else
          return a[field4] > b[field4]
        end
      end
    end)
    
    return records
  end

  function M.sortRecords(records, fields)
    if not records or type(records) ~= "table" then return end
    if not fields or type(fields) ~= "table" then return end

    sort(records, function(a, b)
      for i, entry in ipairs(fields) do
        local field = entry.field
        local reverse = entry.reverse
        if field and a[field] and b[field] and a[field] ~= b[field] then
          if not reverse then
            return a[field] < b[field]
          else
            return a[field] > b[field]
          end
        end
      end
    end)
    
    return records
  end
end