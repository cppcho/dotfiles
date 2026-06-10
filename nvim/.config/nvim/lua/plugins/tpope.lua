-- Base ref for PR review diffs, set by :PRReview. Falls back to origin/main|master.
local function pr_base()
  if vim.g.pr_review_base then
    return vim.g.pr_review_base
  end
  vim.fn.system("git rev-parse --verify origin/main 2>/dev/null")
  return vim.v.shell_error == 0 and "origin/main" or "origin/master"
end

-- Like :only, but keep the quickfix list: close all other windows and
-- reset diff mode.
local function pr_diff_close()
  local cur = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if win ~= cur and vim.bo[buf].buftype ~= "quickfix" and vim.api.nvim_win_get_config(win).relative == "" then
      pcall(vim.api.nvim_win_close, win, false)
    end
  end
  vim.cmd("diffoff!")
end

-- Clamp the quickfix window height: it ends up half the screen when it was
-- momentarily the only window during pr_diff_close.
local function pr_qf_clamp()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "quickfix" then
      vim.api.nvim_win_set_height(win, 10)
    end
  end
end

-- Diff the current file against the PR base. silent: for files with no base
-- version (added in the PR), fugitive diffs vs an empty buffer but echoes a
-- noisy git "fatal: path exists on disk" message.
local function pr_open_diff()
  vim.cmd("silent Gvdiffsplit " .. pr_base() .. "...")
  pr_qf_clamp()
end

-- Open a vertical diff of the current file against the PR base (merge-base via `...`)
local function pr_diff()
  pr_diff_close()
  pr_open_diff()
end

-- Jump within the quickfix list, closing all other windows first
local function pr_nav(cmd)
  pr_diff_close()
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    vim.notify(err:gsub("^Vim%S*:", ""), vim.log.levels.WARN)
  end
  pr_qf_clamp()
  return ok
end

-- Jump to next/prev changed file in the quickfix list and re-open the diff
local function pr_step(cmd)
  if pr_nav(cmd) then
    pr_open_diff()
  end
end

return {
  -- https://github.com/tpope/vim-fugitive
  {
    "tpope/vim-fugitive",
    lazy = false,
    keys = {
      { "<leader>ga", "<cmd>Gwrite<CR>",                 desc = "Git add (stage file)" },
      { "<leader>gs", "<cmd>topleft 12split | 0Git<CR>", desc = "Git status" },
      { "<leader>gd", "<cmd>Gdiffsplit<CR>",             desc = "Git diff" },
      { "<leader>gb", "<cmd>Git blame<CR>",              desc = "Git blame" },
      { "<leader>gv", "<cmd>PRReview<CR>",      desc = "PR review: pick an open PR" },
      { "<leader>gi", ":PRReview ",             desc = "PR review: enter PR/branch/URL" },
      { "<leader>gp", pr_diff,                  desc = "PR review: diff file vs base" },
      { "<leader>gD", pr_diff,                  desc = "PR review: diff file vs base" },
      { "]r",         function() pr_step("cnext") end, desc = "PR review: next file (diff)" },
      { "[r",         function() pr_step("cprev") end, desc = "PR review: prev file (diff)" },
      { "]q",         function() pr_nav("cnext") end,  desc = "Next quickfix (clear windows)" },
      { "[q",         function() pr_nav("cprev") end,  desc = "Prev quickfix (clear windows)" },
    },
    config = function()
      -- Quickfix maps mirroring the fugitive status window: dv opens a
      -- vertical diff vs the PR base, <CR> opens the file plainly.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        callback = function(ev)
          vim.keymap.set("n", "dv", function()
            vim.cmd("cc " .. vim.fn.line("."))
            pr_diff()
          end, { buffer = ev.buf, desc = "PR review: diff entry vs base" })
          vim.keymap.set("n", "<CR>", function()
            pr_diff_close()
            vim.cmd("cc " .. vim.fn.line("."))
            pr_qf_clamp()
          end, { buffer = ev.buf, desc = "Open entry" })
        end,
      })

      -- Checkout the PR, load its changed files into the quickfix list,
      -- then step through with ]r / [r.
      local function pr_review(target)
        vim.fn.system({ "gh", "pr", "checkout", target })
        if vim.v.shell_error ~= 0 then
          vim.notify("gh pr checkout failed: " .. target, vim.log.levels.ERROR)
          return
        end
        vim.cmd("checktime")
        local base = vim.trim(vim.fn.system({ "gh", "pr", "view", "--json", "baseRefName", "-q", ".baseRefName" }))
        if vim.v.shell_error ~= 0 or base == "" then
          vim.notify("No PR found for current branch (gh pr view failed)", vim.log.levels.ERROR)
          return
        end
        vim.fn.system({ "git", "fetch", "origin", base })
        vim.g.pr_review_base = "origin/" .. base
        -- Make gitsigns (signs, ]c outside diff windows) show PR changes
        -- vs the merge-base instead of the index. Undo: :Gitsigns reset_base true
        local mb = vim.trim(vim.fn.system({ "git", "merge-base", vim.g.pr_review_base, "HEAD" }))
        if vim.v.shell_error == 0 and mb ~= "" then
          require("gitsigns").change_base(mb, true)
        end
        vim.cmd("Git difftool --name-only " .. vim.g.pr_review_base .. "...")
        -- render entries as plain file paths instead of fugitive's "@:path||"
        vim.fn.setqflist({}, "r", {
          quickfixtextfunc = function(info)
            local items = vim.fn.getqflist({ id = info.id, items = true }).items
            local out = {}
            for i = info.start_idx, info.end_idx do
              local name = items[i].module ~= "" and items[i].module or vim.fn.bufname(items[i].bufnr)
              out[#out + 1] = (name:gsub("^@:", ""))
            end
            return out
          end,
        })
        vim.cmd("botright copen")
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
      end, { nargs = "?", desc = "Review a PR: checkout + changed files in quickfix" })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "fugitive",
        callback = function()
          vim.wo.winfixheight = true
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = { "FugitiveIndex", "FugitivePager" },
        callback = function()
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
