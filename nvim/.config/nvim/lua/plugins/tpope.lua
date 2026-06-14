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

-- Stash a dirty tree (including untracked) so the only changes left are the
-- ones a review sets up. Returns false on failure.
local function stash_if_dirty()
  if vim.trim(vim.fn.system({ "git", "status", "--porcelain" })) == "" then
    return true
  end
  vim.fn.system({ "git", "stash", "push", "-u", "-m", "PRReview autostash" })
  if vim.v.shell_error ~= 0 then
    vim.notify("git stash failed; aborting", vim.log.levels.ERROR)
    return false
  end
  vim.notify("Stashed local changes (git stash pop to restore)")
  return true
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
  vim.notify(label .. " ready for review (base: " .. base_ref .. ")")
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
      -- Set up the current worktree to review a PR as *unstaged* changes:
      -- stash anything dirty, check out the PR (fetches its head), then hand off
      -- to review_against with the PR's base branch.
      local function pr_review(target)
        if not stash_if_dirty() then
          return
        end
        vim.fn.system({ "gh", "pr", "checkout", target })
        if vim.v.shell_error ~= 0 then
          vim.notify("gh pr checkout failed: " .. target, vim.log.levels.ERROR)
          return
        end
        local base = vim.trim(vim.fn.system({ "gh", "pr", "view", "--json", "baseRefName", "-q", ".baseRefName" }))
        if vim.v.shell_error ~= 0 or base == "" then
          vim.notify("gh pr view failed for: " .. target, vim.log.levels.ERROR)
          return
        end
        vim.fn.system({ "git", "fetch", "origin", base })
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
        if not stash_if_dirty() then
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
