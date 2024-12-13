local plugin_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/luatty"
if not string.find(vim.o.runtimepath, plugin_path, 1, true) then
    vim.o.runtimepath = vim.o.runtimepath .. "," .. plugin_path
end

print("LuaTTY loaded & added to runtimepath")

local M = {
    state = {
        server_name = nil,
        username = nil,
        server_port = nil,
        token = nil,
        connected = false,
        ws_client = nil,
    },
}

function M.authorize(server_name, username, server_port)
    local token, err = M.authenticate(username, server_name .. ":" .. server_port)
    if not token then
        vim.notify("Authorization failed: " .. (err or "Unknown error"), vim.log.levels.ERROR)
        return
    end

    M.state.server_name = server_name
    M.state.username = username
    M.state.server_port = server_port
    M.state.token = token
    M.state.connected = true

    vim.notify("Authorization successful! Token received.", vim.log.levels.INFO)
end

function M.get_websocket_url()
    if not M.state.server_name or not M.state.server_port then
        return nil
    end
    return "ws://" .. M.state.server_name .. "/ws" .. ":" .. M.state.server_port
end

function M.connect_to_websocket(websocket_url)
    local client, err = socket.tcp()
    if not client then
        vim.notify("Failed to create WebSocket client: " .. err, vim.log.levels.ERROR)
        return
    end

    client:connect(websocket_url)
    M.state.ws_client = client
    vim.notify("WebSocket connected to " .. websocket_url, vim.log.levels.INFO)
end

function M.send_message(message)
    if not M.state.ws_client then
        vim.notify("WebSocket client is not connected.", vim.log.levels.ERROR)
        return
    end

    M.state.ws_client:send(message)
    vim.notify("Message sent: " .. message, vim.log.levels.INFO)
end

return M

