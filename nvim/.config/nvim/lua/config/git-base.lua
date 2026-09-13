-- :GitBase <rev> — review the whole branch as if <rev> were HEAD.
--
-- Most git UIs are HEAD- or index-relative with no base to configure (snacks'
-- explorer hardcodes `git status --porcelain`; so do lualine, lazygit and the
-- prompt), so the only lever that moves all of them at once is HEAD itself.
--
-- Detaching first keeps the branch ref still, so linked worktrees, other panes
-- and agents on the same branch see nothing. `--mixed` puts the index on the
-- base too, which is what makes gitsigns agree without being told; the index it
-- overwrites is saved as a tree object and read back verbatim on exit, so
-- staged and unstaged work stay distinct across the round trip.

local STATE_FILE = "NVIM_BASE"

---@return string? stdout, string? stderr
local function git(args)
  local out = vim.system(vim.list_extend({ "git" }, args), { text = true, cwd = vim.fn.getcwd() }):wait()
  if out.code ~= 0 then
    return nil, vim.trim(out.stderr or "")
  end
  return vim.trim(out.stdout or "")
end

-- Per-worktree, not --git-common-dir: HEAD is per-worktree, so base mode is too.
local function state_path()
  local dir = git({ "rev-parse", "--absolute-git-dir" })
  return dir and (dir .. "/" .. STATE_FILE) or nil
end

local function read_state()
  local path = state_path()
  if not path or vim.fn.filereadable(path) == 0 then
    return nil
  end
  local l = vim.fn.readfile(path)
  return l[1] and l[2] and l[3] and { branch = l[1], base = l[2], tree = l[3] } or nil
end

-- The index writes below do reach the file watchers, but only after fs-event
-- debounce; redraw now so the sidebar and signs flip with the command.
local function refresh_git_ui()
  pcall(function() require("snacks.explorer.git").refresh(Snacks.git.get_root(vim.fn.getcwd())) end)
  pcall(function() require("snacks.explorer.watch").refresh() end)
  pcall(function() require("gitsigns").refresh() end)
end

local function base_on(rev)
  if read_state() then
    return vim.notify("Already in base mode. :GitBaseOff first.", vim.log.levels.ERROR)
  end
  local branch = git({ "symbolic-ref", "-q", "HEAD" })
  if not branch then
    return vim.notify("HEAD is detached — no branch to restore afterwards.", vim.log.levels.ERROR)
  end

  -- `~2` / `^` mean HEAD-relative, as they do in gitsigns' change_base.
  rev = rev:match("^[~^]") and ("HEAD" .. rev) or rev

  -- `origin/main...` is the merge-base form diffview.lua already uses.
  local ref = rev:match("^(.-)%.%.%..*$")
  local sha, err
  if ref then
    sha, err = git({ "merge-base", ref, "HEAD" })
  else
    sha, err = git({ "rev-parse", "--verify", rev .. "^{commit}" })
  end
  if not sha then
    return vim.notify("Cannot resolve " .. rev .. ": " .. (err or ""), vim.log.levels.ERROR)
  end

  -- Fails on unmerged paths, which is the one state this cannot round-trip.
  local tree, terr = git({ "write-tree" })
  if not tree then
    return vim.notify("Cannot snapshot the index: " .. (terr or ""), vim.log.levels.ERROR)
  end

  -- Written before the repo is touched, so a crash can never leave a moved HEAD
  -- and a reset index with no record of how to put them back.
  local path = assert(state_path())
  vim.fn.writefile({ branch, sha, tree }, path)

  local function abort(msg)
    git({ "symbolic-ref", "HEAD", branch })
    git({ "read-tree", tree })
    vim.fn.delete(path)
    vim.notify(msg, vim.log.levels.ERROR)
  end

  local _, derr = git({ "checkout", "--detach", "-q" })
  if derr then
    return abort("checkout --detach failed: " .. derr)
  end
  local _, rerr = git({ "reset", "--mixed", "-q", sha })
  if rerr then
    return abort("reset --mixed failed: " .. rerr)
  end

  refresh_git_ui()
  vim.notify("Base: " .. rev .. " (" .. sha:sub(1, 7) .. ") — :GitBaseOff to restore")
end

local function base_off()
  local state = read_state()
  if not state then
    return vim.notify("Not in base mode.", vim.log.levels.ERROR)
  end

  -- Anything committed or staged while based is about to be dropped: the branch
  -- goes back to its own tip and the index back to its snapshot.
  local head = git({ "rev-parse", "HEAD" })
  local staged = git({ "write-tree" })
  local drift = head ~= state.base and ("HEAD moved to " .. (head or "?"):sub(1, 7))
    or staged ~= git({ "rev-parse", state.base .. "^{tree}" }) and "changes were staged"
  if drift then
    local msg = drift .. " during base mode.\nRestoring drops that (commits are recoverable via `git reflog`)."
    if vim.fn.confirm(msg, "&Restore anyway\n&Cancel", 2) ~= 1 then
      return
    end
  end

  local _, err = git({ "symbolic-ref", "HEAD", state.branch })
  if err then
    return vim.notify("Failed to restore " .. state.branch .. ": " .. err, vim.log.levels.ERROR)
  end
  git({ "read-tree", state.tree })
  git({ "update-index", "--refresh" })
  vim.fn.delete(assert(state_path()))

  refresh_git_ui()
  vim.notify("Restored " .. state.branch:gsub("^refs/heads/", ""))
end

vim.api.nvim_create_user_command("GitBase", function(a) base_on(a.args) end, {
  nargs = 1,
  desc = "Git: treat <rev> as HEAD so every git tool diffs against it",
  complete = function()
    local refs = git({ "for-each-ref", "--format=%(refname:short)", "refs/heads", "refs/remotes" })
    return refs and vim.split(refs, "\n") or {}
  end,
})

vim.api.nvim_create_user_command("GitBaseOff", base_off, { desc = "Git: leave base mode, restore the branch" })

-- One key: prompts for a rev when off, restores when on.
vim.keymap.set("n", "<leader>gv", function()
  if read_state() then
    return base_off()
  end
  vim.ui.input({ prompt = "Review base: ", default = "origin/main..." }, function(rev)
    if rev and rev ~= "" then base_on(rev) end
  end)
end, { desc = "Git: toggle review base" })
