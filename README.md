# Float Preview for nvim-tree.lua

Example  
![ezgif com-video-to-gif](https://github.com/JMarkin/nvim-tree.lua-float-preview/assets/15740814/cc2ba591-131b-42e0-afc8-1bac97b1e72a)


## How to add

1. Install plugin
   lazy example

```lua
{
    "nvim-tree/nvim-tree.lua",
    dependencies = {
        {
            "JMarkin/nvim-tree.lua-float-preview",
            lazy = true,
            -- default
            opts = {
                -- lines for scroll
                scroll_lines = 20,
                -- window config
                window = {
                  style = "minimal",
                  relative = "win",
                  border = "rounded",
                  wrap = false,
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
        },
    },

```

2. In nvim-tree.lua on_attach function, attach float-preview and wrap some keymaps for hide window on keymap

```lua
local function on_attach(bufnr)
    local api = require("nvim-tree.api")
    local FloatPreview = require("float-preview")

    FloatPreview.attach_nvimtree(bufnr)
    local float_close_wrap = FloatPreview.close_wrap

    --- There are keymaps must to wrap for correct work
    -- ...
    vim.keymap.set("n", "<C-t>", float_close_wrap(api.node.open.tab), opts("Open: New Tab"))
    vim.keymap.set("n", "<C-v>", float_close_wrap(api.node.open.vertical), opts("Open: Vertical Split"))
    vim.keymap.set("n", "<C-s>", float_close_wrap(api.node.open.horizontal), opts("Open: Horizontal Split"))
    vim.keymap.set("n", "<CR>", float_close_wrap(api.node.open.edit), opts("Open"))
    vim.keymap.set("n", "<Tab>", float_close_wrap(api.node.open.preview), opts("Open"))
    vim.keymap.set("n", "o", float_close_wrap(api.node.open.edit), opts("Open"))
    vim.keymap.set("n", "O", float_close_wrap(api.node.open.no_window_picker), opts("Open: No Window Picker"))
    vim.keymap.set("n", "q", float_close_wrap(api.tree.close), opts("Close"))
    vim.keymap.set("n", "a", float_close_wrap(api.fs.create), opts("Create"))
    vim.keymap.set("n", "d", float_close_wrap(api.fs.remove), opts("Delete"))
    vim.keymap.set("n", "r", float_close_wrap(api.fs.rename), opts("Rename"))
end
```
