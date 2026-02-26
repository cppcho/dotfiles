return {
  -- https://github.com/tpope/vim-fugitive
  {
    "tpope/vim-fugitive",
    lazy = false,
    keys = {
      { "<leader>ga", "<cmd>Gwrite<CR>",                 desc = "Git add (stage file)" },
      { "<leader>gs", "<cmd>topleft 12split | 0Git<CR>", desc = "Git status" },
      { "<leader>gd", "<cmd>Gdiffsplit<CR>",             desc = "Git diff" },
      { "<leader>gb", "<cmd>Git blame<CR>",              desc = "Git blame" },
      {
        "<leader>gD",
        function()
          local main_exists = vim.fn.system("git rev-parse --verify main 2>/dev/null")
          local branch = vim.v.shell_error == 0 and "main" or "master"
          vim.cmd("Gdiffsplit " .. branch)
        end,
        desc = "Git diff vs master",
      },
    },
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "fugitive",
        callback = function()
          vim.wo.winfixheight = true
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = { "FugitiveIndex", "FugitivePager" },
        callback = function()
          vim.keymap.set("n", "q", "gq", { buffer = true, remap = true })
          vim.keymap.set("n", "<C-N>", ")", { buffer = true, remap = true })
          vim.keymap.set("n", "<C-P>", "(", { buffer = true, remap = true })
          vim.keymap.set("n", "<leader>p", "<cmd>Git push<CR>", { buffer = true, desc = "Git push" })
          vim.keymap.set(
            "n",
            "<leader>P",
            "<cmd>Git push -u origin HEAD<CR>",
            { buffer = true, desc = "Git push -u origin" }
          )
          vim.keymap.set("n", "<leader>f", "<cmd>Git pull --rebase<CR>", { buffer = true, desc = "Git pull --rebase" })
        end,
      })
    end,
  },
  -- https://github.com/tpope/vim-rhubarb
  {
    "tpope/vim-rhubarb",
    keys = {
      { "<leader>gB", ":.GBrowse<CR>", desc = "[B]rowse in GitHub" },
      { "<leader>gB", ":GBrowse<CR>",  mode = "v",                 desc = "[B]rowse in GitHub" },
    },
  },
}
