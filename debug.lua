local A = FonzAppraiser

A.loglevels = {
  FATAL=0, -- kills the service [very rare in a hosted application like WoW]
  ERROR=1, -- kills the application [minimum logging for releases]
  WARN=2,  -- unwanted, but potentially recoverable, state
  INFO=3,  -- configuration or administration detail
  TRACE=4, -- developer: path detail
  DEBUG=5, -- developer: state detail
}
A.loglevel = A.loglevels["ERROR"]

function A.logging(level)
  return A.loglevel >= A.loglevels[level]
end

do
  local format = string.format
  local tconcat = table.concat
  
  local header = format("|c%02X%02X%02X%02X", 1, 255, 255, 13)
    .. A.name .. FONT_COLOR_CODE_CLOSE
  
  function A.createDebugFunction(prefix, color)
    color = color or "ffff1100"
    return function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
      if A.loglevel < A.loglevels[prefix] then return end

      local result, message = pcall(format, arg1, arg2, arg3, arg4, arg5, arg6, 
        arg7, arg8, arg9, arg10)
      if not result then
        local t = {}
        tinsert(t, tostring(arg1 or ""))
        tinsert(t, tostring(arg2 or ""))
        tinsert(t, tostring(arg3 or ""))
        tinsert(t, tostring(arg4 or ""))
        tinsert(t, tostring(arg5 or ""))
        tinsert(t, tostring(arg5 or ""))
        tinsert(t, tostring(arg6 or ""))
        tinsert(t, tostring(arg7 or ""))
        tinsert(t, tostring(arg8 or ""))
        tinsert(t, tostring(arg9 or ""))
        tinsert(t, tostring(arg10 or ""))
        message = tconcat(t, " ")
      end
      
      DEFAULT_CHAT_FRAME:AddMessage(
        format("%s: |c%s%s:|r %s", header, color, prefix, message))
    end
  end
end

A.debug = A.createDebugFunction("DEBUG", "ff00ffff") --cyan
A.trace = A.createDebugFunction("TRACE", "ffd800ff") --purple
A.warn = A.createDebugFunction("WARN", "ffffff00")   --yellow
A.info = A.createDebugFunction("INFO", "ff00ff00")   --green
A.error = A.createDebugFunction("ERROR", "ffff0000") --red
A.fatal = A.createDebugFunction("FATAL", "ffffffff") --white
