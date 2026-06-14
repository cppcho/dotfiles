-- Close all diff windows except the current one, then turn off diff. Used to
-- tear down a Gvdiffsplit/Gdiffsplit review pair.
local function close_diff()
  local cur = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= cur and vim.wo[win].diff then
      pcall(vim.api.nvim_win_close, win, false)
    end
  end
  vim.cmd("diffoff!")
end

-- Path to a file inside the per-worktree git dir (absolute, cwd-independent).
-- nil when not in a git repo.
local function git_path(name)
  local dir = vim.trim(vim.fn.system({ "git", "rev-parse", "--absolute-git-dir" }))
  if vim.v.shell_error ~= 0 or dir == "" then
    return nil
  end
  return dir .. "/" .. name
end

local function is_dirty()
  return vim.trim(vim.fn.system({ "git", "status", "--porcelain" })) ~= ""
end

-- True only during an active review. A review always leaves a detached HEAD
-- plus the restore marker; a marker found while on a branch is stale (an
-- abandoned review), so the next review is a fresh start and restore treats the
-- working tree as the user's — never destroying it.
local function review_in_progress()
  local path = git_path("REVIEW_RESTORE")
  if not path or vim.fn.filereadable(path) ~= 1 then
    return false
  end
  return vim.trim(vim.fn.system({ "git", "symbolic-ref", "--quiet", "HEAD" })) == ""
end

-- Pop the exact stash recorded at review start (matched by commit SHA), so a
-- stash from another worktree or an unrelated autostash is never popped by
-- mistake. No-op if the SHA is empty or the stash is already gone.
local function pop_review_stash(sha)
  if not sha or sha == "" then
    return
  end
  local gd = vim.trim(vim.fn.system(
    "git stash list --format='%H %gd' | awk -v s='" .. sha .. "' '$1==s{print $2; exit}'"))
  if gd ~= "" then
    vim.fn.system({ "git", "stash", "pop", gd })
  end
end

-- Start a review; return false if it cannot reach a clean tree. Fresh start (on
-- a branch): record the branch to return to and the SHA of a stash holding the
-- user's real work, overwriting any stale marker. Follow-up (already mid-review):
-- discard the previous review's working-tree diff — that content lives in the
-- PR/branch — so there is only ever one autostash and a single restore returns
-- to the true branch.
local function begin_review()
  if review_in_progress() then
    vim.fn.system({ "git", "reset", "--hard" })
    vim.fn.system({ "git", "clean", "-fd" })
    return true
  end
  local path = git_path("REVIEW_RESTORE")
  if not path then
    vim.notify("Not in a git repo", vim.log.levels.ERROR)
    return false
  end
  local ref = vim.trim(vim.fn.system({ "git", "symbolic-ref", "--quiet", "--short", "HEAD" }))
  if ref == "" then
    ref = vim.trim(vim.fn.system({ "git", "rev-parse", "HEAD" }))
  end
  local stash_sha = ""
  if is_dirty() then
    vim.fn.system({ "git", "stash", "push", "-u", "-m", "PRReview autostash" })
    if vim.v.shell_error ~= 0 then
      vim.notify("git stash failed; aborting", vim.log.levels.ERROR)
      return false
    end
    stash_sha = vim.trim(vim.fn.system({ "git", "rev-parse", "stash@{0}" }))
    vim.notify("Stashed local changes (restored by :ReviewRestore)")
  end
  vim.fn.writefile({ ref, stash_sha }, path)
  return true
end

-- Undo a :PRReview/:DiffReview. During an active review (detached HEAD) the
-- working tree is the review's content: force back to the saved branch, sweep
-- PR-added untracked files, and pop the saved stash. If the marker is stale
-- (already on a branch) never touch the working tree — only pop the saved stash
-- when the tree is clean, and keep the marker if dirty so a retry can finish.
local function review_restore()
  local path = git_path("REVIEW_RESTORE")
  if not path or vim.fn.filereadable(path) ~= 1 then
    vim.notify("No review to restore", vim.log.levels.WARN)
    return
  end
  local lines = vim.fn.readfile(path)
  local ref, stash_sha = lines[1], lines[2] or ""

  if not review_in_progress() then
    if is_dirty() then
      local hint = stash_sha ~= "" and (" Recover work: git stash pop " .. stash_sha) or ""
      vim.notify("Stale review marker; tree dirty — left untouched." .. hint, vim.log.levels.WARN)
      return -- keep marker so a clean retry can still pop the stash
    end
    pop_review_stash(stash_sha)
    vim.fn.delete(path)
    vim.cmd("checktime")
    vim.notify("Cleared stale review marker")
    return
  end

  if not ref or ref == "" then
    vim.notify("Review marker corrupt; aborting", vim.log.levels.ERROR)
    return
  end
  vim.fn.system({ "git", "checkout", "--force", ref })
  if vim.v.shell_error ~= 0 then
    vim.notify("git checkout failed: " .. ref .. " (marker kept)", vim.log.levels.ERROR)
    return
  end
  -- PR-added (untracked) files survive --force; the user's own untracked work
  -- is safe in the stash, popped next.
  vim.fn.system({ "git", "clean", "-fd" })
  pop_review_stash(stash_sha)
  vim.fn.delete(path)
  vim.cmd("checktime")
  vim.notify("Restored to " .. ref)
