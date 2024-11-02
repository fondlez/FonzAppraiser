local A = FonzAppraiser
local L = A.locale

A.module 'fa'

local util = A.requires(
  'util.table',
  'util.string',
  'util.chat'
)

local palette = A.require 'fa.palette'
local misc = A.require 'fa.misc'
local gui_config = A.require 'fa.gui.config'

local color_heading = palette.color.yellow
local color_group = palette.color.blue1
local color_normal = palette.color.white
local color_true = palette.color.green
local color_false = palette.color.red

local format = string.format

local defaults = {
  enable = false,
}
A.registerCharConfigDefaults("fa", defaults)

do
  local join = util.strniljoin
  
  -- General print without an addon name prefix
  function A:rawPrint(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, 
      arg10)
    DEFAULT_CHAT_FRAME:AddMessage(color_normal(join("", arg1, arg2, arg3, 
      arg4, arg5, arg6, arg7, arg8, arg9, arg10)))
  end
  
  -- General print with an addon name prefix
  function A:print(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
    DEFAULT_CHAT_FRAME:AddMessage(format("%s: %s", color_heading(A.name), 
      color_normal(join("", arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, 
        arg9, arg10))))
  end
end

do
  local formatChat = util.formatChat
  
  function A:isEnabled()
    local db = A.getCharConfig("fa")
    return db.enable
  end
  
  -- Toggleable format print with an addon name prefix
  function A:ePrint(format_string, arg2, arg3, arg4, arg5, arg6, arg7, arg8, 
      arg9, arg10)
    if not A:isEnabled() then return end
    
    local addon_prefix = format("%s: ", color_heading(A.name))
    
    formatChat(format("%s%s", addon_prefix, color_normal(format_string)),
      arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
  end
end

--------------------------------------------------------------------------------

do  
  local join, split, match, tolower = strjoin, strsplit, 
    strmatch or util.strmatch, strlower
  local isempty = util.isempty
  local isNotSpaceOrEmpty = util.isNotSpaceOrEmpty
  local leq = util.leq
  local keyslower = util.keyslower
  local sortedKeys = util.sortedKeys
  local sortedPairs = util.sortedPairs
  
  local lowercase_table_cache = setmetatable({}, {
    __index = function(t, k)
      if type(k) == "table" then
        local l = keyslower(k)
        rawset(t, k, l)
        return l
      end
    end
  })
  
  local function getLowercaseKeyTable(t)
    return lowercase_table_cache[t]
  end
  
  local function color_bracket(text, color)
    color = color or color_heading
    return format("%s%s%s", color("["), text or '', color("]"))
  end
  
  local option_formatter = {
    ["text"] = function(name, text)
      return format("%s %s %s", 
        color_heading(name), 
        color_normal(L["is currently set to"]), 
        color_bracket(text))
    end,
    ["toggle"] = function(name, toggle)
      return format("%s %s %s", 
        color_heading(name), 
        color_normal(L["is now set to"]), 
        color_bracket(toggle and color_true(L["On"]) or color_false(L["Off"])))
    end,
    ["group"] = {
      ["text"] = function(name, description, text)
        return format("- %s %s %s", 
          color_heading(format("%s:", name)), 
          color_bracket(text),
          color_normal(description))
      end,
      ["toggle"] = function(name, description, toggle)
        return format("- %s %s %s", 
          color_heading(format("%s:", name)), 
          color_bracket(toggle and color_true(L["On"]) 
            or color_false(L["Off"])),
          color_normal(description))
      end,
      ["group"] = function(name, description, unused)
        return format("- %s %s", 
          color_group(format("%s:", name)),
          color_normal(description))
      end,
      ["execute"] = function(name, description, unused)
        return format("- %s %s", 
          color_heading(format("%s:", name)),
          color_normal(description))
      end,
    },
  }
  
  local function formatUsage(prefix, usage)
    local addon_cmd = L["SLASHCMD_SHORT"]
    local prefix_string = not isempty(prefix) and (' ' .. prefix) or ''
    return format("%s %s%s %s", color_heading("Usage:"), addon_cmd,
      color_normal(prefix_string), usage or '')
  end
  
  function formatOptionUsage(name, option, prefix)
    return formatUsage(prefix, option.usage)
  end
  
  function formatGroupUsage(cmd, group, prefix)
    local list = join(" \124 ", unpack(sortedKeys(group.args)))
    return formatUsage(prefix, format("{%s}", list))
  end

  function processSubcommand(cmd, option, msg, prefix)
    -- No valid option found, so list top level options header
    if not option then 
      local addon_notes = GetAddOnMetadata(A.name, "Notes")
      A:print(color_normal(addon_notes or ""))
      A:rawPrint(formatGroupUsage(nil, A.options, nil))
      
      -- List top level option status
      local group_formatter = option_formatter["group"]
      for k, v in sortedPairs(A.options.args) do
        local formatter = group_formatter[v.type]
        A:rawPrint(formatter(tolower(k), v.desc, v.get and v.get()))
      end     
      return
    end
    
    if leq(option.type, "text") then
      local validate = msg and option.validate
      local set_check = validate and validate(msg) or isNotSpaceOrEmpty(msg)
      local get = option.get
      local formatter = option_formatter["text"]
      
      if not set_check then
        A:print(formatOptionUsage(cmd, option, prefix))
        A:rawPrint(formatter(option.name, get and get() or ''))
      else
        local set = option.set
        if set then set(msg) end
        if get then
          A:print(formatter(option.name, get()))
        end
      end
    elseif leq(option.type, "toggle") then
      local formatter = option_formatter["toggle"]
      local get, set = option.get, option.set
      if set then set() end
      if get then 
        A:print(formatter(option.name, get()))
      end
    elseif leq(option.type, "execute") then
      local func = option.func
      if func then func() end
    elseif leq(option.type, "group") then
      local subcommand, rest
      if msg then
        subcommand, rest = match(msg, "^(%w+)%s*(.*)$")
      end
      local args = getLowercaseKeyTable(option.args)
      local lc_subcommand = subcommand and tolower(subcommand)
      local child_option = lc_subcommand and args[lc_subcommand]
      
      -- No subcommand or valid option found, so list group header and status
      if not subcommand or not child_option then
        A:print(formatGroupUsage(cmd, option, prefix))
        local group_formatter = option_formatter["group"]
        for k, v in sortedPairs(args) do
          local formatter = group_formatter[v.type]
          A:rawPrint(formatter(k, v.desc, v.get and v.get()))
        end  
      else
        -- Tail call (return must be present)
        return processSubcommand(subcommand, child_option, rest,
          subcommand and join(" ", prefix, subcommand) or prefix)
      end
    else
      A.warn("Unknown option type: %s", tostring(option.type))
    end
  end
  
  function processCommand(msg, options)
    local subcommand, rest
    if msg then
      subcommand, rest = match(msg, "^(%w+)%s*(.*)$")
    end
    if not subcommand then
      A.toggleMainWindow()
    else
      local args = getLowercaseKeyTable(options.args)
      return processSubcommand(subcommand, args[tolower(subcommand)], rest, 
        subcommand)
    end
  end
end

function SlashCmdList.fa_cmd(msg)
  processCommand(msg, A.options)
end
_G.SLASH_fa_cmd1 = L["SLASHCMD_SHORT"]
_G.SLASH_fa_cmd2 = L["SLASHCMD_LONG"]

function SlashCmdList.fa_value()
  misc.bagValue()
end
_G.SLASH_fa_value1 = L["SLASHCMD_BAG_VALUE1"]
_G.SLASH_fa_value2 = L["SLASHCMD_BAG_VALUE2"] 

function SlashCmdList.fa_rvalue()
  misc.bagValue(true)
end
_G.SLASH_fa_rvalue1 = L["SLASHCMD_BAG_REVERSE_VALUE1"]
_G.SLASH_fa_rvalue2 = L["SLASHCMD_BAG_REVERSE_VALUE2"]

do
  local function toggleEnabled()
    local db = A.getCharConfig("fa")
    db.enable = not db.enable
    gui_config.update()
  end
  
  if not A.options then
    A.options = {
      type = "group",
      args = {},
    }
  end

  A.options.args["Enable"] = {
    type = "toggle",
    name = L["Enable chat output"],
    desc = L["Toggles whether to show chat output"],
    get = A.isEnabled,
    set = toggleEnabled,
  }
  A.options.args["Value"] = {
    type = "execute",
    name = L["Bag value"],
    desc = L["Value of non-soulbound items in bags"],
    func = SlashCmdList.fa_value,
  }
  A.options.args["RValue"] = {
    type = "execute",
    name = L["Bag value (reverse)"],
    desc = L["Value of non-soulbound items in bags (reverse)"],
    func = SlashCmdList.fa_rvalue,
  }
end