local luatty = require("api")

vim.api.nvim_create_user_command("LuaTTYAuthorize", function(args)
    local input = vim.split(args.args, " ")
    if #input < 3 then
        vim.notify("Usage: :LuaTTYAuthorize <server_name> <username> <server_port>", vim.log.levels.ERROR)
        return
    end
    luatty.authorize(input[1], input[2], input[3])
end, { nargs = "*" })

vim.api.nvim_create_user_command("LuaTTYConnect", function()
    local websocket_url = luatty.get_websocket_url()
    if not websocket_url then
        vim.notify("You must authorize first using :LuaTTYAuthorize", vim.log.levels.ERROR)
        return
    end
    luatty.connect_to_websocket(websocket_url)
end, {})

vim.api.nvim_create_user_command("LuaTTYSend", function(args)
    local message = args.args
    if message == "" then
        vim.notify("Usage: :LuaTTYSend <message>", vim.log.levels.ERROR)
        return
    end
    luatty.send_message(message)
end, { nargs = 1 })

vim.api.nvim_create_user_command("LuaTTYInstallDeps", function()
    vim.notify("Dependencies are no longer needed as the plugin is now dependency-free!", vim.log.levels.INFO)
end, {})
