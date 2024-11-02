local A = FonzAppraiser

A.module 'util.compat'

local client = A.require 'util.client'

if client.is_tbc_or_less then
  -- FrameXML\UIPanelTemplates.lua
  ---[[
  function M.FauxScrollFrame_OnVerticalScroll(self, value, itemHeight, 
      updateFunction)
    return _G.FauxScrollFrame_OnVerticalScroll(itemHeight, updateFunction)
  end
  
  M.PanelTemplates_TabResize = _G.PanelTemplates_TabResize
  --]]
  
  -- FrameXML\UIDropDownMenu.lua
  ---[[
  M.UIDropDownMenu_JustifyText = _G.UIDropDownMenu_JustifyText
  
  M.UIDropDownMenu_SetButtonWidth = _G.UIDropDownMenu_SetButtonWidth
  
  M.UIDropDownMenu_SetText = _G.UIDropDownMenu_SetText
  
  M.UIDropDownMenu_SetWidth = _G.UIDropDownMenu_SetWidth
  --]]
else
  -- FrameXML\UIPanelTemplates.lua
  ---[[
  M.FauxScrollFrame_OnVerticalScroll = _G.FauxScrollFrame_OnVerticalScroll
  
  function M.PanelTemplates_TabResize(padding, tab, absoluteSize, maxWidth, 
      absoluteTextSize)
    return _G.PanelTemplates_TabResize(tab, padding, absoluteSize, maxWidth, 
      absoluteTextSize)
  end
  --]]
  
  -- FrameXML\UIDropDownMenu.lua
  ---[[
  function M.UIDropDownMenu_JustifyText(justification, frame)
    return _G.UIDropDownMenu_JustifyText(frame, justification)
  end
  
  function M.UIDropDownMenu_SetButtonWidth(width, frame)
    return _G.UIDropDownMenu_SetButtonWidth(frame, width)
  end

  function M.UIDropDownMenu_SetText(text, frame)
    return _G.UIDropDownMenu_SetText(frame, text)
  end
  
  function M.UIDropDownMenu_SetWidth(width, frame, padding)
    return _G.UIDropDownMenu_SetWidth(frame, width, padding)
  end
  --]]
end


