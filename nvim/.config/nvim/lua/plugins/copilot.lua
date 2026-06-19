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

    -- copilot.vim's own VimLeavePre handler is a no-op and the language server
    -- doesn't exit on stdin EOF, so it leaks as an orphan on exit. Force-stop it.
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        for _, client in ipairs(vim.lsp.get_clients()) do
          if client.name:lower():find("copilot") then
            client:stop(true)
          end
        end
      end,
    })
  end,
}
