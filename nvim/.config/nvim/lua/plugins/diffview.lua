-- https://github.com/sindrets/diffview.nvim
-- Git diff / merge tool and file history. Single-tabpage interface.

-- Show a PR-style diff: <ref>...HEAD compares from the merge-base, so only
-- changes on this branch since it diverged from the ref are shown
-- (upstream-only commits ignored).
local function open_diff(ref) vim.cmd("DiffviewOpen " .. vim.fn.fnameescape(ref .. "...HEAD")) end

local function prompt_for_ref()
  vim.ui.input({ prompt = "Diff against ref: ", default = "origin/" }, function(ref)
    if ref and ref ~= "" then open_diff(ref) end
  end)
end

-- If the current branch has an open PR, diff against its base branch
-- automatically (via gh, async so the UI doesn't block); otherwise prompt.
local function diff_against_ref()
  local ok = pcall(vim.system, { "gh", "pr", "view", "--json", "baseRefName", "-q", ".baseRefName" }, {
    text = true,
    cwd = vim.fn.getcwd(),
  }, function(out)
    vim.schedule(function()
      local base = out.code == 0 and vim.trim(out.stdout or "") or ""
      if base ~= "" then
        open_diff("origin/" .. base)
      else
        prompt_for_ref()
      end
    end)
  end)
  if not ok then prompt_for_ref() end
end

-- The file history panel inherits the global scrolloff, which wastes rows on
-- the short list. Drop it to 0 so entries reach the top/bottom edges.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "DiffviewFileHistory",
  callback = function() vim.wo.scrolloff = 0 end,
})

local function history(arg)
  return function() vim.cmd("DiffviewFileHistory" .. (arg and (" " .. arg) or "")) end
end

return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewFileHistory",
    "DiffviewToggleFiles",
    "DiffviewFocusFiles",
    "DiffviewRefresh",
  },
  -- opts is a function so require("diffview.actions") only runs when the plugin
  -- loads (via the cmd trigger above), keeping lazy-loading intact.
  opts = function()
    local actions = require("diffview.actions")
    return {
      -- --imply-local: whenever a range ends at HEAD, show the live working-tree
      -- files on that side instead of the committed snapshot. Applied to every
      -- DiffviewOpen (manual or via the mappings below).
      default_args = {
        DiffviewOpen = { "--imply-local" },
      },
      keymaps = {
        file_history_panel = {
          { "n", "D", actions.open_in_diffview, { desc = "Open the entry in a diffview" } },
        },
      },
    }
  end,
  keys = {
    { "<leader>gc", "<cmd>DiffviewOpen<cr>", desc = "Diffview: open (working tree)" },
    { "<leader>gC", diff_against_ref, desc = "Diffview: diff against PR base" },
    { "<leader>gh", history(), desc = "Diffview: repo history" },
    { "<leader>gH", history("%"), desc = "Diffview: current file history" },
    { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
  },
}
