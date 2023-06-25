# Float Preview for nvim-tree.lua

Example

![ezgif-5-8835f4da8d](https://github.com/JMarkin/nvim-tree.lua-float-preview/assets/15740814/e33aef5e-f647-435f-bb23-cee297011757)

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
            opts = {
                scroll_lines = 20, -- lines for scroll
                mapping = {
                  down = { "<C-d>" },
                  up = { "<C-e>", "<C-u>" },
                },
            },
        },
    },

```
2. In nvim-tree.lua on_attach function, attach float-preview and wrap some keymaps
```lua
local function on_attach(bufnr)
    local api = require("nvim-tree.api")
    local FloatPreview = require("float-preview")

    local prev, float_close_wrap = FloatPreview:new()
    prev:attach(bufnr)
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

--
If you want disable diagnostic, and other in preview buffer. You can use `require("float-preview").is_float`, example for null-ls
```lua
require("null-ls").setup({
    should_attach = function(bufnr)
        return not require("float-preview").is_float(bufnr)
    end,
})
```
