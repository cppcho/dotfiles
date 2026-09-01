-- https://github.com/kdheepak/lazygit.nvim
-- Runs the lazygit binary (Brewfile) in a floating terminal.
return {
  "kdheepak/lazygit.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  init = function()
    vim.g.lazygit_floating_window_scaling_factor = 0.95
    vim.g.lazygit_floating_window_border_chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
  end,
  keys = {
    { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit: open (cwd)" },
    { "<leader>gG", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit: open (project root of file)" },
    { "<leader>gl", "<cmd>LazyGitFilter<cr>", desc = "LazyGit: repo commits" },
    { "<leader>gL", "<cmd>LazyGitFilterCurrentFile<cr>", desc = "LazyGit: current file commits" },
  },
}
