local http = require("http")
local websocket = require("http.websocket")
local dkjson = require("dkjson")

local M = {
    state = {
        token = nil,
        username = nil,
        server_name = nil,
        server_port = nil,
        connected = false,
        buffer_id = nil,
    },
    event_handlers = {
        message = nil,
        user_joined = nil,
        user_left = nil,
    },
    ws_client = nil,
}

local function authenticate(username, server_address)
    local url = server_address .. "/auth"
    local request_body = dkjson.encode({ username = username })
    local res, body = http.request("POST", url, {
        headers = {
            ["Content-Type"] = "application/json",
        },
        body = request_body,
    })
    if res.status == 200 then
        local api_response, pos, err = dkjson.decode(body, 1, nil)
        if api_response.token then
            return api_response.token
        else
            return nil, "Authentication failed"
        end
    else
        return nil, "Authentication error: " .. res.status
    end
end

function M.authorize(server_name, username, server_port)
    M.state.server_name = server_name
    M.state.username = username
    M.state.server_port = server_port

    local token, err = authenticate(username, server_name .. ":" .. server_port)
    if token then
        M.state.token = token
        M.state.connected = true
        print("Authentication successful!")

        M.open_chat_buffer()

    else
        M.state.connected = false
        print("Error: " .. err)
    end
end

function M.open_chat_buffer()
    vim.cmd('vsplit')
    vim.cmd('enew')
    vim.api.nvim_buf_set_name(0, "LuaTTY Chat - " .. M.state.username)
    M.state.buffer_id = vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_option(M.state.buffer_id, "modifiable", false)
    vim.api.nvim_buf_set_option(M.state.buffer_id, "buftype", "nofile")
    vim.api.nvim_buf_set_option(M.state.buffer_id, "filetype", "lua-tty")

    vim.api.nvim_buf_set_lines(M.state.buffer_id, 0, -1, false, { "Connected to LuaTTY chat server." })
end

function M.send_message(message)
    if not M.state.connected then
        print("Not connected. Please log in first.")
        return
    end

    local ws_message = dkjson.encode({ message = message })
    if M.ws_client then
        M.ws_client:send(ws_message)
        print("Message sent: " .. message)

        vim.api.nvim_buf_set_lines(M.state.buffer_id, -1, -1, false, { "You: " .. message })
    else
        print("WebSocket client is not initialized.")
    end
end

function M.on_message(handler)
    M.event_handlers["message"] = handler
end

function M.on_user_joined(handler)
    M.event_handlers["user_joined"] = handler
end

function M.on_user_left(handler)
    M.event_handlers["user_left"] = handler
end

local function handle_event(event_type, data)
    local handler = M.event_handlers[event_type]
    if handler then
        handler(data)
    else
        print("No handler registered for event: " .. event_type)
    end
end

function M.connect_to_websocket()
    if not M.state.token then
        print("No authentication token found!")
        return
    end

    local ws_url = "ws://" .. M.state.server_name .. ":" .. M.state.server_port .. "/ws"
    
    local ws, err = websocket.connect(ws_url)
    if not ws then
        print("Error connecting to WebSocket: " .. err)
        return
    end
    
    M.ws_client = ws

    ws:on("message", function(_, msg)
        local event, pos, err = dkjson.decode(msg, 1, nil)
        if event then
            if event.type == "message" then
                handle_event("message", event)
            elseif event.type == "user_joined" then
                handle_event("user_joined", event)
            elseif event.type == "user_left" then
                handle_event("user_left", event)
            else
                print("Received unknown event: " .. event.type)
            end
        else
            print("Failed to decode JSON: " .. err)
        end
    end)

    print("WebSocket connected!")
end

function M.close_connection()
    if M.ws_client then
        M.ws_client:close()
        print("WebSocket connection closed.")
    else
        print("No WebSocket connection to close.")
    end
end

return M

