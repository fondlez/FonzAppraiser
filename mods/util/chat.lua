local A = FonzAppraiser

A.module 'util.chat'

function isempty(s)
  return s == nil or s == ''
end

function M.colorString(msg, color)
  color = color or "ffffffff"
  return string.format("|c%s%s|r", color, msg)
end

function M.systemChat(...)
  local arg = arg or {...}
  local result, message = pcall(string.format, unpack(arg))
  if not result then
    local t = {}
    for i, v in ipairs(arg) do
      t[i] = tostring(v)
    end
    message = table.concat(t, " ")
  end
  DEFAULT_CHAT_FRAME:AddMessage(message)
end

function M.chatMessage(msg, chat_type)
  if isempty(msg) then return end
  chat_type = chat_type or "GROUP"
  if tonumber(chat_type) then
    SendChatMessage(msg, "CHANNEL", nil, chat_type)
  else
    if chat_type == "GROUP" then
      SendChatMessage(msg, UnitInRaid("player") and "RAID" or "PARTY")
    else
      SendChatMessage(msg, chat_type)
    end
  end
end

do
  local function isFriend(name)
    -- Update friend list
    ShowFriends()
    
    local n = GetNumFriends()
    if n and n > 0 then
      local friend_name, level, class, area, connected
      for index=1,n do
        friend_name, level, class, area, connected = GetFriendInfo(index)
        if strlower(friend_name) == strlower(name) then
          return friend_name, connected
        end
      end
      -- Friend not found
      return false
    end
    -- Empty friend list
    return
  end
  
  -- Unfortunately, this online check currently only works with friends
  local function isOnline(name)
    local friend_name, connected = isFriend(name)
    return friend_name and connected
  end

  function M.whisperMessage(target, msg, online_only)
    if isempty(target) or isempty(msg) then return end
    if not online_only or isOnline(target) then
      SendChatMessage(msg, "WHISPER", nil, target)
    end
  end
end