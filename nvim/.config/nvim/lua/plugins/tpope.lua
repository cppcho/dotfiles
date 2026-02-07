return {
  -- https://github.com/tpope/vim-fugitive
  {
    "tpope/vim-fugitive",
    lazy = false,
    keys = {
      { "<leader>ga", "<cmd>Gwrite<CR>", desc = "Git add (stage file)" },
      { "<leader>gs", "<cmd>topleft Git<CR>", desc = "Git status" },
      { "<leader>gd", "<cmd>Gdiffsplit<CR>", desc = "Git diff" },
    },
    config = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = { "FugitiveIndex", "FugitivePager" },
        callback = function()
          vim.keymap.set("n", "q", "gq", { buffer = true, remap = true })
        end,
      })
    end,
  },
  -- https://github.com/tpope/vim-rhubarb
  {
    "tpope/vim-rhubarb",
    keys = {
      { "<leader>gB", "<cmd>GBrowse<CR>", desc = "[B]rowse in GitHub" },
    },
  },
}
