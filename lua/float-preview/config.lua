local CFG = {
  _cfg = {
    -- lines for scroll
    scroll_lines = 20,
    mapping = {
      -- scroll down float buffer
      down = { "<C-d>" },
      -- scroll up float buffer
      up = { "<C-e>", "<C-u>" },
      -- enable/disable float windows
      toggle = {"<C-x>"}
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
