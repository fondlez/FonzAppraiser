local A = FonzAppraiser

A.namespaces = {}

function A.registerCharConfigDefaults(name, defaults)
  if not A.namespaces[name] then
    A.namespaces[name] = {}
  end
  local module = A.namespaces[name]
  
  if not defaults or type(defaults) ~= "table" then 
    A.warn("Table data expected for character variable config defaults.")
  end
  
  module["defaults"] = defaults or {}
end

function A.getCharConfigDefaults(name)
  if not A.namespaces[name] then return end
  return A.namespaces[name]["defaults"]
end

function A.setCharConfigDefaults()
  local _G = getfenv(0)
  local svar_name = A.name .. "CDB"
  if not _G[svar_name] then
    _G[svar_name] = {}
  end
  local saved_variable = _G[svar_name]
  
  if not saved_variable["namespaces"] then 
    saved_variable["namespaces"] = {}
  end
  local namespaces = saved_variable["namespaces"]  
  
  local found = false
  for name, module in pairs(A.namespaces) do
    if not namespaces[name] then
      namespaces[name] = {}
    end
    local namespace = namespaces[name]
    
    local defaults = module["defaults"]
    for k, v in pairs(defaults) do
      if not namespace[k] then
        namespace[k] = v
        found = true
      end
    end
  end
  if found then
    A.info("Saved character variable: defaults set.")
  end
end

function A.getCharConfig(name)
  --Locate variable access attempts before addon name is resolved.
  --This typically may happen with dropdown menu initialization function calls.
  if not A.is_loaded then
    A.error("Addon has not loaded: %s", debugstack(2))
    return
  end
  
  local _G = getfenv(0)
  local saved_variable = _G[A.name .. "CDB"]
  if not saved_variable then 
    A.error("No addon saved character variable found: %s",
      debugstack(2))
    return
  end
  
  local namespaces = saved_variable["namespaces"]
  if not namespaces or not namespaces[name] then 
    A.error("No namespace data for addon saved character variable found: %s",
      debugstack(2))
    return
  end
  
  return namespaces[name]
end