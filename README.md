# npm-latest.nvim

A Neovim plugin that displays the **absolute latest versions** of npm packages in your `package.json` file, fetched directly from the npm registry API.

Unlike other plugins that use `npm outdated` (which respects semver constraints), this plugin shows the actual latest version available on npm, similar to how VS Code works.

## Features

- **Direct Registry Queries**: Fetches version information directly from `https://registry.npmjs.org`
- **Absolute Latest Versions**: Shows the true latest version, ignoring semver constraints in your `package.json`
- **Color-Coded Display**:
  - 🟢 Green for up-to-date packages
  - 🟠 Orange for outdated packages
- **Package Information Hover**: Press `K` on any package name to see detailed information (description, repository, license, author, etc.) in a floating window
- **Automatic Display**: Versions appear automatically when opening `package.json` files
- **Lightweight**: Uses async curl requests with no external dependencies

## Why This Plugin?

If you have `"esbuild": "^0.12.24"` in your `package.json`, tools like `npm outdated` will only show you versions in the `0.12.x` range. But the actual latest version might be `0.25.12`! This plugin solves that problem by querying the npm registry directly.

## Requirements

- Neovim >= 0.9.0
- `curl` command available in your system

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "valVk/npm-latest.nvim",
  event = "BufRead package.json",
  config = function()
    require("npm-latest").setup({
      colors = {
        up_to_date = "#98c379",  -- Green
        outdated = "#d19a66",     -- Orange
      },
      icons = {
        enable = true,
        style = {
          up_to_date = "|  ",
          outdated = "|  ",
        },
      },
    })
  end,
  keys = {
    {
      "<leader>nl",
      function() require("npm-latest").show_versions() end,
      desc = "Show latest npm versions",
      ft = "json",
    },
    {
      "<leader>nh",
      function() require("npm-latest").clear() end,
      desc = "Hide npm versions",
      ft = "json",
    },
    {
      "<leader>nt",
      function() require("npm-latest").toggle() end,
      desc = "Toggle npm latest versions",
      ft = "json",
    },
    {
      "K",
      function() require("npm-latest").show_package_info() end,
      desc = "Show package info",
      ft = "json",
    },
  },
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "valVk/npm-latest.nvim",
  ft = "json",
  config = function()
    require("npm-latest").setup()
  end
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'valVk/npm-latest.nvim'

lua << EOF
require("npm-latest").setup()
EOF
```

## Configuration

Default configuration:

```lua
require("npm-latest").setup({
  colors = {
    up_to_date = "#3C4048",   -- Color for up-to-date packages
    outdated = "#d19a66",      -- Color for outdated packages
    latest = "#98c379",        -- Color for latest version info
  },
  icons = {
    enable = true,             -- Whether to display icons
    style = {
      up_to_date = "|  ",     -- Icon for up-to-date packages
      outdated = "|  ",       -- Icon for outdated packages
      latest = "|  ",         -- Icon for latest info
    },
  },
  registry_url = "https://registry.npmjs.org",  -- npm registry URL
})
```

## Usage

### Automatic Display

The plugin automatically displays version information when you open a `package.json` file.

### Manual Commands

- **Show versions**: `<leader>nl` or `:lua require("npm-latest").show_versions()`
- **Hide versions**: `<leader>nh` or `:lua require("npm-latest").clear()`
- **Toggle versions**: `<leader>nt` or `:lua require("npm-latest").toggle()`
- **Show package info**: Move cursor to a package name and press `K`

### Package Information Popup

When you press `K` on a package name, a floating window appears with:
- Package name and latest version
- Description
- Homepage URL
- Repository URL
- License
- Author information

Press `q` or `Esc` to close the popup.

## How It Works

1. Parses your `package.json` to find dependencies and devDependencies
2. Skips `file:` protocol dependencies (local packages)
3. Queries `https://registry.npmjs.org/{package}/latest` for each package
4. Displays the latest version as virtual text at the end of each line
5. Color-codes based on whether your current version matches the latest

## Comparison with Other Tools

| Tool | Shows Absolute Latest | Respects Semver | Direct Registry API |
|------|----------------------|-----------------|---------------------|
| **npm-latest.nvim** | ✅ | ❌ | ✅ |
| npm outdated | ❌ | ✅ | ❌ |
| package-info.nvim | ❌ | ✅ | ❌ |
| VS Code built-in | ✅ | ❌ | ✅ |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details

## Acknowledgments

Inspired by VS Code's package.json hover functionality and built to solve the limitations of semver-constrained version checking tools.
