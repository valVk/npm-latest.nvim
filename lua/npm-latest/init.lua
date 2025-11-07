local M = {}

M.namespace = vim.api.nvim_create_namespace("npm-latest")
M.config = {
  colors = {
    up_to_date = "#3C4048",
    outdated = "#d19a66",
    latest = "#98c379",
  },
  icons = {
    enable = true,
    style = {
      up_to_date = "|  ",
      outdated = "|  ",
      latest = "|  ",
    },
  },
  registry_url = "https://registry.npmjs.org",
}

local function fetch_latest_version(package_name, callback)
  local url = M.config.registry_url .. "/" .. package_name .. "/latest"

  vim.system({ "curl", "-s", url }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(nil)
        return
      end

      local success, json = pcall(vim.json.decode, result.stdout)
      if success and json and json.version then
        callback(json.version)
      else
        callback(nil)
      end
    end)
  end)
end

local function fetch_package_info(package_name, callback)
  local url = M.config.registry_url .. "/" .. package_name .. "/latest"

  vim.system({ "curl", "-s", url }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(nil)
        return
      end

      local success, json = pcall(vim.json.decode, result.stdout)
      if success and json then
        callback(json)
      else
        callback(nil)
      end
    end)
  end)
end

local function parse_version(version_string)
  if not version_string then
    return nil
  end
  return version_string:match("[%d%.]+")
end

local function compare_versions(current, latest)
  if not current or not latest then
    return "unknown"
  end

  current = parse_version(current)
  latest = parse_version(latest)

  if not current or not latest then
    return "unknown"
  end

  if current == latest then
    return "up_to_date"
  end

  return "outdated"
end

local function get_package_line_info(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local packages = {}
  local in_dependencies = false

  for line_num, line in ipairs(lines) do
    if line:match('"dependencies"') or line:match('"devDependencies"') then
      in_dependencies = true
    elseif line:match('^%s*}') then
      in_dependencies = false
    elseif in_dependencies then
      local package_name, version = line:match('"([^"]+)"%s*:%s*"([^"]+)"')
      if package_name and version and not version:match("^file:") then
        packages[line_num - 1] = {
          name = package_name,
          current_version = version,
        }
      end
    end
  end

  return packages
end

function M.show_versions(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  M.clear(bufnr)

  local packages = get_package_line_info(bufnr)
  local total_packages = vim.tbl_count(packages)
  local processed = 0
  local displayed = 0

  if total_packages == 0 then
    return
  end

  for line_num, pkg_info in pairs(packages) do
    fetch_latest_version(pkg_info.name, function(latest_version)
      processed = processed + 1

      vim.schedule(function()
        if latest_version then
          local status = compare_versions(pkg_info.current_version, latest_version)
          local icon = M.config.icons.enable and M.config.icons.style[status] or ""
          local text = string.format("%s%s", icon, latest_version)

          -- Map status to highlight group
          local hl_group_map = {
            up_to_date = "NpmLatestUpToDate",
            outdated = "NpmLatestOutdated",
            latest = "NpmLatestLatest",
          }
          local hl_group = hl_group_map[status] or "Comment"

          if vim.api.nvim_buf_is_valid(bufnr) then
            local ok, err = pcall(vim.api.nvim_buf_set_extmark, bufnr, M.namespace, line_num, 0, {
              virt_text = { { text, hl_group } },
              virt_text_pos = "eol",
            })
            if ok then
              displayed = displayed + 1
            end
          end
        end
      end)
    end)
  end
end

function M.clear(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
end

function M.toggle(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, M.namespace, 0, -1, {})

  if #extmarks > 0 then
    M.clear(bufnr)
  else
    M.show_versions(bufnr)
  end
end

local function get_package_name_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  local package_name = line:match('"([^"]+)"%s*:%s*"[^"]+"')

  if package_name then
    local start_pos = line:find('"' .. package_name .. '"')
    local end_pos = start_pos + #package_name + 1

    if col >= start_pos - 1 and col <= end_pos then
      return package_name
    end
  end

  return nil
end

function M.show_package_info()
  local package_name = get_package_name_under_cursor()

  if not package_name then
    vim.notify("No package found under cursor", vim.log.levels.WARN)
    return
  end

  vim.notify("Fetching info for " .. package_name .. "...", vim.log.levels.INFO)

  fetch_package_info(package_name, function(info)
    if not info then
      vim.notify("Failed to fetch info for " .. package_name, vim.log.levels.ERROR)
      return
    end

    local lines = {
      string.format("%s v%s", info.name or package_name, info.version or "unknown"),
      string.rep("─", 60),
      "",
    }

    if info.description then
      table.insert(lines, "Description:")
      table.insert(lines, "  " .. info.description)
      table.insert(lines, "")
    end

    if info.homepage then
      table.insert(lines, "Homepage: " .. info.homepage)
    end

    if info.repository and info.repository.url then
      local repo_url = info.repository.url:gsub("git+", ""):gsub("%.git$", "")
      table.insert(lines, "Repository: " .. repo_url)
    end

    if info.license then
      table.insert(lines, "License: " .. info.license)
    end

    if info.author then
      local author = type(info.author) == "string" and info.author or info.author.name
      if author then
        table.insert(lines, "Author: " .. author)
      end
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

    local width = 70
    local height = #lines
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local opts = {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
      title = " Package Info ",
      title_pos = "center",
    }

    local win = vim.api.nvim_open_win(buf, true, opts)

    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
  end)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Create highlight groups for the colors
  vim.api.nvim_set_hl(0, "NpmLatestUpToDate", { fg = M.config.colors.up_to_date })
  vim.api.nvim_set_hl(0, "NpmLatestOutdated", { fg = M.config.colors.outdated })
  vim.api.nvim_set_hl(0, "NpmLatestLatest", { fg = M.config.colors.latest })

  vim.api.nvim_create_autocmd("BufRead", {
    pattern = "package.json",
    callback = function()
      M.show_versions(vim.api.nvim_get_current_buf())
    end,
  })
end

return M
