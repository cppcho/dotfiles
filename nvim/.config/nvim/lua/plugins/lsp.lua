return {
  -- https://github.com/mason-org/mason.nvim
  -- Mason: package manager
  {
    "mason-org/mason.nvim",
    opts = {},
  },

  -- https://github.com/mason-org/mason-lspconfig.nvim
  -- Bridge: mason + lspconfig
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      { "mason-org/mason.nvim" },
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "gopls",
        "pyright",
        "ts_ls",
        "lua_ls",
      },
      automatic_enable = true,
    },
  },

  -- https://github.com/neovim/nvim-lspconfig
  -- LSP configs
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
  },
}
