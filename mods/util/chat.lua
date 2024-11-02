local A = FonzAppraiser

A.module 'util.chat'

local client = A.require 'util.client'
local util = A.require 'util.string'

local format = string.format

function isempty(s)
  return s == nil or s == ''
end

if client.is_tbc_or_less then
  function M.chatlink(item_link)
    if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
      ChatFrameEditBox:Insert(item_link)
    end
  end
else
  -- Shift clicking item links into chat changed from patch 3.3.5 due to
  -- large changes to ChatFrame code.
  -- Alternative to below is using ChatFrame1EditBox instead.
  function M.chatlink(item_link)
    local editbox = ChatEdit_ChooseBoxForSend()
    
    ChatEdit_ActivateChat(editbox)
    
    if editbox then
      editbox:Insert(item_link)
    end
  end
end

do
  local SendChatMessage = SendChatMessage
  
  function M.chatMessage(msg, chat_type)
    if isempty(msg) then return end
    chat_type = chat_type or "GROUP"
    if tonumber(chat_type) then
      SendChatMessage(msg, "CHANNEL", nil, chat_type)
    else
      if strlower(chat_type) == strlower("GROUP") then
        SendChatMessage(msg, UnitInRaid("player") and "RAID" or "PARTY")
      else
        SendChatMessage(msg, chat_type)
      end
    end
  end
end

function M.colorString(msg, color)
  color = color or "ffffffff"
  return format("|c%s%s|r", color, msg)
end

do  
  function M.formatChat(format_string, arg2, arg3, arg4, arg5, arg6, arg7, arg8, 
      arg9, arg10)
    local msg = format(format_string, arg2, arg3, arg4, arg5, arg6, arg7, arg8, 
      arg9, arg10)
    
    DEFAULT_CHAT_FRAME:AddMessage(msg)
  end
end

do
  local GetFriendInfo = GetFriendInfo
  local GetNumFriends = GetNumFriends
  local SendChatMessage = SendChatMessage
  local ShowFriends = ShowFriends
  
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