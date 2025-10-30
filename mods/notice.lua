local A = FonzAppraiser
local L = A.locale

A.module 'fa.notice'

local pricing = A.require 'fa.value.pricing'
local session = A.require 'fa.session'

local client = A.require 'util.client'
local util = A.requires(
  'util.string',
  'util.money',
  'util.chat',
  'util.bag'
)

local leq = util.leq
local lne = util.lne

-- SETTINGS --

--Alternatives sounds (can use single '\' when passing string to addon option)
--/script PlaySoundFile("Sound\\interface\\levelup2.wav")
local SOUNDS = {
  { file=A.addon_path .. [[\sound\Bloodlust.mp3]] },
  { file="Sound\\Doodad\\BoatDockedWarning.wav" },
  { file=A.addon_path .. [[\sound\GM_ChatWarning.mp3]] },
  { file="Sound\\Item\\Weapons\\Gun\\GunFire01.wav" },
  { file=A.addon_path .. [[\sound\Heroism.mp3]] },
  { file=A.addon_path .. [[\sound\chaching.mp3]] },
  { file="Sound\\interface\\iCreateCharacterA.wav" },
  { file="Sound\\interface\\igNewTaxiNodeDiscovered.wav" },
  { file="Sound\\Item\\UseSounds\\iMagicWand1.wav" },
  { file="Sound\\interface\\levelup2.wav" },
  { file=A.addon_path .. [[\sound\Achievement.mp3]] },
  { file=A.addon_path .. [[\sound\BladesRingImpact.mp3]] },
  { file=A.addon_path .. [[\sound\DeathKnight_Bloodtap.mp3]] },
  { file=A.addon_path .. [[\sound\DeathKnight_Deathgate.mp3]] },
  { file=A.addon_path .. [[\sound\DeathKnight_Icebound_Fortitude.mp3]] },
  { file=A.addon_path .. [[\sound\DeathKnight_IcyTouch.mp3]] },
  { file=A.addon_path .. [[\sound\DeathKnight_Obliterate1.mp3]] },
  { file=A.addon_path .. [[\sound\DeathKnight_Unholypresence.mp3]] },
  { file=A.addon_path .. [[\sound\Hunter_Master_Call.mp3]] },
  { file=A.addon_path .. [[\sound\Polymorph_Rabbit.mp3]] },
  { file=A.addon_path .. [[\sound\Polymorph_Turkey.mp3]] },
  { file=A.addon_path .. [[\sound\Monk_TouchOfDeath.mp3]] },
}
M.SOUNDS = SOUNDS

function M.parseStem(path)
  local _, _, parent_path, filename, extension = strfind(path,
    "(.-)([^\\/]-%.?([^%.\\/]*))$")
  if filename then
    extension = strlower(extension)
    if extension == "mp3" or extension == "wav" then
      return strsub(filename, 1, strlen(filename) - 4)
    else
      return filename
    end
  end
end

-- Make a name for each sound based on filename without extension
for i,v in ipairs(SOUNDS) do
  local name = parseStem(v.file)
  v.name = name or v.file
end

local defaults = {
  money_threshold = 20000,
  item_threshold = 30000,
  target = NONE,
  target_notified = false,
  money_notify = {
    ["system"] = L["Earned above threshold ({threshold}) : {money}"],
    ["sound"] = A.addon_path .. [[\sound\GM_ChatWarning.mp3]],
    ["whisper"] = NONE,
    ["channel"] = NONE,
    ["group"] = NONE,
    ["guild"] = NONE,
  },
  item_notify = {
    ["system"] = L["Hot item {item} - threshold ({threshold}) : total value {value}"
      .." ({count}x)"],
    ["sound"] = A.addon_path .. [[\sound\Bloodlust.mp3]],
    ["whisper"] = NONE,
    ["channel"] = NONE,
    ["group"] = NONE,
    ["guild"] = NONE,
  },
  target_notify = {
    ["system"] = L["Target of {threshold} achieved: {value}!"],
    ["sound"] = A.addon_path .. [[\sound\Achievement.mp3]],
    ["whisper"] = NONE,
    ["channel"] = NONE,
    ["group"] = NONE,
    ["guild"] = NONE,
  },
  ignore_soulbound = true,
}
local content = client.content
if content.expansion > content.VANILLA then
  -- Expansion inflation make different thresholds more appropriate
  defaults.money_threshold = 90000
  defaults.item_threshold = 90000
  -- Use a different sound than current in-game combat sounds as defaults.
  defaults.item_notify["sound"] = A.addon_path 
    .. A.addon_path .. [[\sound\chaching.mp3]]
end
M.defaults = defaults
A.registerCharConfigDefaults("fa.notice", defaults)

-- HELPERS --

local NOTIFY_METHOD_HELP = {
  system = L["System chat message (<string>)."],
  sound = L["Any sound playable with WoW PlaySoundFile() or PlaySound() "
    .. "(<string>)."],
  whisper = L["<string: character name> <string: message to whisper>."],
  channel = L["<number: channel number> <string: message to channel>."],
  group = L["<string>"],
  guild = L["<string>"],
}
M.NOTIFY_METHOD_HELP = NOTIFY_METHOD_HELP

function M.getTarget()
  local money = session.getCurrentMoney()
  local value = session.getCurrentItemsValue()
  local total = (money or 0) + (value or 0)
  local db = A.getCharConfig("fa.notice")
  return total, db.target
end

function M.getTargetNotified()
  local db = A.getCharConfig("fa.notice")
  return db.target_notified
end

function M.resetTarget()
  local db = A.getCharConfig("fa.notice")
  db.target_notified = false
  A.info("Target reset.")
end

do
  local find = string.find
  local replace_vars = util.replace_vars
  local whisperMessage = util.whisperMessage
  local chatMessage = util.chatMessage
  
  local function playSound(location)
    local found = find(location, "\\")
    if found then
      PlaySoundFile(location)
    else
      PlaySound(location)
    end
  end
  
  -- NOTIFIERS --
  
  local notifier_priority = {
    "system",
    "sound",
    "error",
    "addon",
    "whisper",
    "channel",
    "group",
    "guild",
  }
  M.NOTIFY_TYPES = notifier_priority

  local money_notifiers = {
    ["system"]=function(money, threshold)
      local db = A.getCharConfig("fa.notice")
      local setting = db.money_notify["system"]
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.money_notify["system"]
      end
      if A:isEnabled() and lne(setting, NONE) then
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          threshold = util.formatMoneyFull(threshold, true),
          money = util.formatMoneyFull(money, true)
        }
        A:ePrint(str)
      end
    end,
    ["sound"]=function()
      local db = A.getCharConfig("fa.notice")
      local setting = db.money_notify["sound"] 
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.money_notify["sound"]
      end
      if lne(setting, NONE) then
        playSound(setting)
      end
    end,
    ["whisper"]=function(money, threshold)
      local db = A.getCharConfig("fa.notice")
      local setting = db.money_notify["whisper"]
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.money_notify["whisper"]
      end
      if lne(setting, NONE) then
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          threshold = util.formatMoneyFull(threshold, true),
          money = util.formatMoneyFull(money, true)
        }
        local _, _, name, msg = find(str, "(%a+)%s+(%S.+)")
        if name and msg then
          whisperMessage(name, msg)
        end
      end
    end,
    ["channel"]=function(money, threshold)
      local db = A.getCharConfig("fa.notice")
      local setting = db.money_notify["channel"]
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.money_notify["channel"]
      end
      if lne(setting, NONE) then
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          threshold = util.formatMoneyFull(threshold, true),
          money = util.formatMoneyFull(money, true)
        }
        local _, _, channel_number, msg = find(str, "(%d+)%s+(%S.+)")
        if channel_number and msg then
          chatMessage(msg, tonumber(channel_number))
        end
      end
    end,
    ["group"]=function(money, threshold)
      local db = A.getCharConfig("fa.notice")
      local setting = db.money_notify["group"]
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.money_notify["group"]
      end
      if lne(setting, NONE) then
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          threshold = util.formatMoneyFull(threshold, true),
          money = util.formatMoneyFull(money, true)
        }
        chatMessage(str, "GROUP")
      end
    end,
    ["guild"]=function(money, threshold)
      local db = A.getCharConfig("fa.notice")
      local setting = db.money_notify["guild"]
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.money_notify["guild"]
      end
      if lne(setting, NONE) then
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          threshold = util.formatMoneyFull(threshold, true),
          money = util.formatMoneyFull(money, true)
        }
        chatMessage(str, "GUILD")
      end
    end,
  }

  local item_notifiers = {
    ["system"]=function(code, count, total, threshold)
      local db = A.getCharConfig("fa.notice")
      local setting = db.item_notify["system"] 
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.item_notify["system"]
      end
      if A:isEnabled() and lne(setting, NONE) then
        local pricing = A.getCharConfig("fa.value.pricing").pricing or ""
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          item = session.safeItemLink(code),
          threshold = util.formatMoneyFull(threshold, true),
          value = util.formatMoneyFull(total, true),
          pricing = pricing,
          count = count
        }
        A:ePrint(str)
      end
    end,
    ["sound"]=function()
      local db = A.getCharConfig("fa.notice")
      local setting = db.item_notify["sound"] 
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.item_notify["sound"]
      end
      if lne(setting, NONE) then
        playSound(setting)
      end
    end,
    ["whisper"]=function(code, count, total, threshold)
      local db = A.getCharConfig("fa.notice")
      local setting = db.item_notify["whisper"] 
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.item_notify["whisper"]
      end
      if lne(setting, NONE) then
        local pricing = A.getCharConfig("fa.value.pricing").pricing or ""
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          item = session.safeItemLink(code),
          threshold = util.formatMoneyFull(threshold, true),
          value = util.formatMoneyFull(total, true),
          pricing = pricing,
          count = count
        }
        local _, _, name, msg = find(str, "(%a+)%s+(%S.+)")
        if name and msg then
          whisperMessage(name, msg)
        end
      end
    end,
    ["channel"]=function(code, count, total, threshold)
      local db = A.getCharConfig("fa.notice")
      local setting = db.item_notify["channel"] 
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.item_notify["channel"]
      end
      if lne(setting, NONE) then
        local pricing = A.getCharConfig("fa.value.pricing").pricing or ""
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          item = session.safeItemLink(code),
          threshold = util.formatMoneyFull(threshold, true),
          value = util.formatMoneyFull(total, true),
          pricing = pricing,
          count = count
        }
        local _, _, channel_number, msg = find(str, "(%d+)%s+(%S.+)")
        if channel_number and msg then
          chatMessage(msg, tonumber(channel_number))
        end
      end
    end,
    ["group"]=function(code, count, total, threshold)
      local db = A.getCharConfig("fa.notice")
      local setting = db.item_notify["group"] 
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.item_notify["group"]
      end
      if lne(setting, NONE) then
        local pricing = A.getCharConfig("fa.value.pricing").pricing or ""
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          item = session.safeItemLink(code),
          threshold = util.formatMoneyFull(threshold, true),
          value = util.formatMoneyFull(total, true),
          pricing = pricing,
          count = count
        }
        chatMessage(str, "GROUP")
      end
    end,
    ["guild"]=function(code, count, total, threshold)
      local db = A.getCharConfig("fa.notice")
      local setting = db.item_notify["guild"] 
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.item_notify["guild"]
      end
      if lne(setting, NONE) then
        local pricing = A.getCharConfig("fa.value.pricing").pricing or ""
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          item = session.safeItemLink(code),
          threshold = util.formatMoneyFull(threshold, true),
          value = util.formatMoneyFull(total, true),
          pricing = pricing,
          count = count
        }
        chatMessage(str, "GUILD")
      end
    end,
  }

  local target_notifiers = {
    ["system"]=function(value, target)
      local db = A.getCharConfig("fa.notice")
      local setting = db.target_notify["system"]
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.target_notify["system"]
      end
      if A:isEnabled() and lne(setting, NONE) then
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          threshold = util.formatMoneyFull(target, true),
          value = util.formatMoneyFull(value, true)
        }
        A:ePrint(str)
      end
    end,
    ["sound"]=function()
      local db = A.getCharConfig("fa.notice")
      local setting = db.target_notify["sound"] 
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.target_notify["sound"]
      end
      if lne(setting, NONE) then
        playSound(setting)
      end
    end,
    ["whisper"]=function(value, target)
      local db = A.getCharConfig("fa.notice")
      local setting = db.target_notify["whisper"]
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.target_notify["whisper"]
      end
      if lne(setting, NONE) then
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          threshold = util.formatMoneyFull(target, true),
          value = util.formatMoneyFull(value, true)
        }
        local _, _, name, msg = find(str, "(%a+)%s+(%S.+)")
        if name and msg then
          whisperMessage(name, msg)
        end
      end
    end,
    ["channel"]=function(value, target)
      local db = A.getCharConfig("fa.notice")
      local setting = db.target_notify["channel"]
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.target_notify["channel"]
      end
      if lne(setting, NONE) then
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          threshold = util.formatMoneyFull(target, true),
          value = util.formatMoneyFull(value, true)
        }
        local _, _, channel_number, msg = find(str, "(%d+)%s+(%S.+)")
        if channel_number and msg then
          chatMessage(msg, tonumber(channel_number))
        end
      end
    end,
    ["group"]=function(value, target)
      local db = A.getCharConfig("fa.notice")
      local setting = db.target_notify["group"]
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.target_notify["group"]
      end
      if lne(setting, NONE) then
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          threshold = util.formatMoneyFull(target, true),
          value = util.formatMoneyFull(value, true)
        }
        chatMessage(str, "GROUP")
      end
    end,
    ["guild"]=function(value, target)
      local db = A.getCharConfig("fa.notice")
      local setting = db.target_notify["guild"]
      if setting and leq(setting, DEFAULTS) or not setting then 
        setting = defaults.target_notify["guild"]
      end
      if lne(setting, NONE) then
        local str = replace_vars{
          setting,
          zone = session.getCurrentZone(),
          threshold = util.formatMoneyFull(target, true),
          value = util.formatMoneyFull(value, true)
        }
        chatMessage(str, "GUILD")
      end
    end,
  }
  
  -- NOTICE UPDATES --

  function checkTarget()
    local db = A.getCharConfig("fa.notice")
    local target_total, target = getTarget()
    if not db.target_notified and lne(target, NONE) 
        and target > 0 and target_total >= target then
      for _, v in ipairs(notifier_priority) do
        local notifier = target_notifiers[v]
        if notifier then notifier(target_total, target) end
      end
      db.target_notified = true
    end
  end

  function M.checkMoney(money)
    local db = A.getCharConfig("fa.notice")
    local threshold = db.money_threshold
    local notified = false
    if lne(threshold, NONE) and threshold > 0 and money >= threshold then
      for _, v in ipairs(notifier_priority) do
        local notifier = money_notifiers[v]
        if notifier then notifier(money, threshold) end
      end
      notified = true
    end
    
    if session.isCurrent() then
      checkTarget()
    end
    return notified
  end

  do
    local hasSoulboundItemCode = util.hasSoulboundItemCode
    
    function M.checkItem(code, item_count, callback)
      local db = A.getCharConfig("fa.notice")
      local value = pricing.value(code)
      if not value or value < 1 then return end
      
      local total_value = value * item_count  

      local threshold = db.item_threshold
      if lne(threshold, NONE) and total_value >= threshold then
        --Soulbound check placed here as late as possible since it 
        --searches bags.
        if db.ignore_soulbound and hasSoulboundItemCode(code) then
          return
        end
        callback()
        for _, v in ipairs(notifier_priority) do
          local notifier = item_notifiers[v]
          if notifier then 
            notifier(code, item_count, total_value, threshold) 
          end
        end
      end
      
      if session.isCurrent() then
        checkTarget()
      end
    end
  end
