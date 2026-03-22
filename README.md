# xsampa.nvim

An X-SAMPA ↔ IPA converter for Neovim.

## Installation

### `lazy.nvim`

```lua
{
  "moltinginstar/xsampa.nvim",
  opts = {},
}
```

### Manual

1. Clone the repository into your Neovim package directory, for example:

   ```sh
   git clone https://github.com/moltinginstar/xsampa.nvim ~/.local/share/nvim/site/pack/moltinginstar/start/xsampa.nvim
   ```

2. Add the following line to your `init.lua`:

   ```lua
   require("xsampa").setup()
   ```

## Example keybindings

```lua
local xsampa = require("xsampa")

vim.keymap.set("i", "<C-'>", function()
  xsampa.open_converter({ from = "xsampa" })
end, { desc = "Open X-SAMPA to IPA converter" })
vim.keymap.set("n", "<leader>xi", function()
  xsampa.open_converter({
    from = "xsampa",
  })
end, { desc = "Open X-SAMPA to IPA converter" })
vim.keymap.set("x", "<leader>xi", function()
  xsampa.open_converter({
    from = "xsampa",
    selection = true,
  })
end, { desc = "Open X-SAMPA to IPA converter for selection" })

vim.keymap.set("x", "<leader>xy", function()
  xsampa.copy_selection({ from = "xsampa" })
end, { desc = "Convert selection from X-SAMPA to IPA and copy" })
vim.keymap.set("x", "<leader>xr", function()
  xsampa.replace_selection({ from = "xsampa" })
end, { desc = "Convert selection from X-SAMPA to IPA in place" })

vim.keymap.set("i", "<M-'>", function()
  xsampa.open_converter({ from = "ipa" })
end, { desc = "Open IPA to X-SAMPA converter" })
vim.keymap.set("n", "<leader>xI", function()
  xsampa.open_converter({
    from = "ipa",
  })
end, { desc = "Open IPA to X-SAMPA converter" })
vim.keymap.set("x", "<leader>xI", function()
  xsampa.open_converter({
    from = "ipa",
    selection = true,
  })
end, { desc = "Open IPA to X-SAMPA converter for selection" })

vim.keymap.set("x", "<leader>xY", function()
  xsampa.copy_selection({ from = "ipa" })
end, { desc = "Convert selection from IPA to X-SAMPA and copy" })
vim.keymap.set("x", "<leader>xR", function()
  xsampa.replace_selection({ from = "ipa" })
end, { desc = "Convert selection from IPA to X-SAMPA in place" })
```

## Commands

- `:XSampa [xsampa|ipa]`: open interactive converter
- `:[range]XSampaConvert [xsampa|ipa]`: convert range and copy result
- `:[range]XSampaConvert! [xsampa|ipa]`: convert range in place

`xsampa` is used by default if not provided.

## Using the interactive converter

- `<Tab>` and `<S-Tab>` to switch fields
- `<CR>` to confirm
- `<Esc>` to return to normal mode
- `<Esc>` again or `q` to cancel

The focused field is the source of truth. Editing one side will normalize the other into the plugin's canonical form.

The interactive panel uses the `xsampa` filetype. If you want to disable plugin behavior (e.g., autocomplete) inside the panel, target that filetype in your config. For example, with `nvim-autopairs`:

```lua
require("nvim-autopairs").setup({
  disable_filetype = { "TelescopePrompt", "spectre_panel", "snacks_picker_input", "xsampa" },
})
```

## License

This project is licensed under the [MIT License](LICENSE).
