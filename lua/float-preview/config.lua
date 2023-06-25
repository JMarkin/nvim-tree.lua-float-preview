local CFG = {
  _cfg = {
    scroll_lines = 20,
    mapping = {
      down = { "<C-d>" },
      up = { "<C-e>", "<C-u>" },
    },
  },
}

CFG.config = function()
  return CFG._cfg
end

CFG.update = function(cfg)
  if not cfg then
    return
  end

  for key, value in pairs(cfg) do
    CFG._cfg[key] = value
  end
end

return CFG
