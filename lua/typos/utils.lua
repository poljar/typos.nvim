local M = {}

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
    local corrections_string

    if #typo["corrections"] == 1 then
        corrections_string = '`' .. typo["corrections"][1] .. '`'
    else
        -- TODO handle the case of multiple corrections
        corrections_string = typo["corrections"][1]
    end

    return {
        lnum = typo['line_num'] - 1,
        col = typo['byte_offset'],
        severity = vim.diagnostic.severity.WARN,
        message = 'typo: ' .. '`' .. typo["typo"] .. '`' .. " should be " .. corrections_string
    }
end

M.to_null_ls = function(typo)
    local diagnostic = M.to_diagnostic(typo)

    return {
        row = diagnostic["lnum"] + 1,
        col = diagnostic["col"] + 1,
        severity = diagnostic["severity"],
        message = diagnostic["message"],
    }
end

return M
