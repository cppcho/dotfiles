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
        "copilot",
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
    config = function()
      -- LSP key mappings
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("my-lsp-attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          -- Rename the variable under your cursor.
          map("gR", vim.lsp.buf.rename, "[R]e[n]ame")

          -- Execute a code action, usually your cursor needs to be on top of an error
          map("gA", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
        end,
      })
    end,
  },
}
