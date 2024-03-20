local M = {}
M.get_size = function(path)
  local ok, stats = pcall(function()
    return vim.loop.fs_stat(path)
  end)
  if not (ok and stats) then
    return
  end
  return math.floor(0.5 + (stats.size / (1024 * 1024)))
end

M.is_text = function(path)
  -- Determine if file is text. This is not 100% proof, but good enough.
  -- Source: https://github.com/sharkdp/content_inspector
  local fd = vim.loop.fs_open(path, "r", 1)
  if not fd then
    return false
  end
  local is_text = vim.loop.fs_read(fd, 1024):find "\0" == nil
  vim.loop.fs_close(fd)
  return is_text
end

M.detach_lsp_clients = function(bufnr)
  -- currently not working
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local clients = vim.lsp.buf_get_clients(bufnr)
  -- disable notified from buf_detach_client
  local prev = vim.notify
  vim.notify = function() end
  for client_id, _ in pairs(clients) do
    vim.lsp.buf_detach_client(bufnr, client_id)
  end
  vim.notify = prev
end

M.is_showed = function(path)
  for _, winnr in ipairs(vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())) do
    local buf = vim.api.nvim_win_get_buf(winnr)
    local _path = vim.api.nvim_buf_get_name(buf)
    if _path == path then
      return true
    end
  end
  return false
end

return M
