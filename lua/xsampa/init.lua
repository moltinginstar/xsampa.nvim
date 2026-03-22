local M = {}

local ns = vim.api.nvim_create_namespace("xsampa")
local xsampa_core = require("xsampa.core")

local config = {
  float = {
    width = 48,
    border = "rounded",
    divider_char = "─",
  },
  specs = nil,
  extend_specs = nil,
}

local engine = xsampa_core
local state = nil
local field_labels = {
  xsampa = "X-SAMPA",
  ipa = "IPA",
}
local field_order = {
  xsampa = 1,
  ipa = 3,
}
local label_width = #field_labels.xsampa
local content_col = #(string.format("%-" .. label_width .. "s   ", ""))

---@class xsampa.RangeOpts: vim.api.keyset.create_user_command.command_args
---@field from "xsampa"|"ipa"

local function build_engine()
  if config.specs or config.extend_specs then
    engine = xsampa_core.new({
      specs = config.specs,
      extend_specs = config.extend_specs,
    })
  else
    engine = xsampa_core
  end
end

local function convert_text(text, opts)
  return engine.xsampa_to_ipa(text, opts)
end

local function reverse_convert_text(text, opts)
  return engine.ipa_to_xsampa(text, opts)
end

local function get_active_row()
  if state and state.active_field == "ipa" then
    return field_order.ipa
  end
  return field_order.xsampa
end

local function get_prefix(field)
  return string.format("%-" .. label_width .. "s   ", field_labels[field])
end

local function get_content_col()
  return content_col
end

