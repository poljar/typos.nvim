local ok, null_ls = pcall(require, 'null-ls')

if not ok then
    return {}
end

local utils = require('typos.utils')

local M = {}

local name = 'typos.nvim'
local meta = {
    url = 'https://github.com/poljar/typos.nvim',
    description = 'Code actions and diagnostics for typos',
}

local function check_exit_code(code, stderr)
    local success = code >= 0

    if not success then
        print(stderr)
    end

    return success
end

M.diagnostics = {
    name = name,
    meta = meta,
    method = null_ls.methods.DIAGNOSTICS,
    filetypes = {},
    generator = null_ls.generator({
        command = 'typos',
        args = {
            '-',
            '--format=json',
        },
        to_stdin = true,
        ignore_stderr = true,
        format = 'line',
        check_exit_code = check_exit_code,
        on_output = function(line, _)
            local json = vim.json.decode(line)
            return utils.to_null_ls(json)
        end
    }),
}

local function fix_typo_title(typo, correction)
    return 'Replace ' .. typo.typo .. ' with ' .. correction
end

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

local function is_cursor_under_typo(params, typo)
    local start_column, end_column = utils.get_typo_location(typo)
    return params.row == typo.line_num and
        (params.col >= start_column and params.col < end_column)
end

M.actions = {
    name = name,
    meta = meta,
    method = null_ls.methods.CODE_ACTION,
    filetypes = {},
    generator = null_ls.generator({
        command = 'typos',
        args = {
            '-',
            '--format=json',
        },
        to_stdin = true,
        ignore_stderr = true,
        format = 'json',
        check_exit_code = check_exit_code,
        on_output = function(params)
            local actions = {}
            local typo = params.output

            if is_cursor_under_typo(params, typo) then
                for _, correction in ipairs(typo.corrections) do
                    table.insert(actions, {
                        title = fix_typo_title(typo, correction),
                        action = fix_typo_action(params.bufnr, typo, correction)
                    })
                end
            end

            return actions

        end
    }),
}

return M
