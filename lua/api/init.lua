local M = {
    state = {
        server_name = nil,
        username = nil,
        server_port = nil,
        token = nil,
        connected = false,
        ws_client = nil,
        message_callback = nil,
        activity_callback = nil,
    },
}

local http = require("socket.http")

function M.authenticate(username, endpoint)
    if not username or not endpoint then
        return nil, "Invalid username or endpoint"
    end

    local response, status = http.request(endpoint .. "/auth", "username=" .. username)
    if status ~= 200 then
        return nil, "Authentication failed with status: " .. status
    end
    local token = response.match('"token":"(.-)"')

    return token, nil
end

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
    return "ws://" .. M.state.server_name .. ":" .. M.state.server_port .. "/ws"
end

function M.connect_to_websocket(websocket_url)
    local client, err = require("websocket").new_client()
    if not client then
        vim.notify("Failed to create WebSocket client: " .. err, vim.log.levels.ERROR)
        return
    end

    client:connect(websocket_url, {
        on_message = function(message)
            if M.state.message_callback then
                M.state.message_callback(message)
            end
        end,
        on_close = function()
            vim.notify("WebSocket disconnected.", vim.log.levels.WARN)
            M.state.connected = false
            M.state.ws_client = nil
        end,
        on_activity = function(event)
            if M.state.activity_callback then
                M.state.activity_callback(event)
            end
        end,
    })

    M.state.ws_client = client
    M.state.connected = true
    vim.notify("WebSocket connected to " .. websocket_url, vim.log.levels.INFO)
end

function M.send_message(message)
    if not M.state.ws_client or not M.state.connected then
        vim.notify("WebSocket client is not connected.", vim.log.levels.ERROR)
        return
    end

    M.state.ws_client:send(message)
    vim.notify("Message sent: " .. message, vim.log.levels.INFO)
end

function M.on_message(callback)
    M.state.message_callback = callback
end

function M.on_activity(callback)
    M.state.activity_callback = callback
end

return M

