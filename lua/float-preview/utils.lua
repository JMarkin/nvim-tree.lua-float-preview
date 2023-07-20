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

return M
