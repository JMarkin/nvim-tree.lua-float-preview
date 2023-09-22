local CFG = {
  _cfg = {
    -- lines for scroll
    scroll_lines = 20,
    -- window config
    window = {
      style = "minimal",
      relative = "win",
      border = "rounded",
    },
    mapping = {
      -- scroll down float buffer
      down = { "<C-d>" },
      -- scroll up float buffer
      up = { "<C-e>", "<C-u>" },
      -- enable/disable float windows
      toggle = { "<C-x>" },
    },
    -- hooks if return false preview doesn't shown
    hooks = {
      pre_open = function(path)
        -- if file > 5 MB or not text -> not preview
        local size = require("float-preview.utils").get_size(path)
        if type(size) ~= "number" then
          return false
        end
        local is_text = require("float-preview.utils").is_text(path)
        return size < 5 and is_text
      end,
      post_open = function(bufnr)
        return true
      end,
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

  CFG._cfg = vim.tbl_extend("force", CFG._cfg, cfg)
end

return CFG
