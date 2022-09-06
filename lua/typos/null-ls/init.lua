local null_ls = require("null-ls")
local utils = require('typos.utils')

local M = {}

local typos = {
    method = null_ls.methods.DIAGNOSTICS,
    filetypes = {},
    generator = null_ls.generator({
        command = "typos",
        args = {
            "-",
            "--format=json",
        },
        to_stdin = true,
        ignore_stderr = true,
        format = "json",
        check_exit_code = function(code, stderr)
            local success = code >= 0

            if not success then
                print(stderr)
            end

            return success
        end,
        on_output = function(params)
            local diagnostics = {}

            local diagnostic = utils.to_null_ls(params.output)
            table.insert(diagnostics, diagnostic)

            return diagnostics
        end
    }),
}

M.diagnostic = typos

return M