local function get_field_text(field)
  if not state or not vim.api.nvim_buf_is_valid(state.buf) then
    return ""
  end
  local row = field_order[field]
  local line = vim.api.nvim_buf_get_lines(state.buf, row - 1, row, false)[1] or ""
  local prefix = get_prefix(field)
  if line:sub(1, #prefix) == prefix then
    return line:sub(#prefix + 1)
  end
  return line:sub(get_content_col() + 1)
end

local function set_field_text(field, text)
  if not state or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end
  local row = field_order[field]
  vim.api.nvim_buf_set_lines(state.buf, row - 1, row, false, {
    get_prefix(field) .. text,
  })
end

local function get_target_column(source_field, source_col)
  if not state or not vim.api.nvim_buf_is_valid(state.buf) then
    return 0
  end

  if source_field == "ipa" then
    local result = reverse_convert_text(get_field_text("ipa"), { tokens = true })
    return engine.map_input_to_output(result, source_col, "byte")
  end

  local result = convert_text(get_field_text("xsampa"), { tokens = true })
  return engine.map_input_to_output(result, source_col, "byte")
end

local function set_cursor_safe(win, row, col)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local buf = vim.api.nvim_win_get_buf(win)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_count == 0 then
    return
  end

  row = math.max(1, math.min(row, line_count))
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
  if row == 2 then
    col = math.max(0, math.min(col, #line))
  else
    col = math.max(get_content_col(), math.min(col, #line))
  end
  vim.api.nvim_win_set_cursor(win, { row, col })
end

local function render_lines(xsampa_text, ipa_text, width)
  local divider_label = string.rep(config.float.divider_char, label_width)
  return {
    get_prefix("xsampa") .. xsampa_text,
    divider_label .. string.rep(config.float.divider_char, 3 + width),
    get_prefix("ipa") .. ipa_text,
  }
end

local function highlight_layout(buf, lines)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local function add_hl(row, start_col, end_col, hl_group)
    vim.api.nvim_buf_set_extmark(buf, ns, row, start_col, {
      end_row = row,
      end_col = end_col,
      hl_group = hl_group,
    })
  end

  add_hl(0, 0, #(lines[1] or ""), "Normal")
  add_hl(1, 0, #(lines[2] or ""), "WinSeparator")
  add_hl(2, 0, #(lines[3] or ""), "Normal")
  add_hl(0, 0, get_content_col(), "WinSeparator")
  add_hl(2, 0, get_content_col(), "WinSeparator")
  local active_row = get_active_row() - 1
  local inactive_row = active_row == 0 and 2 or 0
  add_hl(inactive_row, 0, label_width, "WinSeparator")
  add_hl(active_row, 0, label_width, "Title")
end

local function get_window_title(field)
  if field == "ipa" then
    return " IPA to X-SAMPA "
  end
  return " X-SAMPA to IPA "
end

local function update_title()
  if not state or not vim.api.nvim_win_is_valid(state.win) then
    return
  end

  local config_ = vim.api.nvim_win_get_config(state.win)
  config_.title = get_window_title(state.active_field)
  config_.title_pos = "center"
  vim.api.nvim_win_set_config(state.win, config_)
end

local function set_active_field(field)
  if not state or not vim.api.nvim_win_is_valid(state.win) then
    return
  end

  state.active_field = field
  local row = get_active_row()
  local line = get_field_text(field)
  local lines = vim.api.nvim_buf_get_lines(state.buf, 0, 3, false)
  highlight_layout(state.buf, lines)
  update_title()
  set_cursor_safe(state.win, row, get_content_col() + #line)
end

local function close_float()
  if not state then
    return
  end

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  state = nil
end

local function sync_fields()
  if not state or not vim.api.nvim_buf_is_valid(state.buf) or state.syncing then
    return
  end

  state.syncing = true

  if state.active_field == "ipa" then
    local result = reverse_convert_text(get_field_text("ipa"), { tokens = true })
    set_field_text("xsampa", result.output)
  else
    local result = convert_text(get_field_text("xsampa"), { tokens = true })
    set_field_text("ipa", result.output)
  end

  state.syncing = false
  local xsampa_text = get_field_text("xsampa")
  local ipa_text = get_field_text("ipa")
  local width = math.max(config.float.width, math.max(#xsampa_text, #ipa_text) + 12)
  local lines = render_lines(xsampa_text, ipa_text, width)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  highlight_layout(state.buf, lines)
  update_title()
end

local function switch_field()
  if not state then
    return
  end

  local current = vim.api.nvim_win_get_cursor(state.win)
  local source_field = state.active_field
  local target_col = get_target_column(source_field, current[2] - get_content_col())

  if state.active_field == "ipa" then
    state.active_field = "xsampa"
  else
    state.active_field = "ipa"
  end

  if vim.api.nvim_win_is_valid(state.win) then
    local lines = vim.api.nvim_buf_get_lines(state.buf, 0, 3, false)
    highlight_layout(state.buf, lines)
    update_title()
    local row = get_active_row()
    local line = get_field_text(state.active_field)
    set_cursor_safe(state.win, row, get_content_col() + math.min(target_col, #line))
  end
end

local function insert_text(bufnr, row, col, text)
  vim.api.nvim_buf_set_text(bufnr, row, col, row, col, { text })
end

local function replace_range(bufnr, range, text)
  vim.api.nvim_buf_set_text(bufnr, range.start_row, range.start_col, range.end_row, range.end_col, { text })
end

local function commit_float()
  if not state or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  local converted
  if state.active_field == "ipa" then
    converted = get_field_text("xsampa")
  else
    converted = get_field_text("ipa")
  end
  local target = state.target

  close_float()

  if not target or not vim.api.nvim_buf_is_valid(target.buf) then
    return
  end

  vim.api.nvim_set_current_win(target.win)

  if target.start_mark and target.end_mark then
    local start_pos = vim.api.nvim_buf_get_extmark_by_id(target.buf, ns, target.start_mark, {})
    local end_pos = vim.api.nvim_buf_get_extmark_by_id(target.buf, ns, target.end_mark, {})
    if #start_pos == 0 or #end_pos == 0 then
      return
    end

    local range = {
      start_row = start_pos[1],
      start_col = start_pos[2],
      end_row = end_pos[1],
      end_col = end_pos[2],
    }

    replace_range(target.buf, range, converted)
    vim.api.nvim_buf_del_extmark(target.buf, ns, target.start_mark)
    vim.api.nvim_buf_del_extmark(target.buf, ns, target.end_mark)
    vim.api.nvim_win_set_cursor(target.win, {
      range.start_row + 1,
      range.start_col + #converted,
    })
  else
    local insert_pos = vim.api.nvim_buf_get_extmark_by_id(target.buf, ns, target.insert_mark, {})
    if #insert_pos == 0 then
      return
    end

    insert_text(target.buf, insert_pos[1], insert_pos[2], converted)
    vim.api.nvim_buf_del_extmark(target.buf, ns, target.insert_mark)
    vim.api.nvim_win_set_cursor(target.win, {
      insert_pos[1] + 1,
      insert_pos[2] + #converted,
    })
  end
end

local function open_float(opts)
  close_float()
  opts = opts or {}

  local target_win = vim.api.nvim_get_current_win()
  local target_buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(target_win)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "xsampa"
  vim.bo[buf].omnifunc = ""
  vim.bo[buf].completefunc = ""
  vim.bo[buf].keywordprg = ""

  local initial_field = opts.initial_field or "xsampa"
  local initial_xsampa = initial_field == "ipa" and "" or (opts.initial_text or "")
  local initial_ipa = initial_field == "ipa" and (opts.initial_text or "") or ""
  local width = math.max(config.float.width, #(opts.initial_text or "") + 12)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, render_lines(initial_xsampa, initial_ipa, width))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width + get_content_col(),
    height = 3,
    style = "minimal",
    border = config.float.border,
    title = get_window_title(initial_field),
    title_pos = "center",
  })

  vim.wo[win].wrap = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].cursorline = false
  vim.wo[win].conceallevel = 0

  vim.b[buf].completion = false
  vim.b[buf].blink_cmp_enabled = false
  vim.b[buf].blink_cmp = false

  local lines = vim.api.nvim_buf_get_lines(buf, 0, 3, false)
  highlight_layout(buf, lines)

  state = {
    buf = buf,
    win = win,
    active_field = initial_field,
    syncing = false,
    target = {
      buf = target_buf,
      win = target_win,
    },
  }

  if opts.range then
    state.target.start_mark = vim.api.nvim_buf_set_extmark(target_buf, ns, opts.range.start_row, opts.range.start_col, {
      right_gravity = false,
    })
    state.target.end_mark = vim.api.nvim_buf_set_extmark(target_buf, ns, opts.range.end_row, opts.range.end_col, {
      right_gravity = true,
    })
  else
    state.target.insert_mark = vim.api.nvim_buf_set_extmark(target_buf, ns, cursor[1] - 1, cursor[2], {
      right_gravity = false,
    })
  end

  local group = vim.api.nvim_create_augroup("XSampaFloat" .. buf, { clear = true })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufEnter" }, {
    group = group,
    buffer = buf,
    callback = function()
      sync_fields()
      if vim.api.nvim_win_is_valid(win) then
        local current = vim.api.nvim_win_get_cursor(win)
        local row = get_active_row()
        local line = get_field_text(state.active_field)
        local col = current[2]
        if row ~= 2 then
          col = get_content_col() + math.min(math.max(current[2] - get_content_col(), 0), #line)
        end
        set_cursor_safe(win, row, col)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group,
    buffer = buf,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        local current = vim.api.nvim_win_get_cursor(win)
        if current[1] == 2 then
          set_cursor_safe(win, get_active_row(), current[2])
        elseif current[1] == 1 then
          state.active_field = "xsampa"
          if current[2] < get_content_col() then
            set_cursor_safe(win, 1, get_content_col())
          end
        elseif current[1] == 3 then
          state.active_field = "ipa"
          if current[2] < get_content_col() then
            set_cursor_safe(win, 3, get_content_col())
          end
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = buf,
    callback = function()
      if state and state.buf == buf then
        state = nil
      end
    end,
  })

  for _, mode in ipairs({ "i", "n" }) do
    vim.keymap.set(mode, "<CR>", commit_float, { buffer = buf, silent = true })
    vim.keymap.set(mode, "<Tab>", switch_field, { buffer = buf, silent = true })
    vim.keymap.set(mode, "<S-Tab>", switch_field, { buffer = buf, silent = true })
  end

  vim.keymap.set("i", "<Esc>", "<C-\\><C-n>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close_float, { buffer = buf, silent = true })

  vim.keymap.set("n", "q", close_float, { buffer = buf, silent = true })

  sync_fields()
  set_active_field(initial_field)
  vim.cmd("startinsert!")
end

local function get_visual_selection()
  local selection_type = vim.fn.mode()
  if not selection_type:match("^[vV\022]$") then
    selection_type = vim.fn.visualmode()
  end

  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local opts = {
    type = selection_type,
    eol = true,
  }

  local lines = vim.fn.getregion(start_pos, end_pos, opts)
  local segments = vim.fn.getregionpos(start_pos, end_pos, opts)
  if #segments == 0 then
    return nil, ""
  end

  local first_segment = segments[1]
  local last_segment = segments[#segments]
  local range = {
    start_row = first_segment[1][2] - 1,
    start_col = first_segment[1][3] - 1,
    end_row = last_segment[2][2] - 1,
    end_col = last_segment[2][3],
  }

  return range, table.concat(lines, "\n")
end

local function range_is_valid(range)
  if not range then
    return false
  end

  if range.start_row > range.end_row then
    return false
  end

  if range.start_row == range.end_row and range.start_col > range.end_col then
    return false
  end

  return true
end

local function get_line_range(opts)
  local start_row = (opts.line1 or 1) - 1
  local end_row = (opts.line2 or opts.line1 or 1) - 1
  local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)

  if #lines == 0 then
    return nil, ""
  end

  return {
    start_row = start_row,
    start_col = 0,
    end_row = end_row,
    end_col = #lines[#lines],
  },
    table.concat(lines, "\n")
end

local function copy_to_register(text)
  vim.fn.setreg('"', text)
  vim.notify("Converted text copied to the unnamed register", vim.log.levels.INFO)
end

---@param arg string
---@return "xsampa"|"ipa"
local function parse_direction(arg)
  if arg == nil or arg == "" or arg == "xsampa" then
    return "xsampa"
  end
  if arg == "ipa" then
    return "ipa"
  end

  error(("invalid direction %q; expected 'xsampa' or 'ipa'"):format(arg))
end

function M.convert_range(opts)
  local range, text = get_line_range(opts)
  if not range then
    return
  end

  local converted
  if opts.from == "ipa" then
    converted = reverse_convert_text(text)
  else
    converted = convert_text(text)
  end

  if opts.bang then
    replace_range(0, range, converted)
  else
    copy_to_register(converted)
  end
end

function M.open_converter(opts)
  opts = opts or {}
  local from = opts.from or "xsampa"

  if opts.selection then
    local range, text = get_visual_selection()
    if not range_is_valid(range) then
      return
    end
    open_float({
      initial_text = text,
      initial_field = from,
      range = range,
    })
    return
  end

  open_float({
    initial_field = from,
  })
end

function M.copy_selection(opts)
  opts = opts or {}
  local range, text = get_visual_selection()
  if not range_is_valid(range) then
    return
  end

  if opts.from == "ipa" then
    copy_to_register(reverse_convert_text(text))
  else
    copy_to_register(convert_text(text))
  end
end

function M.replace_selection(opts)
  opts = opts or {}
  local range, text = get_visual_selection()
  if not range_is_valid(range) then
    return
  end

  if opts.from == "ipa" then
    replace_range(0, range, reverse_convert_text(text))
  else
    replace_range(0, range, convert_text(text))
  end
end

function M.setup(user_config)
  config = vim.tbl_deep_extend("force", config, user_config or {})
  build_engine()

  vim.api.nvim_create_user_command("XSampa", function(opts)
    M.open_converter({
      from = parse_direction(opts.args),
    })
  end, {
    desc = "Open the interactive X-SAMPA or IPA converter",
    nargs = "?",
    complete = function()
      return { "xsampa", "ipa" }
    end,
  })

  vim.api.nvim_create_user_command("XSampaConvert", function(opts)
    local range_opts = vim.tbl_extend("force", opts, {
      from = parse_direction(opts.args),
    })
    M.convert_range(range_opts)
  end, {
    bang = true,
    range = true,
    nargs = "?",
    complete = function()
      return { "xsampa", "ipa" }
    end,
    desc = "Convert a line range; use ! to replace the original text",
  })
end

return M
