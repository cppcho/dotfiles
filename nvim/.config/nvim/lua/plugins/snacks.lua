-- https://github.com/folke/snacks.nvim
local find_files_opts = {
  cmd = "rg",
  hidden = true,
  exclude = { ".git" },
  args = {
    "--no-ignore-global",
    "--ignore-file",
    vim.fn.expand("~/.rgignore_find_files"),
  },
}

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    picker = {
      win = {
        input = {
          keys = {
            ["<c-a>"] = { "<Home>", mode = { "i", "n" }, expr = true, desc = "Start of line" },
            ["<c-e>"] = { "<End>", mode = { "i", "n" }, expr = true, desc = "End of line" },
          },
        },
      },
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          win = {
            input = {
              keys = {
                ["<Esc>"] = false,
              },
            },
            list = {
              keys = {
                ["<Esc>"] = false,
              },
            },
          },
        },
      },
    },
    explorer = {},
  },
  -- stylua: ignore
  keys = {
    -- Top Pickers & Explorer
    { "<C-p>",      function() Snacks.picker.files(find_files_opts) end,                    desc = "Search Files" },
    { "<leader>sf", function() Snacks.picker.files(find_files_opts) end,                    desc = "Search Files" },
    { "<leader>;",  function() Snacks.picker.buffers() end,                                 desc = "Buffers" },
    { "<leader>/",  function() Snacks.picker.grep() end,                                    desc = "Grep" },
    { "<leader>:",  function() Snacks.picker.command_history() end,                         desc = "Command History" },
    { "<leader>n",  function() Snacks.picker.notifications() end,                           desc = "Notification History" },
    { "<leader>e",  function() Snacks.explorer() end,                                       desc = "File Explorer" },
    { "<C-e>",      function() Snacks.explorer() end,                                       desc = "File Explorer" },
    -- find
    { "<leader>fb", function() Snacks.picker.buffers() end,                                 desc = "Buffers" },
    { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
    { "<leader>ff", function() Snacks.picker.files() end,                                   desc = "Find Files" },
    { "<leader>fg", function() Snacks.picker.git_files() end,                               desc = "Find Git Files" },
    { "<leader>fp", function() Snacks.picker.projects() end,                                desc = "Projects" },
    { "<leader>fr", function() Snacks.picker.recent() end,                                  desc = "Recent" },
    -- git
    { "<leader>gr", function() Snacks.picker.git_branches() end,                            desc = "Git Branches" },
    --{ "<leader>gl", function() Snacks.picker.git_log() end,                                 desc = "Git Log" },
    --{ "<leader>gL", function() Snacks.picker.git_log_line() end,                            desc = "Git Log Line" },
    --{ "<leader>gs", function() Snacks.picker.git_status() end,                              desc = "Git Status" },
    --{ "<leader>gS", function() Snacks.picker.git_stash() end,                               desc = "Git Stash" },
    --{ "<leader>gD", function() Snacks.picker.git_diff() end,                                desc = "Git Diff (Hunks)" },
    --{ "<leader>gf", function() Snacks.picker.git_log_file() end,                            desc = "Git Log File" },
    -- gh
    { "<leader>gi", function() Snacks.picker.gh_issue() end,                                desc = "GitHub Issues (open)" },
    { "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end,               desc = "GitHub Issues (all)" },
    { "<leader>gp", function() Snacks.picker.gh_pr() end,                                   desc = "GitHub Pull Requests (open)" },
    { "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end,                  desc = "GitHub Pull Requests (all)" },
    -- Grep
    { "<leader>sB", function() Snacks.picker.grep_buffers() end,                            desc = "Grep Open Buffers" },
    { "<leader>sg", function() Snacks.picker.grep() end,                                    desc = "Grep" },
    { "<leader>sw", function() Snacks.picker.grep_word() end,                               desc = "Visual selection or word",   mode = { "n", "x" } },
    -- search
    { '<leader>s"', function() Snacks.picker.registers() end,                               desc = "Registers" },
    { '<leader>s/', function() Snacks.picker.search_history() end,                          desc = "Search History" },
    { "<leader>sa", function() Snacks.picker.autocmds() end,                                desc = "Autocmds" },
    { "<leader>sb", function() Snacks.picker.lines() end,                                   desc = "Buffer Lines" },
    { "<leader>sc", function() Snacks.picker.command_history() end,                         desc = "Command History" },
    { "<leader>sC", function() Snacks.picker.commands() end,                                desc = "Commands" },
    { "<leader>sd", function() Snacks.picker.diagnostics() end,                             desc = "Diagnostics" },
    { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end,                      desc = "Buffer Diagnostics" },
    { "<leader>sh", function() Snacks.picker.help() end,                                    desc = "Help Pages" },
    { "<leader>sH", function() Snacks.picker.highlights() end,                              desc = "Highlights" },
    { "<leader>si", function() Snacks.picker.icons() end,                                   desc = "Icons" },
    { "<leader>sj", function() Snacks.picker.jumps() end,                                   desc = "Jumps" },
    { "<leader>sk", function() Snacks.picker.keymaps() end,                                 desc = "Keymaps" },
    { "<leader>sl", function() Snacks.picker.loclist() end,                                 desc = "Location List" },
    { "<leader>sm", function() Snacks.picker.marks() end,                                   desc = "Marks" },
    { "<leader>sM", function() Snacks.picker.man() end,                                     desc = "Man Pages" },
    { "<leader>sp", function() Snacks.picker.lazy() end,                                    desc = "Search for Plugin Spec" },
    { "<leader>sq", function() Snacks.picker.qflist() end,                                  desc = "Quickfix List" },
    { "<leader>sR", function() Snacks.picker.resume() end,                                  desc = "Resume" },
    { "<leader>su", function() Snacks.picker.undo() end,                                    desc = "Undo History" },
    { "<leader>sL", function() Snacks.picker.colorschemes() end,                            desc = "Colorschemes" },
    -- LSP
    { "gd",         function() Snacks.picker.lsp_definitions() end,                         desc = "Goto Definition" },
    { "grd",        function() Snacks.picker.lsp_definitions() end,                         desc = "Goto Definition" },
    { "grD",        function() Snacks.picker.lsp_declarations() end,                        desc = "Goto Declaration" },
    { "grr",        function() Snacks.picker.lsp_references() end,                          nowait = true,                       desc = "Goto References" },
    { "gri",        function() Snacks.picker.lsp_implementations() end,                     desc = "Goto Implementation" },
    { "grt",        function() Snacks.picker.lsp_type_definitions() end,                    desc = "Goto Type Definition" },
    { "grI",        function() Snacks.picker.lsp_incoming_calls() end,                      desc = "Calls Incoming" },
    { "grO",        function() Snacks.picker.lsp_outgoing_calls() end,                      desc = "Calls Outgoing" },
    { "<leader>ss", function() Snacks.picker.lsp_symbols() end,                             desc = "LSP Symbols" },
    { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end,                   desc = "LSP Workspace Symbols" },
  },
}
