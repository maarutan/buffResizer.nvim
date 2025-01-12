# splitResizer.nvim

https://github.com/user-attachments/assets/fc84baec-54c8-40ba-81f4-5f9345fa86a3

**splitResizer.nvim** is a Neovim plugin that **replaces the default `:vsplit`** for **vertical splits only**.  
When creating a new window, the plugin automatically opens **a separate buffer** and provides convenient key bindings for:

- Managing the width of the focused window (auto expand/auto collapse).
- Enabling/disabling the plugin.
- Creating a vertical split.

> **Note:** The plugin **does not affect** other windows and **only** manages the split created by its own command.

---

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{ "maarutan/splitResizer.nvim" }
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { "maarutan/splitResizer.nvim" }
```

After installing, load the plugin in your Neovim config (example in Lua):

```lua
require("splitResizer").setup()
```

---

## Default Configuration

Below is the table of key parameters with their default values. You can override them by passing your own values to `setup({...})`:

```lua
{
  enabled = true,         -- Plugin is enabled by default
  notify = true,          -- Show notifications
  keymaps = {
    toggle_resize  = "<leader>rw",  -- Force toggle the width of the current window
    toggle_plugin  = "<leader>re",  -- Toggle the entire plugin
    vertical_split = "<leader>wv",  -- Create a vertical split
  },
  notification_icon = "🪓", -- Icon used for notifications
  min_width = 25,           -- Minimum width (percentage of the total screen width)
  max_width = 70,           -- Maximum width (percentage of the total screen width)
  start_width = 50,         -- Initial width (percentage of the total screen width)
}
```

---

## Additional Animation

https://github.com/user-attachments/assets/23f41024-37d3-4188-aa8b-5dff4c810eff

The plugin works without any extra dependencies. However, if you want **smoother animations** for scrolling or cursor movement, you may consider:

- [mini.animate](https://github.com/echasnovski/mini.animate)
- [neoscroll.nvim](https://github.com/karb94/neoscroll.nvim)
- [cinnamon.nvim](https://github.com/declancm/cinnamon.nvim)

---

## FAQ

### Can I use this with horizontal splits?

No, the plugin is designed specifically for vertical splits. Horizontal splits remain unaffected.

### What happens if I disable the plugin while a split is active?

The split remains open, and you can control it using Neovim's default commands.

---

## License

This plugin is distributed under the **MIT License**. See the [LICENSE](LICENSE) file in this repository for details.
