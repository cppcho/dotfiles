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

-- A review happens in a throwaway *linked git worktree*, so the user's real
-- worktree, branch, index and stash are never touched. State lives in one marker
-- file (REVIEW_WT) in the shared git dir: line 1 = scratch worktree path, line 2
-- = the dir to return to. :ReviewRestore tears the worktree down.

-- Absolute shared git dir (same across all linked worktrees of a repo), or nil
-- when not in a git repo. dir overrides where git runs (defaults to cwd).
local function common_dir(dir)
  local cmd = { "git" }
  if dir then
    vim.list_extend(cmd, { "-C", dir })
  end
  vim.list_extend(cmd, { "rev-parse", "--path-format=absolute", "--git-common-dir" })
  local d = vim.trim(vim.fn.system(cmd))
  if vim.v.shell_error ~= 0 or d == "" then
    return nil
  end
  return d
end

local function marker_path(common)
  return common .. "/REVIEW_WT"
end

-- Deterministic scratch worktree path for this repo, kept under nvim's cache
-- (outside the repo tree) so file search / LSP treat it as its own root.
local function scratch_path(common)
  return vim.fn.stdpath("cache") .. "/review-wt/" .. vim.fn.sha256(common):sub(1, 16)
end

-- The dir to run git from / return to: the active review's saved return dir if a
-- review is in progress, otherwise the cwd. Keeps git acting on the user's real
-- worktree even when nvim has cd'd into a previous review's scratch.
local function review_main()
  local common = common_dir()
  if common and vim.fn.filereadable(marker_path(common)) == 1 then
    local rd = vim.fn.readfile(marker_path(common))[2]
    if rd and rd ~= "" then
      return rd
    end
  end
  return vim.fn.getcwd()
end

-- Remove the review worktree, tolerant of a hand-deleted dir. Must run from a
-- cwd outside it (git refuses to remove the worktree you are standing in).
local function remove_worktree(main, scratch)
  vim.fn.system({ "git", "-C", main, "worktree", "remove", "--force", scratch })
  if vim.v.shell_error ~= 0 then
    vim.fn.system({ "git", "-C", main, "worktree", "prune" })
    vim.fn.delete(scratch, "rf")
  end
end

-- Wipe buffers (files and fugitive buffers) living in the scratch worktree so
-- removing it leaves nothing dangling.
local function wipe_scratch_buffers(scratch)
  local id = vim.fn.fnamemodify(scratch, ":t")
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name:find(scratch, 1, true) or name:find("worktrees/" .. id, 1, true) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

-- Open a review of content_sha against merge-base mb in a fresh linked worktree
-- and cd the tab into it. main is the user's real worktree (git runs there, and
-- we return to it). content_sha lands in the working tree while index+HEAD reset
-- to mb, so the diff shows as unstaged, reviewable with fugitive's dv / =.
local function open_review(main, content_sha, mb, label)
  local common = common_dir(main)
  if not common then
    vim.notify("Not in a git repo", vim.log.levels.ERROR)
    return
  end
  local scratch = scratch_path(common)
  remove_worktree(main, scratch) -- drop any previous review's worktree
  vim.fn.system({ "git", "-C", main, "worktree", "add", "--force", "--detach", scratch, content_sha })
  if vim.v.shell_error ~= 0 then
    vim.notify("git worktree add failed", vim.log.levels.ERROR)
    return
  end
  vim.fn.system({ "git", "-C", scratch, "reset", "--mixed", mb })
  vim.fn.writefile({ scratch, main }, marker_path(common))
  vim.cmd("tcd " .. vim.fn.fnameescape(scratch))
  vim.notify(label .. " ready in review worktree — :ReviewRestore to return")
  vim.cmd("topleft 12split | 0Git")
end

-- Tear down the review worktree and cd the tab back to where it started.
local function review_restore()
  local common = common_dir()
  if not common or vim.fn.filereadable(marker_path(common)) ~= 1 then
    vim.notify("No review to restore", vim.log.levels.WARN)
    return
  end
  local lines = vim.fn.readfile(marker_path(common))
  local scratch, return_dir = lines[1], lines[2]
  if return_dir and return_dir ~= "" then
    vim.cmd("tcd " .. vim.fn.fnameescape(return_dir))
  end
  if scratch and scratch ~= "" then
    wipe_scratch_buffers(scratch)
    remove_worktree(return_dir or vim.fn.getcwd(), scratch)
  end
  vim.fn.delete(marker_path(common))
  vim.notify("Review worktree removed")
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
      { "<leader>gr", "<cmd>ReviewRestore<CR>",          desc = "Review restore: remove worktree, return" },
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
      -- Review a PR in a throwaway worktree without touching the user's checkout
      -- or creating a local branch: fetch the PR's head, then open it against its
      -- base's merge-base. Everything that can fail (gh, fetch) runs first and
      -- read-only. Assumes the PR's head lives in origin (same-repo PRs).
      local function pr_review(target)
        local main = review_main()
        local refs = vim.fn.systemlist({
          "gh", "pr", "view", target, "--json", "headRefName,baseRefName",
          "-q", ".headRefName, .baseRefName",
        })
        if vim.v.shell_error ~= 0 or #refs < 2 then
          vim.notify("gh pr view failed for: " .. target, vim.log.levels.ERROR)
          return
        end
        local head, base = refs[1], refs[2]
        vim.fn.system({ "git", "-C", main, "fetch", "origin", head })
        if vim.v.shell_error ~= 0 then
          vim.notify("git fetch failed for PR head: " .. head .. " (fork PRs unsupported)", vim.log.levels.ERROR)
          return
        end
        local head_sha = vim.trim(vim.fn.system({ "git", "-C", main, "rev-parse", "FETCH_HEAD" }))
        vim.fn.system({ "git", "-C", main, "fetch", "origin", base })
        local mb = vim.trim(vim.fn.system({ "git", "-C", main, "merge-base", "origin/" .. base, head_sha }))
        if mb == "" then
          vim.notify("No merge-base with origin/" .. base, vim.log.levels.ERROR)
          return
        end
        open_review(main, head_sha, mb, "PR " .. target)
      end

      -- :DiffReview [ref] — review the current branch's commits since a ref
      -- (e.g. HEAD^, origin/main, a SHA) in a throwaway worktree.
      vim.api.nvim_create_user_command("DiffReview", function(opts)
        local main = review_main()
        local ref = opts.args ~= "" and opts.args or "HEAD^"
        vim.fn.system({ "git", "-C", main, "rev-parse", "--verify", ref .. "^{commit}" })
        if vim.v.shell_error ~= 0 then
          vim.notify("Not a commit: " .. ref, vim.log.levels.ERROR)
          return
        end
        local head_sha = vim.trim(vim.fn.system({ "git", "-C", main, "rev-parse", "HEAD" }))
        local mb = vim.trim(vim.fn.system({ "git", "-C", main, "merge-base", ref, "HEAD" }))
        if mb == "" then
          vim.notify("No merge-base with " .. ref, vim.log.levels.ERROR)
          return
        end
        open_review(main, head_sha, mb, "Diff vs " .. ref)
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
        desc = "Review commits since a ref in a throwaway worktree",
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

      -- :ReviewRestore — tear down the review worktree and cd back. No-op
      -- (warns) if no review is in progress.
      vim.api.nvim_create_user_command("ReviewRestore", review_restore, {
        desc = "Remove the review worktree and return",
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
