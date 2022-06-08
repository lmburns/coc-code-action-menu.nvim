local api = vim.api

local action_utils = require('coc_code_action_menu.utility_functions.actions')
local AnchorWindow = require('coc_code_action_menu.windows.anchor_window')
local MenuWindow = require('coc_code_action_menu.windows.menu_window')
local DetailsWindow = require('coc_code_action_menu.windows.details_window')
local DiffWindow = require('coc_code_action_menu.windows.diff_window')
local WarningMessageWindow = require(
  'coc_code_action_menu.windows.warning_message_window'
)

local anchor_window_instance = nil
local menu_window_instance = nil
local details_window_instance = nil
local diff_window_instance = nil
local warning_message_window_instace = nil

local function close_code_action_menu()
  anchor_window_instance = nil

  if details_window_instance ~= nil then
    details_window_instance:close()
    details_window_instance = nil
  end

  if diff_window_instance ~= nil then
    diff_window_instance:close()
    diff_window_instance = nil
  end

  if menu_window_instance ~= nil then
    menu_window_instance:close()
    menu_window_instance = nil
  end
end

local function close_warning_message_window()
  if warning_message_window_instace ~= nil then
    warning_message_window_instace:close()
    warning_message_window_instace = nil
  end
end

local function open_code_action_menu(mode)
  if vim.g.coc_service_initialized ~= 1 then
    vim.notify('Coc is not ready!', vim.log.levels.ERROR)
    return
  end

  -- Might still be open.
  close_code_action_menu()
  close_warning_message_window()

  mode = mode or api.nvim_get_mode().mode
  -- local use_range = vim.api.nvim_get_mode().mode ~= 'n'
  -- local all_actions = action_utils.request_actions_from_all_servers(use_range)
  --
  -- if #all_actions == 0 then
  --   warning_message_window_instace = WarningMessageWindow:new()
  --   warning_message_window_instace:open()
  --   vim.api.nvim_command(
  --     'autocmd! CursorMoved <buffer> ++once lua require("code_action_menu").close_warning_message_window()'
  --   )
  -- else
  --   anchor_window_instance = AnchorWindow:new()
  --   menu_window_instance = MenuWindow:new(all_actions)
  --   menu_window_instance:open({
  --     window_stack = { anchor_window_instance },
  --   })
  -- end

  action_utils.request_servers_for_actions(mode, function(all_actions)
    if #all_actions == 0 then
      warning_message_window_instace = WarningMessageWindow:new()
      warning_message_window_instace:open()
      vim.cmd(
        'autocmd! CursorMoved <buffer> ++once lua require("coc_code_action_menu").close_warning_message_window()'
      )
    else
      anchor_window_instance = AnchorWindow:new()
      menu_window_instance = MenuWindow:new(all_actions)
      menu_window_instance:open({
        window_stack = { anchor_window_instance },
      })
    end

    if api.nvim_get_mode().mode:lower() == 'v' then
      api.nvim_feedkeys(
        api.nvim_replace_termcodes('<ESC>', true, true, true),
        'n',
        false
      )
    end
  end)
end

local function update_details_window(selected_action)
  if
    vim.g.code_action_menu_show_details == nil
    or vim.g.code_action_menu_show_details
  then
    if details_window_instance == nil then
      details_window_instance = DetailsWindow:new(selected_action)
    else
      details_window_instance:set_action(selected_action)
    end

    local window_stack = { anchor_window_instance, menu_window_instance }

    details_window_instance:open({ window_stack = window_stack })
  end
end

local function update_diff_window(selected_action)
  if
    vim.g.code_action_menu_show_diff == nil or vim.g.code_action_menu_show_diff
  then
    if diff_window_instance == nil then
      diff_window_instance = DiffWindow:new(selected_action)
    else
      diff_window_instance:set_action(selected_action)
    end

    local window_stack = { anchor_window_instance, menu_window_instance }

    if details_window_instance ~= nil then
      table.insert(window_stack, details_window_instance)
    end

    diff_window_instance:open({ window_stack = window_stack })
  end
end

local function update_selected_action()
  local selected_action = menu_window_instance:get_selected_action()
  update_details_window(selected_action)
  update_diff_window(selected_action)
end

local function execute_selected_action()
  local selected_action = menu_window_instance:get_selected_action()

  if selected_action:is_disabled() then
    vim.notify('Can not execute disabled action!', vim.log.levels.ERROR, {})
  else
    close_code_action_menu() -- Close first to execute the action in the correct buffer.
    selected_action:execute()
  end
end

local function select_line_and_execute_action(line_number)
  vim.validate({ ['to select menu line number'] = { line_number, 'number' } })

  api.nvim_win_set_cursor(
    menu_window_instance.window_number,
    { line_number, 0 }
  )
  execute_selected_action()
end

return {
  open_code_action_menu = open_code_action_menu,
  update_selected_action = update_selected_action,
  close_code_action_menu = close_code_action_menu,
  close_warning_message_window = close_warning_message_window,
  execute_selected_action = execute_selected_action,
  select_line_and_execute_action = select_line_and_execute_action,
}
