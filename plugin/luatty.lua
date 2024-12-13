local luatty = require("luatty")

local function open_chat_buffer()
    local buf = vim.api.nvim_create_buf(false, true) -- No file, no swap
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_set_current_buf(buf)
    return buf
end

local chat_buffer = nil

local function append_to_buffer(buf, message)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, { message })
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

vim.api.nvim_create_user_command("LuaTTYConnect", function(args)
    local input = vim.split(args.args, " ")
    if #input < 3 then
        vim.notify("Usage: :LuaTTYConnect <server_name> <username> <server_port>", vim.log.levels.ERROR)
        return
    end

    local server_name, username, server_port = input[1], input[2], input[3]

    luatty.authorize(server_name, username, server_port)
    if not luatty.state.token then
        vim.notify("Authorization failed. Cannot connect to server.", vim.log.levels.ERROR)
        return
    end

    if not chat_buffer then
        chat_buffer = open_chat_buffer()
    end

    local websocket_url = luatty.get_websocket_url()
    if not websocket_url then
        vim.notify("Invalid WebSocket URL. Check your authorization details.", vim.log.levels.ERROR)
        return
    end

    luatty.connect_to_websocket(websocket_url)

    luatty.on_message(function(message)
        append_to_buffer(chat_buffer, "Message: " .. message)
    end)

    luatty.on_activity(function(event)
        append_to_buffer(chat_buffer, "Activity: " .. event)
    end)

    vim.notify("Connected to server successfully!", vim.log.levels.INFO)
end, { nargs = "*" })

vim.api.nvim_create_user_command("LuaTTYSend", function(args)
    local message = args.args
    if message == "" then
        vim.notify("Usage: :LuaTTYSend <message>", vim.log.levels.ERROR)
        return
    end
    luatty.send_message(message)
end, { nargs = 1 })

