-- https://neovide.dev/
if vim.g.neovide then
  vim.o.guifont = "Iosevka:h13"
  vim.o.wrap = true
  vim.o.linebreak = true

  -- Allow clipboard copy/paste with Cmd+C/V
  vim.keymap.set("n", "<D-v>", '"+P', { desc = "Paste from clipboard" })
  vim.keymap.set("v", "<D-v>", '"+P', { desc = "Paste from clipboard" })
  vim.keymap.set("c", "<D-v>", "<C-R>+", { desc = "Paste from clipboard" })
  vim.keymap.set("i", "<D-v>", '<C-R>+', { desc = "Paste from clipboard" })
  vim.keymap.set("t", "<D-v>", '<C-\\><C-n>"+Pi', { desc = "Paste from clipboard" })
end