end

-- MODULE OPTIONS --

if not A.options then
  A.options = {
    type = "group",
    args = {},
  }
end

do
  local money_example = util.formatMoneyFull(1632328)
  local isempty = util.isSpaceOrEmpty
  
  local function moneyToString(money)
    local n = tonumber(money)
    return n and util.formatMoneyFull(n, true) or money
  end
  
  local function normalize(msg)
    if isempty(msg) then return end
    local n = util.stringToMoney(msg)
    return (n and n > 0) and n or NONE
  end
  
  local function check(msg)
    if isempty(msg) then return end
    local n = util.stringToMoney(msg)
    return (n and n >= 0) or (msg and leq(msg, NONE))
  end
  
  function M.changeTarget(msg)
    local target = normalize(msg)
    local db = A.getCharConfig("fa.notice")
    db.target = target
    resetTarget()
    A:guiUpdate()
  end
  
  A.options.args["Notice"] = {
    name = L["Notice"],
    desc = L["Notice valuable loot"],
    type = "group",
    args = {
      Money = {
        type = "text",
        name = L["Money threshold"],
        desc = format(L["Threshold for money notices, e.g. %s"], money_example),
        get = function() 
          local db = A.getCharConfig("fa.notice")
          return moneyToString(db.money_threshold)
        end,
        set = function(msg) 
          local db = A.getCharConfig("fa.notice")
          db.money_threshold = normalize(msg)
          A:guiUpdate()
        end,
        usage = format(L["<money> or |cffffff7f%s|r"], NONE),
        validate = check,
      },
      Item = {
        type = "text",
        name = L["Item value threshold"],
        desc = format(L["Threshold for item value notices, e.g. %s"], 
          money_example),
        get = function() 
          local db = A.getCharConfig("fa.notice")
          return moneyToString(db.item_threshold)
        end,
        set = function(msg) 
          local db = A.getCharConfig("fa.notice")
          db.item_threshold = normalize(msg) 
          A:guiUpdate()
        end,
        usage = format(L["<money> or |cffffff7f%s|r"], NONE),
        validate = check,
      },
      Target = {
        type = "text",
        name = L["Total value target"],
        desc = format(L["Target for total value notices, e.g. %s"], 
          money_example),
        get = function() 
          local db = A.getCharConfig("fa.notice")
          return moneyToString(db.target)
        end,
        set = changeTarget,
        usage = format(L["<money> or |cffffff7f%s|r"], NONE),
        validate = check,
      },
      Soulbound = {
        type = "toggle",
        name = L["Ignore Soulbound"],
        desc = L["Toggle whether to ignore soulbound items"],
        get = function()
          local db = A.getCharConfig("fa.notice")
          return db.ignore_soulbound
        end,
        set = function()
          local db = A.getCharConfig("fa.notice")
          db.ignore_soulbound = not db.ignore_soulbound
          A:guiUpdate()
        end,
      }
    },
  }
  --Alias
  A.options.args["Target"] = A.options.args["Notice"]["args"]["Target"]
