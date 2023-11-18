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
                -- wrap nvimtree commands
                wrap_nvimtree_commands = true,
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

2. In nvim-tree.lua on_attach function

```lua
local function on_attach(bufnr)
    local api = require("nvim-tree.api")
    local FloatPreview = require("float-preview")

    FloatPreview.attach_nvimtree(bufnr)
    local close_wrap = FloatPreview.close_wrap
end
```

By default we wrap there are api funcs for close float window before execute:

- api.node.open.tab
- api.node.open.vertical
- api.node.open.horizontal
- api.node.open.edit
- api.node.open.preview
- api.node.open.no_window_picker
- api.fs.create
- api.fs.remove
- api.fs.rename

You can manually wrap this in on attach function like

```lua
local function on_attach(bufnr)
    local api = require("nvim-tree.api")
    local FloatPreview = require("float-preview")

    FloatPreview.attach_nvimtree(bufnr)
    local close_wrap = FloatPreview.close_wrap

    -- ...
    vim.keymap.set("n", "<C-t>", close_wrap(api.node.open.tab), opts("Open: New Tab"))
    vim.keymap.set("n", "<C-v>", close_wrap(api.node.open.vertical), opts("Open: Vertical Split"))
    vim.keymap.set("n", "<C-s>", close_wrap(api.node.open.horizontal), opts("Open: Horizontal Split"))
    vim.keymap.set("n", "<CR>", close_wrap(api.node.open.edit), opts("Open"))
    vim.keymap.set("n", "<Tab>", close_wrap(api.node.open.preview), opts("Open"))
    vim.keymap.set("n", "o", close_wrap(api.node.open.edit), opts("Open"))
    vim.keymap.set("n", "O", close_wrap(api.node.open.no_window_picker), opts("Open: No Window Picker"))
    vim.keymap.set("n", "a", close_wrap(api.fs.create), opts("Create"))
    vim.keymap.set("n", "d", close_wrap(api.fs.remove), opts("Delete"))
    vim.keymap.set("n", "r", close_wrap(api.fs.rename), opts("Rename"))
end
```

## Configure Window Size

You can augment the window config by adding arguments to be passed to `nvim_open_win` by providing a `window.open_win_config`. This can be either a table or a function that returns a table.

```lua
HEIGHT_PADDING = 10
WIDTH_PADDING = 15
require('float-preview').setup({
    window =  {
        wrap = false,
        trim_height = false,
        open_win_config = function()
            local screen_w = vim.opt.columns:get()
            local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
            local window_w_f = (screen_w - WIDTH_PADDING * 2 -1) / 2
            local window_w = math.floor(window_w_f)
            local window_h = screen_h - HEIGHT_PADDING * 2
            local center_x = window_w_f + WIDTH_PADDING + 2
            local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()

            return {
                style = "minimal",
                relative = "editor",
                border = "single",
                row = center_y,
                col = center_x,
                width = window_w,
                height = window_h
            }
        end
    }
})

```

<img src="https://github.com/haondt/nvim-tree.lua-float-preview/assets/19233365/f71aede5-068b-4a13-b3ca-bd373de40ff6" width="800">