end

-- Set up the worktree to review against base_ref as *unstaged* changes: detach
-- (so the reset moves HEAD, not a branch), then mixed-reset to the merge-base of
-- base_ref and HEAD. HEAD and the index land on base while the working tree is
-- left at its current content, so the base..tree diff shows as unstaged edits in
-- :Git, reviewable with fugitive's native diff (dv / =). Assumes a clean tree.
local function review_against(base_ref, label)
  local mb = vim.trim(vim.fn.system({ "git", "merge-base", base_ref, "HEAD" }))
  if vim.v.shell_error ~= 0 or mb == "" then
    vim.notify("No merge-base with " .. base_ref, vim.log.levels.ERROR)
    return
  end
  vim.fn.system({ "git", "checkout", "--detach" })
  vim.fn.system({ "git", "reset", "--mixed", mb })
  if vim.v.shell_error ~= 0 then
    vim.notify("git reset failed", vim.log.levels.ERROR)
    return
  end
  vim.cmd("checktime")
  vim.notify(label .. " ready (base: " .. base_ref .. ") — :ReviewRestore to return")
  vim.cmd("topleft 12split | 0Git")
end

return {
  -- https://github.com/tpope/vim-fugitive
  {
    "tpope/vim-fugitive",
    lazy = false,
    keys = {
      { "<leader>ga", "<cmd>Gwrite<CR>",                 desc = "Git add (stage file)" },
      { "<leader>gs", "<cmd>topleft 12split | 0Git<CR>", desc = "Git status" },
      { "<leader>gd", "<cmd>Gdiffsplit<CR>",             desc = "Git diff (vs index)" },
      { "<leader>gb", "<cmd>Git blame<CR>",              desc = "Git blame" },
      { "<leader>gv", "<cmd>PRReview<CR>",               desc = "PR review: pick an open PR" },
      { "<leader>gi", ":PRReview ",                      desc = "PR review: enter PR/branch/URL" },
      { "<leader>gr", "<cmd>ReviewRestore<CR>",          desc = "Review restore: return to branch" },
      -- Shadows the global <leader>q (close buffer): in a diff, land on the
      -- working-tree file and close the diff instead
      {
        "<leader>q",
        function()
          if not vim.wo.diff then
            vim.cmd("bd")
            return
          end
          -- Land on the working-tree file (not the fugitive base blob) first
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.wo[win].diff and not vim.api.nvim_buf_get_name(buf):match("^fugitive://") then
              vim.api.nvim_set_current_win(win)
              break
            end
          end
          close_diff()
        end,
        desc = "Close diff (keep working file) / close buffer",
      },
    },
    config = function()
      -- Set up the current worktree to review a PR as *unstaged* changes
      -- without creating a local branch: stash anything dirty, fetch the PR's
      -- head, check it out *detached* (no new branch), then hand off to
      -- review_against, which resets the index to the merge-base so the PR diff
      -- shows as unstaged. Assumes the PR's head lives in origin (same-repo PRs).
      local function pr_review(target)
        -- Everything that can fail (gh, fetch) runs first and read-only, so a bad
        -- target / fork PR / offline aborts before begin_review touches state.
        local refs = vim.fn.systemlist({
          "gh", "pr", "view", target, "--json", "headRefName,baseRefName",
          "-q", ".headRefName, .baseRefName",
        })
        if vim.v.shell_error ~= 0 or #refs < 2 then
          vim.notify("gh pr view failed for: " .. target, vim.log.levels.ERROR)
          return
        end
        local head, base = refs[1], refs[2]
        vim.fn.system({ "git", "fetch", "origin", head })
        if vim.v.shell_error ~= 0 then
          vim.notify("git fetch failed for PR head: " .. head .. " (fork PRs unsupported)", vim.log.levels.ERROR)
          return
        end
        local head_sha = vim.trim(vim.fn.system({ "git", "rev-parse", "FETCH_HEAD" }))
        vim.fn.system({ "git", "fetch", "origin", base })
        if not begin_review() then
          return
        end
        vim.fn.system({ "git", "checkout", "--detach", head_sha })
        if vim.v.shell_error ~= 0 then
          vim.notify("git checkout failed for PR head: " .. head, vim.log.levels.ERROR)
          return
        end
        review_against("origin/" .. base, "PR " .. target)
      end

      -- :DiffReview [ref] — same unstaged-review flow against any commit/ref
      -- (e.g. HEAD^, origin/main, a SHA). Reviews the merge-base..HEAD changes;
      -- for an ancestor ref that's just the commits since ref.
      vim.api.nvim_create_user_command("DiffReview", function(opts)
        local ref = opts.args ~= "" and opts.args or "HEAD^"
        vim.fn.system({ "git", "rev-parse", "--verify", ref .. "^{commit}" })
        if vim.v.shell_error ~= 0 then
          vim.notify("Not a commit: " .. ref, vim.log.levels.ERROR)
          return
        end
        -- Validate the merge-base before begin_review, so an unrelated ref can't
        -- stash the user's work and then abort.
        if vim.trim(vim.fn.system({ "git", "merge-base", ref, "HEAD" })) == "" then
          vim.notify("No merge-base with " .. ref, vim.log.levels.ERROR)
          return
        end
        if not begin_review() then
          return
        end
        review_against(ref, "Diff vs " .. ref)
      end, {
        nargs = "?",
        complete = function(arg)
          local refs = vim.fn.systemlist({
            "git", "for-each-ref", "--format=%(refname:short)",
            "refs/heads", "refs/remotes", "refs/tags",
          })
          table.insert(refs, 1, "HEAD^")
          return vim.tbl_filter(function(r)
            return r:find(arg, 1, true) == 1
          end, refs)
        end,
        desc = "Review working tree vs a ref as unstaged changes (detaches HEAD)",
      })

      -- :PRReview [number|url|branch] — with no args, pick from open PRs.
      vim.api.nvim_create_user_command("PRReview", function(opts)
        if opts.args ~= "" then
          return pr_review(opts.args)
        end
        -- Custom picker instead of Snacks.picker.gh_pr: that one requests
        -- expensive fields (mergeStateStatus etc.) making gh take ~10s.
        Snacks.picker.pick({
          title = "Review PR",
          layout = { preset = "select", layout = { width = 0.7 } },
          finder = function(opts, ctx)
            return require("snacks.picker.source.proc").proc(
              ctx:opts({
                cmd = "gh",
                args = {
                  "pr", "list", "--limit", "100",
                  "--json", "number,title,headRefName,author,isDraft",
                  "--jq", [[.[] | "\(.number)\t\(.isDraft)\t\(.author.login)\t\(.headRefName)\t\(.title)"]],
                },
                transform = function(item)
                  local number, draft, author, branch, title = item.text:match("^(%d+)\t(%S+)\t(.-)\t(.-)\t(.*)$")
                  if not number then
                    return false
                  end
                  item.number = tonumber(number)
                  item.draft = draft == "true"
                  item.author = author
                  item.branch = branch
                  item.title = title
                end,
              }),
              ctx
            )
          end,
          format = function(item)
            local ret = {}
            ret[#ret + 1] = { ("#%-6d "):format(item.number), "Number" }
            if item.draft then
              ret[#ret + 1] = { "[draft] ", "Comment" }
            end
            ret[#ret + 1] = { item.title }
            ret[#ret + 1] = { "  " .. item.branch, "Comment" }
            ret[#ret + 1] = { "  @" .. item.author, "Special" }
            return ret
          end,
          confirm = function(picker, item)
            picker:close()
            if item and item.number then
              vim.schedule(function() pr_review(tostring(item.number)) end)
            end
          end,
        })
      end, { nargs = "?", desc = "Review a PR: base checked out, PR changes unstaged" })

      -- :ReviewRestore — return to the branch you were on before a review,
      -- popping the autostash. No-op (warns) if no review is in progress.
      vim.api.nvim_create_user_command("ReviewRestore", review_restore, {
        desc = "Return to the pre-review branch and pop the autostash",
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "fugitive",
        callback = function()
          vim.wo.winfixheight = true
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = { "FugitiveIndex", "FugitivePager" },
        callback = function(ev)
          -- Pager buffers don't map "-" themselves, so the global Oil map
          -- would fire there; the index buffer keeps fugitive's own
          -- stage/unstage "-".
          if ev.match == "FugitivePager" then
            vim.keymap.set("n", "-", "<Nop>", { buffer = true })
          end
          vim.keymap.set("n", "q", "gq", { buffer = true, remap = true })
          vim.keymap.set("n", "<C-N>", ")", { buffer = true, remap = true })
          vim.keymap.set("n", "<C-P>", "(", { buffer = true, remap = true })
          vim.keymap.set("n", "<leader>p", "<cmd>Git push<CR>", { buffer = true, desc = "Git push" })
          vim.keymap.set(
            "n",
            "<leader>P",
            "<cmd>Git push -u origin HEAD<CR>",
            { buffer = true, desc = "Git push -u origin" }
          )
          vim.keymap.set("n", "<leader>f", "<cmd>Git pull --rebase<CR>", { buffer = true, desc = "Git pull --rebase" })
        end,
      })
    end,
  },
  -- https://github.com/tpope/vim-rhubarb
  {
    "tpope/vim-rhubarb",
    keys = {
      { "<leader>gB", ":.GBrowse<CR>",              desc = "[B]rowse in GitHub" },
      { "<leader>gB", ":GBrowse<CR>",               mode = "v",                    desc = "[B]rowse in GitHub" },
      { "<leader>gO", "<cmd>!gh pr view --web<CR>", desc = "Browse [P]R in GitHub" },
    },
  },
}
