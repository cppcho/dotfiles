-- https://github.com/dlyongemallo/diffview-plus.nvim (maintained fork of sindrets/diffview.nvim)
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

local function git(args)
  local out = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
  local stdout = out.code == 0 and vim.trim(out.stdout or "") or ""
  return stdout ~= "" and stdout or nil
end

local function ref_exists(ref) return git({ "rev-parse", "--verify", "--quiet", ref .. "^{commit}" }) ~= nil end

-- The branch below `branch` in a local `gh stack` (its state file lives in the
-- common git dir, so worktrees share it). Parents are local branches, since
-- the stack rebases onto them before they're pushed.
local function stack_parent(branch)
  local dir = git({ "rev-parse", "--path-format=absolute", "--git-common-dir" })
  local f = dir and io.open(vim.fs.joinpath(dir, "gh-stack"))
  if not f then return nil end
  local ok, state = pcall(vim.json.decode, f:read("*a"))
  f:close()
  if not ok or type(state) ~= "table" then return nil end
  for _, stack in ipairs(state.stacks or {}) do
    for i, b in ipairs(stack.branches or {}) do
      if b.branch == branch then
        local parent = stack.branches[i - 1]
        return parent and parent.branch or ("origin/" .. stack.trunk.branch)
      end
    end
  end
end

-- The remote branch first reached walking back from HEAD: the one missing the
-- fewest of HEAD's commits (ahead-behind's second number, all refs in one
-- pass). Every branch forked later from the same base ties with it, so ties go
-- to the default branch, then to the ref with the fewest commits of its own.
local function nearest_remote(branch, default)
  local out = git({ "for-each-ref", "--format=%(symref)\t%(refname:short)\t%(ahead-behind:HEAD)", "refs/remotes" })
  if not out then return nil end
  local upstream = git({ "rev-parse", "--abbrev-ref", "@{upstream}" })
  local best, best_key
  for line in vim.gsplit(out, "\n") do
    local symref, ref, ahead, behind = line:match("^(.-)\t(.-)\t(%d+) (%d+)$")
    if ref and symref == "" and ref ~= upstream and ref ~= "origin/" .. branch then
      -- Sort key packs (behind, not-default, ahead) into one comparable number.
      local key = tonumber(behind) * 1e12 + (ref == default and 0 or 1e6) + tonumber(ahead)
      if not best_key or key < best_key then
        best, best_key = ref, key
      end
    end
  end
  return best
end

-- Without a PR: the gh stack parent, then the base recorded in branch config
-- (gh pr create's gh-merge-base, VS Code's vscode-merge-base), then the
-- nearest remote branch in HEAD's history, then the remote default branch.
local function detect_base()
  local branch = git({ "branch", "--show-current" })
  if not branch then return nil end
  local default = git({ "symbolic-ref", "--short", "refs/remotes/origin/HEAD" })
  -- The default branch has no base; let the caller prompt.
  if default == "origin/" .. branch then return nil end
  local candidates = {
    function() return stack_parent(branch) end,
    function()
      local merge_base = git({ "config", "branch." .. branch .. ".gh-merge-base" })
      return merge_base and ("origin/" .. merge_base)
    end,
    function() return git({ "config", "branch." .. branch .. ".vscode-merge-base" }) end,
    function() return nearest_remote(branch, default) end,
    function() return default end,
  }
  for _, candidate in ipairs(candidates) do
    local ref = candidate()
    if ref and ref_exists(ref) then return ref end
  end
end

-- Diff against the open PR's base branch (via gh, async so the UI doesn't
-- block); with no PR, detect the base locally, and prompt only if that fails.
local function diff_against_ref()
  local function fallback()
    local base = detect_base()
    if base then
      vim.notify("Diffview: no PR, diffing against " .. base)
      open_diff(base)
    else
      prompt_for_ref()
    end
  end
  local ok = pcall(vim.system, { "gh", "pr", "view", "--json", "baseRefName", "-q", ".baseRefName" }, {
    text = true,
    cwd = vim.fn.getcwd(),
  }, function(out)
    vim.schedule(function()
      local base = out.code == 0 and vim.trim(out.stdout or "") or ""
      if base ~= "" then
        open_diff("origin/" .. base)
      else
        fallback()
      end
    end)
  end)
  if not ok then fallback() end
end

-- Also a command so external callers can launch straight into the PR diff:
-- `nvim -c DiffviewPR` (used by ~/bin/herdr-gwt-prompt when opening a PR URL).
vim.api.nvim_create_user_command("DiffviewPR", diff_against_ref, { desc = "Diffview: diff against PR base" })

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
  "dlyongemallo/diffview-plus.nvim",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewToggle",
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
      enhanced_diff_hl = true,
      -- histogram keeps moved/rewritten blocks together instead of interleaving
      -- them line by line the way the default myers algorithm does.
      diffopt = { algorithm = "histogram" },
      show_help_hints = false,
      clean_up_buffers = true,
      auto_close_on_empty = true,
      -- Files marked reviewed with w in the file panel survive restarts.
      persist_selections = { enabled = true },
      file_panel = {
        show_branch_name = true,
        always_show_sections = true,
      },
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
    { "<leader>gc", "<cmd>DiffviewToggle<cr>", desc = "Diffview: toggle" },
    { "<leader>gC", "<cmd>DiffviewPR<cr>", desc = "Diffview: diff against PR base" },
    { "<leader>gh", history(), desc = "Diffview: repo history" },
    { "<leader>gH", history("%"), desc = "Diffview: current file history" },
    {
      "<leader>gh",
      "<Esc><cmd>'<,'>DiffviewFileHistory --follow<cr>",
      mode = "x",
      desc = "Diffview: selected lines history",
    },
    { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
  },
}
