# LuaTTY

Client for the chaTTY server. Lua based and ready for Neovim integration.

## Installation

## Prerequisites
```bash
python -m pip install hererocks
hererocks ~/.cache/nvim/packer_hererocks/2.1.0-beta3 -r latest -l 5.1
```

Use [Packer](https://github.com/wbthomason/packer.nvim) to install:

```lua
use {
  'mmacz/LuaTTY',
  config = function()
      require('luatty')
  end,
}
