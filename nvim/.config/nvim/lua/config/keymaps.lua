-- Use vim style keybindings
vim.keymap.set("n", "Y", "yy", {
  noremap = true,
  silent = true,
  desc = "Yank to end of line",
})

-- Esc to clear search highlighting
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- Navigate wrapped lines naturally
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- File operations
vim.keymap.set("n", "<leader>fs", "<cmd>wa<cr>", { desc = "Save all files" })
vim.keymap.set("n", "<leader>q", "<cmd>bd<cr>", { desc = "Close buffer" })

-- Config editing
vim.keymap.set("n", "<leader>rc", "<cmd>edit $MYVIMRC<cr>", { desc = "Edit init.lua" })

-- Diff whitespace toggle
vim.keymap.set("n", "<leader>ai", "<cmd>set diffopt+=iwhite<cr>", { desc = "Diff ignore whitespace" })
vim.keymap.set("n", "<leader>aw", "<cmd>set diffopt-=iwhite<cr>", { desc = "Diff show whitespace" })

-- Re-bind Q/q
vim.keymap.set("n", "Q", "q")
vim.keymap.set("n", "q", "<Nop>")

-- Toggle quickfix window
vim.keymap.set("n", "<C-q>", function()
  local qf_exists = false
  for _, win in pairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then qf_exists = true end
  end
  if qf_exists then vim.cmd("cclose") else vim.cmd("copen") end
end, { desc = "Toggle quickfix" })

-- Show file path and copy to clipboard
vim.keymap.set("n", "<C-g>", function()
  vim.cmd("file")
  vim.fn.system("pbcopy", vim.fn.expand("%"))
end, { desc = "Show file path and copy to clipboard" })

-- Command typo fixes
vim.api.nvim_create_user_command("W", "w", {})
vim.api.nvim_create_user_command("Q", "q", {})
vim.api.nvim_create_user_command("Wq", "wq", {})
vim.api.nvim_create_user_command("WQ", "wq", {})
vim.api.nvim_create_user_command("Qa", "qa", {})
