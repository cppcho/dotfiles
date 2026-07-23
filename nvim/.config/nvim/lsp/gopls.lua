-- Resolve imports from the module cache instead of vendor/ so a stale
-- vendor directory no longer breaks the LSP. `-mod=readonly` overrides Go's
-- auto `-mod=vendor` default (fixing the stale-vendor problem) while forbidding
-- gopls from rewriting go.sum or auto-downloading modules on every load.
-- Actual builds/CI still use vendor mode; this only affects gopls.
return {
  settings = {
    gopls = {
      buildFlags = { "-mod=readonly" },
      -- Don't pull the entire module into the workspace on open; keeps memory
      -- and load time sane in large monorepos.
      expandWorkspaceToModule = false,
      directoryFilters = {
        "-**/node_modules",
        "-**/vendor",
      },
    },
  },
}
