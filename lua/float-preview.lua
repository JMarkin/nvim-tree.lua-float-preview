local CFG = require "float-preview.config"

local get_node = require("nvim-tree.api").tree.get_node_under_cursor
local FloatPreview = {}
FloatPreview.__index = FloatPreview

local preview_au = "float_preview_au"
vim.api.nvim_create_augroup(preview_au, { clear = true })

local st = {}
local all_floats = {}
local disabled = false

-- orignal fzf lua
local read_file_async = function(filepath, callback)
  vim.loop.fs_open(filepath, "r", 438, function(err_open, fd)
    if err_open then
      -- we must schedule this or we get
      -- E5560: nvim_exec must not be called in a lua loop callback
      vim.schedule(function()
        vim.notify(("Unable to open file '%s', error: %s"):format(filepath, err_open), vim.log.levels.WARN)
      end)
      return
    end
    vim.loop.fs_fstat(fd, function(err_fstat, stat)
      assert(not err_fstat, err_fstat)
      if stat.type ~= "file" then
        return callback ""
      end
      vim.loop.fs_read(fd, stat.size, 0, function(err_read, data)
        assert(not err_read, err_read)
        vim.loop.fs_close(fd, function(err_close)
          assert(not err_close, err_close)
          return callback(data)
        end)
      end)
    end)
  end)
end

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

function FloatPreview:close(reason)
  if self.path ~= nil and self.buf ~= nil then
    if reason then
      -- vim.notify(string.format("close rason %s", reason))
    end
    pcall(vim.api.nvim_win_close, self.win, { force = true })
    pcall(vim.api.nvim_buf_delete, self.buf, { force = true })
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

  if not self.cfg.hooks.pre_open(path) then
    return
  end

  self.path = path
  self.buf = vim.api.nvim_create_buf(false, false)
  st[self.path] = 1
  st[self.buf] = 1

  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = self.buf })
  vim.api.nvim_set_option_value("buftype", "nowrite", { buf = self.buf })
  vim.api.nvim_set_option_value("buflisted", false, { buf = self.buf })

  local width = vim.api.nvim_get_option "columns"
  local height = vim.api.nvim_get_option "lines"
  local prev_height = math.ceil(height / 2)
  local opts = {
    width = math.ceil(width / 2),
    height = prev_height,
    row = vim.fn.line ".",
    col = vim.fn.winwidth(0) + 1,
    focusable = false,
    noautocmd = true,
    style = self.cfg.window.style,
    relative = self.cfg.window.relative,
    border = self.cfg.window.border,
  }

  local open_win_config = self.cfg.window.open_win_config
  if type(open_win_config) == "function" then
    open_win_config = open_win_config()
  end

  if open_win_config then
    for k, v in pairs(open_win_config) do
      opts[k] = v
    end
  end

  self.win = vim.api.nvim_open_win(self.buf, true, opts)
  vim.api.nvim_set_option_value("wrap", self.cfg.window.wrap, { win = self.win })

  read_file_async(
    path,
    vim.schedule_wrap(function(data)
      local lines = vim.split(data, "[\r]?\n")

      -- if file ends in new line, don't write an empty string as the last
      -- line.
      if data:sub(#data, #data) == "\n" or data:sub(#data - 1, #data) == "\r\n" then
        table.remove(lines)
      end
      self.max_line = #lines
      if self.cfg.window.trim_height then
        if self.max_line < prev_height then
          opts.height = self.max_line + 1
          opts.noautocmd = nil
          vim.api.nvim_win_set_config(self.win, opts)
        end
      end
      vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)

      local ft = vim.filetype.match { buf = self.buf, filename = path }
      local has_lang, lang = pcall(vim.treesitter.language.get_lang, ft)
      local has_ts, _ = pcall(vim.treesitter.start, self.buf, has_lang and lang or ft)
      if not has_ts then
        vim.bo[self.buf].syntax = ft
        vim.bo[self.buf].filetype = ft
      end
    end)
  )
  if not self.cfg.hooks.post_open(self.buf) then
    self:close "post open"
  end
end

function FloatPreview:preview_under_cursor()
  local _, node = pcall(get_node)
  if not node then
    return
  end

  if node.absolute_path == self.path then
    return
  end
  self:close "change file"

  if node.type ~= "file" then
    return
  end

  local win = vim.api.nvim_get_current_win()
  self:preview(node.absolute_path)

  local ok, _ = pcall(vim.api.nvim_set_current_win, win)
  if not ok then
    self:close "cant set win"
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
    vim.api.nvim_create_autocmd({ "CursorHold" }, {
      group = preview_au,
      callback = function()
        if bufnr == vim.api.nvim_get_current_buf() then
          self:preview_under_cursor()
        else
          self:close "changed buffer"
        end
      end,
    })
  )

  vim.api.nvim_create_autocmd({ "BufWipeout" }, {
    buffer = bufnr,
    group = preview_au,
    callback = function()
      self:close "wipe"
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
