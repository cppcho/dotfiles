-- https://github.com/sindrets/diffview.nvim
-- Git diff / merge tool and file history. Single-tabpage interface.

-- diffview opens in its own tab. The snacks explorer is a global picker that
-- would follow onto that tab as a redundant sidebar, so close it when opening.
local function close_snacks_explorer()
  if _G.Snacks and Snacks.picker then
    for _, p in ipairs(Snacks.picker.get({ source = "explorer" })) do
      p:close()
    end
  end
end

-- Show a PR-style diff: <ref>...HEAD compares from the merge-base, so only
-- changes on this branch since it diverged from the ref are shown
-- (upstream-only commits ignored).
local function open_diff(ref)
  close_snacks_explorer()
  vim.cmd("DiffviewOpen " .. vim.fn.fnameescape(ref .. "...HEAD"))
end

local function prompt_for_ref()
  vim.ui.input({ prompt = "Diff against ref: ", default = "origin/" }, function(ref)
    if ref and ref ~= "" then
      open_diff(ref)
    end
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
  if not ok then
    prompt_for_ref()
  end
end

-- The file history panel inherits the global scrolloff, which wastes rows on
-- the short list. Drop it to 0 so entries reach the top/bottom edges.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "DiffviewFileHistory",
  callback = function()
    vim.wo.scrolloff = 0
  end,
})

local function history(arg)
  return function()
    close_snacks_explorer()
    vim.cmd("DiffviewFileHistory" .. (arg and (" " .. arg) or ""))
  end
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
  opts = {},
  keys = {
    { "<leader>gc", diff_against_ref, desc = "Diffview: diff against ref" },
    { "<leader>gl", history(), desc = "Diffview: repo history" },
    { "<leader>gh", history("%"), desc = "Diffview: current file history" },
  },
}
