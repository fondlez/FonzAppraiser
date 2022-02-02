local A = FonzAppraiser

A.module 'util.table'

do
  local setmetatable, setn = setmetatable, table.setn
  
  function M.wipe(t)
    setmetatable(t, nil)
    for i in pairs(t) do
      t[i] = nil
    end
    setn(t, 0)
  end
  
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

  function M.select(index, ...)
    if index == "#" then return arg.n end
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