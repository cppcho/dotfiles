-- https://github.com/sindrets/diffview.nvim
return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
  keys = {
    { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diff view (local changes)" },
    {
      "<leader>gV",
      function()
        vim.fn.system("git rev-parse --verify main 2>/dev/null")
        local default_branch = vim.v.shell_error == 0 and "main" or "master"
        vim.ui.input({ prompt = "Diff against branch/rev: ", default = default_branch }, function(input)
          if input and input ~= "" then
            vim.cmd("DiffviewOpen " .. input)
          end
        end)
      end,
      desc = "Diff view vs branch",
    },
  },
}
