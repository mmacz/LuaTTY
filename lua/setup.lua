print("Running setup.lua to install dependencies...")

local function install_dependencies()
  local dependencies = {"lua-http", "lua-ssl", "dkjson"}
  
  for _, dep in ipairs(dependencies) do
    local command = "luarocks install " .. dep
    local result = vim.fn.system(command)

    if vim.v.shell_error ~= 0 then
      print("Error installing " .. dep .. ": " .. result)
    else
      print(dep .. " installed successfully!")
    end
  end
end

install_dependencies()
