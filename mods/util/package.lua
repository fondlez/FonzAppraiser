--[[ 
Modified (@fondlez):
- add: A.module() can import interface names directly as an initial environment
- add: A.requires() for interface with multiple modules. Order matters
- change: makes packaging safe and flexible by becoming addon-scoped
- change: fully commented for future clarity

Original credit: @shirsig, author of "aux-addon"
--]]

-- Customize for every addon by re-assigning the addon global to the local "A"
local A = FonzAppraiser

-- Global imports
local _G, setfenv, setmetatable = getfenv(0), setfenv, setmetatable

-- Dictionaries
local environments, interfaces = {}, {}

-- Null function
local function pass() end

-- Creates a metatable that indexes the global environment
local environment_mt = {__index=_G}

local function create_module(name)
  -- Creates an "environment" table with shortcuts to the global environment
  -- and a null function. Queries will search the global environment.
  local environment = setmetatable({_G=_G, pass=pass}, environment_mt)
  local exports = {}
  -- Creates a module interface, "M", as a write-only sub-table where 
  -- key-value updates write to the parent table and an exports table.
  environment.M = setmetatable({}, {
    __metatable=false,
    __newindex=function(_, k, v)
      environment[k], exports[k] = v, v
    end,
  })
  -- Adds an internal shortcut to the parent table (similar to '_G' for global)
  environment._M = environment
  -- Names and inserts the "environment" to a dictionary of environments
  environments[name] = environment
  -- Names and inserts an "interface" - a read-only table where queries will 
  -- search the exports table - to a dictionary of interfaces.
  interfaces[name] = setmetatable({}, {__metatable=false, __index=exports, 
    __newindex=pass})
end

-- Use to declare a module or extend an existing one as the local environment
function A.module(name, imports_table)
  -- Creates a named module if not already present, where a module is actually
  -- a table from a dictionary and containing a special key called "M"
  -- for updates.
  local defined = not not environments[name]
  if not defined then
    create_module(name)
  end
  
  local merged = environments[name]
  
  -- Import entries from a list of interface names, if available
  if imports_table then
    for _, import_name in ipairs(imports_table) do
      local import_env = environments[import_name]
      local import_interface = interfaces[import_name]
      for k, v in pairs(import_env) do
        -- Do not overwrite existing entries
        if import_interface[k] and not rawget(merged, k) then
          merged[k] = v
        end
      end
    end
  end
  
  -- Sets the named module's table as the caller's environment.
  -- Note. 0 = global, 1 = current function, 2 = caller.
  setfenv(2, merged)
  -- Returns whether the module was already defined  
  return defined, name
end

-- Grant read-only access to the interface (exported names) of a module as a
-- variable
function A.require(name)
  -- Creates a named module if not already present
  if not interfaces[name] then
    create_module(name)
  end
  -- Returns the interface of a named module
  return interfaces[name]
end

do
  -- A utility to process multiple arguments as a (non-nil) table instead
  local function into_table(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, 
      arg9, arg10)
    local t = {}
    if arg1 then tinsert(t, arg1) end
    if arg2 then tinsert(t, arg2) end
    if arg3 then tinsert(t, arg3) end
    if arg4 then tinsert(t, arg4) end
    if arg5 then tinsert(t, arg5) end
    if arg6 then tinsert(t, arg6) end
    if arg7 then tinsert(t, arg7) end
    if arg8 then tinsert(t, arg8) end
    if arg9 then tinsert(t, arg9) end
    if arg10 then tinsert(t, arg10) end
    
    return t
  end
  
  -- Grant read-only access to interfaces (exported names) of multiple modules
  -- as a variable
  function A.requires(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, 
      arg9, arg10)
    local arg = into_table(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, 
      arg9, arg10)
    -- Checks that all arguments already exist as a named interface.
    -- Creating new modules is not permitted through this function.
    for _, name in ipairs(arg) do
      if not interfaces[name] then return end
    end
    -- Creates a read-only metatable that searches for a key across all the
    -- named input interfaces.
    -- Returns the first value found. Therefore, the order of the named inputs
    -- matters.
    local aggregate_mt = {
      __metatable=false,
      __newindex=pass,
      __index=function(_, key)
        for _, name in ipairs(arg) do
          local value = interfaces[name][key]
          if value ~= nil then return value end --nil check intentional
        end
      end
    }
    -- Returns a searchable table as a "namespace" across named interfaces
    return setmetatable({}, aggregate_mt)
  end
end
