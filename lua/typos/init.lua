local utils = require("typos.utils")

local api = vim.api
local loop = vim.loop
local cmd = "typos"

local namespace = api.nvim_create_namespace("typos")

local M = {}

M.setup = function()
    local group = api.nvim_create_augroup("typos", {})

    api.nvim_create_autocmd(
        { 'BufWritePost', 'BufEnter', 'InsertLeave' },
        {
            group = group,
            callback = M.typos,
        })
end

-- Convert the output of our spawned task into diagnostic definitions.
local function parse_output(chunks)
    -- The output is a list of chunks of the typos-cli stdout output, join them
    -- into a single string.
    local output = table.concat(chunks)

    -- Each typo will be a json string delimited by a newline, split the string
    -- at each newline.
    local lines = vim.split(
        output,
        "\n",
        {
            plain = true,
            trimempty = true
        }
    )

    -- Parse each json string.
    local typos = vim.tbl_map(vim.json.decode, lines)

    -- Convert the typos JSON into a neovim diagnostic struct
    return vim.tbl_map(utils.to_diagnostic, typos)
end

local function handle_output(buffer_number, chunks)
    local diagnostics = parse_output(chunks)

    if api.nvim_buf_is_valid(buffer_number) then
        vim.diagnostic.set(namespace, buffer_number, diagnostics)
    end

end

local function read_output(buffer_number, cleanup)
    local chunks = {}

    return function(err, chunk)
        assert(not err, err)

        if chunk then
            table.insert(chunks, chunk)
        else
            cleanup()

            vim.schedule(function()
                handle_output(buffer_number, chunks)
            end)
        end
    end
end

local function send_buffer_content_to_stdin(buffer_number, stdin)
    local lines = vim.api.nvim_buf_get_lines(buffer_number, 0, -1, true)

    for _, line in ipairs(lines) do
        stdin:write(line .. '\n')
    end

    stdin:write('', function()
        stdin:shutdown(function()
            stdin:close()
        end)
    end)
end

M.typos = function()
    local stdout = loop.new_pipe(false)
    local stdin = loop.new_pipe(false)
    local handle
    local pid_or_err

    local env = {}
    table.insert(env, "PATH=" .. os.getenv("PATH"))

    local buffer_number = api.nvim_get_current_buf()

    local opts = {
        args = {
            "-",
            "--format=json",
        },
        stdio = { stdin, stdout, nil },
        env = env,
        cwd = vim.fn.getcwd(),
        detached = false
    }

    handle, pid_or_err = loop.spawn(cmd, opts, function(code)
        handle:close()

        if code ~= 0 then
            return
        end
    end)

    if not handle then
        stdout:close()
        stdin:close()
        vim.notify('Error running ' .. cmd .. ': ' .. pid_or_err, vim.log.levels.ERROR)
        return
    end

    local cleanup = function()
        stdout:shutdown()
        stdout:close()
    end

    stdout:read_start(read_output(buffer_number, cleanup))
    send_buffer_content_to_stdin(buffer_number, stdin)
end

return M
