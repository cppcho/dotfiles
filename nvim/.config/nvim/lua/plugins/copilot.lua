return {
  "github/copilot.vim",
  event = "InsertEnter",
  init = function()
    -- Disable default Tab mapping; we handle it in blink-cmp
    vim.g.copilot_no_tab_map = true

    -- Keymaps: <leader>a prefix for Copilot actions
    vim.keymap.set("n", "<leader>ae", "<cmd>Copilot enable<cr>", { desc = "Copilot enable" })
    vim.keymap.set("n", "<leader>ad", "<cmd>Copilot disable<cr>", { desc = "Copilot disable" })
    vim.keymap.set("n", "<leader>as", "<cmd>Copilot status<cr>", { desc = "Copilot status" })
    vim.keymap.set("n", "<leader>ap", "<cmd>Copilot panel<cr>", { desc = "Copilot panel" })

    -- Inline suggestion navigation (insert mode)
    vim.keymap.set("i", "<M-]>", "<Plug>(copilot-next)", { desc = "Copilot next suggestion" })
    vim.keymap.set("i", "<M-[>", "<Plug>(copilot-previous)", { desc = "Copilot previous suggestion" })
    vim.keymap.set("i", "<C-]>", "<Plug>(copilot-dismiss)", { desc = "Copilot dismiss" })
  end,
}
