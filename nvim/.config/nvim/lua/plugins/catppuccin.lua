-- https://github.com/catppuccin/nvim
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  -- load the default colorscheme during startup
  lazy = false,
  opts = {
    -- latte, frappe, macchiato, mocha
    flavour = "macchiato",
    -- https://github.com/catppuccin/nvim?tab=readme-ov-file#why-do-my-treesitter-highlights-look-incorrect
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    auto_integrations = true,
  },
  config = function()
    vim.cmd.colorscheme("catppuccin-macchiato")
  end,
}