end

do
  function M.normalizePath(path)
    local _, _, double_quoted_path = string.find(path, '^"([^"]+)"$')
    local _, _, single_quoted_path = string.find(path, "^'([^']+)'$")
    path = double_quoted_path or single_quoted_path or path
    path = gsub(path, [[\\]], [[\]])
    return path
  end
  
  local function getOption(notify_type, option)
    local db = A.getCharConfig("fa.notice")
    local notify_name = notify_type .. "_notify"
    return db[notify_name][option]
  end
  
  local function setOption(notify_type, option, value)
    local db = A.getCharConfig("fa.notice")
    local notify_name = notify_type .. "_notify"
    if leq(value, DEFAULTS) then value = defaults[notify_name][option] end
    db[notify_name][option] = normalizePath(value)
    A:guiUpdate()
  end
  
  local suboptions = {
    {
      name = L["System"],
      desc = L["Notify system chat"],
      method = "system",
      help = NOTIFY_METHOD_HELP["system"],
    },
    {
      name = L["Sound"],
      desc = L["Notify by sound"],
      method = "sound",
      help = NOTIFY_METHOD_HELP["sound"],
    },
    {
      name = L["Whisper"],
      desc = L["Notify by whisper"],
      method = "whisper",
      help = NOTIFY_METHOD_HELP["whisper"],
    },
    {
      name = L["Channel"],
      desc = L["Notify channel"],
      method = "channel",
      help = NOTIFY_METHOD_HELP["channel"],
    },
    {
      name = L["Group"],
      desc = L["Notify group"],
      method = "group",
      help = NOTIFY_METHOD_HELP["group"],
    },
    {
      name = L["Guild"],
      desc = L["Notify guild"],
      method = "guild",
      help = NOTIFY_METHOD_HELP["guild"],
    },
  }
  
  local function optionsGen()
    local args = {}
    for i,option in ipairs({ "Money", "Item", "Target" }) do
      args[option] = {
        name = L[option],
        desc = format(L["Notify methods for %s"], L[option]),
        type = "group",
      }
      local sub_args = {}
      for j,suboption in ipairs(suboptions) do
        local notify_type = strlower(option)
        local method = suboption.method
        sub_args[method] = {
          type = "text",
          name = suboption.name,
          desc = suboption.desc,
          get = function()
            return getOption(notify_type, method)
          end,
          set = function(value)
            setOption(notify_type, method, value)
          end,
          usage = format(
          L["|cffffff7f%s|r to reset or |cffffff7f%s|r to disable. Format: %s"], 
            DEFAULTS, NONE, suboption.help),
        }
      end
      args[option]["args"] = sub_args
    end
    return args
  end
  
  local notify_options = optionsGen()
  
  A.options.args["Notify"] = {
    name = L["Notify"],
    desc = L["Notify methods for Notices"],
    type = "group",
    args = notify_options,
  }
end