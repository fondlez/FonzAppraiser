local A = FonzAppraiser

A.module 'util.string'

local util_table = A.require 'util.table'

function M.isempty(s)
  return s == nil or s == ''
end

function M.leq(a, b)
  return strlower(a) == strlower(b)
end

function M.lne(a, b)
  return not leq(a, b)
end

do
  local find, sub, gsub, len = string.find, string.sub, string.gsub, string.len
  
  function M.strmatch(str, pattern, index)
    local unpack = util_table.unpack
    local t = { find(str, pattern, index, false) }
    if not t[1] then return nil end
    if t[3] then
      return unpack(t, 3)
    else
      return sub(str, t[1], t[2])
    end
  end
  
  function M.strtrim(str)
    return (gsub(str, "^%s*(.-)%s*$", "%1"))
  end

  -- splitByPlainSeparator
  -- http://lua-users.org/wiki/SplitJoin
  function M.strsplit(sep, str, nmax)
    local z = len(sep)
    sep = "^.-" .. gsub(sep, "[$%%()*+%-.?%[%]^]", "%%%0")
    local t, n, p, q, r = {}, 1, 1, find(str, sep)
    while q and n ~= nmax do
        t[n], n, p = sub(str, q, r-z), n+1, r+1
        q, r = find(str, sep, p)
    end
    t[n] = sub(str, p)
    return unpack(t)
  end
  
  function M.strTrunc(str, max_len, dots)
    max_len = max_len or 80
    local str_len = len(str)
    if str_len <= max_len then return str end
    dots = dots or ""
    return sub(str, 1, max_len) .. dots
  end
  
  function M.strStartsWith(str, start_str)
    return sub(str, 1, len(start_str)) == start_str
  end
  
  function M.strEscapePunctuation(str)
    return gsub(str, "(%p)", "%%%1")
  end
  
  function M.strEscapeFormat(str)
    return gsub(str, "(%%)", "%%%1")
  end
  
  --[[
  --"World of Warcraft Programming" by James Whitehead II + Rick Roe
  --
  -- This function can return a substring of a UTF-8 string, properly
  -- handling UTF-8 codepoints. Rather than taking a start index and
  -- optionally an end index, it takes the string, the start index, and
  -- the number of characters to select from the string.
  --
  -- UTF-8 Reference:
  -- 0xxxxxx - ASCII character
  -- 110yyyxx - 2 byte UTF codepoint
  -- 1110yyyy - 3 byte UTF codepoint
  -- 11110zzz - 4 byte UTF codepoint
  --]]
  function M.utf8sub(str, start, num_chars)
    local current_index = start
    while num_chars > 0 and current_index <= len(str) do
      local char = strbyte(str, current_index)
      if char >=240 then
        current_index = current_index + 4
      elseif char >=255 then
        current_index = current_index + 3
      elseif char >=192 then
        current_index = current_index + 2
      else
        current_index = current_index + 1
      end
      num_chars = num_chars - 1
    end
    return sub(str, start, current_index - 1)
  end
  
  function M.keySearch(t, substring, comparator, case_sensitive)
    local compare = comparator or find
    local result = {}
    local found = false
    for k in pairs(t) do
      local key = k
      if not case_sensitive then
        key = strlower(k)
        substring = strlower(substring)
      end
      if compare(key, substring) then
        result[k] = result[k] and result[k] + 1 or 1
        found = true
      end
    end
    return found, result
  end
  
  function M.valueSearch(t, substring, comparator, case_sensitive)
    local compare = comparator or find
    local result = {}
    local found = false
    for k, v in pairs(t) do
      local value = v
      if not case_sensitive then
        value = strlower(v)
        substring = strlower(substring)
      end
      if compare(value, substring) then
        result[v] = result[v] and result[v] + 1 or 1
        found = true
      end
    end
    return found, result
  end
  
  function M.uniqueKeySearch(t, substring, comparator, case_sensitive)
    local compare = comparator or find
    local result
    local count = 0
    for k in pairs(t) do
      local key = k
      if not case_sensitive then
        key = strlower(k)
        substring = strlower(substring)
      end
      if compare(key, substring) then
        result = k
        count = count + 1
      end
    end
    if result and count == 1 then return result end
  end
end

-- Named Parameters and Format String in Same Table
-- http://lua-users.org/wiki/StringInterpolation
function M.replace_vars(str, vars)
  -- Allow replace_vars{str, vars} syntax as well as replace_vars(str, {vars})
  if not vars then
    vars = str
    str = vars[1]
  end
  return (gsub(str, "({([^}]+)})",
    function(whole, key)
      return vars[key] or whole
    end))
end

-- Modified from:
-- http://lua-users.org/wiki/TableSerialization
do
  function M.tablePrint(input, indent, done)
    local format = string.format
    local rep = string.rep
    local concat = table.concat
    
    done = done or {}
    indent = indent or 0
    if type(input) == "table" then
      local sb = {}
      for key, value in pairs(input) do
        tinsert(sb, rep (" ", indent))
        if type(value) == "table" and not done[value] then
          done[value] = true
          local k = type(key) == "number" and format("[%g]", key)
            or format('"%s"', key)
          tinsert(sb, k .. " = {\n")
          tinsert(sb, tablePrint(value, indent + 2, done))
          tinsert(sb, rep (" ", indent) .. "}\n")
        elseif type(key) == "number" then
          tinsert(sb, format('[%g] = "%s"\n', key, tostring(value)))
        elseif type(key) == "string" then
          tinsert(sb, format('"%s" = "%s"\n', key, tostring(value)))
        else
          tinsert(sb, format("%s = %s\n", tostring(key), tostring(value)))
        end
      end
      return concat(sb)
    else
      return tostring(input)
    end
  end

  function M.tostringall(...)
    return tablePrint(arg)
  end
end

do
  local mod = math.mod
  local lshift = bit.lshift
  local sbyte, slen = string.byte, string.len

  -- Ported from:
  -- https://github.com/philanc/plc/blob/master/plc/checksum.lua
  function M.adler32(s)
    local length = slen(s)
    local prime = 65521
    local s1, s2 = 1, 0
    
    for i = 1,length do
      local b = sbyte(s, i)
      s1 = s1 + b
      s2 = s2 + s1
    end
    s1 = mod(s1, prime)
    s2 = mod(s2, prime)
    return lshift(s2, 16) + s1
  end
end