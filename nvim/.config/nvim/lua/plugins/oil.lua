-- https://github.com/stevearc/oil.nvim

-- Winbar content for oil windows: the current directory, or the buffer name
-- when there is no local directory (e.g. over ssh). Global because winbar
-- expressions are evaluated as vimscript (%!v:lua...).
function _G.get_oil_winbar()
  local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local dir = require("oil").get_current_dir(bufnr)
  if dir then
    return vim.fn.fnamemodify(dir, ":~")
  else
    return vim.api.nvim_buf_get_name(0)
  end
end

-- Whether the detail columns (permissions/size/mtime) are shown; toggled by gd.
local detail = false

return {
  "stevearc/oil.nvim",
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    view_options = {
      show_hidden = true,
    },
    -- Show the current directory as a header at the top of the oil window.
    -- Scoped to oil windows only, so it won't affect normal buffers.
    win_options = {
      winbar = "%!v:lua.get_oil_winbar()",
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
      ["gd"] = {
        desc = "Toggle file detail view",
        callback = function()
          detail = not detail
          if detail then
            require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
          else
            require("oil").set_columns({ "icon" })
          end
        end,
      },
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
