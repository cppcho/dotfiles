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

local function is_status_win(win)
  return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "fugitive"
end

-- Collapse the tab to just the status + diff pair: close every window that is
-- neither a diff window nor the fugitive status (files left over from earlier
-- opens) so a review shows only the status and the left/right diff. No-op
-- until a diff window exists.
local function only_diff()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  if not vim.tbl_contains(vim.tbl_map(function(w) return vim.wo[w].diff end, wins), true) then
    return
  end
  for _, win in ipairs(wins) do
    if not vim.wo[win].diff and not is_status_win(win) then
      pcall(vim.api.nvim_win_close, win, false)
    end
  end
end

-- Trigger a fugitive status map by its <Plug> name, then run cleanup once the
-- file/diff windows have opened (scheduled so they exist by the time it runs).
local function fugitive_then(plug, cleanup)
  return function()
    local keys = vim.api.nvim_replace_termcodes("<Plug>fugitive:" .. plug, true, false, true)
    vim.api.nvim_feedkeys(keys, "mx", false)
    vim.schedule(cleanup)
  end
end

-- <CR> in the status buffer: open the file, then rebuild the layout as the
-- status (top split) + file (main area below), dropping any stray windows.
-- Keeps the status cursor line. No-op on header lines that open nothing.
local function open_keep_status()
  local line = vim.fn.line(".")
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Plug>fugitive:<CR>", true, false, true), "mx", false)
  vim.schedule(function()
    if vim.bo.filetype == "fugitive" then
      return
    end
    vim.cmd("only")
    vim.cmd("topleft 12split | 0Git")
    pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
    vim.cmd("wincmd j")
  end)
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
      { "<leader>gV", "<cmd>PRReviewDone<CR>",           desc = "PR review: finish & tear down worktree" },
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
      -- Run a gwt subcommand from this nvim's cwd, surfacing stderr on failure.
      -- gwt drives tmux (switching/killing sessions) itself, so we just fire it.
      local function run_gwt(args, label)
        local err = {}
        vim.fn.jobstart(vim.list_extend({ "gwt" }, args), {
          cwd = vim.fn.getcwd(),
          on_stderr = function(_, data)
            vim.list_extend(err, data)
          end,
          on_exit = function(_, code)
            if code ~= 0 then
              vim.schedule(function()
                vim.notify(label .. " failed: " .. vim.trim(table.concat(err, "\n")), vim.log.levels.ERROR)
              end)
            end
          end,
        })
      end

      -- Review a PR in its own gwt-managed worktree + tmux session (rather than
      -- re-rooting this nvim): hand off to `gwt review`, which creates the
      -- worktree, surfaces the PR as one unstaged diff, and switches the tmux
      -- client into a fresh nvim there.
      local function pr_review(target)
        run_gwt({ "review", target }, "gwt review")
      end

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

      -- :PRReviewDone — tear down the review worktree this nvim sits in (remove
      -- worktree + branch, kill the tmux session, switch back to the main repo
      -- session). gwt refuses unless we're in a review/pr-* worktree.
      vim.api.nvim_create_user_command("PRReviewDone", function()
        run_gwt({ "review-done" }, "gwt review-done")
      end, { desc = "Finish a PR review: tear down its worktree + tmux session" })

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
          -- In the status buffer, opening a file or diff collapses the layout
          -- while keeping the status window: <CR> leaves status + the file in
          -- the main area, the diff maps leave status + the left/right diff
          -- pair. o/gO/O keep fugitive's explicit split/vsplit/tab behaviour.
          if ev.match == "FugitiveIndex" then
            vim.keymap.set("n", "<CR>", open_keep_status,
              { buffer = true, desc = "Open file (keep status, close stray windows)" })
            for _, key in ipairs({ "dv", "dh", "ds", "dd" }) do
              vim.keymap.set("n", key, fugitive_then(key, only_diff),
                { buffer = true, desc = "Diff (close non-diff windows)" })
            end
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
