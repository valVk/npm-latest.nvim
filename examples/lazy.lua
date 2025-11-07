-- Example configuration for lazy.nvim
return {
  "valVk/npm-latest.nvim",
  event = "BufRead package.json",
  config = function()
    require("npm-latest").setup({
      colors = {
        up_to_date = "#98c379", -- Green for packages at latest
        outdated = "#d19a66", -- Orange for outdated packages
        latest = "#61afef", -- Blue for latest version info
      },
      icons = {
        enable = true,
        style = {
          up_to_date = "|  ",
          outdated = "|  ",
          latest = "|  ",
        },
      },
    })
  end,
  keys = {
    {
      "<leader>nl",
      function()
        require("npm-latest").show_versions()
      end,
      desc = "Show latest npm versions",
      ft = "json",
    },
    {
      "<leader>nh",
      function()
        require("npm-latest").clear()
      end,
      desc = "Hide npm versions",
      ft = "json",
    },
    {
      "<leader>nt",
      function()
        require("npm-latest").toggle()
      end,
      desc = "Toggle npm latest versions",
      ft = "json",
    },
    {
      "K",
      function()
        require("npm-latest").show_package_info()
      end,
      desc = "Show package info",
      ft = "json",
      buffer = true,
    },
  },
}
