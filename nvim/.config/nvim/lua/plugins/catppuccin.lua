-- https://github.com/catppuccin/nvim
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  -- load the default colorscheme during startup
  lazy = false,
  opts = {
    -- latte, frappe, macchiato, mocha
    flavour = "mocha",
    default_integrations = true,
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin-mocha")
  end,
}
