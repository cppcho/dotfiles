-- https://github.com/stevearc/oil.nvim
return {
  "stevearc/oil.nvim",
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    view_options = {
      show_hidden = true,
    },
    use_default_keymaps = false,
    keymaps = {
      ["-"] = { "actions.parent", mode = "n" },
      ["<CR>"] = "actions.select",
      ["_"] = { "actions.open_cwd", mode = "n" },
      ["`"] = { "actions.cd", mode = "n" },
      ["g."] = { "actions.toggle_hidden", mode = "n" },
      ["g?"] = { "actions.show_help", mode = "n" },
      ["g\\"] = { "actions.toggle_trash", mode = "n" },
      ["gp"] = "actions.preview",
      ["gr"] = "actions.refresh",
      ["gs"] = { "actions.change_sort", mode = "n" },
      ["gx"] = "actions.open_external",
      ["q"] = { "actions.close", mode = "n" },
    },
  },
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  lazy = false,
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
  },
}
