local function install_dependencies()
    local dependencies = { "http", "dkjson" }
    for _, dep in ipairs(dependencies) do
        local command = "luarocks install " .. dep
        local result = vim.fn.system(command)
        if vim.v.shell_error ~= 0 then
            vim.notify("Failed to install " .. dep .. ": " .. result, vim.log.levels.ERROR)
        else
            vim.notify(dep .. " installed successfully", vim.log.levels.INFO)
        end
    end
end

return {
    install_dependencies = install_dependencies,
}

