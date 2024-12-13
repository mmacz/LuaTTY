local function add_packer_luarocks_paths()
    local hererocks_base = vim.fn.stdpath("cache") .. "/packer_hererocks/2.1.0-beta3"
    local lua_path = hererocks_base .. "/share/lua/5.1/?.lua;" .. hererocks_base .. "/share/lua/5.1/?/init.lua;" .. package.path
    local lua_cpath = hererocks_base .. "/lib/lua/5.1/?.so;" .. package.cpath
    package.path = lua_path
    package.cpath = lua_cpath
end

local function install_luarocks_dependencies()
    local luarocks_binary = vim.fn.stdpath("cache") .. "/packer_hererocks/2.1.0-beta3/bin/luarocks"

    -- Ensure luarocks exists
    if vim.fn.filereadable(luarocks_binary) == 0 then
        vim.notify("LuaRocks not found in Packer environment!", vim.log.levels.ERROR)
        return
    end

    local dependencies = { "http", "dkjson" }
    for _, dep in ipairs(dependencies) do
        local install_command = luarocks_binary .. " install " .. dep
        local result = vim.fn.system(install_command)
        if vim.v.shell_error ~= 0 then
            vim.notify("Failed to install " .. dep .. ": " .. result, vim.log.levels.ERROR)
        else
            vim.notify(dep .. " installed successfully!", vim.log.levels.INFO)
        end
    end
end

return {
    add_packer_luarocks_paths = add_packer_luarocks_paths,
    install_luarocks_dependencies = install_luarocks_dependencies,
}

