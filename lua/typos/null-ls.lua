local null_ls = require("null-ls")
local utils = require('typos.utils')

local M = {}

M.diagnostics = {
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

local function fix_typo_action(buffer_number, typo, correction)
    return function()
        local lines = { correction }

        local start_column, end_column = utils.get_typo_location(typo)
        local line_number = typo.line_num - 1

        vim.api.nvim_buf_set_text(
            buffer_number,
            line_number,
            start_column,
            line_number,
            end_column,
            lines
        )
    end
end

local function cursor_under_typo(params, typo)
    local start_column, end_column = utils.get_typo_location(typo)
    return params.row == typo.line_num and
        (params.col >= start_column and params.col < end_column)
end

M.actions = {
    method = null_ls.methods.CODE_ACTION,
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
            local actions = {}
            local typo = params.output

            if cursor_under_typo(params, typo) then
                for _, correction in ipairs(typo.corrections) do
                    table.insert(actions, {
                        title = "Replace " .. typo.typo .. " with " .. correction,
                        action = fix_typo_action(params.bufnr, typo, correction)
                    })
                end
            end

            return actions

        end
    }),
}

return M
