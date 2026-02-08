-- https://neovide.dev/
if vim.g.neovide then
  vim.o.guifont = "Iosevka:h13"
  vim.o.wrap = true
  vim.o.linebreak = true

  vim.keymap.set("n", "<D-v>", '"+P', { desc = "Paste from clipboard" })
  vim.keymap.set("v", "<D-v>", '"+P', { desc = "Paste from clipboard" })
  vim.keymap.set("c", "<D-v>", "<C-R>+", { desc = "Paste from clipboard" })
  vim.keymap.set("i", "<D-v>", "<C-R>+", { desc = "Paste from clipboard" })
  vim.keymap.set("t", "<D-v>", '<C-\\><C-n>"+Pi', { desc = "Paste from clipboard" })
  vim.keymap.set("v", "<D-c>", '"+y', { desc = "Copy to clipboard" })
  vim.keymap.set("v", "<D-x>", '"+d', { desc = "Cut to clipboard" })
  vim.keymap.set("n", "<D-s>", "<Cmd>w<CR>", { desc = "Save file" })
  vim.keymap.set("n", "<D-a>", "ggVG", { desc = "Select all" })
  vim.keymap.set("n", "<D-z>", "u", { desc = "Undo" })
  vim.keymap.set("n", "<D-Z>", "<C-r>", { desc = "Redo" })
  vim.keymap.set("n", "<D-t>", "<Cmd>tabnew<CR>", { desc = "New tab" })
  vim.keymap.set("n", "<D-w>", "<Cmd>tabclose<CR>", { desc = "Close tab" })
end
