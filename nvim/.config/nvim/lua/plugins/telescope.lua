-- https://github.com/nvim-telescope/telescope.nvim
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    { "nvim-telescope/telescope-ui-select.nvim" },
  },
  config = function()
    local actions = require("telescope.actions")

    -- https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes#file-and-text-search-in-hidden-files-and-directories
    local vimgrep_arguments = vim.deepcopy(require("telescope.config").values.vimgrep_arguments)
    table.insert(vimgrep_arguments, "--hidden")
    table.insert(vimgrep_arguments, "--glob")
    table.insert(vimgrep_arguments, "!**/.git/*")

    require("telescope").setup({
      defaults = {
        wrap_results = false,
        vimgrep_arguments = vimgrep_arguments,
        mappings = {
          i = {
            -- C-j/k to navigate selections in insert mode
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            -- Readline-like navigation in insert mode
            ["<C-a>"] = function()
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Home>", true, false, true), "n", false)
            end,
            ["<C-e>"] = function()
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<End>", true, false, true), "n", false)
            end,
            ["<C-f>"] = actions.to_fuzzy_refine,
            ["<C-w>"] = function(prompt_bufnr)
              local action_state = require("telescope.actions.state")
              local picker = action_state.get_current_picker(prompt_bufnr)
              local current = vim.wo[picker.results_win].wrap
              vim.wo[picker.results_win].wrap = not current
            end,
            ["<C-u>"] = actions.results_scrolling_up,
            ["<C-d>"] = actions.results_scrolling_down,
          },
        },
      },
      pickers = {
        find_files = {
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        },
      },
      extensions = {
        ["ui-select"] = { require("telescope.themes").get_dropdown() },
      },
    })

    -- Enable Telescope extensions if they are installed
    pcall(require("telescope").load_extension, "fzf")
    pcall(require("telescope").load_extension, "ui-select")

    -- Telescope key mappings
    local builtin = require("telescope.builtin")
    vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
    vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
    vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
    vim.keymap.set("n", "<leader>sg", builtin.git_files, { desc = "Find files tracked by [G]it" })
    vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
    vim.keymap.set({ "n", "v" }, "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
    vim.keymap.set("n", "<leader>sl", builtin.live_grep, { desc = "[L]ive Grep" })
    vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
    vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
    vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set("n", "<leader>sc", builtin.commands, { desc = "[S]earch [C]ommands" })
    vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
    vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Search Files" })
    vim.keymap.set("n", "<leader>/", function()
      local ok, search = pcall(vim.fn.input, "Grep > ")
      vim.cmd("echo ''")
      if ok and search ~= "" then
        builtin.grep_string({ search = search })
      end
    end, { desc = "Grep string" })

    -- Search Neovim files
    vim.keymap.set("n", "<leader>sn", function()
      builtin.find_files({ cwd = vim.fn.stdpath("config") })
    end, { desc = "[S]earch [N]eovim files" })
  end,
}
