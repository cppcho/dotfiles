return {
  {
    -- https://github.com/nvim-neotest/neotest
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      {
        -- https://github.com/fredrikaverpil/neotest-golang
        "fredrikaverpil/neotest-golang",
        version = "*",
        build = function()
          vim.system({ "go", "install", "gotest.tools/gotestsum@latest" }):wait()
        end,
      },
    },
    keys = {
      { "<leader>tn", function() require("neotest").run.run() end,                   desc = "Run nearest test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file tests" },
      { "<leader>ts", function() require("neotest").summary.toggle() end,            desc = "Toggle test summary" },
      { "<leader>to", function() require("neotest").output_panel.toggle() end,       desc = "Toggle output panel" },
      { "<leader>tl", function() require("neotest").run.run_last() end,              desc = "Run last test" },
      { "<leader>tx", function() require("neotest").run.stop() end,                  desc = "Stop tests" },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-golang")(),
        },
      })
    end,
  },
}
