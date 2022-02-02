local A = FonzAppraiser

function A.createDebugFunction(prefix, color)
  color = color or "ffff1100"
  return function(...)
    if A.loglevel < A.loglevels[prefix] then return end
    local format = string.format
    local result, message = pcall(format, unpack(arg))
    if not result then
      local t = {}
      for i, v in ipairs(arg) do
        t[i] = tostring(v)
      end
      message = table.concat(t, " ")
    end
    
    A:Print(format("|c%s%s:|r %s", color, prefix, message))
  end
end

A.debug = A.createDebugFunction("DEBUG", "ff00ffff") --cyan
A.trace = A.createDebugFunction("TRACE", "ffd800ff") --purple
A.warn = A.createDebugFunction("WARN", "ffffff00")   --yellow
A.info = A.createDebugFunction("INFO", "ff00ff00")   --green
A.error = A.createDebugFunction("ERROR", "ffff0000") --red
A.fatal = A.createDebugFunction("FATAL", "ffffffff") --white
