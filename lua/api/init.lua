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

local function http_post(url, body, callback)
    local parsed_url = require("socket.url").parse(url)
    local host = parsed_url.host
    local port = tonumber(parsed_url.port) or (parsed_url.scheme == "https" and 443 or 80)

    local tcp = vim.loop.new_tcp()
    tcp:connect(host, port, function(err)
        if err then
            tcp:close()
            return callback(nil, "Connection error: " .. err)
        end

        local request = {
            "POST " .. (parsed_url.path or "/") .. " HTTP/1.1",
            "Host: " .. host,
            "Content-Type: application/x-www-form-urlencoded",
            "Content-Length: " .. #body,
            "",
            body
        }
        local request_data = table.concat(request, "\r\n")

        tcp:write(request_data, function(write_err)
            if write_err then
                tcp:close()
                return callback(nil, "Write error: " .. write_err)
            end

            tcp:read_start(function(read_err, data)
                if read_err then
                    tcp:close()
                    return callback(nil, "Read error: " .. read_err)
                end

                if not data then
                    tcp:close()
                    return
                end

                local token = data:match('"token":"(.-)"')
                if token then
                    callback(token, nil)
                else
                    callback(nil, "Failed to parse token from response")
                end
                tcp:close()
            end)
        end)
    end)
end

function M.authenticate(username, endpoint, callback)
    local url = endpoint .. "/auth"
    local body = "username=" .. username

    http_post(url, body, function(token, err)
        if err then
            return callback(nil, err)
        end
        callback(token, nil)
    end)
end

function M.authorize(server_name, username, server_port)
    local endpoint = server_name .. ":" .. server_port
    M.authenticate(username, endpoint, function(token, err)
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
    end)
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

