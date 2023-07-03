local CFG = require "float-preview.config"

local get_node = require("nvim-tree.api").tree.get_node_under_cursor
local FloatPreview = {}
FloatPreview.__index = FloatPreview

local preview_au = "float_preview_au"
vim.api.nvim_create_augroup(preview_au, { clear = true })

local st = {}
local all_floats = {}
local disabled = false

function FloatPreview.is_float(bufnr, path)
  if path then
    return st[path] ~= nil
  end
  if not bufnr then
    bufnr = vim.api.nvim_get_current_buf()
  end

  return st[bufnr] ~= nil
end

local function all_close()
  for _, fl in pairs(all_floats) do
    fl:close()
  end
end

local function all_open()
  for _, fl in pairs(all_floats) do
    fl:preview_under_cursor()
  end
end

function FloatPreview.setup(cfg)
  CFG.update(cfg)
end

function FloatPreview.attach_nvimtree(bufnr)
  local prev = FloatPreview:new()
  prev:attach(bufnr)
  return prev
end

function FloatPreview.close_wrap(f)
  return function(...)
    all_close()
    return f(...)
  end
end

function FloatPreview.toggle()
  disabled = not disabled
  if disabled then
    all_close()
  else
    all_open()
  end
end

function FloatPreview:new(cfg)
  local prev = {}
  setmetatable(prev, FloatPreview)

  cfg = cfg or CFG.config()
  prev.buf = nil
  prev.win = nil
  prev.path = nil
  prev.current_line = 1
  prev.max_line = 999999
  prev.disabled = false
  prev.cfg = cfg

  local function action_wrap(f)
    return function(...)
      prev:close()
      return f(...)
    end
  end

  return prev, action_wrap
end

function FloatPreview:close()
  if self.path ~= nil then
    local save_ei = vim.o.eventignore
    vim.o.eventignore = "all"
    pcall(vim.api.nvim_win_close, self.win, { force = true })
    pcall(vim.api.nvim_buf_delete, self.buf, { force = true })
    vim.o.eventignore = save_ei
    self.win = nil
    st[self.buf] = nil
    st[self.path] = nil
    self.buf = nil
    self.path = nil
    self.current_line = 1
    self.max_line = 999999
  end
end

--TODO: add bat preview
function FloatPreview:preview(path)
  if disabled then
    return
  end

  self.path = path
  self.buf = vim.api.nvim_create_buf(false, true)
  st[self.path] = 1
  st[self.buf] = 1

  local o = vim.opt_local
  o.bufhidden = "wipe"
  o.writebackup = false
  o.buflisted = false
  o.buftype = "nowrite"
  o.updatetime = 300

  vim.api.nvim_buf_set_option(self.buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(self.buf, "readonly", true)

  local width = vim.api.nvim_get_option "columns"
  local height = vim.api.nvim_get_option "lines"
  local prev_height = math.ceil(height / 2)
  local opts = {
    -- TODO: add minimal variant
    -- style = "minimal",
    relative = "win",
    width = math.ceil(width / 2),
    height = prev_height,
    row = vim.fn.line ".",
    col = vim.fn.winwidth(0) + 1,
    border = "rounded",
    focusable = false,
    noautocmd = true,
  }

  self.win = vim.api.nvim_open_win(self.buf, true, opts)

  local save_ei = vim.o.eventignore
  vim.o.eventignore = "all"
  vim.o.swapfile = false
  local mess = vim.o.shortmess
  vim.o.shortmess = "AF"
  local cmd = string.format("edit %s", vim.fn.fnameescape(self.path))
  local ok, _ = pcall(vim.api.nvim_command, cmd)
  vim.o.swapfile = true
  vim.o.shortmess = mess
  vim.o.eventignore = save_ei
  if not ok then
    self:close()
    return
  end
  self.max_line = vim.fn.line "$"
  local out
  ok, out = pcall(vim.filetype.match, { buf = self.buf, filename = self.path })
  if ok and out then
    cmd = string.format("set filetype=%s", out)
    pcall(vim.api.nvim_command, cmd)
  end
  vim.api.nvim_set_option_value("winhl", "NormalFloat:Normal,FloatBorder:none", { win = self.win })
end

function FloatPreview:preview_under_cursor()
  local _, node = pcall(get_node)
  if not node then
    return
  end

  if node.absolute_path == self.path then
    return
  end
  self:close()

  if node.type ~= "file" then
    return
  end

  local win = vim.api.nvim_get_current_win()
  self:preview(node.absolute_path)

  local ok, _ = pcall(vim.api.nvim_set_current_win, win)
  if not ok then
    self:close()
  end
end

function FloatPreview:scroll(line)
  if self.win then
    local ok, _ = pcall(vim.api.nvim_win_set_cursor, self.win, { line, 0 })
    if ok then
      self.current_line = line
    end
  end
end

function FloatPreview:scroll_down()
  if self.buf then
    local next_line = math.min(self.current_line + self.cfg.scroll_lines, self.max_line)
    self:scroll(next_line)
  end
end

function FloatPreview:scroll_up()
  if self.buf then
    local next_line = math.max(self.current_line - self.cfg.scroll_lines, 1)
    self:scroll(next_line)
  end
end

function FloatPreview:attach(bufnr)
  for _, key in ipairs(self.cfg.mapping.up) do
    vim.keymap.set("n", key, function()
      self:scroll_up()
    end, { buffer = bufnr })
  end

  for _, key in ipairs(self.cfg.mapping.down) do
    vim.keymap.set("n", key, function()
      self:scroll_down()
    end, { buffer = bufnr })
  end

  for _, key in ipairs(self.cfg.mapping.toggle) do
    vim.keymap.set("n", key, function()
      FloatPreview.toggle()
    end, { buffer = bufnr })
  end
  local au = {}
  table.insert(
    au,
    vim.api.nvim_create_autocmd({ "User CloseNvimFloatPreview" }, {
      callback = function()
        self:close()
      end,
      group = preview_au,
    })
  )

  table.insert(
    au,
    vim.api.nvim_create_autocmd({ "CursorHold" }, {
      group = preview_au,
      callback = function()
        if bufnr == vim.api.nvim_get_current_buf() then
          self:preview_under_cursor()
        else
          self:close()
        end
      end,
    })
  )

  vim.api.nvim_create_autocmd({ "BufWipeout" }, {
    buffer = bufnr,
    group = preview_au,
    callback = function()
      self:close()
      all_floats[bufnr] = nil
      for _, au_id in pairs(au) do
        vim.api.nvim_del_autocmd(au_id)
      end
      self = nil
    end,
  })

  all_floats[bufnr] = self
end

return FloatPreview
