-- https://github.com/neovim/nvim-lspconfig/issues/3189
return {
  on_init = function(client)
    -- Respect project-local luarc files
    local path = client.workspace_folders and client.workspace_folders[1] and client.workspace_folders[1].name
    if path and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc")) then
      return
    end

    -- Neovim runtime files, excluding user config to avoid duplicate indexing
    local config_dir = vim.fn.stdpath("config")
    local library = vim.tbl_filter(function(p)
      return p ~= config_dir and not vim.startswith(p, config_dir .. "/")
    end, vim.api.nvim_get_runtime_file("", true))

    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
      runtime = {
        version = "LuaJIT",
      },
      workspace = {
        checkThirdParty = false,
        library = library,
      },
    })
  end,
  settings = {
    Lua = {},
  },
}
