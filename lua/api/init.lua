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

local function parse_url(address)
    local host, port = address:match("^([^:]+):?(%d*)$")
    if not host then
        return nil, "Invalid address format"
    end
    port = port ~= "" and tonumber(port) or 8880
    return { host = host, port = port }
end

local function http_post(address, body_table, callback)
    local parsed_url, err = parse_url(address)
    if not parsed_url then
        return callback(nil, "Address parsing error: " .. err)
    end

    local body = vim.fn.json_encode(body_table)

    vim.loop.getaddrinfo(parsed_url.host, nil, {}, function(err, addresses)
        if err or not addresses or #addresses == 0 then
            return callback(nil, "DNS resolution error: " .. (err or "No addresses found"))
        end

        local ip = addresses[1].addr
        local tcp = vim.loop.new_tcp()

        tcp:connect(ip, parsed_url.port, function(connect_err)
            if connect_err then
                tcp:close()
                return callback(nil, "Connection error: " .. connect_err)
            end

            local request = {
                "POST /auth HTTP/1.1",
                "Host: " .. parsed_url.host,
                "Content-Type: application/json",
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

                    local token = data:match('"token"%s*:%s*"(.-)"')
                    if token then
                        callback(token, nil)
                    else
                        callback(nil, "Failed to parse token from response: " .. data)
                    end
                    tcp:close()
                end)
            end)
        end)
    end)
end

function M.authenticate(username, server_address, callback)
    local body_table = { username = username }

    http_post(server_address, body_table, function(token, err)
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

