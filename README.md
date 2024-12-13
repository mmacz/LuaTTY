# LuaTTY

Client for the chaTTY server. Lua based and ready for Neovim integration.

## Installation

Use [Packer](https://github.com/wbthomason/packer.nvim) to install:

```lua
use {
  'mmacz/LuaTTY',
  config = function()
      require('luatty')
  end,
  run = function()
      vim.fn.system('luarocks install http')
      vim.fn.system('luarocks install dkjson')
  end
}
