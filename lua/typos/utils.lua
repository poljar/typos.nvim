local M = {}

M.get_typo_location = function(typo)
    local start_column = typo.byte_offset
    local end_column = start_column + string.len(typo.typo)

    return start_column, end_column
end

local function format_message(typo)
    local corrections_string

    if #typo.corrections == 1 then
        corrections_string = '`' .. typo.corrections[1] .. '`'
    else
        -- TODO handle the case of multiple corrections
        corrections_string = typo.corrections[1]
    end

    return 'typo: ' .. '`' .. typo.typo .. '`' .. ' should be ' .. corrections_string
end

-- Convert the output of the typos command into a parsed list of typo tables.
M.output_to_typos = function(output)
    -- Each typo will be a json string delimited by a newline, split the string
    -- at each newline.
    local lines = vim.split(
        output,
        '\n',
        {
            plain = true,
            trimempty = true
        }
    )

    -- Parse each json string.
    return vim.tbl_map(vim.json.decode, lines)
end

-- typo will contain a table that contains the following key/value
-- pairs:
--  * `type` - The type of the, will usually be "typo"
--  * `path` - The path of the file that contains the typo
--  * `line_num` - The line number where the typo can be found
--  * `byte_offset` - The offset from the line start where the typo can be found
--  * `typo` - The word that contains the typo
--  * `corrections` - A list of suggestinons that will fix the typo
--
--  Example:
--  ```json
--      {
--          "type": "typo",
--          "path": "/home/test/myfile.rs",
--          "line_num": 123,
--          "byte_offset": 14,
--          "typo": "refernce",
--          "corrections": ["reference"]
--      }
--  ```
M.to_diagnostic = function(typo)
    local message = format_message(typo)
    local start_column, end_column = M.get_typo_location(typo)

    return {
        lnum = typo.line_num - 1,
        col = start_column,
        end_col = end_column,
        severity = vim.diagnostic.severity.WARN,
        message = message
    }
end

M.to_null_ls = function(typo)
    local diagnostic = M.to_diagnostic(typo)

    return {
        row = diagnostic.lnum + 1,
        col = diagnostic.col + 1,
        end_col = diagnostic.end_col + 1,
        severity = diagnostic.severity,
        message = diagnostic.message,
    }
end

return M
