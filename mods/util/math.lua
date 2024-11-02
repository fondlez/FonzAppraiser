local A = FonzAppraiser

A.module 'util.math'

do
  local mod = math.fmod or math.mod or mod
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